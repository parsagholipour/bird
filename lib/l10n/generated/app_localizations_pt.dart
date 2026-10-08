// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get commonTryAgain => 'Tentar de novo';

  @override
  String get languageKeyLabel => 'Idioma';

  @override
  String languageKeySemantics(String language) {
    return 'Idioma: $language. Mude o idioma do jogo.';
  }

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String languageSystemDetail(String language) {
    return 'Segue o celular: $language';
  }

  @override
  String get languageCurrent => 'Idioma atual';

  @override
  String get languageName_en => 'Inglês';

  @override
  String get languageName_es_419 => 'Espanhol latino';

  @override
  String get languageName_pt_br => 'Português (Brasil)';

  @override
  String get languageName_id => 'Indonésio';

  @override
  String get languageName_fr => 'Francês';

  @override
  String get languageName_de => 'Alemão';

  @override
  String get languageName_ja => 'Japonês';

  @override
  String get languageName_ko => 'Coreano';

  @override
  String get languageName_tr => 'Turco';

  @override
  String get languageName_zh_hant => 'Chinês tradicional';

  @override
  String get languageName_ru => 'Russo';

  @override
  String get languageName_ar => 'Árabe';

  @override
  String get voicePackReady => 'Vozes prontas';

  @override
  String get voicePackDownload => 'Baixar vozes';

  @override
  String voicePackDownloading(int percent) {
    return 'Vozes $percent%';
  }

  @override
  String get voicePackStarting => 'Baixando vozes';

  @override
  String get voicePackEnglish => 'Vozes em inglês';

  @override
  String get voicePackFailed => 'Erro nas vozes';

  @override
  String get settingsTitle => 'Fique à vontade.';

  @override
  String get settingsSectionSound => 'Som';

  @override
  String get settingsSectionComfort => 'Conforto';

  @override
  String get settingsMusicTitle => 'Trilha do Clube do Céu';

  @override
  String get settingsMusicDetail => 'Temas do menu, da aventura e dos chefões.';

  @override
  String get settingsEffectsTitle => 'Efeitos sonoros';

  @override
  String get settingsEffectsDetail => 'Sons de voo, combate, itens e menus.';

  @override
  String get settingsVoicesTitle => 'Vozes dos personagens';

  @override
  String get settingsVoicesDetail =>
      'Cenas da história, bilhetes e gritos de turbo.';

  @override
  String get settingsReducedMotionTitle => 'Reduzir movimento';

  @override
  String get settingsReducedMotionDetail =>
      'Menus calmos e menos efeitos decorativos.';

  @override
  String get settingsSwitchOn => 'SIM';

  @override
  String get settingsSwitchOff => 'NÃO';

  @override
  String get settingsUnavailable => 'As configurações não carregaram.';

  @override
  String get settingsPrivacyKicker => 'NO CELULAR. SEMPRE.';

  @override
  String get settingsPrivacyTitle => 'Sua câmera é só sua.';

  @override
  String get settingsPrivacyBody =>
      'Vídeo e áudio opcional do microfone ficam neste celular. Clipes não salvos são apagados. Nada é enviado.';

  @override
  String get settingsCameraLab => 'Laboratório da câmera';

  @override
  String get settingsAbout => 'Sobre e licenças';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'Sobre e licenças, versão $version';
  }

  @override
  String get settingsReset => 'Apagar progresso local';

  @override
  String settingsResetDone(String bird) {
    return 'Um novo começo. $bird está esperando por você.';
  }

  @override
  String get settingsResetTitle => 'Começar uma nova aventura?';

  @override
  String get settingsResetBody =>
      'Isto apaga deste celular seus vídeos salvos, replays, pontuações, voos, fases criadas e configurações. Não dá para desfazer.';

  @override
  String get settingsResetBodyCloud =>
      'Isto apaga deste celular seus vídeos salvos, replays, pontuações, voos, fases criadas e configurações, e também seu salvamento na nuvem do Play Games. Não dá para desfazer.';

  @override
  String get settingsResetConfirm => 'Apagar tudo';

  @override
  String get settingsResetKeep => 'Manter meu progresso';

  @override
  String get playGamesName => 'Play Games';

  @override
  String get playGamesConnected => 'Conectado';

  @override
  String get playGamesNotConnected => 'Desconectado';

  @override
  String get playGamesConnecting => 'Conectando…';

  @override
  String get playGamesConnectFailed => 'Não foi possível conectar';

  @override
  String get playGamesIdle => 'Salvar na nuvem e conquistas';

  @override
  String get playGamesSaving => 'Salvando na nuvem…';

  @override
  String get playGamesOfflineUnsaved => 'Sem internet · ainda não salvo';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'Sem internet · salvo $ago';
  }

  @override
  String get playGamesUpdateNeeded => 'Atualize para sincronizar';

  @override
  String get playGamesUnreadable => 'Não deu para ler o salvamento';

  @override
  String get playGamesOn => 'Salvamento na nuvem ativo';

  @override
  String get playGamesResetElsewhere => 'Apagado em outro celular';

  @override
  String playGamesRestored(String ago) {
    return 'Restaurado da nuvem · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'Salvo na nuvem · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Conquistas do Play Games';

  @override
  String get playGamesConnectSemantics => 'Conectar ao Play Games';

  @override
  String get playGamesAchievements => 'Conquistas';

  @override
  String get playGamesConnect => 'Conectar';

  @override
  String get timeAgoJustNow => 'agora mesmo';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'há $minutes min',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'há $hours h',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'há $days dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '+1 VIDA!';

  @override
  String calloutStarTrio(int points) {
    return '3 ESTRELAS +$points!';
  }

  @override
  String get calloutNiceShot => 'BELO TIRO!';

  @override
  String calloutNiceShotPoints(int points) {
    return 'BELO TIRO +$points!';
  }

  @override
  String get calloutSmash => 'ESMAGOU!';

  @override
  String calloutSmashPoints(int points) {
    return 'ESMAGOU +$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return 'ESMAGOU ×$count!';
  }

  @override
  String get calloutBossDown => 'CHEFÃO CAIU!';

  @override
  String calloutBossDownPoints(int points) {
    return 'CHEFÃO CAIU +$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier× PODER ESTELAR!';
  }

  @override
  String get calloutPerfect => 'PERFEITO!';

  @override
  String calloutPerfectChain(int count) {
    return 'PERFEITO ×$count';
  }

  @override
  String get calloutShieldReady => 'ESCUDO PRONTO';

  @override
  String get calloutShieldSave => 'ESCUDO SALVOU!';

  @override
  String get calloutKeepFlying => 'SIGA VOANDO!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PORTAIS!',
      one: '$count PORTAL!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'SÓ $seconds SEGUNDOS!',
      one: 'SÓ $seconds SEGUNDO!',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => 'ÍMÃ ESTELAR!';

  @override
  String get calloutSprintRing => 'ANEL TURBO!';

  @override
  String calloutRushChain(int count) {
    return 'ANÉIS ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'METEORO +$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return 'MORCEGO +$points!';
  }

  @override
  String get calloutScorched => 'CHAMUSCADO!';

  @override
  String get region_jungle => 'Selva';

  @override
  String get region_antarctica => 'Antártida';

  @override
  String get region_aztec => 'Terra Asteca';

  @override
  String get region_paris => 'Paris';

  @override
  String get region_egypt => 'Egito';

  @override
  String get region_cyberpunk => 'Cidade Cyberpunk';

  @override
  String get region_china => 'China';

  @override
  String get region_brazil => 'Brasil';

  @override
  String get region_newYork => 'Nova York';

  @override
  String get region_arabia => 'Arábia Antiga';

  @override
  String get region_rome => 'Roma Antiga';

  @override
  String get region_mexico => 'México';

  @override
  String get region_sea => 'Mar Aberto';

  @override
  String get boss_baronBat_name => 'Barão Morcego';

  @override
  String get boss_spitterBeetle_name => 'Rei Cuspidor';

  @override
  String get boss_duskMoth_name => 'Imperatriz do Crepúsculo';

  @override
  String get boss_pirate_name => 'Capitão Pirata';

  @override
  String get boss_dragon_name => 'Dragão das Brasas';

  @override
  String get boss_kingCoo_name => 'Rei Pruu';

  @override
  String get boss_searchlightGargoyle_name => 'Gárgula do Holofote';

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
  String get playMode_pushUp => 'Voo de Flexões';

  @override
  String get playMode_jump => 'Pule e Voe';

  @override
  String get playMode_touch => 'Toque e Voe';

  @override
  String get playMode_squat => 'Agache e Voe';

  @override
  String get chapter_1_route => 'A Rota das Copas';

  @override
  String get chapter_1_postmark => 'ROTA DAS COPAS';

  @override
  String get chapter_1_postcard =>
      'As cartas voltaram a chegar nas copas! Os tucanos agradecem (bem alto). A coroa do Barão Morcego está na nossa estante.';

  @override
  String get chapter_1_postscript =>
      'A estrada antiga está com cheiro de coisa fervendo.';

  @override
  String get chapter_2_route => 'A Estrada Antiga';

  @override
  String get chapter_2_postmark => 'ESTRADA ANTIGA';

  @override
  String get chapter_2_postcard =>
      'As caravanas voltaram a andar, e a única coisa fervendo é chá de menta. Guardamos a coroa de frasco do Rei como vaso.';

  @override
  String get chapter_2_postscript =>
      'Os lampiões da cidade apagaram ontem à noite. Traga uma luz.';

  @override
  String get chapter_3_route => 'A Linha dos Lampiões';

  @override
  String get chapter_3_postmark => 'LINHA DOS LAMPIÕES';

  @override
  String get chapter_3_postcard =>
      'Os lampiões estão acesos e o correio noturno está bem acordado! Paris manda um croissant. Nova York manda um pretzel.';

  @override
  String get chapter_3_postscript => 'Os sinos do porto pararam de tocar.';

  @override
  String get chapter_4_route => 'A Rota da Maré';

  @override
  String get chapter_4_postmark => 'ROTA DA MARÉ';

  @override
  String get chapter_4_postcard =>
      'Os sinos do porto tocam de novo por cartas, não por canhões. O papagaio ficou. Ele manda um oi.';

  @override
  String get chapter_4_postscript =>
      'Dizem que o céu na beira do mapa está pegando fogo.';

  @override
  String get chapter_5_route => 'A Beira do Mapa';

  @override
  String get chapter_5_postmark => 'BEIRA DO MAPA';

  @override
  String get chapter_5_postcard =>
      'O céu está limpo de polo a polo e todas as rotas estão funcionando. O Clube do Céu inteiro tem orgulho de você.';

  @override
  String get chapter_5_postscript =>
      'O céu infinito continua lá, quando você quiser.';

  @override
  String get level_1_1_name => 'Primeira Entrega';

  @override
  String get level_1_1_cargo => 'Um cartão de aniversário pros tucanos gêmeos';

  @override
  String get level_1_1_sender => 'Os tucanos gêmeos';

  @override
  String get level_1_1_hint => 'Toque para bater as asas. Voe pelas estrelas.';

  @override
  String get level_1_2_name => 'Sequência Estelar';

  @override
  String get level_1_2_cargo => 'Mapas do céu para o bicho-preguiça astrônomo';

  @override
  String get level_1_2_sender => 'O bicho-preguiça astrônomo';

  @override
  String get level_1_2_hint =>
      'Pegue estrelas em sequência para 3×; três portais perfeitos dão um ímã.';

  @override
  String get level_1_3_name => 'Patrulha dos Morcegos';

  @override
  String get level_1_3_cargo => 'Luzinhas para a creche dos vaga-lumes';

  @override
  String get level_1_3_sender => 'A creche dos vaga-lumes';

  @override
  String get level_1_3_hint =>
      'Atirar: toque em Atirar para derrubar os morcegos.';

  @override
  String get level_1_4_name => 'Céu de Carnaval';

  @override
  String get level_1_4_cargo => 'Boás de plumas para o desfile de Carnaval';

  @override
  String get level_1_4_sender => 'As araras do samba';

  @override
  String get level_1_4_hint =>
      'Ventania! Fique de olho no ! e desvie das bolas de futebol.';

  @override
  String get level_1_5_name => 'Correio Expresso';

  @override
  String get level_1_5_cargo => 'Um convite urgente pro mestre de bateria';

  @override
  String get level_1_5_sender => 'O mestre de bateria';

  @override
  String get level_1_5_hint => 'O Turbo esmaga morcegos e dispara à frente.';

  @override
  String get level_1_6_name => 'Degraus do Templo';

  @override
  String get level_1_6_cargo => 'Cacau para os cozinheiros do templo';

  @override
  String get level_1_6_sender => 'Os cozinheiros do templo';

  @override
  String get level_1_7_name => 'Poleiro do Amanhecer';

  @override
  String get level_1_7_cargo => 'Um relógio de sol pro guardião da aurora';

  @override
  String get level_1_7_sender => 'O guardião da aurora';

  @override
  String get level_1_8_name => 'Barão Morcego';

  @override
  String get level_1_8_cargo => 'Último aviso para o Barão Morcego';

  @override
  String get level_1_8_sender => 'Barão Morcego';

  @override
  String get level_2_1_name => 'Estrada dos Besouros';

  @override
  String get level_2_1_cargo => 'Coroas de louro para os corredores de biga';

  @override
  String get level_2_1_sender => 'Os corredores de biga';

  @override
  String get level_2_1_hint => 'Besouros cospem sementes. Derrube as sementes.';

  @override
  String get level_2_2_name => 'Portais Bloqueados';

  @override
  String get level_2_2_cargo => 'Um cinzel novo para o escultor';

  @override
  String get level_2_2_sender => 'O escultor';

  @override
  String get level_2_2_hint =>
      'Segure Atirar para lançar uma pedrona que quebra pedra.';

  @override
  String get level_2_3_name => 'Fuga do Incêndio';

  @override
  String get level_2_3_cargo => 'Baldes de água para os bombeiros';

  @override
  String get level_2_3_sender => 'Os bombeiros';

  @override
  String get level_2_3_hint => 'Voe pelos anéis dourados para fugir do fogo!';

  @override
  String get level_2_4_name => 'Zigue-Zagues do Nilo';

  @override
  String get level_2_4_cargo => 'Um livro de charadas novas para a Esfinge';

  @override
  String get level_2_4_sender => 'A Esfinge';

  @override
  String get level_2_5_name => 'Céu Desabando';

  @override
  String get level_2_5_cargo => 'Um telescópio pro astrônomo da pirâmide';

  @override
  String get level_2_5_sender => 'O astrônomo da pirâmide';

  @override
  String get level_2_5_hint => 'O turbo do anel esmaga meteoros.';

  @override
  String get level_2_6_name => 'Devolver ao Remetente';

  @override
  String get level_2_6_cargo => 'Um espanador de penas para a zeladora';

  @override
  String get level_2_6_sender => 'A zeladora da pirâmide';

  @override
  String get level_2_6_hint =>
      'Atire nas cartas dele para mandá-las de volta. Devolver ao remetente!';

  @override
  String get level_2_7_name => 'Bazar das Lanternas';

  @override
  String get level_2_7_cargo =>
      'Óleo de lamparina pros vendedores de lanternas';

  @override
  String get level_2_7_sender => 'Os vendedores de lanternas';

  @override
  String get level_2_8_name => 'A Longa Caravana';

  @override
  String get level_2_8_cargo => 'Cantis de água para a longa caravana';

  @override
  String get level_2_8_sender => 'O líder da caravana';

  @override
  String get level_2_9_name => 'Rei Cuspidor';

  @override
  String get level_2_9_cargo => 'Uma ordem de parar a poção pro Rei Cuspidor';

  @override
  String get level_2_9_sender => 'Rei Cuspidor';

  @override
  String get level_3_1_name => 'Luz de Mariposa';

  @override
  String get level_3_1_cargo => 'Lâmpadas para a marquise do teatro';

  @override
  String get level_3_1_sender => 'O diretor de palco';

  @override
  String get level_3_1_hint =>
      'Mariposas atiram leques de três. Passe por entre eles.';

  @override
  String get level_3_2_name => 'Rodas na Chuva';

  @override
  String get level_3_2_cargo => 'Guarda-chuvas para os pombos da banca';

  @override
  String get level_3_2_sender => 'Os pombos da banca de jornal';

  @override
  String get level_3_2_hint =>
      'Pombos de beco mergulham para pegar estrelas. Atire neles antes!';

  @override
  String get level_3_3_name => 'Beco do Vapor';

  @override
  String get level_3_3_cargo =>
      'Pretzels quentes pros taxistas do turno da noite';

  @override
  String get level_3_3_sender => 'Os taxistas da noite';

  @override
  String get level_3_3_hint =>
      'Os bueiros chiam e depois jorram. Pule os quentes, pegue carona nos fracos.';

  @override
  String get level_3_4_name => 'Alerta de Tempestade';

  @override
  String get level_3_4_cargo => 'Um cata-vento para a torre mais alta';

  @override
  String get level_3_4_sender => 'O zelador da torre';

  @override
  String get level_3_4_hint =>
      'Fuja da luz. Atire na lâmpada quando ela abrir! Aqui não tem Turbo.';

  @override
  String get level_3_5_name => 'Telhados de Cristal';

  @override
  String get level_3_5_cargo => 'Croissants para os pintores dos telhados';

  @override
  String get level_3_5_sender => 'Os pintores dos telhados';

  @override
  String get level_3_6_name => 'Depois da Ventania';

  @override
  String get level_3_6_cargo => 'Partituras para o sanfoneiro';

  @override
  String get level_3_6_sender => 'O sanfoneiro';

  @override
  String get level_3_6_hint =>
      'Ventania! Fique de olho no ! e vá pelo lado livre.';

  @override
  String get level_3_7_name => 'Expresso da Meia-Noite';

  @override
  String get level_3_7_cargo => 'Uma carta de amor da meia-noite pra padeira';

  @override
  String get level_3_7_sender => 'A padeira';

  @override
  String get level_3_7_hint => 'Turbo pelos bandos.';

  @override
  String get level_3_8_name => 'Imperatriz do Crepúsculo';

  @override
  String get level_3_8_cargo =>
      'Um toque de despertar pra Imperatriz do Crepúsculo';

  @override
  String get level_3_8_sender => 'Imperatriz do Crepúsculo';

  @override
  String get level_4_1_name => 'Luzes do Porto';

  @override
  String get level_4_1_cargo => 'Uma lente nova para a faroleira';

  @override
  String get level_4_1_sender => 'A faroleira';

  @override
  String get level_4_2_name => 'Passagem do Vulcão';

  @override
  String get level_4_2_cargo => 'Luvas de forno para a confeiteira do vulcão';

  @override
  String get level_4_2_sender => 'A confeiteira do vulcão';

  @override
  String get level_4_2_hint => 'Pule os jatos de lava.';

  @override
  String get level_4_3_name => 'Pela Costa';

  @override
  String get level_4_3_cargo => 'Linha de pipa para a festa da praia';

  @override
  String get level_4_3_sender => 'A turma das pipas';

  @override
  String get level_4_4_name => 'Maré Baixa';

  @override
  String get level_4_4_cargo => 'Uma resposta para o eremita da ilha';

  @override
  String get level_4_4_sender => 'O eremita da ilha';

  @override
  String get level_4_4_hint => 'Não encoste na água.';

  @override
  String get level_4_5_name => 'Maré Viva';

  @override
  String get level_4_5_cargo => 'Uma tábua de marés para a tripulação da balsa';

  @override
  String get level_4_5_sender => 'A tripulação da balsa';

  @override
  String get level_4_5_hint => 'Quando o sino tocar, voe alto.';

  @override
  String get level_4_6_name => 'Baía da Bordada';

  @override
  String get level_4_6_cargo => 'Biscoitos de peixe para a colônia de gaivotas';

  @override
  String get level_4_6_sender => 'A colônia de gaivotas';

  @override
  String get level_4_7_name => 'Travessia Tempestuosa';

  @override
  String get level_4_7_cargo => 'Meias secas para os vigias da tempestade';

  @override
  String get level_4_7_sender => 'Os vigias da tempestade';

  @override
  String get level_4_8_name => 'Capitão Pirata';

  @override
  String get level_4_8_cargo => 'Uma ordem de devolver o correio pro Capitão';

  @override
  String get level_4_8_sender => 'Capitão Pirata';

  @override
  String get level_5_1_name => 'Correio da Aurora';

  @override
  String get level_5_1_cargo => 'Gorros de lã para o coral de pinguins';

  @override
  String get level_5_1_sender => 'O coral de pinguins';

  @override
  String get level_5_1_hint =>
      'Agora qualquer correria pode aparecer. Leia a faixa!';

  @override
  String get level_5_2_name => 'Noite Polar';

  @override
  String get level_5_2_cargo => 'Chocolate quente para a estação polar';

  @override
  String get level_5_2_sender => 'A estação polar';

  @override
  String get level_5_3_name => 'Expresso Neon';

  @override
  String get level_5_3_cargo => 'Fusíveis para o letreiro do bar de lámen';

  @override
  String get level_5_3_sender => 'O chef do lámen';

  @override
  String get level_5_4_name => 'Tempestade de Dados';

  @override
  String get level_5_4_cargo => 'Uma carta de papel para um robô curioso';

  @override
  String get level_5_4_sender => 'Unidade 7';

  @override
  String get level_5_5_name => 'Turbo no Horizonte';

  @override
  String get level_5_5_cargo => 'Ingressos para os corredores dos telhados';

  @override
  String get level_5_5_sender => 'Os corredores dos telhados';

  @override
  String get level_5_6_name => 'Festival das Lanternas';

  @override
  String get level_5_6_cargo => 'Lanternas de papel para o festival';

  @override
  String get level_5_6_sender => 'Os artesãos de lanternas';

  @override
  String get level_5_7_name => 'A Reta Final';

  @override
  String get level_5_7_cargo => 'Chá da montanha para o mosteiro';

  @override
  String get level_5_7_sender => 'Os monges da montanha';

  @override
  String get level_5_8_name => 'Dragão das Brasas';

  @override
  String get level_5_8_cargo => 'A primeira carta já enviada ao Dragão';

  @override
  String get level_5_8_sender => 'Dragão das Brasas';

  @override
  String get storyPostmasterName => 'Carteiro-Chefe Bill';

  @override
  String get storySkip => 'Pular';

  @override
  String get storyNextLineSemantics => 'Próxima fala';

  @override
  String get storyFinishSemantics => 'Concluir';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => 'Toda carta chega.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => 'Voar!';

  @override
  String levelIntroRunUp(int seconds) {
    return 'Antes, $seconds s de aquecimento';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'Cerca de $seconds s até a chegada';
  }

  @override
  String get campaignGuardian => 'GUARDIÃO';

  @override
  String get levelIntroBossFight => 'LUTA DE CHEFÃO';

  @override
  String get levelIntroNew => 'NOVO';

  @override
  String get levelIntroTip => 'DICA';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Derrote o $boss',
      'spitterBeetle': 'Derrote o $boss',
      'duskMoth': 'Derrote a $boss',
      'pirate': 'Derrote o $boss',
      'dragon': 'Derrote o $boss',
      'kingCoo': 'Derrote o $boss',
      'searchlightGargoyle': 'Derrote a $boss',
      'other': 'Derrote $boss',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroGoalFinish => 'Cruze a linha de chegada';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Colete $count estrelas',
      one: 'Colete 1 estrela',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Uma estrela: $goal.',
      'two': 'Duas estrelas: $goal.',
      'other': 'Três estrelas: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Uma estrela: $goal. Conquistada.',
      'two': 'Duas estrelas: $goal. Conquistadas.',
      'other': 'Três estrelas: $goal. Conquistadas.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorde: $count estrelas',
      one: 'Recorde: 1 estrela',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'Ainda não entregue';

  @override
  String get levelIntroFirstFlight => 'Primeiro voo';

  @override
  String get levelIntroControlFlap => 'Bater asas';

  @override
  String get levelIntroControlShoot => 'Atirar';

  @override
  String get levelIntroControlSprint => 'Turbo';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Controles: Bater asas.',
      'shoot': 'Controles: Bater asas, Atirar.',
      'sprint': 'Controles: Bater asas, Turbo.',
      'other': 'Controles: Bater asas, Atirar, Turbo.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => 'ENTREGA ESPECIAL';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return 'Entrega especial: $cargo.';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return 'Fase $level, $name. $region.';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return 'Fase $level, $name. $region. Fase do guardião: $boss.';
  }

  @override
  String get levelIntroStory => 'História';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonHome => 'Início';

  @override
  String get commonBackHome => 'Voltar ao início';

  @override
  String get campaignComingSoon => 'Em breve';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — em breve';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Derrote o $boss para desbloquear',
      'spitterBeetle': 'Derrote o $boss para desbloquear',
      'duskMoth': 'Derrote a $boss para desbloquear',
      'pirate': 'Derrote o $boss para desbloquear',
      'dragon': 'Derrote o $boss para desbloquear',
      'kingCoo': 'Derrote o $boss para desbloquear',
      'searchlightGargoyle': 'Derrote a $boss para desbloquear',
      'other': 'Derrote $boss para desbloquear',
    });
    return '$_temp0';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'Conclua a $level para desbloquear';
  }

  @override
  String get campaignMapUnavailable => 'O mapa não carregou.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return 'Fechar $name';
  }

  @override
  String get campaignMapPreviousStop => 'Parada anterior';

  @override
  String get campaignMapNextStop => 'Próxima parada';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. Capítulo $chapter, $route. Em breve.',
      'locked': '$region. Capítulo $chapter, $route. Bloqueado.',
      'other': '$region. Capítulo $chapter, $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return 'CAPÍTULO $chapter · $route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level, $name, chefão',
      'guardian': 'Fase $level, $name, guardião $boss',
      'other': 'Fase $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. Bloqueada.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. Bloqueada. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars de 3 estrelas',
    );
    return '$node. É a próxima. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars de 3 estrelas',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'Gárgula',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return 'Cartão-postal do capítulo $chapter';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars de $total estrelas da campanha',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'Querido carteiro,';

  @override
  String get campaignPostcardPs => 'P.S.';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'Cartão-postal: $route. Querido carteiro, $body P.S. $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'Lembranças de';

  @override
  String get campaignPostcardHeader => 'POSTAL DO CLUBE DO CÉU';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'Ao carteiro';

  @override
  String get campaignPostcardAddressStreet => 'Correio do Clube';

  @override
  String get campaignPostcardAddressCity => 'Lá no céu';

  @override
  String get campaignPostmarkDelivered => 'ENTREGUE';

  @override
  String get campaignPostmarkClub => 'CLUBE DO CÉU';

  @override
  String get campaignStampSkyClub => 'CLUBE DO CÉU';

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
    return 'Bilhete de agradecimento. $sender: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'Preparo rapidinho. Céu de montão.';

  @override
  String get flightSetupTitleSquat => 'Pés no chão. Asas abertas.';

  @override
  String get flightSetupTitleJump => 'Pulos pequenos. Asas grandes.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'FASE · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · VALENDO';
  }

  @override
  String get flightSetupRoomPushUp => 'Abra um espacinho para se mexer.';

  @override
  String get flightSetupRoomBody => 'Mostre o corpo inteiro.';

  @override
  String get flightSetupTipsPushUp =>
      'Celular baixo. Mostre um braço e o quadril.\nDe frente? Mantenha os dois ombros à vista.';

  @override
  String get flightSetupTipsSquat =>
      'Agache para descer. Levante para subir.\nMantenha os dois pés no chão.';

  @override
  String get flightSetupTipsJump =>
      'Pule para ganhar impulso + 3s planando.\nPouse antes de pular de novo.';

  @override
  String get flightSetupHowToFly => 'COMO VOAR';

  @override
  String get flightSetupStep1PushUp => 'Mostre o braço e o quadril';

  @override
  String get flightSetupStep1Squat => 'Abra espaço para agachar';

  @override
  String get flightSetupStep1Jump => 'Abra espaço para pular';

  @override
  String get flightSetupStep1DetailPushUp =>
      'De frente para o celular? Mostre os dois ombros, um braço e o quadril.';

  @override
  String get flightSetupStep1DetailBody =>
      'Celular na horizontal. Mostre o corpo e os dois pés.';

  @override
  String get flightSetupStep2PushUp => 'Encontre sua amplitude';

  @override
  String get flightSetupStep2Squat => 'Agache de um jeito confortável';

  @override
  String get flightSetupStep2Jump => 'Fique em pé, sem se mexer';

  @override
  String get flightSetupStep2DetailPushUp =>
      'Ache uma posição alta confortável, depois desça e suba duas vezes.';

  @override
  String get flightSetupStep2DetailSquat =>
      'Fique em pé sem se mexer, agache, segure um pouco e levante de novo.';

  @override
  String get flightSetupStep2DetailJump =>
      'Não se mexa por um instante. Depois pule para um grande impulso.';

  @override
  String get flightSetupStep3Stars => 'Colete estrelas';

  @override
  String get flightSetupStep3DetailJump =>
      'Estrelas dão 0,75s de planeio, até 5s. Pegue trios para +5 pontos.';

  @override
  String get flightSetupLivesEndless =>
      'Três corações + um escudo. Você pode pausar a qualquer momento.';

  @override
  String get flightSetupLivesClassic =>
      'Uma colisão ou sair da posição encerra o voo valendo pontos. Você pode pausar a qualquer momento.';

  @override
  String get flightSetupCameraButton => 'Configurar minha câmera';

  @override
  String get flightMicTitle => 'Gravar microfone';

  @override
  String get flightMicOn => 'Ligado';

  @override
  String get flightMicOptional => 'Opcional';

  @override
  String get flightMicDetail =>
      'Coloca sua voz e o som do ambiente nos replays. Usa o microfone só durante o voo. Fica salvo neste celular.';

  @override
  String get flightMicSemantics => 'Gravar microfone nos replays';

  @override
  String get flightMicSettings => 'Ajustes do microfone';

  @override
  String get flightCalibrationTitleReady => 'Você encontrou suas asas!';

  @override
  String get flightCalibrationTitleWaking => 'Acordando sua câmera…';

  @override
  String get flightCalibrationTitleError => 'Vamos reconectar sua câmera.';

  @override
  String get flightCalibrationTitleRange => 'Encontre sua amplitude.';

  @override
  String get flightCalibrationTitleStill => 'Fique em pé, sem se mexer.';

  @override
  String get flightCalibrationStepTry => 'Tente mover seu pássaro.';

  @override
  String get flightCalibrationStepTop => 'Posição alta e confortável.';

  @override
  String get flightCalibrationStepLower => 'Desça devagar.';

  @override
  String get flightCalibrationStepPushBack => 'Empurre e suba de novo.';

  @override
  String get flightCalibrationStepStill => 'Fique em pé, sem se mexer.';

  @override
  String get flightCalibrationStepSquat => 'Agache com conforto.';

  @override
  String get flightCalibrationStepStandUp => 'Levante de novo.';

  @override
  String get flightCalibrationStepDone => 'Você encontrou suas asas!';

  @override
  String get flightCalibrationReadyPushUp =>
      'Empurre para subir. Desça para planar.';

  @override
  String get flightCalibrationReadySquat =>
      'Agache para descer. Levante para subir.';

  @override
  String get flightCalibrationReadyJump =>
      'Pule e descanse enquanto seu pássaro plana.';

  @override
  String get flightCalibrationKeepPushUp =>
      'Mantenha os ombros, um braço e o quadril à vista. Mexa-se com conforto.';

  @override
  String get flightCalibrationKeepBody =>
      'Mantenha os ombros, o quadril e os dois pés à vista.';

  @override
  String get flightCalibrationLearning => 'Aprendendo como você se mexe.';

  @override
  String get flightCalibrationAfter => 'Seu pássaro se move após a calibração.';

  @override
  String get flightCalibrationJump => 'Pulou!';

  @override
  String get flightCalibrationTagCheck => 'TESTE DE CONTROLE';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '$count / 2 FLEXÕES';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '$percent% CALIBRADO';
  }

  @override
  String get flightCalibrationTakeoff => 'Hora de decolar';

  @override
  String get flightCalibrationStarting => 'Iniciando…';

  @override
  String get flightCalibrationRestart => 'Calibrar de novo';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate atualizações/s · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate atualizações/s · $p95 ms p95 (só processamento)';
  }

  @override
  String get flightCalibrationStatusReady => 'PRONTO';

  @override
  String get flightCalibrationStatusStarting => 'INICIANDO';

  @override
  String get flightCalibrationStatusCameraOff => 'SEM CÂMERA';

  @override
  String get flightCalibrationStatusCalibrating => 'CALIBRANDO';

  @override
  String get flightSwitchCameraSemantics => 'Trocar de câmera';

  @override
  String get flightCalibrationStepIntoView => 'Entre no campo da câmera';

  @override
  String get flightCameraTroubleTitle => 'Recomeçar costuma ajudar.';

  @override
  String get flightCameraTroubleAllow =>
      'Permita o acesso à câmera nas Configurações.';

  @override
  String get flightCameraTroubleClose =>
      'Feche outros apps de câmera e tente de novo.';

  @override
  String get flightCameraPermissionSemantics => 'Permissão da câmera';

  @override
  String get flightNoteRememberFailed =>
      'Alterado só neste voo. Não deu para lembrar sua preferência.';

  @override
  String get flightNoteMicUnavailable =>
      'Microfone indisponível. O vídeo e o jogo continuam funcionando.';

  @override
  String get flightNoteMicBlocked =>
      'Microfone bloqueado. Você pode permitir nas Configurações; o vídeo continua funcionando.';

  @override
  String get flightNoteMicOff =>
      'Microfone desligado. Você ainda pode jogar e salvar o vídeo.';

  @override
  String get flightNoteVideoUnavailable =>
      'Vídeo da câmera indisponível. A partida ainda pode ser salva.';

  @override
  String get flightNoteMicAudioLost =>
      'O áudio do microfone ficou indisponível. Seu vídeo e a partida ainda podem ser salvos.';

  @override
  String get flightNoteVideoInterrupted =>
      'O vídeo da câmera foi interrompido. O que foi gravado e a partida ainda podem ser salvos.';

  @override
  String get flightNoteSessionSaveFailed =>
      'Não deu para salvar a sessão. Toque em Salvar sessão para tentar de novo.';

  @override
  String get flightNoteWakingCamera => 'Acordando sua câmera…';

  @override
  String get flightNoteCameraOff =>
      'O acesso à câmera está desligado. Permita nas configurações do Android, depois volte e tente de novo.';

  @override
  String get flightNoteCameraFailed =>
      'A câmera não iniciou. Tente de novo ou troque de câmera.';

  @override
  String get flightNotePreparing => 'Preparando sua sessão…';

  @override
  String get flightNoteSaveFailed =>
      'Não deu para salvar seu voo. Toque para tentar de novo.';

  @override
  String get flightNoteWelcomeBack =>
      'Que bom ter você de volta. Vamos conferir sua posição de novo.';

  @override
  String get flightNoteCameraInterrupted =>
      'Câmera interrompida. Confira a permissão da câmera e tente de novo.';

  @override
  String get flightNoteTrackingInterrupted => 'Rastreamento interrompido';

  @override
  String get flightFindPosition => 'Ache sua posição';

  @override
  String get flightTapSemantics => 'Toque para bater as asas';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'Toque para bater as asas. Vanguarda do chefão: $group';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'Toque para bater as asas. $boss: $hp de $maxHp de vida';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'Toque para bater as asas. $boss: $hp de $maxHp de vida. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'Pular para os resultados';

  @override
  String get hudPauseSemantics => 'Pausar o voo';

  @override
  String get flightHintTestSteerKeys => 'Voo de teste: guie com as setas.';

  @override
  String get flightHintTestSteerDrag =>
      'Voo de teste: arraste para cima e para baixo para guiar.';

  @override
  String get flightHintTestJumpKeys => 'Voo de teste: Espaço para pular.';

  @override
  String get flightHintTestJumpTap => 'Voo de teste: toque para pular.';

  @override
  String get flightHintKeysStars =>
      'Espaço para bater as asas. Voe pelas estrelas.';

  @override
  String get flightHintKeysShoot =>
      'Espaço para bater as asas. Segure D para carregar o tiro.';

  @override
  String get flightHintKeysCombat =>
      'Espaço para bater as asas. Segure D para carregar o tiro. A para o Turbo!';

  @override
  String get flightHintKeysPause => 'Espaço para bater as asas. Esc pausa.';

  @override
  String get flightHintTapStars =>
      'Toque no céu para bater as asas. Voe pelas estrelas.';

  @override
  String get flightHintTapShoot =>
      'Toque no céu para bater as asas. Segure Atirar para carregar.';

  @override
  String get flightHintTapCombat =>
      'Toque no céu para bater as asas. Segure Atirar para carregar. Turbo para esmagar!';

  @override
  String get flightHintTapRelease =>
      'Toque para bater as asas. Solte entre os toques.';

  @override
  String get flightHintTrail => 'Siga as estrelas. Seu escudo está pronto.';

  @override
  String get flightHintSky => 'O céu é seu.';

  @override
  String hudClockSemantics(String time) {
    return 'Faltam $time';
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
      other: 'Ímã de estrelas: faltam $seconds segundos',
      one: 'Ímã de estrelas: falta $seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Ímã carregando: $charge de $gates portais perfeitos',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'Procurando você…';

  @override
  String get hudShoot => 'Atirar';

  @override
  String get hudSprint => 'Turbo';

  @override
  String get flightTestNothingSaved => 'nada é salvo';

  @override
  String get flightCountdownReady => 'Preparar, apontar…';

  @override
  String get flightPauseTitle => 'Respira um pouco.';

  @override
  String get flightPauseKeepFlying => 'Continuar voando';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. Seu pássaro está no poleiro, esperando.';
  }

  @override
  String flightPausedTest(String name) {
    return 'Voo de teste de $name. Nada é salvo.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. Seu pássaro está no poleiro, esperando.';
  }

  @override
  String get flightPausedTouch =>
      'Seu pássaro está no poleiro, esperando. A gente conta de novo antes de voltar.';

  @override
  String get flightPausedCamera =>
      'Dê uma sacudida e volte para a posição. A gente faz a contagem.';

  @override
  String get flightPauseEdit => 'Editar';

  @override
  String get flightPauseBuilder => 'Criador';

  @override
  String get flightPauseFinish => 'Encerrar voo';

  @override
  String get hudShieldRecovering => 'Recuperando';

  @override
  String get hudShieldReady => 'Escudo pronto';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Escudo carregando: $charge de $stars estrelas',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count corações restantes',
      one: '$count coração restante',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'No turbo';

  @override
  String get hudSprintReady => 'Pronto';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Recarregando, $seconds segundos',
      one: 'Recarregando, $seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint =>
      'Dispare à frente para esmagar morcegos e placas de pedra';

  @override
  String get hudShotReloading => 'Recarregando…';

  @override
  String hudShotFullCharge(int ms) {
    return 'Carga total, faltam $ms ms';
  }

  @override
  String hudShotCharging(int percent) {
    return 'Carregando $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'Munição $percent%';
  }

  @override
  String get hudShotHint => 'Segure para carregar uma pedra maior';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas alcançadas',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas com $at',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars estrelas coletadas',
      one: '$stars estrela coletada',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'MÁX';

  @override
  String hudRouteSemantics(int percent) {
    return '$percent% da rota percorrida';
  }

  @override
  String hudGlideCompact(String time) {
    return 'Planeio · $time';
  }

  @override
  String get hudJumpToGlide => 'Pule para planar';

  @override
  String get hudJump => 'Pule';

  @override
  String hudGlideSemantics(String time) {
    return 'Planando, faltam $time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'Planeio acabando, faltam $time';
  }

  @override
  String get hudJumpChargeSemantics =>
      'Pule para carregar 3 segundos de planeio';

  @override
  String get hudRecordNewBest => 'Novo recorde!';

  @override
  String get hudRecordMatched => 'Empatou!';

  @override
  String hudRecordBest(int best) {
    return 'Recorde $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '+$points além do recorde';
  }

  @override
  String get hudRecordOneMore => 'Mais um para o recorde';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count até o recorde',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'Pontuação $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'Pontuação $score, multiplicador de $multiplier vezes';
  }

  @override
  String get commonBusySemantics => 'Aguarde';

  @override
  String get flightResultBumpClouds => 'Um tropeção nas nuvens.';

  @override
  String get flightResultPersonalBest => 'RECORDE PESSOAL';

  @override
  String get flightResultNewPersonalBest => 'NOVO RECORDE PESSOAL!';

  @override
  String get flightResultStarsCollected => 'ESTRELAS COLETADAS';

  @override
  String get flightResultDailyStamped => 'Cartão-postal de hoje carimbado!';

  @override
  String flightResultNextStamp(String stamp) {
    return 'Próximo: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'Salvo neste celular';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Salvo neste celular · $total portais no total',
      one: 'Salvo neste celular · $total portal no total',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'Salvando seu voo…';

  @override
  String get flightResultSessionSaved => 'Sessão salva · Veja em Recordes';

  @override
  String get flightResultWatchReplay => 'Ver replay';

  @override
  String get flightResultPreparing => 'Preparando…';

  @override
  String get flightResultSavingShort => 'Salvando…';

  @override
  String get flightResultSaveSession => 'Salvar sessão';

  @override
  String get flightResultFlyAgain => 'Voar de novo';

  @override
  String get commonRetry => 'Repetir';

  @override
  String get commonMap => 'Mapa';

  @override
  String get commonNext => 'Próxima';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flexões',
      one: 'flexão',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'agachamentos',
      one: 'agachamento',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pulos',
      one: 'pulo',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'batidas de asa',
      one: 'batida de asa',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'tempo de voo';

  @override
  String get flightStatPerfect => 'perfeitos';

  @override
  String get flightStatBestStreak => 'sequência máx.';

  @override
  String get flightStatRank => 'título';

  @override
  String get flightRankSkyCaptain => 'Capitão do céu';

  @override
  String get flightRankCloudExplorer => 'Explorador';

  @override
  String get flightRankFirstWings => 'Primeiras asas';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => 'Bateu, mas com recorde novinho!';

  @override
  String get gameOverCaptionSea => 'Um tchibum no mar.';

  @override
  String get gameOverSplash => 'Tchibum!';

  @override
  String get gameOverBonk => 'Tóim!';

  @override
  String get gameOverEveryMarkSemantics => 'Todas as marcas alcançadas';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count estrelas para $mark estrelas',
      one: 'Falta $count estrela para $mark estrelas',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: restam $hp de $maxHp de vida';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '$percent por cento da rota percorrida';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: RESTAM $hp HP';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$boss: VIDA RESTANTE';
  }

  @override
  String get gameOverRouteFlown => 'ROTA PERCORRIDA';

  @override
  String gameOverHp(int hp) {
    return '$hp HP';
  }

  @override
  String gameOverMoreFor(int count) {
    return '+$count para';
  }

  @override
  String get gameOverBothMarks => 'Duas marcas alcançadas';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Marcas alcançadas. Derrote o $boss!',
      'spitterBeetle': 'Marcas alcançadas. Derrote o $boss!',
      'duskMoth': 'Marcas alcançadas. Derrote a $boss!',
      'pirate': 'Marcas alcançadas. Derrote o $boss!',
      'dragon': 'Marcas alcançadas. Derrote o $boss!',
      'kingCoo': 'Marcas alcançadas. Derrote o $boss!',
      'searchlightGargoyle': 'Marcas alcançadas. Derrote a $boss!',
      'other': 'Marcas alcançadas. Derrote $boss!',
    });
    return '$_temp0';
  }

  @override
  String get miniResultTitle => 'Todo voo conta.';

  @override
  String get miniResultComplete => 'VOO CONCLUÍDO';

  @override
  String get miniResultCheerBest => 'Arrasou!';

  @override
  String get miniResultCheerComplete => 'Voo concluído!';

  @override
  String get miniResultCheerNice => 'Belo voo.';

  @override
  String get miniResultNew => 'NOVO';

  @override
  String get flightEndTrackingLost => 'Perdemos você de vista por um instante.';

  @override
  String get flightEndPostureLost => 'Sua posição saiu do alcance da câmera.';

  @override
  String get flightEndBackgrounded => 'Você se afastou do céu.';

  @override
  String get flightEndBreak => 'Uma pausa merecida.';

  @override
  String get flightEndQuit => 'Até a próxima aventura.';

  @override
  String get flightEndStalled => 'O jogo foi interrompido.';

  @override
  String get flightEndCompleted => 'Um céu inteiro de estrelas. Todo seu.';

  @override
  String get levelResultTryAgain => 'Tente de novo!';

  @override
  String get levelResultVictory => 'Vitória!';

  @override
  String get levelResultGuardianDown => 'Guardião caiu!';

  @override
  String get levelResultDelivered => 'Entregue!';

  @override
  String levelResultComingSoon(String region) {
    return '$region chega em breve!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned de 3 estrelas';
  }

  @override
  String levelResultBest(int best) {
    return 'Recorde $best';
  }

  @override
  String get levelResultNoBest => 'Sem recorde';

  @override
  String get levelResultFirstClear => 'Primeira vez!';

  @override
  String get levelResultNewBest => 'NOVO RECORDE!';

  @override
  String get levelResultScore => 'PONTUAÇÃO';

  @override
  String get levelResultGoalBoss => 'Chefão';

  @override
  String get levelResultGoalGuardian => 'Guardião';

  @override
  String get levelResultGoalFinish => 'Chegada';

  @override
  String get levelResultGoalDone => 'Feito';

  @override
  String get levelResultGoalNotYet => 'Ainda não';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count',
      one: 'Falta $count',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'Precisa chegar';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. Feito.';
  }

  @override
  String get levelResultPostcardWaiting =>
      'Tem um cartão-postal esperando no mapa!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return 'Liberou: $id $name!';
  }

  @override
  String get levelResultReachFinish => 'Chegue ao fim para ganhar estrelas.';

  @override
  String get course_classic_title => 'Clássico';

  @override
  String get course_starTrail_title => 'Infinito';

  @override
  String get course_classic_instructions =>
      'Encontre os vãos. Siga as miras para uma passagem perfeita.';

  @override
  String get course_starTrail_instructions =>
      'Pegue as 3 estrelas de um grupo para +5. Encadeie estrelas para até 3×. Estrelas recarregam seu escudo; portais perfeitos dão um ímã de estrelas. Melhore os dois com estrelas!';

  @override
  String get course_classic_scoreLabel => 'OBSTÁCULOS';

  @override
  String get course_starTrail_scoreLabel => 'PONTOS DE ESTRELA';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portais',
      one: 'portal',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pontos',
      one: 'ponto',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics => 'Clássico: voe pelos vãos.';

  @override
  String get course_starTrail_previewSemantics =>
      'Infinito: colete estrelas com três corações e um escudo.';

  @override
  String get obstacle_garden_name => 'Portal do jardim';

  @override
  String get obstacle_windLift_name => 'Vento sobe-e-desce';

  @override
  String get obstacle_petalGate_name => 'Portais de pétalas';

  @override
  String get obstacle_switchback_name => 'Zigue-zague';

  @override
  String get obstacle_lanternDrift_name => 'Lanternas à deriva';

  @override
  String get obstacle_sunWheels_name => 'Rodas de sol';

  @override
  String get obstacle_crystalSteps_name => 'Degraus de cristal';

  @override
  String get rush_wildfire_name => 'Incêndio';

  @override
  String get rush_wildfire_escape => 'Fugiu do incêndio';

  @override
  String get rush_skyfall_name => 'Céu Desabando';

  @override
  String get rush_skyfall_escape => 'Sobreviveu ao Céu Desabando';

  @override
  String get rush_eruption_name => 'Erupção';

  @override
  String get rush_eruption_escape => 'Venceu a erupção';

  @override
  String get rush_swarm_name => 'Enxame';

  @override
  String get rush_swarm_escape => 'Atravessou o enxame';

  @override
  String get boss_baronBat_title => 'SENHOR DA TEMPESTADE';

  @override
  String get boss_spitterBeetle_title => 'ALQUIMISTA DO ENXAME';

  @override
  String get boss_duskMoth_title => 'GUARDIÃ DO VÉU DO CREPÚSCULO';

  @override
  String get boss_pirate_title => 'TERROR DA MARÉ ALTA';

  @override
  String get boss_dragon_title => 'SOBERANO DO CÉU EM CHAMAS';

  @override
  String get boss_kingCoo_title => 'COMISSÁRIO DA CALÇADA';

  @override
  String get boss_searchlightGargoyle_title => 'SENTINELA DA TORRE MAIS ALTA';

  @override
  String get boss_neferhoo_title => 'ZELADOR DA CARTA PERDIDA';

  @override
  String get boss_baronBat_returnTitle => 'A TEMPESTADE VOLTOU';

  @override
  String get boss_baronBat_barName => 'BARÃO MORCEGO';

  @override
  String get boss_spitterBeetle_barName => 'REI CUSPIDOR';

  @override
  String get boss_duskMoth_barName => 'IMPERATRIZ';

  @override
  String get boss_pirate_barName => 'CAPITÃO PIRATA';

  @override
  String get boss_dragon_barName => 'DRAGÃO';

  @override
  String get boss_kingCoo_barName => 'REI PRUU';

  @override
  String get boss_searchlightGargoyle_barName => 'GÁRGULA';

  @override
  String get boss_neferhoo_barName => 'NEFERHOO';

  @override
  String get vanguard_baronBat_title => 'OS MORCEGOS DO BARÃO';

  @override
  String get vanguard_baronBat_call => 'Lá vêm eles! O Barão vem logo atrás.';

  @override
  String get vanguard_spitterBeetle_title => 'A NINHADA DO REI CUSPIDOR';

  @override
  String get vanguard_spitterBeetle_call =>
      'Lá vêm eles! O Rei Cuspidor vem logo atrás.';

  @override
  String get vanguard_duskMoth_title => 'AS MARIPOSAS DA IMPERATRIZ';

  @override
  String get vanguard_duskMoth_call =>
      'Lá vêm elas! A Imperatriz vem logo atrás.';

  @override
  String get vanguard_kingCoo_title => 'A ESQUADRILHA DO REI PRUU';

  @override
  String get vanguard_kingCoo_call => 'Lá vêm eles! O Rei Pruu vem logo atrás.';

  @override
  String get vanguard_kingCoo_callCrusts =>
      'Lá vêm eles! Desvie das cascas de pão!';

  @override
  String get vanguard_kingCoo_callReturns =>
      'Desvie das cascas! Se um escapar, ele volta!';

  @override
  String get bossVanguardClear => 'LIMPO!';

  @override
  String get bossVanguardLeft => 'NO AR';

  @override
  String get bossStragglersCaught => 'TODOS PEGOS!';

  @override
  String get bossHint_strongerBaronBat =>
      'MAIS FORTE · Tiros triplos, e os morcegos dele entram na briga!';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'MAIS FORTE · Leques completos, e os besouros dele entram na briga!';

  @override
  String get bossHint_strongerDuskMoth =>
      'MAIS FORTE · Leques de sete tiros, e as mariposas dela entram na briga!';

  @override
  String get bossHint_strongerPirate => 'MAIS FORTE · A maré está virando!';

  @override
  String get bossHint_strongerDragon =>
      'MAIS FORTE · Cuidado com o sopro e os bandos!';

  @override
  String get bossHint_strongerKingCoo =>
      'MAIS FORTE · Ele apita para chamar a esquadrilha!';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'MAIS FORTE · Caem penas com a lâmpada aberta!';

  @override
  String get bossHint_strongerGargoyle => 'MAIS FORTE · Caem penas de pedra!';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'MAIS FORTE · O ankh e os morcegos múmia dele!';

  @override
  String get bossHint_strongerNeferhoo => 'MAIS FORTE · O ankh dourado volta!';

  @override
  String get bossHint_tideRising => 'MARÉ SUBINDO · Voe alto!';

  @override
  String get bossHint_highTide => 'MARÉ ALTA · Fique acima da água';

  @override
  String get bossHint_tideFury => 'FÚRIA · Bordadas entre as ondas';

  @override
  String get bossHint_tideCalm =>
      'Desvie das balas de canhão · Fique longe da água';

  @override
  String get bossHint_dragonSwarm =>
      'ENXAME · Desvie dos morcegos ou passe no turbo';

  @override
  String get bossHint_dragonFuryDebut => 'FÚRIA · Bolas de fogo mais rápidas';

  @override
  String get bossHint_dragonFury => 'FÚRIA · Bolas de fogo viram brasas';

  @override
  String get bossHint_dragonCalm =>
      'Desvie das bolas de fogo · Cuidado com o sopro';

  @override
  String get bossHint_screechFury =>
      'FÚRIA · Bolas de fogo mais rápidas, mais morcegos';

  @override
  String get bossHint_screechCalm =>
      'Desvie das bolas de fogo e dos morcegos · Cuidado com o guincho';

  @override
  String get bossHint_cooPopped => 'POF! · Sem esquadrilha';

  @override
  String get bossHint_cooSquadron => 'ESQUADRILHA · Siga a faixa livre!';

  @override
  String get bossHint_cooPuffed => 'PEITO ESTUFADO · Atire no peito (x2)!';

  @override
  String get bossHint_cooCrumbBomb => 'BOMBA DE MIGALHAS · Saia do círculo!';

  @override
  String get bossHint_cooFury => 'FÚRIA · Fique entre os círculos';

  @override
  String get bossHint_cooCalm =>
      'Desvie das bombas de migalhas · Atire no peito quando ele estufar';

  @override
  String get bossHint_beamOn => 'FACHO DE LUZ · Fique no escuro';

  @override
  String get bossHint_beamFury => 'FÚRIA · Passe entre os fachos';

  @override
  String get bossHint_beamIncomingHigh => 'FACHO CHEGANDO · Voe baixo!';

  @override
  String get bossHint_beamIncomingLow => 'FACHO CHEGANDO · Voe alto!';

  @override
  String get bossHint_lampOpen => 'LÂMPADA ABERTA · Atire na lâmpada!';

  @override
  String get bossHint_shuttersClosed => 'PERSIANAS FECHADAS · Guarde os tiros';

  @override
  String get bossHint_mothFuryNoVeil =>
      'FÚRIA · Leques de sete tiros. Ainda sem véu!';

  @override
  String get bossHint_mothNoVeil => 'Ainda sem véu · Atire entre os leques!';

  @override
  String get bossHint_mothShielded => 'PROTEGIDA · Desvie até o véu cair';

  @override
  String get bossHint_mothShieldForming =>
      'ESCUDO SE FORMANDO · Prepare-se para desviar';

  @override
  String get bossHint_mothFury => 'FÚRIA · Leques de sete tiros. O véu caiu!';

  @override
  String get bossHint_mothCalm => 'O véu caiu · Atire entre os leques!';

  @override
  String get bossHint_neferhooMailCall => 'OLHA O CORREIO! · Atire de volta!';

  @override
  String get bossHint_neferhooReturn => 'DEVOLVER AO REMETENTE! · −25';

  @override
  String get bossHint_neferhooReturnFaster => 'DEVOLVER AO REMETENTE! · −18';

  @override
  String get bossHint_neferhooAnkh => 'O ANKH · Ele volta!';

  @override
  String get bossHint_neferhooExpress =>
      'CORREIO EXPRESSO · Cinco cartas, mais rápido';

  @override
  String get bossHint_neferhooTwoAnkhs =>
      'DOIS ANKHS · Fique fora das duas faixas';

  @override
  String get bossHint_neferhooBats => 'MORCEGOS MÚMIA · Atire neles!';

  @override
  String get bossHint_neferhooScuff =>
      'Pedras só arranham as ataduras. Atire as CARTAS de volta!';

  @override
  String get bossHint_neferhooWarmUp =>
      'Atire as cartas de volta · Devolver ao remetente';

  @override
  String get bossHint_neferhooCalm =>
      'Atire as cartas de volta · Desvie do ankh dourado';

  @override
  String get bossHint_neferhooFury => 'FÚRIA · Correio expresso e dois ankhs';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'SOPRO DO DRAGÃO · Voe baixo! O coração está aberto',
      'middle': 'SOPRO DO DRAGÃO · Suba ou mergulhe! O coração está aberto',
      'other': 'SOPRO DO DRAGÃO · Voe alto! O coração está aberto',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'FOGO · Voe baixo! Acerte o coração brilhante',
      'middle': 'FOGO · Suba ou mergulhe! Acerte o coração brilhante',
      'other': 'FOGO · Voe alto! Acerte o coração brilhante',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'GUINCHO SÔNICO · Voe para a brecha de cima!',
      'middle': 'GUINCHO SÔNICO · Voe para a brecha do meio!',
      'other': 'GUINCHO SÔNICO · Voe para a brecha de baixo!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'GUINCHO · Fique na brecha de cima',
      'middle': 'GUINCHO · Fique na brecha do meio',
      'other': 'GUINCHO · Fique na brecha de baixo',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'DESVIE DOS LEQUES  ·  ATIRE QUANDO O VÉU CAIR';

  @override
  String get encounterCaption_pirate =>
      'DESVIE DO CANHÃO  ·  FIQUE LONGE DA ÁGUA';

  @override
  String get encounterCaption_dragon =>
      'DESVIE DAS BOLAS DE FOGO  ·  FUJA DO SOPRO';

  @override
  String get encounterCaption_kingCoo =>
      'SAIA DOS CÍRCULOS  ·  ATIRE NO PEITO QUANDO ELE ESTUFAR';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'FUJA DA LUZ  ·  ATIRE NA LÂMPADA QUANDO ELA ABRIR';

  @override
  String get encounterCaption_neferhoo =>
      'PREPARE-SE  ·  ATIRE AS CARTAS DE VOLTA';

  @override
  String get encounterCaption_screech =>
      'QUANDO ELE GUINCHAR  ·  VOE PARA A BRECHA';

  @override
  String get encounterCaption_default =>
      'PREPARE-SE  ·  BATA ASAS, DESVIE, ATIRE';

  @override
  String get encounterCoasting => 'Seu pássaro está planando em segurança';

  @override
  String get encounterOpenSky => 'De volta ao céu aberto';

  @override
  String get encounterOmenTitle_duskMoth => 'O CREPÚSCULO LEVANTA VOO';

  @override
  String get encounterOmenLine_duskMoth =>
      'Um véu de seda se forma no crepúsculo…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'TEM ALGO FERVENDO';

  @override
  String get encounterOmenLine_spitterBeetle =>
      'O ar está começando a borbulhar…';

  @override
  String get encounterOmenTitle_dragon => 'O CÉU PEGA FOGO';

  @override
  String get encounterOmenLine_dragon => 'Grandes asas batem acima das nuvens…';

  @override
  String get encounterOmenTitle_kingCoo => 'CALÇADA INTERDITADA';

  @override
  String get encounterOmenLine_kingCoo =>
      'Alguém está muito bravo com o carrinho de pão…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => 'ALERTA DE TEMPESTADE';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      'Tem algo no parapeito, observando…';

  @override
  String get encounterOmenTitle_neferhoo => 'A PIRÂMIDE DESPERTA';

  @override
  String get encounterOmenLine_neferhoo =>
      'A poeira da pirâmide está se mexendo…';

  @override
  String get encounterOmenTitle_baronReturns => 'O BARÃO VOLTOU';

  @override
  String get encounterOmenLine_baronReturns =>
      'Ele voltou, e muito mais barulhento…';

  @override
  String get encounterOmenTitle_default => 'UMA SOMBRA SE APROXIMA';

  @override
  String get encounterOmenLine_default => 'O céu agora tem outro dono…';

  @override
  String get encounterOmenTitle_pirate => 'NAVIO À VISTA!';

  @override
  String get encounterOmenLine_pirate => 'Um navio chega com a maré subindo…';

  @override
  String get bossGuardianEyebrow => 'GUARDIÃO';

  @override
  String bossEncounterEyebrow(String number) {
    return 'ENCONTRO $number';
  }

  @override
  String get bossGuardianDown => 'GUARDIÃO CAIU!';

  @override
  String get bossSkyReclaimed => 'CÉU RECONQUISTADO';

  @override
  String bossVictoryPoints(int points) {
    return '+$points PONTOS   ·   ESCUDO RECUPERADO';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'BARÃO MORCEGO DERROTADO',
      'spitterBeetle': 'REI CUSPIDOR DERROTADO',
      'duskMoth': 'IMPERATRIZ DO CREPÚSCULO DERROTADA',
      'pirate': 'CAPITÃO PIRATA DERROTADO',
      'dragon': 'DRAGÃO DAS BRASAS DERROTADO',
      'kingCoo': 'REI PRUU DERROTADO',
      'searchlightGargoyle': 'GÁRGULA DO HOLOFOTE DERROTADA',
      'other': 'NEFERHOO DERROTADO',
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
  String get bossGargoyleCardSmall => 'DO HOLOFOTE';

  @override
  String get bossGargoyleCardBig => 'GÁRGULA';

  @override
  String get bossGargoyleCardOrder => 'big-small';

  @override
  String get bossDodgeFlyLow => 'VOE BAIXO';

  @override
  String get bossDodgeFlyHigh => 'VOE ALTO';

  @override
  String get bossDodgeClimbOrDive => 'SUBA OU MERGULHE';

  @override
  String get bossDodgeSlipBetween => 'PASSE ENTRE\nOS FACHOS';

  @override
  String get bossSpotted => 'TE VI!';

  @override
  String get bossShieldLost => 'ESCUDO PERDIDO';

  @override
  String get bossHeartLost => '-1 CORAÇÃO';

  @override
  String get bossGargoyleLampOpen => 'LÂMPADA';

  @override
  String get bossGargoyleShoot => 'ATIRE!';

  @override
  String get bossScreechFlyToGap => 'VOE ATÉ A BRECHA';

  @override
  String get bossScreechHoldGap => 'FIQUE NA BRECHA';

  @override
  String get bossPirateHighTide => 'MARÉ ALTA';

  @override
  String get bossBarDefeated => 'NOCAUTE';

  @override
  String get bossBarIncoming => 'CHEGANDO';

  @override
  String get bossBarFury => 'FÚRIA';

  @override
  String get bossBarHeartDouble => 'CORAÇÃO ×2';

  @override
  String get bossStronger => 'MAIS FORTE!';

  @override
  String get bossKingCooPuffed => 'ESTUFADO';

  @override
  String get bossKingCooShout => 'PRUU!';

  @override
  String get bossKingCooPop => 'POF!';

  @override
  String get bossKingCooPoof => 'PUF!';

  @override
  String get bossSquadOpenLane => 'FAIXA LIVRE = VÁ';

  @override
  String get bossSquadUseGap => 'PASSE NO VÃO';

  @override
  String get bossSquadThenV => 'DEPOIS: V';

  @override
  String get bossSquadThenGap => 'DEPOIS: VÃO';

  @override
  String get bossSquadCancelled => 'SEM ESQUADRILHA';

  @override
  String get bossNeferhooFound => 'A CARTA PERDIDA FOI ACHADA';

  @override
  String get bossNeferhooHoo => 'HUU';

  @override
  String get bossNeferhooPoo => 'PUU';

  @override
  String get bossNeferhooMailCall => 'OLHA O CORREIO';

  @override
  String get bossNeferhooExpressPost => 'EXPRESSO';

  @override
  String get bossNeferhooShootBack => 'Atire de volta!';

  @override
  String get bossNeferhooAnkh => 'O ANKH';

  @override
  String get bossNeferhooTwoAnkhs => 'DOIS ANKHS';

  @override
  String get bossNeferhooComesBack => 'Ele volta!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'INCÊNDIO!',
      'skyfall': 'CÉU DESABANDO!',
      'eruption': 'ERUPÇÃO!',
      'other': 'ENXAME!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Pegue os anéis turbo e fuja dele!',
      'skyfall': 'Pegue os anéis turbo e fuja dos meteoros!',
      'eruption': 'Pegue os anéis turbo e vença as explosões!',
      'other': 'Pegue os anéis turbo e atravesse tudo!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return 'ESCAPOU! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'IMPECÁVEL! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Você fugiu do incêndio',
      'skyfall': 'Você sobreviveu ao Céu Desabando',
      'eruption': 'Você venceu a erupção',
      'other': 'Você atravessou o enxame',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => 'VENTANIA!';

  @override
  String encounterGaleDetail(String mark) {
    return 'Desvie dos destroços onde o $mark piscar!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'AGUENTOU! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail => 'Você enfrentou a ventania';

  @override
  String get encounterAllRings => 'TODOS OS ANÉIS';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'Turbo extra +${seconds}s';
  }

  @override
  String get encounterFinish => 'CHEGADA';

  @override
  String get builderMode_pushUp => 'Flexões';

  @override
  String get builderMode_squat => 'Agachamentos';

  @override
  String get builderMode_jump => 'Pulos';

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
      other: '$count flexões',
      one: '1 flexão',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agachamentos',
      one: '1 agachamento',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'Fase de toque';

  @override
  String get builderNewLevel_pushUp => 'Fase de flexões';

  @override
  String get builderNewLevel_squat => 'Fase de agachamento';

  @override
  String get builderNewLevel_jump => 'Fase de pulos';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'Minha fase';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Voe na minha fase do Beakbound “$name” ($mode): $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$earned de $total estrelas';
  }

  @override
  String get builderBackSemantics => 'Voltar';

  @override
  String get builderKeepIt => 'Manter';

  @override
  String builderLessSemantics(String name) {
    return 'Diminuir $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'Aumentar $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name: $value';
  }

  @override
  String get builderDuplicateSemantics => 'Duplicar';

  @override
  String get builderCopy => 'Copiar';

  @override
  String get builderDeleteSemantics => 'Apagar';

  @override
  String get builderDelete => 'Apagar';

  @override
  String get builderMoreBelow => 'Mais abaixo';

  @override
  String builderStepSemantics(String caption, String value) {
    return '$caption: $value';
  }

  @override
  String builderStepHintSemantics(String caption, String value, String hint) {
    return '$caption: $value, $hint';
  }

  @override
  String builderPercent(int percent) {
    return '$percent%';
  }

  @override
  String get builderLane => 'Faixa';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'em cima ou embaixo no agachamento',
      'other': 'em cima ou embaixo na flexão',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'Em cima';

  @override
  String get builderLaneBottom => 'Embaixo';

  @override
  String get builderHeight => 'Altura';

  @override
  String get builderHeightHint => 'do céu';

  @override
  String get builderLowerSemantics => 'Mais baixo';

  @override
  String get builderHigherSemantics => 'Mais alto';

  @override
  String get builderOpening => 'Abertura';

  @override
  String builderOpeningHint(int percent) {
    return 'no mínimo $percent%';
  }

  @override
  String get builderNarrowerSemantics => 'Mais estreito';

  @override
  String get builderWiderSemantics => 'Mais largo';

  @override
  String get builderMotion => 'Movimento';

  @override
  String get builderMotionGardenHint => 'portais do jardim ficam parados';

  @override
  String get builderMotionStill => 'Parado';

  @override
  String get builderMotionGentle => 'Suave';

  @override
  String get builderMotionLively => 'Agitado';

  @override
  String get builderMotionGardenToast =>
      'Portais do jardim ficam parados: escolha outro tipo para o portal se mover.';

  @override
  String get builderSway => 'Balanço';

  @override
  String builderSwayHint(String seconds) {
    return 'um balanço: $seconds';
  }

  @override
  String get builderSwayFast => 'Rápido';

  @override
  String get builderSwayMedium => 'Médio';

  @override
  String get builderSwaySlow => 'Lento';

  @override
  String get builderPhase => 'Quando você chega';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position de $count';
  }

  @override
  String get builderPhaseHint => 'onde está no balanço';

  @override
  String get builderPhaseEarlierSemantics => 'Mais cedo no balanço';

  @override
  String get builderPhaseLaterSemantics => 'Mais tarde no balanço';

  @override
  String get builderLook => 'Visual';

  @override
  String builderLookSemantics(int number) {
    return 'Visual $number';
  }

  @override
  String get builderDoor => 'Porta de pedra';

  @override
  String get builderDoorHint => 'atire para abrir';

  @override
  String get builderDoorNone => 'Sem porta';

  @override
  String get builderDoorNeedsShootToast =>
      'Ligue o Atirar nas configurações da fase para usar portas.';

  @override
  String get builderPlace => 'Posição';

  @override
  String get builderPlaceHint => 'desde o início';

  @override
  String get builderEarlierSemantics => 'Mais cedo';

  @override
  String get builderLaterSemantics => 'Mais tarde';

  @override
  String builderFamilySemantics(String family) {
    return 'Tipo de portal: $family. Trocar';
  }

  @override
  String get builderChangeFamily => 'Trocar tipo';

  @override
  String get builderItemStar => 'Estrela';

  @override
  String get builderItemTrio => 'Trio de estrelas';

  @override
  String get builderItemHeart => 'Coração';

  @override
  String get builderItemEnemy => 'Inimigo';

  @override
  String get builderItemGate => 'Portal';

  @override
  String get builderItemStarDetail => 'Uma estrela para coletar';

  @override
  String get builderItemTrioDetail => 'As três juntas dão bônus';

  @override
  String get builderItemHeartDetail => 'Devolve um coração';

  @override
  String get builderEnemyKind => 'Tipo';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'O pássaro voa em cima e embaixo de cada agachamento: coloque os itens sobre as linhas amarelas ou entre elas.',
      'other':
          'O pássaro voa em cima e embaixo de cada flexão: coloque os itens sobre as linhas amarelas ou entre elas.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'Morcego roxo';

  @override
  String get builderEnemy_caveBat => 'Morcego das cavernas';

  @override
  String get builderEnemy_spitterBeetle => 'Besouro-cuspidor';

  @override
  String get builderEnemy_duskMoth => 'Mariposa do crepúsculo';

  @override
  String get builderEnemy_alleyPigeon => 'Pombo de beco';

  @override
  String get builderEnemy_mummyBat => 'Morcego múmia';

  @override
  String get builderSummaryTitle => 'Esta fase';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'Duração';

  @override
  String get builderFactStars => 'Estrelas';

  @override
  String get builderFactMarks => 'Marcas';

  @override
  String get builderFactWorkout => 'Exercício';

  @override
  String get builderFactPace => 'Ritmo';

  @override
  String get builderFactBoss => 'Chefão';

  @override
  String get builderPace_relaxed => 'Tranquilo';

  @override
  String get builderPace_steady => 'Constante';

  @override
  String get builderPace_brisk => 'Acelerado';

  @override
  String get builderSummaryStarterNote =>
      'Uma fase de exemplo para voar do jeito que está ou remixar como sua.';

  @override
  String get builderSummaryClearedNote =>
      'Concluída por você: você voou até o fim.';

  @override
  String get builderSummaryClearNote =>
      'Faça um voo de teste até a chegada para marcá-la como concluída.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat':
          'Faça um voo de teste, derrote o $boss e cruze a linha para marcá-la como concluída.',
      'spitterBeetle':
          'Faça um voo de teste, derrote o $boss e cruze a linha para marcá-la como concluída.',
      'duskMoth':
          'Faça um voo de teste, derrote a $boss e cruze a linha para marcá-la como concluída.',
      'pirate':
          'Faça um voo de teste, derrote o $boss e cruze a linha para marcá-la como concluída.',
      'dragon':
          'Faça um voo de teste, derrote o $boss e cruze a linha para marcá-la como concluída.',
      'kingCoo':
          'Faça um voo de teste, derrote o $boss e cruze a linha para marcá-la como concluída.',
      'searchlightGargoyle':
          'Faça um voo de teste, derrote a $boss e cruze a linha para marcá-la como concluída.',
      'other':
          'Faça um voo de teste, derrote $boss e cruze a linha para marcá-la como concluída.',
    });
    return '$_temp0';
  }

  @override
  String get builderSummaryHowTo =>
      'Escolha uma ferramenta à esquerda e toque no céu. Toque em algo para mudar; arraste para mover.';

  @override
  String get builderFamily_garden_detail =>
      'Fica parado. Pode ter uma porta de pedra.';

  @override
  String get builderFamily_windLift_detail => 'A abertura sobe e desce.';

  @override
  String get builderFamily_petalGate_detail => 'A abertura estreita e alarga.';

  @override
  String get builderFamily_switchback_detail =>
      'Duas aberturas que se afastam.';

  @override
  String get builderFamily_lanternDrift_detail =>
      'Lanternas penduradas que balançam.';

  @override
  String get builderFamily_sunWheels_detail => 'Rodas que se fecham e voltam.';

  @override
  String get builderFamily_crystalSteps_detail => 'Três degraus em onda.';

  @override
  String get builderFamiliesCloseSemantics => 'Fechar tipos de portal';

  @override
  String get builderFamiliesTitle => 'Tipo de portal';

  @override
  String get builderFamiliesSubtitle => 'Como o portal parece e se move.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dê à fase um nome de até $count letras.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort =>
      'Leve a linha de chegada mais longe: a fase está curta demais.';

  @override
  String get reach_tooLong =>
      'Traga a linha de chegada mais perto: a fase está longa demais.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Coisas demais: uma fase comporta até $count.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap =>
      'Só fases de Toque e Voe terminam com chefão.';

  @override
  String get reach_noGates => 'Adicione portais para o pássaro atravessar.';

  @override
  String get reach_startZone =>
      'Perto demais da largada: mova para depois da zona de largada.';

  @override
  String get reach_finishRoom =>
      'Deixe espaço antes da linha de chegada depois deste portal.';

  @override
  String get reach_overlap => 'Dois portais se sobrepõem: afaste um do outro.';

  @override
  String get reach_gateHeight => 'Este portal está alto ou baixo demais.';

  @override
  String get reach_gateMotion => 'Este portal não pode se mover assim.';

  @override
  String get reach_gateLook => 'Este portal tem um visual desconhecido.';

  @override
  String get reach_gateNarrow => 'Abra mais este portal: o pássaro não passa.';

  @override
  String get reach_gateWide => 'Este portal está aberto demais.';

  @override
  String get reach_doorNeedsShoot =>
      'Uma porta de pedra precisa de Toque e Voe com Atirar ligado.';

  @override
  String get reach_doorNeedsGarden =>
      'Só um portal do jardim pode ter porta de pedra.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Troca apertada: um agachamento tranquilo pode não chegar a tempo.',
      'other': 'Troca apertada: uma flexão tranquila pode não chegar a tempo.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'Subida íngreme: deixe mais espaço para pular até este portal.';

  @override
  String get reach_enemyNeedsTap => 'Inimigos só voam em fases de Toque e Voe.';

  @override
  String get reach_outsideSky => 'Mantenha dentro do céu.';

  @override
  String get reach_pastFinish => 'Coloque antes da linha de chegada.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Fora do alcance do agachamento: aproxime das faixas.',
      'other': 'Fora do alcance da flexão: aproxime das faixas.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'Dentro de uma parede: mova para a abertura.';

  @override
  String get reach_noStars => 'Coloque pelo menos uma estrela.';

  @override
  String get reach_marks =>
      'As marcas de estrela pedem mais estrelas do que a fase tem.';

  @override
  String reach_cannotFly(String problem) {
    return 'Esta fase ainda não pode voar ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'A fase não foi salva, então ainda não pode voar. Toque no nome dela para tentar de novo.';

  @override
  String get builderShareBlockedToast =>
      'Corrija os avisos vermelhos primeiro: depois a fase pode ser compartilhada.';

  @override
  String get builderEditorBackSemantics => 'Voltar ao criador';

  @override
  String get builderSettingsSemantics => 'Configurações da fase';

  @override
  String get builderFly => 'VOAR';

  @override
  String get builderTestFly => 'TESTAR VOO';

  @override
  String get builderFlySemantics => 'Voar nesta fase';

  @override
  String get builderTestFlySemantics => 'Fazer um voo de teste da fase inteira';

  @override
  String get builderUndoSemantics => 'Desfazer';

  @override
  String get builderRedoSemantics => 'Refazer';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice dicas',
      one: '$advice dica',
    );
    return '$blocking para corrigir, $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice dicas',
      one: '$advice dica',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => 'Pronta para voar';

  @override
  String get builderShareSemantics => 'Código da fase';

  @override
  String get builderFromHereSemantics => 'Voo de teste a partir daqui';

  @override
  String get builderFromHere => 'Daqui';

  @override
  String get builderStatusStarter => 'Exemplo · veja, voe ou remixe';

  @override
  String get builderStatusSaveFailed => 'Erro ao salvar · toque para repetir';

  @override
  String get builderStatusSaving => 'Salvando…';

  @override
  String get builderStatusSaved => 'Todas as alterações salvas';

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
    return '$name. $mode. $status. Toque para renomear.';
  }

  @override
  String get builderStarterBanner => 'Remixe para deixar do seu jeito';

  @override
  String get builderRemix => 'Remixar';

  @override
  String get builderRemixSemantics => 'Remixar';

  @override
  String get builderIssuesCloseSemantics => 'Fechar problemas e dicas';

  @override
  String get builderIssuesReadyTitle => 'Pronta para voar!';

  @override
  String get builderIssuesFixTitle => 'Corrija antes de voar';

  @override
  String get builderIssuesTipsTitle => 'Pronta, com algumas dicas';

  @override
  String get builderIssuesReadyDetail =>
      'Nada a corrigir. Faça um voo de teste até o fim para concluí-la.';

  @override
  String get builderIssuesDetail =>
      'Toque em um para ir até o lugar dele na rota.';

  @override
  String get builderSettingsCloseSemantics => 'Fechar configurações';

  @override
  String get builderSettingsTitle => 'Configurações da fase';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · as mudanças são salvas na hora';
  }

  @override
  String get builderSettingsName => 'Nome';

  @override
  String get builderRename => 'Renomear';

  @override
  String get builderRenameSemantics => 'Renomear';

  @override
  String get builderSettingsRegion => 'Região';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugares · deslize para ver',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'Ritmo';

  @override
  String get builderSettingsPaceHint => 'quão rápido o céu passa';

  @override
  String get builderSettingsMarks => 'Marcas';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas colocadas',
      one: '1 estrela colocada',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'marca de duas estrelas';

  @override
  String get builderMarkThreeSemantics => 'marca de três estrelas';

  @override
  String get builderMarksAuto => 'Automático: segue as estrelas';

  @override
  String get builderMarksByHand => 'Definir à mão';

  @override
  String get builderSettingsControls => 'Controles';

  @override
  String get builderShootOn => 'Atirar ligado';

  @override
  String get builderShootOff => 'Atirar desligado';

  @override
  String get builderSprintOn => 'Turbo ligado';

  @override
  String get builderSprintOff => 'Turbo desligado';

  @override
  String get builderSettingsBoss => 'Chefão final';

  @override
  String get builderSettingsBossHint => 'espera no fim';

  @override
  String get builderNoBossSemantics => 'Sem chefão: linha de chegada';

  @override
  String get builderNoBoss => 'Nenhum';

  @override
  String get builderBossShort_baronBat => 'Barão';

  @override
  String get builderBossShort_spitterBeetle => 'Rei';

  @override
  String get builderBossShort_duskMoth => 'Imperatriz';

  @override
  String get builderBossShort_pirate => 'Pirata';

  @override
  String get builderBossShort_dragon => 'Dragão';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'O pássaro voa em duas faixas: em cima e embaixo de cada agachamento. Quem é mais devagar encontra a mesma fase numa velocidade mais calma. Aqui não tem tiro, turbo nem chefão.',
      'other':
          'O pássaro voa em duas faixas: em cima e embaixo de cada flexão. Quem é mais devagar encontra a mesma fase numa velocidade mais calma. Aqui não tem tiro, turbo nem chefão.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'Cada pulo levanta o pássaro; ele plana entre um e outro. Aqui não tem tiro, turbo nem chefão.';

  @override
  String get builderStartZoneToast =>
      'Deixe a zona de largada livre: coloque as coisas à direita da linha tracejada.';

  @override
  String get builderSkySemantics =>
      'Céu da fase. Toque para colocar, arraste para mover ou rolar.';

  @override
  String get builderSkyReadOnlySemantics =>
      'Céu da fase. Toque em algo para ver.';

  @override
  String get builderCoachTitle => 'Monte sua fase';

  @override
  String get builderCoachPickTool => 'Escolha uma ferramenta à esquerda';

  @override
  String get builderCoachTapSky => 'Toque no céu para colocar';

  @override
  String get builderCoachTestFly => 'Faça um voo de teste!';

  @override
  String get builderCoachDrag =>
      'Arraste algo para mover · arraste o céu para rolar';

  @override
  String get builderTipDrag => 'Arraste para mover · arraste o céu para rolar';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'EM CIMA NO AGACHAMENTO',
      'other': 'EM CIMA NA FLEXÃO',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'EM CIMA';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'EMBAIXO NO AGACHAMENTO',
      'other': 'EMBAIXO NA FLEXÃO',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'EMBAIXO';

  @override
  String get builderCanvasStartZoneFull => 'ZONA DE LARGADA · NÃO OCUPE';

  @override
  String get builderCanvasStartZone => 'LARGADA';

  @override
  String get builderCanvasFinishHere => 'CHEGADA AQUI';

  @override
  String get builderTool_select => 'Escolher';

  @override
  String get builderToolHint_select =>
      'Escolher: toque em algo para mudar, arraste para mover';

  @override
  String get builderTool_gate => 'Portal';

  @override
  String get builderToolHint_gate =>
      'Portal: toque no céu para colocar um portal';

  @override
  String get builderTool_star => 'Estrela';

  @override
  String get builderToolHint_star =>
      'Estrela: toque no céu para colocar uma estrela';

  @override
  String get builderTool_trio => 'Trio';

  @override
  String get builderToolHint_trio =>
      'Trio de estrelas: toque no céu para colocar três estrelas';

  @override
  String get builderTool_heart => 'Coração';

  @override
  String get builderToolHint_heart =>
      'Coração: toque no céu para colocar um coração';

  @override
  String get builderTool_enemy => 'Inimigo';

  @override
  String get builderToolHint_enemy =>
      'Inimigo: toque no céu para colocar um inimigo';

  @override
  String get builderTool_finish => 'Chegada';

  @override
  String get builderToolHint_finish =>
      'Chegada: toque no céu para mover a linha de chegada';

  @override
  String get builderTool_boss => 'Chefão';

  @override
  String get builderToolHint_boss =>
      'Marca do chefão: toque no céu para mudar onde o chefão espera';

  @override
  String get builderStarterToolsToast =>
      'Fases de exemplo ficam como estão: remixe para mudar.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Visão da rota. $length até o chefão. Arraste para percorrer a rota.',
      'other':
          'Visão da rota. $length até a chegada. Arraste para percorrer a rota.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Visão da rota. $length até o chefão. $reps. Arraste para percorrer a rota.',
      'other':
          'Visão da rota. $length até a chegada. $reps. Arraste para percorrer a rota.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '$length até o chefão';
  }

  @override
  String get builtResultTestFlight => 'VOO DE TESTE';

  @override
  String get builtResultCleared => 'Concluída!';

  @override
  String get builtResultBonk => 'Tóim!';

  @override
  String get builtResultLanded => 'Pousou';

  @override
  String get builtResultTestTab => 'TESTE';

  @override
  String get builtResultGoalFinish => 'Chegada';

  @override
  String get builtResultGoalBoss => 'Chefão';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. Feito.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Colete $count estrelas.',
      one: 'Colete 1 estrela.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Colete $count estrelas. Feito.',
      one: 'Colete 1 estrela. Feito.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'Feito';

  @override
  String get builtResultNotYet => 'Ainda não';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count',
      one: 'Falta $count',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'Precisa chegar';

  @override
  String get builtResultClearedByYou => 'CONCLUÍDA POR VOCÊ';

  @override
  String get builtResultNewBest => 'NOVO RECORDE!';

  @override
  String get builtResultPractice => 'Treino';

  @override
  String builtResultBest(int count) {
    return 'Recorde $count';
  }

  @override
  String get builtResultFirstClear => 'Primeira vez!';

  @override
  String get builtResultStarsCollected => 'ESTRELAS COLETADAS';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de 3 estrelas da fase',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'A FASE PEDE';

  @override
  String get builtResultWorkout => 'EXERCÍCIO';

  @override
  String get builtResultGotTo => 'CHEGOU A';

  @override
  String get builtResultScore => 'PONTUAÇÃO';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flexões',
      one: 'flexão',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'agachamentos',
      one: 'agachamento',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pulos',
      one: 'pulo',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flexões na câmera',
      one: 'flexão na câmera',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'agachamentos na câmera',
      one: 'agachamento na câmera',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'de $length';
  }

  @override
  String get builtResultNotKept => 'Não fica salvo';

  @override
  String get builtResultNoBest => 'Sem recorde';

  @override
  String get builtResultClearedStrip =>
      'Concluída por você · pronta para compartilhar!';

  @override
  String builtResultFlownFrom(String from) {
    return 'Voo a partir de $from. Voe tudo para concluir.';
  }

  @override
  String get builtResultTestNothingSaved => 'Voo de teste · nada é salvo';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'Voo de teste · chegou a $reached de $length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return 'Chegou a $reached de $length. Chegue ao fim para ganhar estrelas.';
  }

  @override
  String get builtResultReachFinish => 'Chegue ao fim para ganhar estrelas.';

  @override
  String get builtResultSaved => 'Salvo neste celular';

  @override
  String get builtResultSaving => 'Salvando seu voo…';

  @override
  String get builtResultBuilder => 'Criador';

  @override
  String get builtResultEditLevel => 'Editar fase';

  @override
  String get builtResultEdit => 'Editar';

  @override
  String get builtResultFlyAgain => 'Voar de novo';

  @override
  String get builtResultWatchReplay => 'Ver replay';

  @override
  String get builtResultPreparing => 'Preparando…';

  @override
  String get builtResultSessionSaving => 'Salvando…';

  @override
  String get builtResultSaveSession => 'Salvar sessão';

  @override
  String get builderShelfTitle => 'Criador de Fases';

  @override
  String get builderShelfPasteCode => 'Colar código';

  @override
  String get builderShelfNewLevel => 'Nova fase';

  @override
  String get builderShelfSaveFailed => 'Não deu para salvar. Tente de novo.';

  @override
  String builderShelfDeleteTitle(String name) {
    return 'Apagar “$name”?';
  }

  @override
  String get builderShelfDeleteBody =>
      'Os recordes dela vão junto. As flexões, agachamentos e pulos que você fez nela continuam valendo.';

  @override
  String get builderShelfDelete => 'Apagar';

  @override
  String builderShelfDeleted(String name) {
    return '“$name” foi apagada.';
  }

  @override
  String get builderShelfFixFirst =>
      'Corrija o que está em vermelho antes de compartilhar: toque em Corrigir.';

  @override
  String get builderShelfCodeCopied =>
      'Código copiado! Cole e mande pros amigos.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'Código copiado! Voe até a chegada também, para os amigos saberem que dá para passar.';

  @override
  String get builderShelfNotReady =>
      'Esta fase ainda não pode voar: toque em Corrigir.';

  @override
  String get builderShelfPasteMissingTitle =>
      'Nenhum código de fase para colar';

  @override
  String get builderShelfPasteNewerTitle =>
      'Uma fase de um Beakbound mais novo';

  @override
  String get builderShelfPasteDamagedTitle => 'Esse código veio embaralhado';

  @override
  String get builderShelfPasteMissingBody =>
      'Copie o código da fase de um amigo (começa com BEAK1.) e toque em Colar código de novo.';

  @override
  String get builderShelfPasteNewerBody =>
      'Atualize o Beakbound para voar nela e cole o código de novo.';

  @override
  String get builderShelfPasteDamagedBody =>
      'Falta um pedaço ou tem algo digitado errado. Peça para quem mandou copiar o código inteiro de novo.';

  @override
  String builderShelfImported(String name) {
    return '“$name” está na sua estante!';
  }

  @override
  String get builderShelfUnavailable => 'Suas fases não carregaram.';

  @override
  String get builderShelfMine => 'Minhas fases';

  @override
  String get builderShelfStarters => 'Fases de exemplo';

  @override
  String get builderShelfStartersHint =>
      'Voe numa delas ou remixe para criar a sua';

  @override
  String get builderShelfEmptyTitle => 'Crie sua primeira fase';

  @override
  String get builderShelfEmptyBody =>
      'Coloque portais, estrelas e corações à mão, defina a linha de chegada e faça um voo de teste.';

  @override
  String get builderShelfPasteFriend => 'Colar o código de um amigo';

  @override
  String get builderShelfNeedsWork => 'Precisa de ajustes';

  @override
  String get builderShelfClearedByYou => 'Concluída por você';

  @override
  String get builderShelfFromFriend => 'De um amigo';

  @override
  String get builderShelfFly => 'Voar';

  @override
  String builderShelfFlySemantics(String name) {
    return 'Voar em $name';
  }

  @override
  String get builderShelfFixIt => 'Corrigir';

  @override
  String builderShelfFixSemantics(String name) {
    return 'Corrigir $name';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return 'Editar $name';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return 'Compartilhar $name';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return 'Compartilhar $name: você concluiu';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'Opções de $name';
  }

  @override
  String get builderShelfRemix => 'Remixar';

  @override
  String builderShelfRemixSemantics(String name) {
    return 'Remixar $name';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coisas para corrigir no editor',
      one: '1 coisa para corrigir no editor',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas',
      one: '$count estrela',
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
    return '$name. $mode, $region. $length.';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Recorde: $stars de 3 estrelas.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Precisa de ajustes: $count coisas para corrigir.',
      one: 'Precisa de ajustes: 1 coisa para corrigir.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'Concluída por você.';

  @override
  String get builderShelfFromFriendSemantics => 'De um amigo.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return 'Ver $name. $mode, $length, $fact.';
  }

  @override
  String get builderShelfRemixSuffix => 'remix';

  @override
  String get builderShelfCopySuffix => 'cópia';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get starter_t_tap_1_name => 'Pulos no Jardim';

  @override
  String get starter_t_push_1_name => 'Dez Flexões';

  @override
  String get starter_t_squat_1_name => 'Agacha na Escada';

  @override
  String get starter_t_jump_1_name => 'Baía Pula-Pula';

  @override
  String get starter_t_tap_boss_name => 'Ponte do Barão';

  @override
  String get builderPickCloseNewLevel => 'Fechar nova fase';

  @override
  String get builderPickModeTitle => 'Como vai ser?';

  @override
  String get builderPickRegionTitle => 'Onde vai voar?';

  @override
  String get builderPickModeSubtitle =>
      'Escolha como se voa (não dá para mudar depois). Todo voo de teste é por toque.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · escolha onde ela voa. Dá para mudar depois.';
  }

  @override
  String get builderPickTouchLine =>
      'Toque para bater as asas. Portais, estrelas, inimigos e um chefão.';

  @override
  String get builderPickPushUpLine =>
      'Uma faixa alta e uma baixa: cada descida é uma flexão.';

  @override
  String get builderPickSquatLine =>
      'Uma faixa alta e uma baixa: cada descida é um agachamento.';

  @override
  String get builderPickJumpLine =>
      'Pule para subir. Portais em qualquer altura do céu.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'Câmera';

  @override
  String get builderPickSuggested => 'Sugestão';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, sugestão';
  }

  @override
  String get builderPickClose => 'Fechar';

  @override
  String get builderPickNotYet =>
      'Ainda não: corrija primeiro o que está em vermelho.';

  @override
  String get builderPickShare => 'Código da fase';

  @override
  String get builderPickShareLine =>
      'Copie um código que um amigo pode colar no Beakbound dele.';

  @override
  String get builderPickDuplicate => 'Duplicar';

  @override
  String get builderPickDuplicateLine =>
      'Faça uma cópia para testar outra ideia.';

  @override
  String get builderPickDeleteLine =>
      'Jogue a fase fora. Vamos perguntar antes.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'Cancelar importação';

  @override
  String get builderPickImportTitle => 'Uma fase para voar!';

  @override
  String get builderPickImportSubtitle =>
      'Alguém compartilhou esta fase com você.';

  @override
  String get builderPickClearedByMaker => 'Concluída por quem criou';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas para coletar',
      one: '$count estrela para coletar',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Termina com o $boss',
      'spitterBeetle': 'Termina com o $boss',
      'duskMoth': 'Termina com a $boss',
      'pirate': 'Termina com o $boss',
      'dragon': 'Termina com o $boss',
      'kingCoo': 'Termina com o $boss',
      'searchlightGargoyle': 'Termina com a $boss',
      'other': 'Termina com $boss',
    });
    return '$_temp0';
  }

  @override
  String get builderPickNotFlown => 'Quem criou ainda não voou até o fim.';

  @override
  String get builderPickRoute => 'A rota';

  @override
  String builderPickAlreadyHave(String name) {
    return 'Você já tem esta fase: “$name”.';
  }

  @override
  String get builderPickImportCopy => 'Importar uma cópia';

  @override
  String get builderPickOpenYours => 'Abrir a sua';

  @override
  String get builderPickImport => 'Importar';

  @override
  String get builderShelfRenameCancelSemantics => 'Cancelar renomeação';

  @override
  String get builderShelfRenameTitle => 'Dê um nome à sua fase';

  @override
  String get builderShelfRenameEmpty => 'Um nome precisa de uma ou duas letras';

  @override
  String get builderShelfRenameSaveSemantics => 'Salvar nome';

  @override
  String get builderShelfRenameSave => 'Salvar';

  @override
  String get coopMode_roped => 'Na corda';

  @override
  String get coopMode_free => 'Sem corda';

  @override
  String get coopMode_duel => '1 contra 1';

  @override
  String get coopTitle => 'Voem Juntos';

  @override
  String get coopPlayersTag => 'DOIS JOGADORES · UM CELULAR';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode: RECORDE $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: SEM RECORDE';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count DUELOS',
      one: '$mode · $count DUELO',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode: PRIMEIRO DUELO';
  }

  @override
  String get coopRopedLead => 'Seus pássaros dividem uma corda.';

  @override
  String get coopRopedBody =>
      'Batam asas juntos para subir alto: um pássaro sozinho levanta os dois, mas só um pouco. Usem o Turbo para puxar o outro pássaro.';

  @override
  String get coopFreeLead => 'Sem corda:';

  @override
  String get coopFreeBody =>
      'cada pássaro voa sozinho e só esbarra no outro. Corações, escudo e pontuação continuam compartilhados.';

  @override
  String get duelLead => 'Duelo!';

  @override
  String get duelBody =>
      'Cada pássaro tem seus próprios corações. Peguem caixas-surpresa: algumas mandam morcegos, um besouro-cuspidor ou meteoros no rival, outras dão um coração, um escudo ou poder estelar. Vence o último pássaro no ar.';

  @override
  String get coopStart => 'Voar juntos';

  @override
  String get duelStart => 'Lutar!';

  @override
  String get coopFlightSemantics =>
      'Jogador 1 toca na metade esquerda para bater as asas, jogador 2 na metade direita';

  @override
  String get coopPauseSemantics => 'Pausar o voo';

  @override
  String coopShootSemantics(int player) {
    return 'Jogador $player: atirar';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'Jogador $player: turbo';
  }

  @override
  String coopPlayerShort(int player) {
    return 'J$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'JOGADOR $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Ímã de estrelas: faltam $seconds segundos',
      one: 'Ímã de estrelas: falta $seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Ímã carregando: $charge de $gates portais perfeitos',
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
  String get coopCountdownRoped => 'Corda presa. Preparar, apontar…';

  @override
  String get coopCountdownFree => 'Preparar, apontar…';

  @override
  String get duelCountdown => 'Prontos para o duelo…';

  @override
  String get coopCountdownRopedHint =>
      'Batam asas juntos para subir alto.\nUsem o Turbo para puxar o outro!';

  @override
  String get coopCountdownFreeHint =>
      'Cada pássaro voa sozinho.\nDividam os corações, vençam os portais!';

  @override
  String get duelCountdownHint =>
      'Peguem as caixas-surpresa!\nVence o último pássaro no ar.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Poder estelar do jogador $player: faltam $seconds segundos',
      one: 'Poder estelar do jogador $player: falta $seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'Início';

  @override
  String get coopChangeBirds => 'Trocar pássaros';

  @override
  String get coopSaved => 'Salvo';

  @override
  String get coopSaving => 'Salvando…';

  @override
  String get coopSaveSession => 'Salvar sessão';

  @override
  String get duelRematch => 'Revanche';

  @override
  String get coopFlyAgain => 'Voar de novo';

  @override
  String duelWinner(int player) {
    return 'Jogador $player venceu!';
  }

  @override
  String get duelDraw => 'Empate!';

  @override
  String get duelStopped => 'Duelo interrompido';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first x $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner venceu $loser';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize no J$rival!';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize!';
  }

  @override
  String get duelPrize_batSwarm => 'Morcegada';

  @override
  String get duelPrize_spitter => 'Besouro-cuspidor';

  @override
  String get duelPrize_meteorShower => 'Chuva meteórica';

  @override
  String get duelPrize_heart => 'Coração';

  @override
  String get duelPrize_shield => 'Escudo';

  @override
  String get duelPrize_starPower => 'Poder estelar';

  @override
  String get coopTapLeftHalf => 'Toque na metade esquerda';

  @override
  String get coopTapRightHalf => 'Toque na metade direita';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'Jogador $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'J$player · toque deste lado';
  }

  @override
  String get coopKeysP1 => 'J1 · W asas · D atira · A turbo';

  @override
  String get coopKeysP2 => 'J2 · Cima asas · Dir. atira · Esq. turbo';

  @override
  String get coopRopedSemantics => 'Na corda: os pássaros dividem uma corda';

  @override
  String get coopFreeSemantics => 'Sem corda: cada pássaro voa sozinho';

  @override
  String get duelModeSemantics => '1 contra 1: os pássaros lutam entre si';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'Sessão salva · Veja em Recordes';

  @override
  String get coopNewTeamBest => 'Novo recorde da equipe!';

  @override
  String get coopWhatATeam => 'Que dupla!';

  @override
  String coopPairCaption(String first, String second) {
    return '$first e $second';
  }

  @override
  String get coopTeamScore => 'PONTOS DA EQUIPE';

  @override
  String get coopTeamBest => 'RECORDE DA EQUIPE';

  @override
  String get coopNewTeamBestRibbon => 'NOVO RECORDE DE EQUIPE';

  @override
  String get coopStatFlightTime => 'tempo de voo';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'estrelas',
      one: 'estrela',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portais',
      one: 'portal',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'DIVISÃO DAS BATIDAS';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'batidas do J$player',
      one: 'batida do J$player',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'Tempo de duelo $time';
  }

  @override
  String get duelSeries => 'PLACAR';

  @override
  String get duelHeartsLeft => 'corações restantes';

  @override
  String get duelBoxesOpened => 'caixas abertas';

  @override
  String get duelHitsLanded => 'acertos';

  @override
  String get coopPauseSubtitle =>
      'Vocês dois estão no poleiro, esperando. A gente faz a contagem para os dois.';

  @override
  String get coopFinishFlight => 'Encerrar voo';

  @override
  String get cameraLabIntro =>
      'Apoie o celular baixo, na horizontal, de frente para você ou ao seu lado.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'Quase lá · preciso ver melhor: $parts';
  }

  @override
  String get cameraLabJointShoulder => 'ombro';

  @override
  String get cameraLabJointElbow => 'cotovelo';

  @override
  String get cameraLabJointWrist => 'pulso';

  @override
  String get cameraLabJointHip => 'quadril';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => 'Iniciando a câmera…';

  @override
  String get cameraLabDenied =>
      'O acesso à câmera está desligado. Permita nas configurações do app e tente de novo.';

  @override
  String cameraLabFailed(String error) {
    return 'A câmera não iniciou: $error';
  }

  @override
  String get cameraLabStopped =>
      'Câmera parada. Toque em Iniciar câmera para recalibrar.';

  @override
  String get cameraLabBack => 'LAB DA CÂMERA · Voltar ao início';

  @override
  String get cameraLabStepShow => '1. Mostre braços e quadril';

  @override
  String get cameraLabStepPushUps => '2. Faça duas flexões';

  @override
  String get cameraLabStepMove => '3. Mova seu pássaro!';

  @override
  String get cameraLabStepSquat => 'Encontre seu agachamento';

  @override
  String get cameraLabStepJump => 'Encontre sua posição em pé';

  @override
  String get cameraLabPushUpHelp =>
      'Celular baixo, de frente ou ao seu lado.\nDe frente? Mostre os dois ombros, um braço e o quadril.\nDesça e suba duas vezes, no seu ritmo.';

  @override
  String get cameraLabSquatHelp =>
      'Fique em pé sem se mexer, agache com conforto, segure um pouco e levante. Agache para descer; levante para subir.';

  @override
  String get cameraLabJumpHelp =>
      'Fique de frente para o celular com o corpo inteiro e os pés à vista. Não se mexa, depois dê pulinhos. Um pulo = um grande impulso.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'CALIBRAÇÃO\n$done / $total calibradas',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'CALIBRAÇÃO\n$percent% calibrado';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TESTE DE CONTROLE\n$count flexões',
      one: 'TESTE DE CONTROLE\n$count flexão',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TESTE DE CONTROLE\n$count agachamentos',
      one: 'TESTE DE CONTROLE\n$count agachamento',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TESTE DE CONTROLE\n$count pulos',
      one: 'TESTE DE CONTROLE\n$count pulo',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Hz · $ms ms p95';
  }

  @override
  String get cameraLabStartingButton => 'Iniciando…';

  @override
  String get cameraLabRecalibrate => 'Recalibrar';

  @override
  String get cameraLabStartCamera => 'Iniciar câmera';

  @override
  String get cameraLabTapStart => 'Toque em Iniciar câmera';

  @override
  String cameraLabTry(String mode) {
    return 'Testar $mode';
  }

  @override
  String get cameraBadgeWaking => 'ACORDANDO';

  @override
  String get cameraBadgeLive => 'AO VIVO';

  @override
  String get cameraBadgeLockedOn => 'NA MIRA';

  @override
  String get cameraBadgeOffline => 'DESLIGADA';

  @override
  String get trackingCatchingUp => 'Câmera atrasada · um instante';

  @override
  String get trackingStepIntoOutline => 'Entre no contorno do corpo';

  @override
  String get trackingKeepShoulders => 'Mantenha os dois ombros à vista';

  @override
  String get trackingShowSide =>
      'Mostre de lado um ombro, cotovelo, pulso e quadril';

  @override
  String get trackingMoveCloser => 'Chegue um pouco mais perto';

  @override
  String get trackingGetDown => 'Desça para a posição de flexão';

  @override
  String get trackingHandsOnFloor =>
      'Ponha as mãos no chão e estique o corpo para trás';

  @override
  String get trackingExtendBody =>
      'Estique o corpo um pouco mais atrás das mãos';

  @override
  String get trackingComfortableRange =>
      'Fique numa amplitude de flexão confortável';

  @override
  String get trackingPlaceHands =>
      'Ponha as mãos no chão com o corpo atrás delas';

  @override
  String get trackingFrontTracked =>
      'Visão frontal detectada · mantenha as mãos à vista';

  @override
  String get trackingBodyInView => 'Corpo à vista · pode olhar para baixo';

  @override
  String get trackingArmsTracked => 'Braços detectados · pernas pouco visíveis';

  @override
  String get trackingFindTop => 'Ache uma posição alta confortável';

  @override
  String get trackingCalibrated => 'Calibrado! Tente mover seu pássaro.';

  @override
  String get trackingFreshFrame => 'Esperando uma imagem nova';

  @override
  String get trackingDistanceChanged =>
      'A distância da câmera mudou · recalibre';

  @override
  String get trackingKeepArm => 'Mantenha um braço à vista';

  @override
  String get trackingSquatStepBack =>
      'Dê um passo para trás para mostrar ombros, quadril, joelhos e pés';

  @override
  String get trackingSquatFaceCamera =>
      'Fique de frente para a câmera com os dois pés no chão';

  @override
  String get trackingSquatControls => 'Agache para descer · levante para subir';

  @override
  String get trackingStartingDistance =>
      'Fique de frente para a câmera na distância inicial · recalibre se mudou';

  @override
  String get trackingFeetPlanted =>
      'Mantenha os pés firmes no ponto de partida';

  @override
  String get trackingSquatStandTall =>
      'Fique em pé, sem se mexer, com os dois pés à vista';

  @override
  String get trackingStandStill => 'Fique em pé, sem se mexer, por um instante';

  @override
  String get trackingSquatDepth =>
      'Agache até uma altura confortável e segure um pouco';

  @override
  String get trackingSquatHold =>
      'Agache com conforto e segure por um instante';

  @override
  String get trackingSquatHoldBriefly =>
      'Segure um pouco esse agachamento confortável';

  @override
  String get trackingSquatStandUp =>
      'Levante de novo para terminar a calibração';

  @override
  String get trackingSquatReady =>
      'Pronto! Agache para descer · levante para subir';

  @override
  String get trackingJumpStepBack =>
      'Dê um passo para trás para mostrar ombros, quadril e os dois pés';

  @override
  String get trackingJumpFaceCamera =>
      'Fique de frente para a câmera com espaço acima para pular';

  @override
  String get trackingJumpSmall =>
      'Pulinhos bastam · pouse antes de pular de novo';

  @override
  String get trackingJumpStandStill =>
      'Não se mexa, com o corpo inteiro e os dois pés à vista';

  @override
  String get trackingJumpReady => 'Pronto! Um pulinho dá um grande impulso.';

  @override
  String get trackingFindPosition => 'Ache sua posição';

  @override
  String get trackingInterrupted => 'Rastreamento interrompido';

  @override
  String get trackingCameraInterrupted =>
      'Câmera interrompida. Confira a permissão da câmera e tente de novo.';

  @override
  String get trackingCameraAway =>
      'A câmera parou enquanto o app estava em segundo plano';

  @override
  String get trackingJumpBoost => 'Pule para um grande impulso';

  @override
  String get trackingJumpLand => 'Pouse para preparar o próximo pulo';

  @override
  String trackingLowerMore(int step, int total) {
    return 'Desça mais um pouco · $step de $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'Desça com conforto · $step de $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'Empurre e suba · $step de $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'Repita a mesma amplitude da primeira · $step de $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Não deu para salvar esta mudança. Tente de novo. ($error)';
  }

  @override
  String get commonDelete => 'Apagar';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count',
      one: 'Falta $count',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'Seu ninho não carregou.';

  @override
  String get homeSettings => 'Configurações';

  @override
  String homeGreetingFirst(String bird) {
    return 'Oi, eu sou $bird! Bora voar?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Aventura completa! $bird está orgulhoso.',
      'female': 'Aventura completa! $bird está orgulhosa.',
      'other': 'Aventura completa! $bird está feliz.',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird está pronto. E você?',
      'female': '$bird está pronta. E você?',
      'other': '$bird está a postos. E você?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'INFINITO';

  @override
  String get homeEndlessDetail => 'Voe o mais longe que puder';

  @override
  String get homeEndlessSemantics => 'Infinito. Voe o mais longe que puder.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: 'Infinito. Voe o mais longe que puder. Recorde: $best estrelas.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'Recorde';

  @override
  String get homeBestNone => 'Seu primeiro recorde!';

  @override
  String get homeCampaignTitle => 'CAMPANHA';

  @override
  String get homeCampaignDone => 'Toda carta entregue';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Campanha. Próxima: $level. $stars de $total estrelas.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Campanha. Toda carta entregue. $stars de $total estrelas.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'MINIJOGOS';

  @override
  String get homeMiniGamesDetail => 'Exercícios · 2 jogadores';

  @override
  String get homeMiniGamesSemantics =>
      'Minijogos. Flexões, agachamentos, pulos ou dois jogadores.';

  @override
  String get homeBuilderTitle => 'CRIADOR DE FASES';

  @override
  String get homeBuilderDetail => 'Crie · voe · compartilhe';

  @override
  String get homeBuilderSemantics =>
      'Criador de Fases. Crie suas próprias fases, voe nelas e compartilhe.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Libera em $count voos',
      one: 'Libera em 1 voo',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Criador de Fases. Bloqueado. Libera em $count voos.',
      one: 'Criador de Fases. Bloqueado. Libera em 1 voo.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'Aventura';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Aventura de hoje. $done de 3 metas concluídas.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'Pássaros';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'Pássaros. Voando com $bird.';
  }

  @override
  String get homeDockUpgrades => 'Melhorias';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Melhorias. $stars estrelas para gastar.',
      one: 'Melhorias. $stars estrela para gastar.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'Passaporte';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Passaporte. $earned de $total medalhas.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'Recordes';

  @override
  String get homeMiniGamesPickerTitle => 'Minijogos';

  @override
  String get homeMiniGamesPickerIntro =>
      'Mexa o corpo para voar ou divida o celular com um amigo.';

  @override
  String get homeMiniGamesCloseSemantics => 'Fechar minijogos';

  @override
  String get homeMiniGamesPushUpCard => 'Desça e mergulhe.\nEmpurre e decole.';

  @override
  String get homeMiniGamesSquatCard => 'Agache fundo.\nLevante e decole.';

  @override
  String get homeMiniGamesJumpCard => 'Pule para subir.\nPlane pelas estrelas.';

  @override
  String get homeMiniGamesCoopCard =>
      'Dois jogadores, um celular.\nDupla ou duelo.';

  @override
  String get homeMiniGamesCamera => 'Câmera';

  @override
  String get homeMiniGamesPlayers => 'Para dois';

  @override
  String get homeMiniGamesCoop => 'Voem Juntos';

  @override
  String get birdsTitle => 'Conheça sua tripulação.';

  @override
  String birdsFlownTag(int flown, int total) {
    return '$flown DE $total JÁ VOARAM';
  }

  @override
  String get birdsStatusCopilot => 'SUA DUPLA';

  @override
  String get birdsStatusReady => 'DISPONÍVEL';

  @override
  String get birdsStatusLocked => 'BLOQUEADO';

  @override
  String get birdsNotFlown => 'Ainda não voou';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voos',
      one: '1 voo',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return 'Voar com $bird';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return 'Voar com $bird em vez de $current';
  }

  @override
  String birdsUnlock(String bird) {
    return 'Desbloquear $bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Desbloquear $bird por $price estrelas',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Desbloquear $bird por $price estrelas, ainda faltam estrelas',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'Voando com você';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, voando com você';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, voando com você, novidade';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, bloqueado, $price estrelas',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird, novidade';
  }

  @override
  String get birdsTagFlying => 'VOANDO';

  @override
  String get birdsTagNew => 'NOVO';

  @override
  String get bird_0_description => 'Pássaro pequeno. Céu grande.';

  @override
  String get bird_0_trail => 'Bolhas de sol';

  @override
  String get bird_1_description =>
      'Bochecha rosada, topete cacheado, puro coração.';

  @override
  String get bird_1_trail => 'Corações de pêssego';

  @override
  String get bird_2_description =>
      'Beija-flor mini. Raminho fresco. A mil por hora.';

  @override
  String get bird_2_trail => 'Folhas de menta';

  @override
  String get bird_3_description =>
      'Corujinha sonhadora que voa à luz das estrelas.';

  @override
  String get bird_3_trail => 'Poeira estelar';

  @override
  String get upgradesWalletLabel => 'SEU\nSALDO';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars estrelas para gastar',
      one: '$stars estrela para gastar',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'Melhore seu pássaro.';

  @override
  String get upgradesIntro =>
      'Toque numa engrenagem para ver o que ela faz. Cada estrela que você pega no voo pode ser gasta.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, nível $level de $max. Próximo nível: $cost estrelas',
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
          '$power, nível $level de $max. Próximo nível: $cost estrelas, ainda faltam estrelas',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, nível $level de $max. No máximo';
  }

  @override
  String get upgradesMax => 'MÁX';

  @override
  String upgradesLevel(int level) {
    return 'Nível $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'Nível $level, o máximo';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label: $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label: $now, próximo nível $next';
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
      other: 'Vão sobrar $count estrelas.',
      one: 'Vai sobrar $count estrela.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'Melhorar';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Melhorar por $cost estrelas',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Melhorar por $cost estrelas, ainda faltam estrelas',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'No máximo';

  @override
  String get power_shot_name => 'Força do tiro';

  @override
  String get power_shot_blurb =>
      'Segure Atirar para carregar uma pedra maior e mais forte.';

  @override
  String get power_sprint_name => 'Turbo';

  @override
  String get power_sprint_blurb =>
      'Uma arrancada que esmaga os inimigos no caminho.';

  @override
  String get power_shield_name => 'Escudo';

  @override
  String get power_shield_blurb =>
      'Bloqueia um golpe para você. Pegue estrelas no voo para recarregar.';

  @override
  String get power_magnet_name => 'Ímã';

  @override
  String get power_magnet_blurb =>
      'Voe perfeito pelos portais para ganhá-lo. Ele atrai estrelas.';

  @override
  String get power_stat_maxCharge => 'Carga máxima';

  @override
  String get power_stat_burstLength => 'Duração da arrancada';

  @override
  String get power_stat_cooldown => 'Recarga';

  @override
  String get power_stat_starsToRefill => 'Estrelas para recarregar';

  @override
  String get power_stat_safeTime => 'Tempo seguro após quebrar';

  @override
  String get power_stat_perfectGates => 'Portais perfeitos exigidos';

  @override
  String get power_stat_lasts => 'Duração';

  @override
  String get power_stat_reach => 'Alcance';

  @override
  String get passportTitle => 'Seu passaporte do céu.';

  @override
  String get passportDailyCard => 'Cartão do dia';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total MEDALHAS';
  }

  @override
  String get passportIntro =>
      'Pequenas aventuras. Lembranças para sempre. Bronze, prata e ouro em cada carimbo.';

  @override
  String get passportNoMedal => 'Sem medalha ainda';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Medalha de bronze',
      'silver': 'Medalha de prata',
      'other': 'Medalha de ouro',
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
    return '$stamp. $held. Próxima, $next: $goal $current de $target.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. Medalha de ouro. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'ATÉ O BRONZE',
      'silver': 'ATÉ A PRATA',
      'other': 'ATÉ O OURO',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'CARIMBADO';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: nenhuma ainda';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'Bronze';

  @override
  String get passportMedal_silver => 'Prata';

  @override
  String get passportMedal_gold => 'Ouro';

  @override
  String get stamp_frequentFlyer_name => 'Viajante frequente';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conclua $n voos valendo pontos.',
      one: 'Conclua $n voo valendo pontos.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'Na mosca';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faça $n passagens perfeitas pelas miras.',
      one: 'Faça $n passagem perfeita pelas miras.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'Caça-estrelas';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Colete $n estrelas.',
      one: 'Colete $n estrela.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => 'Constelação';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Colete $n estrelas numa só sequência.',
      one: 'Colete $n estrela numa só sequência.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'Capitão do céu';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Marque $n pontos num só voo infinito.',
      one: 'Marque $n ponto num só voo infinito.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'Desbravador';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voe pelo menos 60 segundos em $n voos infinitos.',
      one: 'Voe pelo menos 60 segundos em $n voo infinito.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'Voando em bando';

  @override
  String get stamp_allRounder_name => 'Faz-tudo';

  @override
  String get stamp_flockTogether_goalBronze =>
      'Leve dois pássaros diferentes em voos valendo pontos.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'Leve os quatro pássaros em voos valendo pontos.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faça $n voos valendo pontos com cada pássaro.',
      one: 'Faça $n voo valendo pontos com cada pássaro.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'Voe num minijogo de flexão, agachamento ou pulo.';

  @override
  String get stamp_allRounder_goalSilver =>
      'Voe nos três minijogos: flexão, agachamento, pulo.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faça $n voos valendo pontos em cada minijogo.',
      one: 'Faça $n voo valendo pontos em cada minijogo.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals medalhas · na $level',
      one: '$stars★ · $medals medalha · na $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'Sua aventura não carregou.';

  @override
  String get dailyTitle => 'A pequena aventura de hoje.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · $done/3 METAS';
  }

  @override
  String get dailyIntro =>
      'Três metas. Qualquer controle. Um voo infinito vale para as três.';

  @override
  String get dailyLaunchEndless => 'Infinito';

  @override
  String get dailyPostcardKicker => 'POSTAL DO CLUBE DO CÉU';

  @override
  String get dailyStamped => 'POSTAL CARIMBADO!';

  @override
  String dailyGoalsComplete(int done) {
    return '$done / 3 METAS CUMPRIDAS';
  }

  @override
  String get dailyDoneNote => 'Uma pequena aventura, toda sua.';

  @override
  String get dailyOpenNote => 'Cumpra as três para carimbar o postal.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal Concluída';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current de $target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: postal carimbado';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: $done/3 metas';
  }

  @override
  String get dailyNoStreak => 'Metas novas. Nenhuma sequência a perder.';

  @override
  String get dailyTheme_0 => 'Entrega ao amanhecer';

  @override
  String get dailyTheme_1 => 'Piquenique de pêssego';

  @override
  String get dailyTheme_2 => 'Correio ao luar';

  @override
  String get dailyTheme_3 => 'Desfile de nuvens';

  @override
  String get dailyTheme_4 => 'Tesouro do crepúsculo';

  @override
  String get dailyTheme_5 => 'Festa no jardim';

  @override
  String get task_flights_title => 'Abra as asas';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conclua $count voos valendo pontos hoje.',
      one: 'Conclua $count voo valendo pontos hoje.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'Horizontes abertos';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Passe por $count portais nos voos valendo pontos de hoje.',
      one: 'Passe por $count portal nos voos valendo pontos de hoje.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'Bolso de estrelas';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Colete $count estrelas nos voos de hoje.',
      one: 'Colete $count estrela nos voos de hoje.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'Não perca o brilho';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Colete $count estrelas numa só sequência.',
      one: 'Colete $count estrela numa só sequência.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'Bem no alvo';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faça $count passagens perfeitas hoje.',
      one: 'Faça $count passagem perfeita hoje.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'A viagem inteira';

  @override
  String get task_finishTrail_goal =>
      'Voe pelo menos 60 segundos num só voo infinito.';

  @override
  String get recordsTitle => 'Suas pequenas vitórias.';

  @override
  String get recordsBestsTitle => 'Seus pontos de estrela a bater';

  @override
  String get recordsSectionMain => 'JOGO PRINCIPAL';

  @override
  String get recordsSectionMini => 'MINIJOGOS';

  @override
  String get recordsEndless => 'Infinito · Toque e Voe';

  @override
  String get recordsCampaignStars => 'Estrelas da campanha';

  @override
  String recordsCoopName(String mode) {
    return 'Voem Juntos · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'voos pontuados',
      one: 'voo pontuado',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portais',
      one: 'portal',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'em dupla',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'duelos',
      one: 'duelo',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flexões',
      one: 'flexão',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'agachamentos',
      one: 'agachamento',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'Voos recentes';

  @override
  String get recordsEmptyTitle => 'Céu grande. Página em branco.';

  @override
  String get recordsEmptyBody =>
      'Seu primeiro voo valendo pontos abre a história.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds s';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'Clássico · $date · $seconds s';
  }

  @override
  String get replaySavedSessions => 'Sessões salvas';

  @override
  String get replayBackToRecordsSemantics => 'Voltar aos Recordes';

  @override
  String get replaySessionsLoadFailed => 'Erro ao carregar sessões. Repetir';

  @override
  String get replayEmptyTitle => 'Seus voos ficam aqui';

  @override
  String get replayEmptyBody =>
      'Salve uma sessão depois de um voo para assistir aqui.';

  @override
  String get replayEmptyButton => 'Escolher um voo';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds s · $score pontos de estrela',
      one: '$date · $seconds s · $score ponto de estrela',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds s · $score portais',
      one: '$date · $seconds s · $score portal',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'Apagar sessão';

  @override
  String get replayDeleteTitle => 'Apagar esta sessão?';

  @override
  String get replayDeleteBody =>
      'O vídeo da câmera e o replay serão removidos. Suas pontuações continuam em Recordes.';

  @override
  String get replayDeleteFailed =>
      'Não deu para apagar a sessão. Tente de novo.';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return 'Fase $id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · Infinito';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · Treino';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · Infinito · Treino';
  }

  @override
  String get replayOpenFailed => 'Não deu para abrir esta sessão.';

  @override
  String get replayBackToSessions => 'Voltar às sessões';

  @override
  String get replayCameraPaused =>
      'A câmera estava pausada nesta parte da sessão';

  @override
  String get replayCameraUnavailable =>
      'Clipe da câmera indisponível · O jogo continua';

  @override
  String get replayCameraLoading => 'Carregando câmera…';

  @override
  String get replayPaused => 'Respirando um pouco';

  @override
  String get replayHideControlsSemantics => 'Esconder controles do replay';

  @override
  String get replayShowControlsSemantics => 'Mostrar controles do replay';

  @override
  String get replayBackToSavedSemantics => 'Voltar às sessões salvas';

  @override
  String get replayTitle => 'REPLAY';

  @override
  String replayTitleSession(String session) {
    return 'REPLAY · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'Pontuação: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts corações',
      one: '$hearts coração',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'J1 $p1 · J2 $p2 corações · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String replayMagnet(int seconds) {
    return 'Ímã · ${seconds}s';
  }

  @override
  String get replayPauseSemantics => 'Pausar replay';

  @override
  String get replayPlaySemantics => 'Reproduzir replay';

  @override
  String get replayRestartSemantics => 'Reiniciar replay';

  @override
  String get replayBack5Semantics => 'Voltar 5 segundos';

  @override
  String get replayForward5Semantics => 'Avançar 5 segundos';

  @override
  String get replayHighlightsFinding =>
      'Procurando os melhores momentos do voo';

  @override
  String get replayHighlightsNone => 'Nenhum melhor momento disponível';

  @override
  String get replayHighlights => 'Melhores momentos do voo';

  @override
  String get replayHighlightsCloseSemantics => 'Fechar melhores momentos';

  @override
  String get replayHighlightsHint =>
      'Escolha um momento. Assista desde um pouco antes.';

  @override
  String get replayViewCorner => 'Câmera no canto';

  @override
  String get replayViewBackground => 'Câmera de fundo';

  @override
  String get replayViewGameplay => 'Só o jogo';

  @override
  String get replayMoveCornerSemantics => 'Mover a câmera de canto';

  @override
  String get replayMuteRecordedSemantics => 'Silenciar áudio gravado';

  @override
  String get replayUnmuteRecordedSemantics => 'Ativar áudio gravado';

  @override
  String get replayMuteGameSemantics => 'Silenciar som do jogo';

  @override
  String get replayUnmuteGameSemantics => 'Ativar som do jogo';

  @override
  String get replayFullScreenSemantics => 'Esconder controles / tela cheia';

  @override
  String get replayMomentTakeoff => 'Decolagem';

  @override
  String get replayMomentTakeoffDetail => 'O céu é seu.';

  @override
  String get replayMomentMagnet => 'Ímã estelar';

  @override
  String get replayMomentMagnetDetail =>
      'Três passagens perfeitas trazem as estrelas para perto.';

  @override
  String get replayMomentStarTrio => 'Primeiro trio de estrelas';

  @override
  String get replayMomentStarTrioDetail =>
      'Três estrelas viram uma constelação. +5 pontos!';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'Todas as estrelas do grupo coletadas. +5 pontos!';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier× poder estelar';
  }

  @override
  String get replayMomentStreakDetail => 'Uma sequência brilhante de estrelas.';

  @override
  String get replayMomentShield => 'Escudo salvou';

  @override
  String get replayMomentShieldDetail => 'Foi por pouco, e veio outra chance.';

  @override
  String get replayMomentPerfect => 'Primeira passagem perfeita';

  @override
  String get replayMomentPerfectDetail => 'Bem no meio da mira.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portais vencidos',
      one: '$count portal vencido',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'Um pouco mais longe no céu.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Nem um arranhão. +$points pontos!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Salvo pelos anéis turbo. +$points pontos!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'Enfrentou a ventania';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Desviou dos destroços voando. +$points pontos!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'Rota concluída';

  @override
  String get replayMomentFinal => 'Momento final';

  @override
  String get replayMomentCompleteDetail => 'Você chegou ao fim da rota.';

  @override
  String get replayMomentCollisionDetail => 'Veja a aproximação final.';

  @override
  String get replayMomentEndDetail => 'O fim deste voo.';

  @override
  String get welcomeTitle => 'Escolha seu idioma';

  @override
  String get welcomeContinue => 'Bora voar!';

  @override
  String get welcomeHint => 'Dá para mudar quando quiser em Configurações.';

  @override
  String get welcomeDevice => 'Idioma do celular';

  @override
  String get tutorialTitle => 'Escola de Voo';

  @override
  String get tutorialSkip => 'Pular lição';

  @override
  String get tutorialSkipTitle => 'Pular a Escola de Voo?';

  @override
  String get tutorialSkipBody =>
      'Você pode refazer a lição quando quiser em Configurações.';

  @override
  String get tutorialSkipConfirm => 'Pular';

  @override
  String get tutorialSkipCancel => 'Continuar a lição';

  @override
  String get tutorialRestart => 'Recomeçar';

  @override
  String get tutorialGoalFlaps => 'Bata as asas';

  @override
  String get tutorialGoalStars => 'Colete estrelas';

  @override
  String get tutorialGoalGates => 'Passe nos portais';

  @override
  String get tutorialGoalBats => 'Derrube morcegos';

  @override
  String get tutorialGoalDoor => 'Quebre a porta';

  @override
  String get tutorialGoalSprint => 'Use o Turbo';

  @override
  String get tutorialGoalBoss => 'Vença o Capitão';

  @override
  String get tutorialPromptTap => 'Toque!';

  @override
  String get tutorialPromptShoot => 'Toque em Atirar';

  @override
  String get tutorialPromptHoldShoot => 'Segure Atirar';

  @override
  String get tutorialPromptSprint => 'Toque em Turbo';

  @override
  String get tutorialPraiseNice => 'Boa!';

  @override
  String get tutorialPraiseGreat => 'Mandou bem!';

  @override
  String get tutorialPraiseSuper => 'Brilhante!';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return 'A lição está esperando: $prompt';
  }

  @override
  String get licenceTitle => 'Licença de carteiro';

  @override
  String get licenceIssuer => 'Correio do Clube';

  @override
  String get licenceHolder => 'Carteiro';

  @override
  String get licenceRank => 'Cargo';

  @override
  String get licenceRankRookie => 'Carteiro aprendiz';

  @override
  String get licenceSkills => 'Habilidades';

  @override
  String get licenceStamp => 'Aprovado';

  @override
  String licenceSignedBy(String name) {
    return 'Assinado: $name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas',
      one: '1 estrela',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => 'Minha primeira rota!';

  @override
  String get licenceAgain => 'Voar de novo';

  @override
  String get settingsTutorial => 'Escola de Voo';

  @override
  String get settingsTutorialDetail => 'Refazer a primeira lição';
}
