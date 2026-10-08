// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get commonTryAgain => '再試一次';

  @override
  String get languageKeyLabel => '語言';

  @override
  String languageKeySemantics(String language) {
    return '語言：$language。變更遊戲的語言。';
  }

  @override
  String get languageSystemDefault => '系統預設';

  @override
  String languageSystemDetail(String language) {
    return '跟隨手機：$language';
  }

  @override
  String get languageCurrent => '目前的語言';

  @override
  String get languageName_en => '英文';

  @override
  String get languageName_es_419 => '西班牙文（拉丁美洲）';

  @override
  String get languageName_pt_br => '葡萄牙文（巴西）';

  @override
  String get languageName_id => '印尼文';

  @override
  String get languageName_fr => '法文';

  @override
  String get languageName_de => '德文';

  @override
  String get languageName_ja => '日文';

  @override
  String get languageName_ko => '韓文';

  @override
  String get languageName_tr => '土耳其文';

  @override
  String get languageName_zh_hant => '繁體中文';

  @override
  String get languageName_ru => '俄文';

  @override
  String get languageName_ar => '阿拉伯文';

  @override
  String get voicePackReady => '語音已就緒';

  @override
  String get voicePackDownload => '下載語音';

  @override
  String voicePackDownloading(int percent) {
    return '語音 $percent%';
  }

  @override
  String get voicePackStarting => '正在取得語音';

  @override
  String get voicePackEnglish => '英文語音';

  @override
  String get voicePackFailed => '語音下載失敗';

  @override
  String get settingsTitle => '把這裡當自己家吧。';

  @override
  String get settingsSectionSound => '聲音';

  @override
  String get settingsSectionComfort => '舒適';

  @override
  String get settingsMusicTitle => '天空俱樂部原聲帶';

  @override
  String get settingsMusicDetail => '選單、冒險與頭目主題曲。';

  @override
  String get settingsEffectsTitle => '音效';

  @override
  String get settingsEffectsDetail => '飛行、戰鬥、道具與選單的音效。';

  @override
  String get settingsVoicesTitle => '角色語音';

  @override
  String get settingsVoicesDetail => '劇情、感謝卡與衝刺呼喊。';

  @override
  String get settingsReducedMotionTitle => '減少動態效果';

  @override
  String get settingsReducedMotionDetail => '選單更安靜，裝飾效果更少。';

  @override
  String get settingsSwitchOn => '開';

  @override
  String get settingsSwitchOff => '關';

  @override
  String get settingsUnavailable => '設定需要一點時間。';

  @override
  String get settingsPrivacyKicker => '永遠只在本機上';

  @override
  String get settingsPrivacyTitle => '你的鏡頭，只屬於你。';

  @override
  String get settingsPrivacyBody => '影片和選用的麥克風聲音都只留在這支手機上。未儲存的片段會被捨棄。絕不上傳。';

  @override
  String get settingsCameraLab => '鏡頭與追蹤實驗室';

  @override
  String get settingsAbout => '關於與授權';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return '關於與授權，版本 $version';
  }

  @override
  String get settingsReset => '重設本機進度';

  @override
  String settingsResetDone(String bird) {
    return '全新開始！$bird已經準備好囉。';
  }

  @override
  String get settingsResetTitle => '要展開全新的冒險嗎？';

  @override
  String get settingsResetBody => '這會刪除這支手機上已存的影片、重播、分數、飛行紀錄、自製關卡與設定，而且無法復原。';

  @override
  String get settingsResetBodyCloud =>
      '這會刪除這支手機上已存的影片、重播、分數、飛行紀錄、自製關卡與設定，以及你的 Google Play 遊戲雲端存檔，而且無法復原。';

  @override
  String get settingsResetConfirm => '全部重設';

  @override
  String get settingsResetKeep => '保留我的進度';

  @override
  String get playGamesName => 'Google Play 遊戲';

  @override
  String get playGamesConnected => '已連線';

  @override
  String get playGamesNotConnected => '未連線';

  @override
  String get playGamesConnecting => '連線中……';

  @override
  String get playGamesConnectFailed => '無法連線';

  @override
  String get playGamesIdle => '雲端存檔與成就';

  @override
  String get playGamesSaving => '正在存到雲端……';

  @override
  String get playGamesOfflineUnsaved => '離線 · 尚未儲存';

  @override
  String playGamesOfflineSaved(String ago) {
    return '離線 · $ago已儲存';
  }

  @override
  String get playGamesUpdateNeeded => '請更新 Beakbound 才能同步存檔';

  @override
  String get playGamesUnreadable => '無法讀取雲端存檔';

  @override
  String get playGamesOn => '雲端存檔已開啟';

  @override
  String get playGamesResetElsewhere => '已在另一支手機上重設';

  @override
  String playGamesRestored(String ago) {
    return '已從雲端還原 · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return '已存到雲端 · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Google Play 遊戲成就';

  @override
  String get playGamesConnectSemantics => '連結 Google Play 遊戲';

  @override
  String get playGamesAchievements => '成就';

  @override
  String get playGamesConnect => '連結';

  @override
  String get timeAgoJustNow => '剛剛';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分鐘前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours 小時前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天前',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '生命 +1！';

  @override
  String calloutStarTrio(int points) {
    return '三星組 +$points！';
  }

  @override
  String get calloutNiceShot => '漂亮一擊！';

  @override
  String calloutNiceShotPoints(int points) {
    return '漂亮一擊 +$points！';
  }

  @override
  String get calloutSmash => '撞碎！';

  @override
  String calloutSmashPoints(int points) {
    return '撞碎 +$points！';
  }

  @override
  String calloutSmashChain(int count) {
    return '撞碎 ×$count！';
  }

  @override
  String get calloutBossDown => '擊敗頭目！';

  @override
  String calloutBossDownPoints(int points) {
    return '擊敗頭目 +$points！';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier× 星星倍率！';
  }

  @override
  String get calloutPerfect => '完美！';

  @override
  String calloutPerfectChain(int count) {
    return '完美 ×$count';
  }

  @override
  String get calloutShieldReady => '護盾就緒';

  @override
  String get calloutShieldSave => '護盾擋下！';

  @override
  String get calloutKeepFlying => '繼續飛！';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 道門！',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '最後 $seconds 秒！',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => '星星磁鐵！';

  @override
  String get calloutSprintRing => '衝刺環！';

  @override
  String calloutRushChain(int count) {
    return '急襲 ×$count！';
  }

  @override
  String calloutMeteorPoints(int points) {
    return '流星 +$points！';
  }

  @override
  String calloutBatPoints(int points) {
    return '蝙蝠 +$points！';
  }

  @override
  String get calloutScorched => '烤焦了！';

  @override
  String get region_jungle => '叢林';

  @override
  String get region_antarctica => '南極洲';

  @override
  String get region_aztec => '阿茲特克';

  @override
  String get region_paris => '巴黎';

  @override
  String get region_egypt => '埃及';

  @override
  String get region_cyberpunk => '電馭叛客城';

  @override
  String get region_china => '中國';

  @override
  String get region_brazil => '巴西';

  @override
  String get region_newYork => '紐約';

  @override
  String get region_arabia => '古阿拉伯';

  @override
  String get region_rome => '古羅馬';

  @override
  String get region_mexico => '墨西哥';

  @override
  String get region_sea => '茫茫大海';

  @override
  String get boss_baronBat_name => '蝙蝠男爵';

  @override
  String get boss_spitterBeetle_name => '噴噴王';

  @override
  String get boss_duskMoth_name => '暮光女皇';

  @override
  String get boss_pirate_name => '海盜船長';

  @override
  String get boss_dragon_name => '餘燼巨龍';

  @override
  String get boss_kingCoo_name => '咕咕王';

  @override
  String get boss_searchlightGargoyle_name => '探照燈石像鬼';

  @override
  String get boss_neferhoo_name => '奈弗胡';

  @override
  String get bird_0_name => '皮普';

  @override
  String get bird_1_name => '碧琪';

  @override
  String get bird_2_name => '敏弟';

  @override
  String get bird_3_name => '歐比';

  @override
  String get playMode_pushUp => '伏地挺身飛行';

  @override
  String get playMode_jump => '跳躍飛行';

  @override
  String get playMode_touch => '點擊飛行';

  @override
  String get playMode_squat => '深蹲飛行';

  @override
  String get chapter_1_route => '樹冠航線';

  @override
  String get chapter_1_postmark => '樹冠航線';

  @override
  String get chapter_1_postcard => '信又能送到樹梢上了！巨嘴鳥們說謝謝你（超大聲）。蝙蝠男爵的王冠，就擺在我們的壁爐上。';

  @override
  String get chapter_1_postscript => '古道那邊，好像有什麼東西在咕嘟咕嘟冒泡。';

  @override
  String get chapter_2_route => '古道';

  @override
  String get chapter_2_postmark => '古道';

  @override
  String get chapter_2_postcard => '商隊又上路了，現在唯一在熬的只有薄荷茶。國王的燒瓶王冠，我們留下來當花瓶了。';

  @override
  String get chapter_2_postscript => '昨晚城裡的路燈全熄了。記得帶盞燈。';

  @override
  String get chapter_3_route => '燈火航線';

  @override
  String get chapter_3_postmark => '燈火航線';

  @override
  String get chapter_3_postcard => '路燈亮了，夜間郵件也醒得很！巴黎送你一個可頌，紐約送你一個椒鹽捲餅。';

  @override
  String get chapter_3_postscript => '港口的鐘不再響了。';

  @override
  String get chapter_4_route => '潮汐航線';

  @override
  String get chapter_4_postmark => '潮汐航線';

  @override
  String get chapter_4_postcard => '港口鐘聲又為信件而響，不再為大砲而響。鸚鵡留下來了，他向你問好。';

  @override
  String get chapter_4_postscript => '聽說地圖邊緣的天空著火了。';

  @override
  String get chapter_5_route => '地圖邊緣';

  @override
  String get chapter_5_postmark => '地圖邊緣';

  @override
  String get chapter_5_postcard => '從南極到北極，天空一片晴朗，每條航線都暢通了。整個天空俱樂部都以你為榮。';

  @override
  String get chapter_5_postscript => '無盡的天空一直都在，隨時等你再來。';

  @override
  String get level_1_1_name => '第一次送信';

  @override
  String get level_1_1_cargo => '給巨嘴鳥雙胞胎的生日卡';

  @override
  String get level_1_1_sender => '巨嘴鳥雙胞胎';

  @override
  String get level_1_1_hint => '點一下就拍翅。飛過星星吧。';

  @override
  String get level_1_2_name => '星星連擊';

  @override
  String get level_1_2_cargo => '給觀星樹懶的星圖';

  @override
  String get level_1_2_sender => '觀星樹懶';

  @override
  String get level_1_2_hint => '連吃星星最高 3 倍；三次完美穿越可得磁鐵。';

  @override
  String get level_1_3_name => '蝙蝠巡邏隊';

  @override
  String get level_1_3_cargo => '給螢火蟲幼兒園的小夜燈';

  @override
  String get level_1_3_sender => '螢火蟲幼兒園';

  @override
  String get level_1_3_hint => '射擊！點射擊把蝙蝠打昏。';

  @override
  String get level_1_4_name => '嘉年華天空';

  @override
  String get level_1_4_cargo => '給嘉年華遊行的羽毛圍巾';

  @override
  String get level_1_4_sender => '森巴金剛鸚鵡';

  @override
  String get level_1_4_hint => '狂風！注意「!」，閃開足球。';

  @override
  String get level_1_5_name => '限時專送';

  @override
  String get level_1_5_cargo => '給鼓隊隊長的緊急邀請函';

  @override
  String get level_1_5_sender => '鼓隊隊長';

  @override
  String get level_1_5_hint => '衝刺能撞碎蝙蝠，一路向前猛衝。';

  @override
  String get level_1_6_name => '神殿階梯';

  @override
  String get level_1_6_cargo => '給神殿廚師的可可豆';

  @override
  String get level_1_6_sender => '神殿廚師們';

  @override
  String get level_1_7_name => '日出棲所';

  @override
  String get level_1_7_cargo => '給黎明看守人的日晷';

  @override
  String get level_1_7_sender => '黎明看守人';

  @override
  String get level_1_8_name => '蝙蝠男爵';

  @override
  String get level_1_8_cargo => '給蝙蝠男爵的最後通知';

  @override
  String get level_1_8_sender => '蝙蝠男爵';

  @override
  String get level_2_1_name => '甲蟲古道';

  @override
  String get level_2_1_cargo => '給戰車賽手的月桂冠';

  @override
  String get level_2_1_sender => '戰車賽手們';

  @override
  String get level_2_1_hint => '甲蟲會噴種子。把種子射下來。';

  @override
  String get level_2_2_name => '石封之門';

  @override
  String get level_2_2_cargo => '給雕像師傅的新鑿子';

  @override
  String get level_2_2_sender => '雕像師傅';

  @override
  String get level_2_2_hint => '按住射擊，丟出大石頭打碎石板。';

  @override
  String get level_2_3_name => '野火狂奔';

  @override
  String get level_2_3_cargo => '給消防隊的水桶';

  @override
  String get level_2_3_sender => '消防隊';

  @override
  String get level_2_3_hint => '飛過金環，甩開野火！';

  @override
  String get level_2_4_name => '尼羅河之字門';

  @override
  String get level_2_4_cargo => '給人面獅身的新謎語書';

  @override
  String get level_2_4_sender => '人面獅身';

  @override
  String get level_2_5_name => '流星天降';

  @override
  String get level_2_5_cargo => '給金字塔天文學家的望遠鏡';

  @override
  String get level_2_5_sender => '金字塔天文學家';

  @override
  String get level_2_5_hint => '金環衝刺能撞碎流星。';

  @override
  String get level_2_6_name => '退回寄件人';

  @override
  String get level_2_6_cargo => '給管理員的雞毛撢子';

  @override
  String get level_2_6_sender => '金字塔管理員';

  @override
  String get level_2_6_hint => '射擊他的信，把信打回去。退回寄件人！';

  @override
  String get level_2_7_name => '燈籠市集';

  @override
  String get level_2_7_cargo => '給燈籠小販的燈油';

  @override
  String get level_2_7_sender => '燈籠小販';

  @override
  String get level_2_8_name => '漫漫商隊';

  @override
  String get level_2_8_cargo => '給漫漫商隊的水壺';

  @override
  String get level_2_8_sender => '商隊隊長';

  @override
  String get level_2_9_name => '噴噴王';

  @override
  String get level_2_9_cargo => '給噴噴王的停熬令';

  @override
  String get level_2_9_sender => '噴噴王';

  @override
  String get level_3_1_name => '飛蛾逐光';

  @override
  String get level_3_1_cargo => '給劇院門簷的燈泡';

  @override
  String get level_3_1_sender => '舞台監督';

  @override
  String get level_3_1_hint => '飛蛾會射出三發扇形彈幕。從縫隙鑽過去。';

  @override
  String get level_3_2_name => '雨中車輪';

  @override
  String get level_3_2_cargo => '給書報攤鴿子的雨傘';

  @override
  String get level_3_2_sender => '書報攤鴿子';

  @override
  String get level_3_2_hint => '巷弄鴿會俯衝搶星星。先射牠們！';

  @override
  String get level_3_3_name => '蒸氣巷';

  @override
  String get level_3_3_cargo => '給夜班司機的熱椒鹽捲餅';

  @override
  String get level_3_3_sender => '夜班計程車司機';

  @override
  String get level_3_3_hint => '蒸氣孔先嘶嘶響，再噴發。燙的跳過，軟的乘著飛。';

  @override
  String get level_3_4_name => '風暴警報';

  @override
  String get level_3_4_cargo => '給最高的塔的風向標';

  @override
  String get level_3_4_sender => '高塔管理員';

  @override
  String get level_3_4_hint => '別被光照到。胸燈打開時射它！這裡不能衝刺。';

  @override
  String get level_3_5_name => '水晶屋頂';

  @override
  String get level_3_5_cargo => '給屋頂畫家的可頌';

  @override
  String get level_3_5_sender => '屋頂畫家';

  @override
  String get level_3_6_name => '狂風過後';

  @override
  String get level_3_6_cargo => '給手風琴師的樂譜';

  @override
  String get level_3_6_sender => '手風琴師';

  @override
  String get level_3_6_hint => '狂風！注意「!」，從空出來的那一側飛過。';

  @override
  String get level_3_7_name => '午夜快遞';

  @override
  String get level_3_7_cargo => '給麵包師傅的午夜情書';

  @override
  String get level_3_7_sender => '麵包師傅';

  @override
  String get level_3_7_hint => '衝刺穿過蝙蝠群。';

  @override
  String get level_3_8_name => '暮光女皇';

  @override
  String get level_3_8_cargo => '給暮光女皇的起床號';

  @override
  String get level_3_8_sender => '暮光女皇';

  @override
  String get level_4_1_name => '港口燈火';

  @override
  String get level_4_1_cargo => '給燈塔看守人的新鏡片';

  @override
  String get level_4_1_sender => '燈塔看守人';

  @override
  String get level_4_2_name => '火山隘口';

  @override
  String get level_4_2_cargo => '給火山烘焙師的隔熱手套';

  @override
  String get level_4_2_sender => '火山烘焙師';

  @override
  String get level_4_2_hint => '跳過岩漿柱。';

  @override
  String get level_4_3_name => '沿岸南下';

  @override
  String get level_4_3_cargo => '給海灘節的風箏線';

  @override
  String get level_4_3_sender => '放風箏的人';

  @override
  String get level_4_4_name => '低潮';

  @override
  String get level_4_4_cargo => '給小島隱士的回信';

  @override
  String get level_4_4_sender => '小島隱士';

  @override
  String get level_4_4_hint => '別碰到水。';

  @override
  String get level_4_5_name => '大潮';

  @override
  String get level_4_5_cargo => '給渡輪船員的潮汐表';

  @override
  String get level_4_5_sender => '渡輪船員';

  @override
  String get level_4_5_hint => '潮鐘一響，就往高處飛。';

  @override
  String get level_4_6_name => '舷砲海灣';

  @override
  String get level_4_6_cargo => '給海鷗群的魚餅乾';

  @override
  String get level_4_6_sender => '海鷗群';

  @override
  String get level_4_7_name => '風暴橫渡';

  @override
  String get level_4_7_cargo => '給風暴守望隊水手的乾襪子';

  @override
  String get level_4_7_sender => '風暴守望隊';

  @override
  String get level_4_8_name => '海盜船長';

  @override
  String get level_4_8_cargo => '給船長的還信令';

  @override
  String get level_4_8_sender => '海盜船長';

  @override
  String get level_5_1_name => '極光郵站';

  @override
  String get level_5_1_cargo => '給企鵝合唱團的毛線帽';

  @override
  String get level_5_1_sender => '企鵝合唱團';

  @override
  String get level_5_1_hint => '現在任何急襲都可能出現。看清楚橫幅！';

  @override
  String get level_5_2_name => '極夜';

  @override
  String get level_5_2_cargo => '給極地研究站的熱可可';

  @override
  String get level_5_2_sender => '極地研究站';

  @override
  String get level_5_3_name => '霓虹快遞';

  @override
  String get level_5_3_cargo => '給麵館招牌的備用保險絲';

  @override
  String get level_5_3_sender => '麵館大廚';

  @override
  String get level_5_4_name => '資料風暴';

  @override
  String get level_5_4_cargo => '給好奇機器人的紙本信';

  @override
  String get level_5_4_sender => '七號機';

  @override
  String get level_5_5_name => '天際線衝刺';

  @override
  String get level_5_5_cargo => '給屋頂飛毛腿的比賽門票';

  @override
  String get level_5_5_sender => '屋頂飛毛腿';

  @override
  String get level_5_6_name => '元宵燈會';

  @override
  String get level_5_6_cargo => '給燈會的紙燈籠';

  @override
  String get level_5_6_sender => '燈籠師傅';

  @override
  String get level_5_7_name => '最後一哩路';

  @override
  String get level_5_7_cargo => '給山寺的高山茶';

  @override
  String get level_5_7_sender => '山寺僧人';

  @override
  String get level_5_8_name => '餘燼巨龍';

  @override
  String get level_5_8_cargo => '第一封寄給巨龍的信';

  @override
  String get level_5_8_sender => '餘燼巨龍';

  @override
  String get storyPostmasterName => '比爾局長';

  @override
  String get storySkip => '跳過';

  @override
  String get storyNextLineSemantics => '下一句';

  @override
  String get storyFinishSemantics => '結束';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name：$line';
  }

  @override
  String get campaignMotto => '封封必達。';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand。$motto';
  }

  @override
  String get levelIntroFly => '起飛！';

  @override
  String levelIntroRunUp(int seconds) {
    return '先開場飛行 $seconds 秒';
  }

  @override
  String levelIntroLength(int seconds) {
    return '約 $seconds 秒抵達終點';
  }

  @override
  String get campaignGuardian => '守護者';

  @override
  String get levelIntroBossFight => '頭目戰';

  @override
  String get levelIntroNew => '新';

  @override
  String get levelIntroTip => '小撇步';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    return '擊敗$boss';
  }

  @override
  String get levelIntroGoalFinish => '抵達終點';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '收集 $count 顆星星',
      one: '收集 1 顆星星',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': '一顆星：$goal。',
      'two': '兩顆星：$goal。',
      'other': '三顆星：$goal。',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': '一顆星：$goal。已達成。',
      'two': '兩顆星：$goal。已達成。',
      'other': '三顆星：$goal。已達成。',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最佳：$count 顆星',
      one: '最佳：1 顆星',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => '尚未送達';

  @override
  String get levelIntroFirstFlight => '首次飛行';

  @override
  String get levelIntroControlFlap => '拍翅';

  @override
  String get levelIntroControlShoot => '射擊';

  @override
  String get levelIntroControlSprint => '衝刺';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': '操作：拍翅。',
      'shoot': '操作：拍翅、射擊。',
      'sprint': '操作：拍翅、衝刺。',
      'other': '操作：拍翅、射擊、衝刺。',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => '特別專送';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return '特別專送：$cargo。';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return '第 $level 關，$name。$region。';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return '第 $level 關，$name。$region。守護者關卡：$boss。';
  }

  @override
  String get levelIntroStory => '劇情';

  @override
  String get commonClose => '關閉';

  @override
  String get commonContinue => '繼續';

  @override
  String get commonHome => '主畫面';

  @override
  String get commonBackHome => '回主畫面';

  @override
  String get campaignComingSoon => '即將推出';

  @override
  String campaignStopComingSoon(String region) {
    return '$region：即將推出';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    return '擊敗$boss即可解鎖';
  }

  @override
  String campaignLockedFinish(String level) {
    return '完成 $level 即可解鎖';
  }

  @override
  String get campaignMapUnavailable => '地圖需要一點時間。';

  @override
  String campaignCloseLevelSemantics(String name) {
    return '關閉$name';
  }

  @override
  String get campaignMapPreviousStop => '上一站';

  @override
  String get campaignMapNextStop => '下一站';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region。第 $chapter 章，$route。即將推出。',
      'locked': '$region。第 $chapter 章，$route。尚未解鎖。',
      'other': '$region。第 $chapter 章，$route。',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return '第 $chapter 章 · $route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level，$name，頭目',
      'guardian': '第 $level 關，$name，守護者$boss',
      'other': '第 $level 關，$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node。尚未解鎖。';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node。尚未解鎖。$note。';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '已得 $stars 顆星，共 3 顆',
    );
    return '$node。下一關。$_temp0。';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '已得 $stars 顆星，共 3 顆',
    );
    return '$node。$_temp0。';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': '石像鬼',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return '第 $chapter 章明信片';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '故事模式星星：已得 $stars 顆，共 $total 顆',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => '親愛的郵差：';

  @override
  String get campaignPostcardPs => '附註：';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return '來自$route的明信片。親愛的郵差：$body 附註：$postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => '寄自';

  @override
  String get campaignPostcardHeader => '天空俱樂部明信片';

  @override
  String campaignPostcardSignature(String route) {
    return '——$route';
  }

  @override
  String get campaignPostcardAddressName => '郵差 收';

  @override
  String get campaignPostcardAddressStreet => '天空俱樂部郵局';

  @override
  String get campaignPostcardAddressCity => '高高的天上';

  @override
  String get campaignPostmarkDelivered => '已送達';

  @override
  String get campaignPostmarkClub => '天空俱樂部郵局';

  @override
  String get campaignStampSkyClub => '天空俱樂部';

  @override
  String campaignThanksQuoted(String thanks) {
    return '「$thanks」';
  }

  @override
  String campaignThanksSignature(String sender) {
    return '——$sender';
  }

  @override
  String campaignThanksSemantics(String sender, String thanks) {
    return '$sender的感謝卡：$thanks';
  }

  @override
  String get flightSetupTitlePushUp => '小小準備，大大天空。';

  @override
  String get flightSetupTitleSquat => '雙腳站穩，翅膀張開。';

  @override
  String get flightSetupTitleJump => '輕輕一跳，展翅高飛。';

  @override
  String flightSetupBuiltTag(String name) {
    return '關卡 · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · 計分';
  }

  @override
  String get flightSetupRoomPushUp => '騰出一點活動空間。';

  @override
  String get flightSetupRoomBody => '讓鏡頭拍到你的全身。';

  @override
  String get flightSetupTipsPushUp => '手機放低，拍到一隻手臂和臀部。\n面向手機？讓雙肩都入鏡。';

  @override
  String get flightSetupTipsSquat => '蹲下就下降，站起就上升。\n雙腳都要踩在地上。';

  @override
  String get flightSetupTipsJump => '跳一下就加速，再滑翔 3 秒。\n落地後才能再跳。';

  @override
  String get flightSetupHowToFly => '飛行方式';

  @override
  String get flightSetupStep1PushUp => '拍到你的手臂和臀部';

  @override
  String get flightSetupStep1Squat => '騰出深蹲的空間';

  @override
  String get flightSetupStep1Jump => '騰出跳躍的空間';

  @override
  String get flightSetupStep1DetailPushUp => '面向手機嗎？讓雙肩、一隻手臂和臀部入鏡。';

  @override
  String get flightSetupStep1DetailBody => '手機橫放。讓身體和雙腳都入鏡。';

  @override
  String get flightSetupStep2PushUp => '找出你的動作範圍';

  @override
  String get flightSetupStep2Squat => '找出舒服的深蹲幅度';

  @override
  String get flightSetupStep2Jump => '站直不動';

  @override
  String get flightSetupStep2DetailPushUp => '找到舒服的高點，再下去、上來兩次。';

  @override
  String get flightSetupStep2DetailSquat => '站好不動，蹲下停一下，再站起來。';

  @override
  String get flightSetupStep2DetailJump => '先靜止一下，然後跳起來大加速。';

  @override
  String get flightSetupStep3Stars => '收集星星';

  @override
  String get flightSetupStep3DetailJump =>
      '每顆星星加 0.75 秒滑翔，最多 5 秒。收集三星組可得 +5 分。';

  @override
  String get flightSetupLivesEndless => '三顆愛心加一個護盾。隨時都能暫停。';

  @override
  String get flightSetupLivesClassic => '計分飛行中，撞到東西或離開定位就會結束。隨時都能暫停。';

  @override
  String get flightSetupCameraButton => '設定我的鏡頭';

  @override
  String get flightMicTitle => '錄製麥克風';

  @override
  String get flightMicOn => '開啟';

  @override
  String get flightMicOptional => '選用';

  @override
  String get flightMicDetail => '把你的聲音和環境音加進重播。只在飛行時使用麥克風。儲存在這支手機上。';

  @override
  String get flightMicSemantics => '為重播錄製麥克風聲音';

  @override
  String get flightMicSettings => '麥克風設定';

  @override
  String get flightCalibrationTitleReady => '你找到翅膀了！';

  @override
  String get flightCalibrationTitleWaking => '正在喚醒鏡頭……';

  @override
  String get flightCalibrationTitleError => '我們重新連接鏡頭吧。';

  @override
  String get flightCalibrationTitleRange => '找出你的動作範圍。';

  @override
  String get flightCalibrationTitleStill => '站直，別動。';

  @override
  String get flightCalibrationStepTry => '試著操控你的鳥兒。';

  @override
  String get flightCalibrationStepTop => '找到舒服的高點。';

  @override
  String get flightCalibrationStepLower => '慢慢往下。';

  @override
  String get flightCalibrationStepPushBack => '撐回上方。';

  @override
  String get flightCalibrationStepStill => '站直，別動。';

  @override
  String get flightCalibrationStepSquat => '舒服地蹲下。';

  @override
  String get flightCalibrationStepStandUp => '再站起來。';

  @override
  String get flightCalibrationStepDone => '你找到翅膀了！';

  @override
  String get flightCalibrationReadyPushUp => '撐起來就上升，放低就滑翔。';

  @override
  String get flightCalibrationReadySquat => '蹲下就下降，站起就上升。';

  @override
  String get flightCalibrationReadyJump => '跳一下，然後趁鳥兒滑翔時休息。';

  @override
  String get flightCalibrationKeepPushUp => '讓雙肩、一隻手臂和臀部保持入鏡。動作放輕鬆。';

  @override
  String get flightCalibrationKeepBody => '讓雙肩、臀部和雙腳保持入鏡。';

  @override
  String get flightCalibrationLearning => '邊動邊學習你的動作範圍。';

  @override
  String get flightCalibrationAfter => '校準完成後，鳥兒就會動。';

  @override
  String get flightCalibrationJump => '跳！';

  @override
  String get flightCalibrationTagCheck => '操作測試';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '伏地挺身 $count / 2';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '已校準 $percent%';
  }

  @override
  String get flightCalibrationTakeoff => '準備起飛';

  @override
  String get flightCalibrationStarting => '啟動中……';

  @override
  String get flightCalibrationRestart => '重新校準';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate 次更新/秒 · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate 次更新/秒 · $p95 ms p95（僅計處理）';
  }

  @override
  String get flightCalibrationStatusReady => '就緒';

  @override
  String get flightCalibrationStatusStarting => '啟動中';

  @override
  String get flightCalibrationStatusCameraOff => '鏡頭關閉';

  @override
  String get flightCalibrationStatusCalibrating => '校準中';

  @override
  String get flightSwitchCameraSemantics => '切換鏡頭';

  @override
  String get flightCalibrationStepIntoView => '走進畫面裡';

  @override
  String get flightCameraTroubleTitle => '重新開始通常有用。';

  @override
  String get flightCameraTroubleAllow => '請在設定中開啟相機權限。';

  @override
  String get flightCameraTroubleClose => '關閉其他使用相機的應用程式，再試一次。';

  @override
  String get flightCameraPermissionSemantics => '相機權限設定';

  @override
  String get flightNoteRememberFailed => '已套用於這趟飛行，但無法記住你的偏好。';

  @override
  String get flightNoteMicUnavailable => '無法使用麥克風。影片和遊戲仍可正常運作。';

  @override
  String get flightNoteMicBlocked => '麥克風已被封鎖。你可以在設定中允許；影片仍可正常運作。';

  @override
  String get flightNoteMicOff => '麥克風已關閉。你仍然可以遊玩和儲存影片。';

  @override
  String get flightNoteVideoUnavailable => '無法錄製鏡頭影片。遊戲過程仍可儲存。';

  @override
  String get flightNoteMicAudioLost => '沒有錄到麥克風聲音。你的影片和遊戲過程仍可儲存。';

  @override
  String get flightNoteVideoInterrupted => '鏡頭影片中斷了。已錄下的畫面和遊戲過程仍可儲存。';

  @override
  String get flightNoteSessionSaveFailed => '無法儲存這趟飛行。點「儲存飛行」再試一次。';

  @override
  String get flightNoteWakingCamera => '正在喚醒鏡頭……';

  @override
  String get flightNoteCameraOff => '相機權限已關閉。請到 Android 設定中允許，再回來試一次。';

  @override
  String get flightNoteCameraFailed => '鏡頭無法啟動。請再試一次或切換鏡頭。';

  @override
  String get flightNotePreparing => '正在準備你的飛行……';

  @override
  String get flightNoteSaveFailed => '無法儲存你的飛行。點一下重試。';

  @override
  String get flightNoteWelcomeBack => '歡迎回來。我們再確認一次你的位置。';

  @override
  String get flightNoteCameraInterrupted => '鏡頭中斷了。請檢查相機權限後再試一次。';

  @override
  String get flightNoteTrackingInterrupted => '追蹤中斷';

  @override
  String get flightFindPosition => '找好你的位置';

  @override
  String get flightTapSemantics => '點一下拍翅';

  @override
  String flightTapVanguardSemantics(String group) {
    return '點一下拍翅。$group搶在頭目之前飛來了';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return '點一下拍翅。$boss：生命值 $hp／$maxHp';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return '點一下拍翅。$boss：生命值 $hp／$maxHp。$hint';
  }

  @override
  String get flightSkipToResultsSemantics => '跳到結果';

  @override
  String get hudPauseSemantics => '暫停飛行';

  @override
  String get flightHintTestSteerKeys => '試飛：用上、下鍵操控。';

  @override
  String get flightHintTestSteerDrag => '試飛：上下拖曳來操控。';

  @override
  String get flightHintTestJumpKeys => '試飛：按 Space 鍵跳躍。';

  @override
  String get flightHintTestJumpTap => '試飛：點一下跳躍。';

  @override
  String get flightHintKeysStars => '按 Space 鍵拍翅。飛過星星吧。';

  @override
  String get flightHintKeysShoot => '按 Space 鍵拍翅。按住 D 鍵蓄力射擊。';

  @override
  String get flightHintKeysCombat => '按 Space 鍵拍翅。按住 D 鍵蓄力射擊。按 A 鍵衝刺！';

  @override
  String get flightHintKeysPause => '按 Space 鍵拍翅。按 Esc 鍵暫停。';

  @override
  String get flightHintTapStars => '點天空拍翅。飛過星星吧。';

  @override
  String get flightHintTapShoot => '點天空拍翅。按住射擊來蓄力。';

  @override
  String get flightHintTapCombat => '點天空拍翅。按住射擊來蓄力。衝刺撞碎一切！';

  @override
  String get flightHintTapRelease => '點一下拍翅。每次點完都要放開。';

  @override
  String get flightHintTrail => '跟著星星飛。你的護盾已就緒。';

  @override
  String get flightHintSky => '天空是你的。';

  @override
  String hudClockSemantics(String time) {
    return '剩下 $time';
  }

  @override
  String flightSeconds(String seconds) {
    return '$seconds秒';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '星星磁鐵：剩下 $seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: '磁鐵充能中：完美穿越 $charge／$gates 次',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => '正在找你……';

  @override
  String get hudShoot => '射擊';

  @override
  String get hudSprint => '衝刺';

  @override
  String get flightTestNothingSaved => '不會存檔';

  @override
  String get flightCountdownReady => '預備……';

  @override
  String get flightPauseTitle => '喘口氣吧。';

  @override
  String get flightPauseKeepFlying => '繼續飛';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name。你的鳥兒正停在枝頭等你。';
  }

  @override
  String flightPausedTest(String name) {
    return '$name試飛中。不會存檔。';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name。你的鳥兒正停在枝頭等你。';
  }

  @override
  String get flightPausedTouch => '你的鳥兒正停在枝頭等你。回來時我們會先倒數。';

  @override
  String get flightPausedCamera => '甩甩手腳，再回到定位。我們會倒數讓你開始。';

  @override
  String get flightPauseEdit => '編輯';

  @override
  String get flightPauseBuilder => '關卡編輯器';

  @override
  String get flightPauseFinish => '結束飛行';

  @override
  String get hudShieldRecovering => '恢復中';

  @override
  String get hudShieldReady => '護盾就緒';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '護盾充能中：星星 $charge／$stars 顆',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '剩下 $count 顆愛心',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => '衝刺中';

  @override
  String get hudSprintReady => '就緒';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '充能中，還要 $seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint => '向前猛衝，撞碎蝙蝠和石板';

  @override
  String get hudShotReloading => '裝填中……';

  @override
  String hudShotFullCharge(int ms) {
    return '蓄力已滿，$ms 毫秒後自動發射';
  }

  @override
  String hudShotCharging(int percent) {
    return '蓄力 $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return '彈藥 $percent%';
  }

  @override
  String get hudShotHint => '按住可蓄力，丟出更大的石頭';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已達 $count 星',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '收集 $at 顆可得 $count 星',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '已收集 $stars 顆星星',
    );
    return '$_temp0。$two。$three。';
  }

  @override
  String get hudMax => '滿星';

  @override
  String hudRouteSemantics(int percent) {
    return '航程已飛 $percent%';
  }

  @override
  String hudGlideCompact(String time) {
    return '滑翔 · $time';
  }

  @override
  String get hudJumpToGlide => '跳躍來滑翔';

  @override
  String get hudJump => '跳躍';

  @override
  String hudGlideSemantics(String time) {
    return '滑翔中，剩下 $time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return '滑翔快結束了，剩下 $time';
  }

  @override
  String get hudJumpChargeSemantics => '跳一下，充能 3 秒滑翔';

  @override
  String get hudRecordNewBest => '新紀錄！';

  @override
  String get hudRecordMatched => '平紀錄！';

  @override
  String hudRecordBest(int best) {
    return '最佳 $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '超越最佳 +$points';
  }

  @override
  String get hudRecordOneMore => '再 1 分破紀錄';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再 $count 分破紀錄',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title。$detail。';
  }

  @override
  String hudScoreSemantics(int score) {
    return '分數 $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return '分數 $score，倍率 $multiplier 倍';
  }

  @override
  String get commonBusySemantics => '處理中';

  @override
  String get flightResultBumpClouds => '在雲裡小小撞了一下。';

  @override
  String get flightResultPersonalBest => '個人最佳';

  @override
  String get flightResultNewPersonalBest => '個人新紀錄！';

  @override
  String get flightResultStarsCollected => '收集的星星';

  @override
  String get flightResultDailyStamped => '今日明信片已蓋章！';

  @override
  String flightResultNextStamp(String stamp) {
    return '下一個：$stamp';
  }

  @override
  String get flightResultSavedOnPhone => '已存在這支手機上';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '已存在這支手機上 · 累計 $total 道門',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => '正在儲存你的飛行……';

  @override
  String get flightResultSessionSaved => '飛行已儲存 · 可在「紀錄」觀看';

  @override
  String get flightResultWatchReplay => '觀看重播';

  @override
  String get flightResultPreparing => '準備中……';

  @override
  String get flightResultSavingShort => '儲存中……';

  @override
  String get flightResultSaveSession => '儲存飛行';

  @override
  String get flightResultFlyAgain => '再飛一次';

  @override
  String get commonRetry => '再試一次';

  @override
  String get commonMap => '地圖';

  @override
  String get commonNext => '下一關';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '伏地挺身',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '深蹲',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '跳躍',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '拍翅',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => '飛行時間';

  @override
  String get flightStatPerfect => '完美';

  @override
  String get flightStatBestStreak => '最佳連擊';

  @override
  String get flightStatRank => '等級';

  @override
  String get flightRankSkyCaptain => '天空機長';

  @override
  String get flightRankCloudExplorer => '雲端探險家';

  @override
  String get flightRankFirstWings => '初試身手';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => '雖然撞到了，但創下新紀錄！';

  @override
  String get gameOverCaptionSea => '在海裡小小噗通了一下。';

  @override
  String get gameOverSplash => '噗通！';

  @override
  String get gameOverBonk => '咚！';

  @override
  String get gameOverEveryMarkSemantics => '所有星級刻度都已達成';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再 $count 顆星星就能拿 $mark 星',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss：剩下生命值 $hp／$maxHp';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '已飛完航程的 $percent%';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss：剩餘 $hp HP';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$boss剩餘生命';
  }

  @override
  String get gameOverRouteFlown => '已飛航程';

  @override
  String gameOverHp(int hp) {
    return '$hp HP';
  }

  @override
  String gameOverMoreFor(int count) {
    return '再 $count 顆可得';
  }

  @override
  String get gameOverBothMarks => '星級刻度全達成';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    return '星級刻度全達成。擊敗$boss！';
  }

  @override
  String get miniResultTitle => '每趟飛行都算數。';

  @override
  String get miniResultComplete => '飛行完成';

  @override
  String get miniResultCheerBest => '你太厲害了！';

  @override
  String get miniResultCheerComplete => '飛行完成！';

  @override
  String get miniResultCheerNice => '飛得真好。';

  @override
  String get miniResultNew => '新';

  @override
  String get flightEndTrackingLost => '我們有一下子看不到你。';

  @override
  String get flightEndPostureLost => '你的位置超出了範圍。';

  @override
  String get flightEndBackgrounded => '你暫時離開了天空。';

  @override
  String get flightEndBreak => '好好休息一下，這是你應得的。';

  @override
  String get flightEndQuit => '下次冒險見。';

  @override
  String get flightEndStalled => '遊戲中斷了。';

  @override
  String get flightEndCompleted => '滿天的星星，全都是你的。';

  @override
  String get levelResultTryAgain => '再試一次！';

  @override
  String get levelResultVictory => '勝利！';

  @override
  String get levelResultGuardianDown => '守護者倒下！';

  @override
  String get levelResultDelivered => '送達！';

  @override
  String levelResultComingSoon(String region) {
    return '$region即將推出！';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned／3 顆星';
  }

  @override
  String levelResultBest(int best) {
    return '最佳 $best';
  }

  @override
  String get levelResultNoBest => '尚無最佳紀錄';

  @override
  String get levelResultFirstClear => '首次過關！';

  @override
  String get levelResultNewBest => '新紀錄！';

  @override
  String get levelResultScore => '分數';

  @override
  String get levelResultGoalBoss => '頭目';

  @override
  String get levelResultGoalGuardian => '守護者';

  @override
  String get levelResultGoalFinish => '終點';

  @override
  String get levelResultGoalDone => '完成';

  @override
  String get levelResultGoalNotYet => '還沒';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還差 $count 顆',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => '先抵達終點';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal。';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal。已完成。';
  }

  @override
  String get levelResultPostcardWaiting => '地圖上有明信片在等你！';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '$id $name已開放！';
  }

  @override
  String get levelResultReachFinish => '抵達終點才能拿到星星。';

  @override
  String get course_classic_title => '經典';

  @override
  String get course_starTrail_title => '無盡模式';

  @override
  String get course_classic_instructions => '找到縫隙。跟著準心飛，就能完美穿越。';

  @override
  String get course_starTrail_instructions =>
      '一組 3 顆星星全部收集可得 +5。連吃星星，倍率最高 3×。星星能恢復護盾；完美穿越能換來星星磁鐵。用星星把兩者都升級吧！';

  @override
  String get course_classic_scoreLabel => '障礙數';

  @override
  String get course_starTrail_scoreLabel => '星星分數';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '道門',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星星分',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics => '經典：飛過縫隙。';

  @override
  String get course_starTrail_previewSemantics => '無盡模式：帶著三顆愛心和一個護盾收集星星。';

  @override
  String get obstacle_garden_name => '花園門';

  @override
  String get obstacle_windLift_name => '升風門';

  @override
  String get obstacle_petalGate_name => '花瓣門';

  @override
  String get obstacle_switchback_name => '之字門';

  @override
  String get obstacle_lanternDrift_name => '飄燈門';

  @override
  String get obstacle_sunWheels_name => '太陽輪';

  @override
  String get obstacle_crystalSteps_name => '水晶階梯';

  @override
  String get rush_wildfire_name => '野火';

  @override
  String get rush_wildfire_escape => '甩開野火了';

  @override
  String get rush_skyfall_name => '流星天降';

  @override
  String get rush_skyfall_escape => '撐過流星天降';

  @override
  String get rush_eruption_name => '火山噴發';

  @override
  String get rush_eruption_escape => '躲過火山噴發';

  @override
  String get rush_swarm_name => '蝙蝠群';

  @override
  String get rush_swarm_escape => '衝破蝙蝠群';

  @override
  String get boss_baronBat_title => '風暴之主';

  @override
  String get boss_spitterBeetle_title => '蟲群釀造師';

  @override
  String get boss_duskMoth_title => '暮光薄紗守護者';

  @override
  String get boss_pirate_title => '滿潮霸王';

  @override
  String get boss_dragon_title => '焚天之王';

  @override
  String get boss_kingCoo_title => '街角大警長';

  @override
  String get boss_searchlightGargoyle_title => '最高塔守望者';

  @override
  String get boss_neferhoo_title => '遺失之信守護者';

  @override
  String get boss_baronBat_returnTitle => '風暴再臨';

  @override
  String get boss_baronBat_barName => '蝙蝠男爵';

  @override
  String get boss_spitterBeetle_barName => '噴噴王';

  @override
  String get boss_duskMoth_barName => '暮光女皇';

  @override
  String get boss_pirate_barName => '海盜船長';

  @override
  String get boss_dragon_barName => '餘燼巨龍';

  @override
  String get boss_kingCoo_barName => '咕咕王';

  @override
  String get boss_searchlightGargoyle_barName => '石像鬼';

  @override
  String get boss_neferhoo_barName => '奈弗胡';

  @override
  String get vanguard_baronBat_title => '蝙蝠男爵的蝙蝠';

  @override
  String get vanguard_baronBat_call => '牠們來了！男爵就在後面。';

  @override
  String get vanguard_spitterBeetle_title => '噴噴王的蟲寶寶';

  @override
  String get vanguard_spitterBeetle_call => '牠們來了！噴噴王就在後面。';

  @override
  String get vanguard_duskMoth_title => '暮光女皇的飛蛾';

  @override
  String get vanguard_duskMoth_call => '牠們來了！女皇就在後面。';

  @override
  String get vanguard_kingCoo_title => '咕咕王的鴿子中隊';

  @override
  String get vanguard_kingCoo_call => '牠們來了！咕咕王就在後面。';

  @override
  String get vanguard_kingCoo_callCrusts => '牠們來了！快躲硬麵包皮！';

  @override
  String get vanguard_kingCoo_callReturns => '快躲硬麵包皮！漏掉一隻，牠還會回來！';

  @override
  String get bossVanguardClear => '全清！';

  @override
  String get bossVanguardLeft => '隻還在';

  @override
  String get bossStragglersCaught => '全部抓到！';

  @override
  String get bossHint_strongerBaronBat => '強化 · 三連發，蝙蝠也來幫忙！';

  @override
  String get bossHint_strongerSpitterBeetle => '強化 · 完整扇形彈幕，甲蟲也來幫忙！';

  @override
  String get bossHint_strongerDuskMoth => '強化 · 七發扇形彈幕，飛蛾也來幫忙！';

  @override
  String get bossHint_strongerPirate => '強化 · 潮水開始翻騰了！';

  @override
  String get bossHint_strongerDragon => '強化 · 小心龍息和蝙蝠群！';

  @override
  String get bossHint_strongerKingCoo => '強化 · 他吹哨叫來鴿子中隊！';

  @override
  String get bossHint_strongerGargoyleFierce => '強化 · 胸燈一開，石羽毛就落下！';

  @override
  String get bossHint_strongerGargoyle => '強化 · 石羽毛落下了！';

  @override
  String get bossHint_strongerNeferhooTougher => '強化 · 安卡，還有木乃伊蝙蝠！';

  @override
  String get bossHint_strongerNeferhoo => '強化 · 黃金安卡會飛回來！';

  @override
  String get bossHint_tideRising => '漲潮了 · 往高處飛！';

  @override
  String get bossHint_highTide => '滿潮 · 待在水面上方';

  @override
  String get bossHint_tideFury => '狂怒 · 浪潮之間有舷砲齊射';

  @override
  String get bossHint_tideCalm => '躲開砲彈 · 別碰到水';

  @override
  String get bossHint_dragonSwarm => '蝙蝠群 · 躲開蝙蝠，或衝刺穿過去';

  @override
  String get bossHint_dragonFuryDebut => '狂怒 · 火球變快了';

  @override
  String get bossHint_dragonFury => '狂怒 · 火球會炸成餘燼';

  @override
  String get bossHint_dragonCalm => '躲開火球 · 小心龍息';

  @override
  String get bossHint_screechFury => '狂怒 · 火球更快，蝙蝠更多';

  @override
  String get bossHint_screechCalm => '躲開火球和蝙蝠 · 小心音波尖叫';

  @override
  String get bossHint_cooPopped => '啵！ · 鴿子中隊不來了';

  @override
  String get bossHint_cooSquadron => '鴿子中隊 · 跟著安全航道飛！';

  @override
  String get bossHint_cooPuffed => '鼓胸 · 射他的胸口（x2）！';

  @override
  String get bossHint_cooCrumbBomb => '麵包屑炸彈 · 離開圓圈！';

  @override
  String get bossHint_cooFury => '狂怒 · 待在圓圈之間';

  @override
  String get bossHint_cooCalm => '躲開麵包屑炸彈 · 他鼓胸時射他的胸口';

  @override
  String get bossHint_beamOn => '光束 · 待在暗處';

  @override
  String get bossHint_beamFury => '狂怒 · 從光束之間鑽過去';

  @override
  String get bossHint_beamIncomingHigh => '光束來了 · 往低處飛！';

  @override
  String get bossHint_beamIncomingLow => '光束來了 · 往高處飛！';

  @override
  String get bossHint_lampOpen => '胸燈打開 · 射胸燈！';

  @override
  String get bossHint_shuttersClosed => '遮板關上 · 省下你的石頭';

  @override
  String get bossHint_mothFuryNoVeil => '狂怒 · 七發扇形彈幕。還沒有薄紗！';

  @override
  String get bossHint_mothNoVeil => '還沒有薄紗 · 從扇形彈幕之間射擊！';

  @override
  String get bossHint_mothShielded => '薄紗護體 · 閃躲到薄紗落下';

  @override
  String get bossHint_mothShieldForming => '薄紗成形中 · 準備閃躲';

  @override
  String get bossHint_mothFury => '狂怒 · 七發扇形彈幕。薄紗落下了！';

  @override
  String get bossHint_mothCalm => '薄紗落下了 · 從扇形彈幕之間射擊！';

  @override
  String get bossHint_neferhooMailCall => '來信囉 · 把信射回去！';

  @override
  String get bossHint_neferhooReturn => '退回寄件人！ · −25';

  @override
  String get bossHint_neferhooReturnFaster => '退回寄件人！ · −18';

  @override
  String get bossHint_neferhooAnkh => '安卡 · 它會飛回來！';

  @override
  String get bossHint_neferhooExpress => '限時專送 · 五封信，更快';

  @override
  String get bossHint_neferhooTwoAnkhs => '兩個安卡 · 避開兩條航道';

  @override
  String get bossHint_neferhooBats => '木乃伊蝙蝠 · 把牠們射下來！';

  @override
  String get bossHint_neferhooScuff => '石頭只能刮傷他的裹布。把他的「信」射回去！';

  @override
  String get bossHint_neferhooWarmUp => '把他的信射回去 · 退回寄件人';

  @override
  String get bossHint_neferhooCalm => '把他的信射回去 · 躲開黃金安卡';

  @override
  String get bossHint_neferhooFury => '狂怒 · 限時專送加兩個安卡';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': '龍息 · 往低處飛！牠的心臟露出來了',
      'middle': '龍息 · 往上或往下閃！牠的心臟露出來了',
      'other': '龍息 · 往高處飛！牠的心臟露出來了',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': '噴火 · 往低處飛！攻擊發光的心臟',
      'middle': '噴火 · 往上或往下閃！攻擊發光的心臟',
      'other': '噴火 · 往高處飛！攻擊發光的心臟',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': '音波尖叫 · 飛到上方的缺口！',
      'middle': '音波尖叫 · 飛到中間的缺口！',
      'other': '音波尖叫 · 飛到下方的缺口！',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': '尖叫 · 守住上方的缺口',
      'middle': '尖叫 · 守住中間的缺口',
      'other': '尖叫 · 守住下方的缺口',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth => '閃開扇形彈幕  ·  薄紗落下就開火';

  @override
  String get encounterCaption_pirate => '閃開砲彈  ·  別碰到水';

  @override
  String get encounterCaption_dragon => '閃開火球  ·  逃離龍息';

  @override
  String get encounterCaption_kingCoo => '離開圓圈  ·  他鼓胸時射他的胸口';

  @override
  String get encounterCaption_searchlightGargoyle => '別被光照到  ·  胸燈打開時射它';

  @override
  String get encounterCaption_neferhoo => '準備好  ·  把他的信射回去';

  @override
  String get encounterCaption_screech => '他一尖叫  ·  就飛到缺口';

  @override
  String get encounterCaption_default => '準備好  ·  拍翅、閃躲、開火';

  @override
  String get encounterCoasting => '你的鳥兒正安全地滑行';

  @override
  String get encounterOpenSky => '回到開闊的天空';

  @override
  String get encounterOmenTitle_duskMoth => '暮光展翅';

  @override
  String get encounterOmenLine_duskMoth => '暮色中，一層絲綢薄紗正在聚攏……';

  @override
  String get encounterOmenTitle_spitterBeetle => '有事正在醞釀';

  @override
  String get encounterOmenLine_spitterBeetle => '空氣開始冒泡泡了……';

  @override
  String get encounterOmenTitle_dragon => '天空著火了';

  @override
  String get encounterOmenLine_dragon => '巨大的翅膀在雲層上方拍動……';

  @override
  String get encounterOmenTitle_kingCoo => '街角封鎖';

  @override
  String get encounterOmenLine_kingCoo => '有人為了麵包推車氣炸了……';

  @override
  String get encounterOmenTitle_searchlightGargoyle => '風暴警報';

  @override
  String get encounterOmenLine_searchlightGargoyle => '高樓簷邊上，有東西正盯著看……';

  @override
  String get encounterOmenTitle_neferhoo => '金字塔騷動';

  @override
  String get encounterOmenLine_neferhoo => '金字塔的塵土開始翻動……';

  @override
  String get encounterOmenTitle_baronReturns => '男爵回來了';

  @override
  String get encounterOmenLine_baronReturns => '他回來了，而且更吵了……';

  @override
  String get encounterOmenTitle_default => '黑影逼近';

  @override
  String get encounterOmenLine_default => '天空落入了別人手中……';

  @override
  String get encounterOmenTitle_pirate => '發現船帆！';

  @override
  String get encounterOmenLine_pirate => '一艘船乘著漲潮駛來……';

  @override
  String get bossGuardianEyebrow => '守護者';

  @override
  String bossEncounterEyebrow(String number) {
    return '遭遇 $number';
  }

  @override
  String get bossGuardianDown => '守護者倒下！';

  @override
  String get bossSkyReclaimed => '奪回天空';

  @override
  String bossVictoryPoints(int points) {
    return '+$points 分   ·   護盾恢復';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': '已擊敗蝙蝠男爵',
      'spitterBeetle': '已擊敗噴噴王',
      'duskMoth': '已擊敗暮光女皇',
      'pirate': '已擊敗海盜船長',
      'dragon': '已擊敗餘燼巨龍',
      'kingCoo': '已擊敗咕咕王',
      'searchlightGargoyle': '已擊敗探照燈石像鬼',
      'other': '已擊敗奈弗胡',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '「$line」';
  }

  @override
  String get bossPirateRoar => '呀哈！';

  @override
  String get bossGargoyleCardSmall => '探照燈';

  @override
  String get bossGargoyleCardBig => '石像鬼';

  @override
  String get bossGargoyleCardOrder => 'small-big';

  @override
  String get bossDodgeFlyLow => '往低飛';

  @override
  String get bossDodgeFlyHigh => '往高飛';

  @override
  String get bossDodgeClimbOrDive => '往上或往下';

  @override
  String get bossDodgeSlipBetween => '從光束之間\n鑽過去';

  @override
  String get bossSpotted => '被照到！';

  @override
  String get bossShieldLost => '護盾沒了';

  @override
  String get bossHeartLost => '-1 愛心';

  @override
  String get bossGargoyleLampOpen => '胸燈打開';

  @override
  String get bossGargoyleShoot => '射擊！';

  @override
  String get bossScreechFlyToGap => '飛到缺口';

  @override
  String get bossScreechHoldGap => '守住缺口';

  @override
  String get bossPirateHighTide => '滿潮';

  @override
  String get bossBarDefeated => '已擊敗';

  @override
  String get bossBarIncoming => '來襲中';

  @override
  String get bossBarFury => '狂怒';

  @override
  String get bossBarHeartDouble => '心臟 ×2';

  @override
  String get bossStronger => '強化！';

  @override
  String get bossKingCooPuffed => '鼓胸';

  @override
  String get bossKingCooShout => '咕咕！';

  @override
  String get bossKingCooPop => '啵！';

  @override
  String get bossKingCooPoof => '噗！';

  @override
  String get bossSquadOpenLane => '走安全航道';

  @override
  String get bossSquadUseGap => '從缺口穿過';

  @override
  String get bossSquadThenV => '接著：V 字';

  @override
  String get bossSquadThenGap => '接著：缺口';

  @override
  String get bossSquadCancelled => '中隊取消';

  @override
  String get bossNeferhooFound => '遺失的信找到了';

  @override
  String get bossNeferhooHoo => '嗚';

  @override
  String get bossNeferhooPoo => '呼';

  @override
  String get bossNeferhooMailCall => '來信囉';

  @override
  String get bossNeferhooExpressPost => '限時專送';

  @override
  String get bossNeferhooShootBack => '把信射回去！';

  @override
  String get bossNeferhooAnkh => '安卡';

  @override
  String get bossNeferhooTwoAnkhs => '兩個安卡';

  @override
  String get bossNeferhooComesBack => '它會飛回來！';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '野火！',
      'skyfall': '流星天降！',
      'eruption': '噴發！',
      'other': '蝙蝠群來襲！',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '抓住衝刺環，跑贏野火！',
      'skyfall': '抓住衝刺環，和流星賽跑！',
      'eruption': '抓住衝刺環，躲過噴發！',
      'other': '抓住衝刺環，一路衝過去！',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return '逃脫！+$points';
  }

  @override
  String encounterFlawless(int points) {
    return '完美無傷！+$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '你跑贏了野火',
      'skyfall': '你撐過了流星天降',
      'eruption': '你躲過了火山噴發',
      'other': '你衝破了蝙蝠群',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => '狂風！';

  @override
  String encounterGaleDetail(String mark) {
    return '注意閃爍的 $mark，閃開飛來的雜物！';
  }

  @override
  String encounterGaleWeathered(int points) {
    return '撐過了！+$points';
  }

  @override
  String get encounterGaleWeatheredDetail => '你撐過了狂風';

  @override
  String get encounterAllRings => '金環全拿！';

  @override
  String encounterAllRingsDetail(String seconds) {
    return '渦輪加速 +$seconds 秒';
  }

  @override
  String get encounterFinish => '終點';

  @override
  String get builderMode_pushUp => '伏地挺身';

  @override
  String get builderMode_squat => '深蹲';

  @override
  String get builderMode_jump => '跳躍';

  @override
  String builderSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 下伏地挺身',
      one: '1 下伏地挺身',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 下深蹲',
      one: '1 下深蹲',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => '我的點擊關卡';

  @override
  String get builderNewLevel_pushUp => '我的伏地挺身關卡';

  @override
  String get builderNewLevel_squat => '我的深蹲關卡';

  @override
  String get builderNewLevel_jump => '我的跳躍關卡';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => '我的關卡';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return '來飛飛看我在 Beakbound 做的關卡「$name」（$mode）：$code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$earned／$total 顆星';
  }

  @override
  String get builderBackSemantics => '返回';

  @override
  String get builderKeepIt => '保留';

  @override
  String builderLessSemantics(String name) {
    return '減少$name';
  }

  @override
  String builderMoreSemantics(String name) {
    return '增加$name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => '複製';

  @override
  String get builderCopy => '複製';

  @override
  String get builderDeleteSemantics => '刪除';

  @override
  String get builderDelete => '刪除';

  @override
  String get builderMoreBelow => '下面還有';

  @override
  String builderStepSemantics(String caption, String value) {
    return '$caption $value';
  }

  @override
  String builderStepHintSemantics(String caption, String value, String hint) {
    return '$caption $value，$hint';
  }

  @override
  String builderPercent(int percent) {
    return '$percent%';
  }

  @override
  String get builderLane => '航道';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '深蹲的上方或下方',
      'other': '伏地挺身的上方或下方',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => '上方';

  @override
  String get builderLaneBottom => '下方';

  @override
  String get builderHeight => '高度';

  @override
  String get builderHeightHint => '佔天空高度';

  @override
  String get builderLowerSemantics => '往下';

  @override
  String get builderHigherSemantics => '往上';

  @override
  String get builderOpening => '開口';

  @override
  String builderOpeningHint(int percent) {
    return '至少 $percent%';
  }

  @override
  String get builderNarrowerSemantics => '縮小開口';

  @override
  String get builderWiderSemantics => '加大開口';

  @override
  String get builderMotion => '動態';

  @override
  String get builderMotionGardenHint => '花園門固定不動';

  @override
  String get builderMotionStill => '靜止';

  @override
  String get builderMotionGentle => '輕柔';

  @override
  String get builderMotionLively => '活潑';

  @override
  String get builderMotionGardenToast => '花園門固定不動：換一種門才能讓它動起來。';

  @override
  String get builderSway => '擺動';

  @override
  String builderSwayHint(String seconds) {
    return '擺一次：$seconds';
  }

  @override
  String get builderSwayFast => '快';

  @override
  String get builderSwayMedium => '中';

  @override
  String get builderSwaySlow => '慢';

  @override
  String get builderPhase => '你抵達時';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position／$count';
  }

  @override
  String get builderPhaseHint => '它擺到哪個位置';

  @override
  String get builderPhaseEarlierSemantics => '擺動中較早的位置';

  @override
  String get builderPhaseLaterSemantics => '擺動中較晚的位置';

  @override
  String get builderLook => '外觀';

  @override
  String builderLookSemantics(int number) {
    return '外觀 $number';
  }

  @override
  String get builderDoor => '石門';

  @override
  String get builderDoorHint => '用射擊打開它';

  @override
  String get builderDoorNone => '沒有門';

  @override
  String get builderDoorNeedsShootToast => '要使用石門，請先在關卡設定中開啟射擊。';

  @override
  String get builderPlace => '位置';

  @override
  String get builderPlaceHint => '從起點算起';

  @override
  String get builderEarlierSemantics => '提早';

  @override
  String get builderLaterSemantics => '延後';

  @override
  String builderFamilySemantics(String family) {
    return '門的種類：$family。更換';
  }

  @override
  String get builderChangeFamily => '更換種類';

  @override
  String get builderItemStar => '星星';

  @override
  String get builderItemTrio => '三星組';

  @override
  String get builderItemHeart => '愛心';

  @override
  String get builderItemEnemy => '敵人';

  @override
  String get builderItemGate => '門';

  @override
  String get builderItemStarDetail => '一顆可收集的星星';

  @override
  String get builderItemTrioDetail => '三顆全拿有額外獎勵';

  @override
  String get builderItemHeartDetail => '補回一顆愛心';

  @override
  String get builderEnemyKind => '種類';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '鳥兒會飛在每次深蹲的上方和下方：把道具放在黃線上或黃線之間。',
      'other': '鳥兒會飛在每次伏地挺身的上方和下方：把道具放在黃線上或黃線之間。',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => '紫蝙蝠';

  @override
  String get builderEnemy_caveBat => '洞穴蝙蝠';

  @override
  String get builderEnemy_spitterBeetle => '噴噴甲蟲';

  @override
  String get builderEnemy_duskMoth => '暮光蛾';

  @override
  String get builderEnemy_alleyPigeon => '巷弄鴿';

  @override
  String get builderEnemy_mummyBat => '木乃伊蝙蝠';

  @override
  String get builderSummaryTitle => '這個關卡';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => '長度';

  @override
  String get builderFactStars => '星星';

  @override
  String get builderFactMarks => '星級刻度';

  @override
  String get builderFactWorkout => '運動量';

  @override
  String get builderFactPace => '節奏';

  @override
  String get builderFactBoss => '頭目';

  @override
  String get builderPace_relaxed => '悠閒';

  @override
  String get builderPace_steady => '穩定';

  @override
  String get builderPace_brisk => '輕快';

  @override
  String get builderSummaryStarterNote => '入門關卡：可以直接飛，也可以改編成你自己的關卡。';

  @override
  String get builderSummaryClearedNote => '你已破關：你把它一路飛到了終點。';

  @override
  String get builderSummaryClearNote => '試飛到終點，就能標記為已破關。';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    return '試飛、擊敗$boss並衝過終點線，就能標記為已破關。';
  }

  @override
  String get builderSummaryHowTo => '先在左邊選一個工具，再點天空。點一下物件可以修改；拖曳可以移動。';

  @override
  String get builderFamily_garden_detail => '固定不動。可以裝上石門。';

  @override
  String get builderFamily_windLift_detail => '開口會上下移動。';

  @override
  String get builderFamily_petalGate_detail => '開口會變窄又變寬。';

  @override
  String get builderFamily_switchback_detail => '兩個會往兩邊滑開的開口。';

  @override
  String get builderFamily_lanternDrift_detail => '會上下晃動的吊燈籠。';

  @override
  String get builderFamily_sunWheels_detail => '會合攏又張開的輪子。';

  @override
  String get builderFamily_crystalSteps_detail => '三道像漣漪般起伏的階梯。';

  @override
  String get builderFamiliesCloseSemantics => '關閉門的種類';

  @override
  String get builderFamiliesTitle => '門的種類';

  @override
  String get builderFamiliesSubtitle => '門的外觀和動態。';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family。$detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '幫關卡取個名字，最多 $count 個字。',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort => '把終點線往後移：關卡太短了。';

  @override
  String get reach_tooLong => '把終點線往前移：關卡太長了。';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '東西太多了：一個關卡最多放 $count 個。',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap => '只有點擊飛行關卡能以頭目收尾。';

  @override
  String get reach_noGates => '加一些門讓鳥兒飛過。';

  @override
  String get reach_startZone => '離起點太近：把它移到起點區之後。';

  @override
  String get reach_finishRoom => '這道門之後，終點線前要留點空間。';

  @override
  String get reach_overlap => '兩道門重疊了：把它們分開。';

  @override
  String get reach_gateHeight => '這道門太高或太低了。';

  @override
  String get reach_gateMotion => '這道門不能這樣動。';

  @override
  String get reach_gateLook => '這道門的外觀無法辨識。';

  @override
  String get reach_gateNarrow => '把這道門開大一點：鳥兒擠不過去。';

  @override
  String get reach_gateWide => '這道門開得太大了。';

  @override
  String get reach_doorNeedsShoot => '石門需要點擊飛行並開啟射擊。';

  @override
  String get reach_doorNeedsGarden => '只有花園門能裝石門。';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '切換太急：穩穩深蹲可能來不及。',
      'other': '切換太急：穩穩做伏地挺身可能來不及。',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb => '爬升太陡：多留點空間跳上這道門。';

  @override
  String get reach_enemyNeedsTap => '敵人只會出現在點擊飛行關卡。';

  @override
  String get reach_outsideSky => '要放在天空範圍內。';

  @override
  String get reach_pastFinish => '要放在終點線之前。';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '深蹲碰不到：把它移近航道。',
      'other': '伏地挺身碰不到：把它移近航道。',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => '卡在牆裡：把它移到開口中。';

  @override
  String get reach_noStars => '至少放一顆星星。';

  @override
  String get reach_marks => '星級刻度要求的星星，比關卡裡放的還多。';

  @override
  String reach_cannotFly(String problem) {
    return '這個關卡還不能飛（$problem）。';
  }

  @override
  String get builderSaveFailedFlyToast => '關卡沒有存成功，所以還不能飛。點它的名字重試。';

  @override
  String get builderShareBlockedToast => '先修好紅色標記，之後就能分享關卡了。';

  @override
  String get builderEditorBackSemantics => '回到關卡編輯器';

  @override
  String get builderSettingsSemantics => '關卡設定';

  @override
  String get builderFly => '起飛';

  @override
  String get builderTestFly => '試飛';

  @override
  String get builderFlySemantics => '飛這個關卡';

  @override
  String get builderTestFlySemantics => '試飛整個關卡';

  @override
  String get builderUndoSemantics => '復原';

  @override
  String get builderRedoSemantics => '重做';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice 個建議',
    );
    return '$blocking 個問題待修，$_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice 個建議',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => '可以起飛了';

  @override
  String get builderShareSemantics => '分享碼';

  @override
  String get builderFromHereSemantics => '從這裡開始試飛';

  @override
  String get builderFromHere => '從這裡';

  @override
  String get builderStatusStarter => '入門關卡 · 看看、飛飛或改編';

  @override
  String get builderStatusSaveFailed => '無法儲存 · 點一下重試';

  @override
  String get builderStatusSaving => '儲存中……';

  @override
  String get builderStatusSaved => '所有變更已儲存';

  @override
  String builderNamePlateSemantics(String name, String mode, String status) {
    return '$name。$mode。$status。';
  }

  @override
  String builderNamePlateRenameSemantics(
    String name,
    String mode,
    String status,
  ) {
    return '$name。$mode。$status。點一下重新命名。';
  }

  @override
  String get builderStarterBanner => '改編它，變成你的關卡';

  @override
  String get builderRemix => '改編';

  @override
  String get builderRemixSemantics => '改編';

  @override
  String get builderIssuesCloseSemantics => '關閉問題與建議';

  @override
  String get builderIssuesReadyTitle => '可以起飛了！';

  @override
  String get builderIssuesFixTitle => '起飛前要修好的地方';

  @override
  String get builderIssuesTipsTitle => '可以飛了，附幾個建議';

  @override
  String get builderIssuesReadyDetail => '沒有要修的。試飛到終點就能破關。';

  @override
  String get builderIssuesDetail => '點一項，就能跳到它在航線上的位置。';

  @override
  String get builderSettingsCloseSemantics => '關閉設定';

  @override
  String get builderSettingsTitle => '關卡設定';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · 變更會自動儲存';
  }

  @override
  String get builderSettingsName => '名稱';

  @override
  String get builderRename => '重新命名';

  @override
  String get builderRenameSemantics => '重新命名';

  @override
  String get builderSettingsRegion => '地區';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個地點 · 滑動看更多',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => '節奏';

  @override
  String get builderSettingsPaceHint => '天空捲動的速度';

  @override
  String get builderSettingsMarks => '星級刻度';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已放 $count 顆星星',
      one: '已放 1 顆星星',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => '兩星刻度';

  @override
  String get builderMarkThreeSemantics => '三星刻度';

  @override
  String get builderMarksAuto => '自動：跟著星星數';

  @override
  String get builderMarksByHand => '手動設定';

  @override
  String get builderSettingsControls => '操作';

  @override
  String get builderShootOn => '射擊：開';

  @override
  String get builderShootOff => '射擊：關';

  @override
  String get builderSprintOn => '衝刺：開';

  @override
  String get builderSprintOff => '衝刺：關';

  @override
  String get builderSettingsBoss => '頭目壓軸';

  @override
  String get builderSettingsBossHint => '在終點等著';

  @override
  String get builderNoBossSemantics => '無頭目：終點線';

  @override
  String get builderNoBoss => '無';

  @override
  String get builderBossShort_baronBat => '男爵';

  @override
  String get builderBossShort_spitterBeetle => '噴噴王';

  @override
  String get builderBossShort_duskMoth => '女皇';

  @override
  String get builderBossShort_pirate => '船長';

  @override
  String get builderBossShort_dragon => '巨龍';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '鳥兒會飛兩條航道：每次深蹲的上方和下方。動作較慢的玩家，會以較溫和的速度玩同一個關卡。這裡沒有射擊、衝刺或頭目。',
      'other': '鳥兒會飛兩條航道：每次伏地挺身的上方和下方。動作較慢的玩家，會以較溫和的速度玩同一個關卡。這裡沒有射擊、衝刺或頭目。',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote => '每跳一次，鳥兒就往上飛；兩次跳躍之間會滑翔。這裡沒有射擊、衝刺或頭目。';

  @override
  String get builderStartZoneToast => '起點區要保持淨空：請把東西放在虛線右邊。';

  @override
  String get builderSkySemantics => '關卡天空。點一下放置，拖曳可移動或捲動。';

  @override
  String get builderSkyReadOnlySemantics => '關卡天空。點一下物件來查看。';

  @override
  String get builderCoachTitle => '打造你的關卡';

  @override
  String get builderCoachPickTool => '在左邊選一個工具';

  @override
  String get builderCoachTapSky => '點天空來放置';

  @override
  String get builderCoachTestFly => '試飛看看！';

  @override
  String get builderCoachDrag => '拖曳物件來移動 · 拖曳天空來捲動';

  @override
  String get builderTipDrag => '拖曳它來移動 · 拖曳天空來捲動';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '深蹲最高點',
      'other': '伏地挺身最高點',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => '最高點';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '深蹲最低點',
      'other': '伏地挺身最低點',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => '最低點';

  @override
  String get builderCanvasStartZoneFull => '起點區 · 保持淨空';

  @override
  String get builderCanvasStartZone => '起點區';

  @override
  String get builderCanvasFinishHere => '終點在這';

  @override
  String get builderTool_select => '選取';

  @override
  String get builderToolHint_select => '選取：點一下物件來修改，拖曳來移動';

  @override
  String get builderTool_gate => '門';

  @override
  String get builderToolHint_gate => '門：點天空放一道門';

  @override
  String get builderTool_star => '星星';

  @override
  String get builderToolHint_star => '星星：點天空放一顆星星';

  @override
  String get builderTool_trio => '三星組';

  @override
  String get builderToolHint_trio => '三星組：點天空放三顆星星';

  @override
  String get builderTool_heart => '愛心';

  @override
  String get builderToolHint_heart => '愛心：點天空放一顆愛心';

  @override
  String get builderTool_enemy => '敵人';

  @override
  String get builderToolHint_enemy => '敵人：點天空放一個敵人';

  @override
  String get builderTool_finish => '終點';

  @override
  String get builderToolHint_finish => '終點：點天空移動終點線';

  @override
  String get builderTool_boss => '頭目';

  @override
  String get builderToolHint_boss => '頭目標記：點天空移動頭目等待的位置';

  @override
  String get builderStarterToolsToast => '入門關卡不能修改：改編之後就能變更。';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss': '航線總覽。到頭目 $length。拖曳可沿航線移動。',
      'other': '航線總覽。到終點 $length。拖曳可沿航線移動。',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss': '航線總覽。到頭目 $length。$reps。拖曳可沿航線移動。',
      'other': '航線總覽。到終點 $length。$reps。拖曳可沿航線移動。',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '距頭目 $length';
  }

  @override
  String get builtResultTestFlight => '試飛';

  @override
  String get builtResultCleared => '破關！';

  @override
  String get builtResultBonk => '咚！';

  @override
  String get builtResultLanded => '降落';

  @override
  String get builtResultTestTab => '試飛';

  @override
  String get builtResultGoalFinish => '終點';

  @override
  String get builtResultGoalBoss => '頭目';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal。';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal。已完成。';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '收集 $count 顆星星。',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '收集 $count 顆星星。已完成。',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => '完成';

  @override
  String get builtResultNotYet => '還沒';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還差 $count 顆',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => '先抵達終點';

  @override
  String get builtResultClearedByYou => '你已破關';

  @override
  String get builtResultNewBest => '新紀錄！';

  @override
  String get builtResultPractice => '練習';

  @override
  String builtResultBest(int count) {
    return '最佳 $count';
  }

  @override
  String get builtResultFirstClear => '首次過關！';

  @override
  String get builtResultStarsCollected => '收集的星星';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '關卡星級：$count／3 顆星',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => '需要';

  @override
  String get builtResultWorkout => '運動量';

  @override
  String get builtResultGotTo => '飛到';

  @override
  String get builtResultScore => '分數';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '伏地挺身',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '深蹲',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '跳躍',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '鏡頭前伏地挺身',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '鏡頭前深蹲',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return '全長 $length';
  }

  @override
  String get builtResultNotKept => '不保留';

  @override
  String get builtResultNoBest => '尚無最佳紀錄';

  @override
  String get builtResultClearedStrip => '你已破關 · 可以分享了！';

  @override
  String builtResultFlownFrom(String from) {
    return '從 $from 開始飛。完整飛完才能破關。';
  }

  @override
  String get builtResultTestNothingSaved => '試飛 · 不會存檔';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return '試飛 · 飛到 $reached／$length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return '飛到 $reached／$length。抵達終點才能拿星星。';
  }

  @override
  String get builtResultReachFinish => '抵達終點才能拿到星星。';

  @override
  String get builtResultSaved => '已存在這支手機上';

  @override
  String get builtResultSaving => '正在儲存你的飛行……';

  @override
  String get builtResultBuilder => '關卡編輯器';

  @override
  String get builtResultEditLevel => '編輯關卡';

  @override
  String get builtResultEdit => '編輯';

  @override
  String get builtResultFlyAgain => '再飛一次';

  @override
  String get builtResultWatchReplay => '觀看重播';

  @override
  String get builtResultPreparing => '準備中……';

  @override
  String get builtResultSessionSaving => '儲存中……';

  @override
  String get builtResultSaveSession => '儲存飛行';

  @override
  String get builderShelfTitle => '關卡編輯器';

  @override
  String get builderShelfPasteCode => '貼上分享碼';

  @override
  String get builderShelfNewLevel => '新關卡';

  @override
  String get builderShelfSaveFailed => '沒有存成功，請再試一次。';

  @override
  String builderShelfDeleteTitle(String name) {
    return '要刪除「$name」嗎？';
  }

  @override
  String get builderShelfDeleteBody => '它的最佳紀錄也會一起刪除。你在這個關卡做過的伏地挺身、深蹲和跳躍仍然算數。';

  @override
  String get builderShelfDelete => '刪除';

  @override
  String builderShelfDeleted(String name) {
    return '已刪除「$name」。';
  }

  @override
  String get builderShelfFixFirst => '分享前請先修好標成紅色的地方：點「修正」。';

  @override
  String get builderShelfCodeCopied => '已複製分享碼！貼給朋友吧。';

  @override
  String get builderShelfCodeCopiedUncleared => '已複製分享碼！也請把它飛到終點，讓朋友知道這關過得去。';

  @override
  String get builderShelfNotReady => '這個關卡還不能飛：點「修正」。';

  @override
  String get builderShelfPasteMissingTitle => '沒有可貼上的分享碼';

  @override
  String get builderShelfPasteNewerTitle => '這個關卡來自較新版的 Beakbound';

  @override
  String get builderShelfPasteDamagedTitle => '這組分享碼亂掉了';

  @override
  String get builderShelfPasteMissingBody =>
      '複製朋友的關卡分享碼（開頭是 BEAK1.），再點一次「貼上分享碼」。';

  @override
  String get builderShelfPasteNewerBody => '請更新 Beakbound 才能飛這關，然後再貼一次分享碼。';

  @override
  String get builderShelfPasteDamagedBody => '有一部分遺失或打錯了。請朋友再複製一次完整的分享碼。';

  @override
  String builderShelfImported(String name) {
    return '「$name」已加入你的關卡！';
  }

  @override
  String get builderShelfUnavailable => '你的關卡需要一點時間。';

  @override
  String get builderShelfMine => '我的關卡';

  @override
  String get builderShelfStarters => '入門關卡';

  @override
  String get builderShelfStartersHint => '直接飛，或改編成你自己的關卡';

  @override
  String get builderShelfEmptyTitle => '打造你的第一個關卡';

  @override
  String get builderShelfEmptyBody => '親手放上門、星星和愛心，設好終點線，再試飛看看。';

  @override
  String get builderShelfPasteFriend => '貼上朋友的分享碼';

  @override
  String get builderShelfNeedsWork => '需要修正';

  @override
  String get builderShelfClearedByYou => '你已破關';

  @override
  String get builderShelfFromFriend => '來自朋友';

  @override
  String get builderShelfFly => '起飛';

  @override
  String builderShelfFlySemantics(String name) {
    return '飛「$name」';
  }

  @override
  String get builderShelfFixIt => '修正';

  @override
  String builderShelfFixSemantics(String name) {
    return '修正「$name」';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return '編輯「$name」';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return '分享「$name」';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return '分享「$name」：你已破關';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return '「$name」的更多選項';
  }

  @override
  String get builderShelfRemix => '改編';

  @override
  String builderShelfRemixSemantics(String name) {
    return '改編「$name」';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 個地方要在編輯器中修正',
      one: '有 1 個地方要在編輯器中修正',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 顆星星',
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
    return '$name。$region的$mode。$length。';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '最佳：$stars／3 顆星。',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '需要修正：$count 個地方。',
      one: '需要修正：1 個地方。',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => '你已破關。';

  @override
  String get builderShelfFromFriendSemantics => '來自朋友。';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return '查看「$name」。$mode，$length，$fact。';
  }

  @override
  String get builderShelfRemixSuffix => '改編版';

  @override
  String get builderShelfCopySuffix => '副本';

  @override
  String get commonOk => '好';

  @override
  String get commonCancel => '取消';

  @override
  String get starter_t_tap_1_name => '花園跳跳';

  @override
  String get starter_t_push_1_name => '十下伏地挺身';

  @override
  String get starter_t_squat_1_name => '階梯深蹲';

  @override
  String get starter_t_jump_1_name => '彈跳灣';

  @override
  String get starter_t_tap_boss_name => '男爵之橋';

  @override
  String get builderPickCloseNewLevel => '關閉新關卡';

  @override
  String get builderPickModeTitle => '要做什麼樣的關卡？';

  @override
  String get builderPickRegionTitle => '要飛去哪裡？';

  @override
  String get builderPickModeSubtitle => '選擇飛行方式（之後不能更改）。每個關卡都用觸控來試飛。';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · 選擇要飛的地方。之後可以更改。';
  }

  @override
  String get builderPickTouchLine => '點一下拍翅。有門、星星、敵人和頭目。';

  @override
  String get builderPickPushUpLine => '一高一低兩條航道：每往下一次，就是一下伏地挺身。';

  @override
  String get builderPickSquatLine => '一高一低兩條航道：每往下一次，就是一下深蹲。';

  @override
  String get builderPickJumpLine => '跳躍來升空。門可以放在天空任何高度。';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode。$line';
  }

  @override
  String get builderPickCamera => '鏡頭';

  @override
  String get builderPickSuggested => '推薦';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region，推薦';
  }

  @override
  String get builderPickClose => '關閉';

  @override
  String get builderPickNotYet => '還不行：請先修好標成紅色的地方。';

  @override
  String get builderPickShare => '分享碼';

  @override
  String get builderPickShareLine => '複製一組分享碼，朋友可以貼到他們的 Beakbound。';

  @override
  String get builderPickDuplicate => '建立副本';

  @override
  String get builderPickDuplicateLine => '複製一份，試試別的點子。';

  @override
  String get builderPickDeleteLine => '把關卡丟掉。刪除前會先問你。';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => '取消匯入';

  @override
  String get builderPickImportTitle => '有關卡可以飛！';

  @override
  String get builderPickImportSubtitle => '有人跟你分享了這個關卡。';

  @override
  String get builderPickClearedByMaker => '作者已破關';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 顆星星可收集',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    return '最後是$boss';
  }

  @override
  String get builderPickNotFlown => '作者還沒把它飛到終點。';

  @override
  String get builderPickRoute => '航線';

  @override
  String builderPickAlreadyHave(String name) {
    return '你已經有這個關卡了：「$name」。';
  }

  @override
  String get builderPickImportCopy => '匯入一份副本';

  @override
  String get builderPickOpenYours => '打開你的版本';

  @override
  String get builderPickImport => '匯入';

  @override
  String get builderShelfRenameCancelSemantics => '取消重新命名';

  @override
  String get builderShelfRenameTitle => '幫關卡取名字';

  @override
  String get builderShelfRenameEmpty => '名字至少要一兩個字';

  @override
  String get builderShelfRenameSaveSemantics => '儲存名稱';

  @override
  String get builderShelfRenameSave => '儲存';

  @override
  String get coopMode_roped => '綁繩';

  @override
  String get coopMode_free => '無繩';

  @override
  String get coopMode_duel => '1 對 1';

  @override
  String get coopTitle => '一起飛';

  @override
  String get coopPlayersTag => '兩位玩家 · 一支手機';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode 最佳 $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode：尚無最佳';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count 場對決',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode：首場對決';
  }

  @override
  String get coopRopedLead => '你們的鳥兒共用一條繩子。';

  @override
  String get coopRopedBody => '一起拍翅才能飛得高：單獨一隻拍翅也能把兩隻都往上帶，但只有一點點。衝刺可以拉著搭檔前進。';

  @override
  String get coopFreeLead => '無繩：';

  @override
  String get coopFreeBody => '每隻鳥各飛各的，只會和對方互撞。愛心、護盾和分數仍然共用。';

  @override
  String get duelLead => '開戰！';

  @override
  String get duelBody =>
      '每隻鳥都有自己的愛心。搶神秘箱：有的會派蝙蝠、噴噴甲蟲或流星去攻擊對手，有的會帶來愛心、護盾或星星無敵。最後還在飛的鳥獲勝。';

  @override
  String get coopStart => '一起飛';

  @override
  String get duelStart => '開戰！';

  @override
  String get coopFlightSemantics => '玩家 1 點左半邊拍翅，玩家 2 點右半邊';

  @override
  String get coopPauseSemantics => '暫停飛行';

  @override
  String coopShootSemantics(int player) {
    return '玩家 $player 射擊';
  }

  @override
  String coopSprintSemantics(int player) {
    return '玩家 $player 衝刺';
  }

  @override
  String coopPlayerShort(int player) {
    return 'P$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return '玩家 $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '星星磁鐵：剩下 $seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: '磁鐵充能中：完美穿越 $charge／$gates 次',
    );
    return '$_temp0';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds秒',
    );
    return '$_temp0';
  }

  @override
  String get coopCountdownRoped => '綁好繩子。預備……';

  @override
  String get coopCountdownFree => '預備……';

  @override
  String get duelCountdown => '準備對決……';

  @override
  String get coopCountdownRopedHint => '一起拍翅，飛得更高。\n衝刺可以拉著搭檔前進！';

  @override
  String get coopCountdownFreeHint => '每隻鳥各飛各的。\n共用愛心，一起過門！';

  @override
  String get duelCountdownHint => '搶神秘箱！\n最後還在飛的鳥獲勝。';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '玩家 $player 星星無敵：剩下 $seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => '主畫面';

  @override
  String get coopChangeBirds => '換鳥兒';

  @override
  String get coopSaved => '已儲存';

  @override
  String get coopSaving => '儲存中……';

  @override
  String get coopSaveSession => '儲存飛行';

  @override
  String get duelRematch => '再戰';

  @override
  String get coopFlyAgain => '再飛一次';

  @override
  String duelWinner(int player) {
    return '玩家 $player 獲勝！';
  }

  @override
  String get duelDraw => '平手！';

  @override
  String get duelStopped => '對決中止';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first 對 $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner打敗了$loser';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize攻向 P$rival！';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize！';
  }

  @override
  String get duelPrize_batSwarm => '蝙蝠群';

  @override
  String get duelPrize_spitter => '噴噴甲蟲';

  @override
  String get duelPrize_meteorShower => '流星雨';

  @override
  String get duelPrize_heart => '愛心';

  @override
  String get duelPrize_shield => '護盾';

  @override
  String get duelPrize_starPower => '星星無敵';

  @override
  String get coopTapLeftHalf => '點左半邊';

  @override
  String get coopTapRightHalf => '點右半邊';

  @override
  String coopPickSemantics(int player, String bird) {
    return '玩家 $player：$bird';
  }

  @override
  String coopSideHint(int player) {
    return 'P$player · 點這一邊';
  }

  @override
  String get coopKeysP1 => 'P1 · W 鍵拍翅 · D 鍵射擊 · A 鍵衝刺';

  @override
  String get coopKeysP2 => 'P2 · 上鍵拍翅 · 右鍵射擊 · 左鍵衝刺';

  @override
  String get coopRopedSemantics => '綁繩：鳥兒共用一條繩子';

  @override
  String get coopFreeSemantics => '無繩：每隻鳥各飛各的';

  @override
  String get duelModeSemantics => '1 對 1：鳥兒互相對戰';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => '飛行已儲存 · 可在「紀錄」觀看';

  @override
  String get coopNewTeamBest => '團隊新紀錄！';

  @override
  String get coopWhatATeam => '好棒的團隊。';

  @override
  String coopPairCaption(String first, String second) {
    return '$first 和 $second';
  }

  @override
  String get coopTeamScore => '團隊分數';

  @override
  String get coopTeamBest => '團隊最佳';

  @override
  String get coopNewTeamBestRibbon => '團隊新紀錄！';

  @override
  String get coopStatFlightTime => '飛行時間';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星星',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '道門',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => '拍翅比例';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'P$player 拍翅',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return '對決時間 $time';
  }

  @override
  String get duelSeries => '戰績';

  @override
  String get duelHeartsLeft => '剩餘愛心';

  @override
  String get duelBoxesOpened => '打開的神秘箱';

  @override
  String get duelHitsLanded => '命中次數';

  @override
  String get coopPauseSubtitle => '你們都停在枝頭等著。我們會先倒數，再讓你們一起出發。';

  @override
  String get coopFinishFlight => '結束飛行';

  @override
  String get cameraLabIntro => '把手機橫放、擺低，面向你或放在你旁邊。';

  @override
  String cameraLabAlmostThere(String parts) {
    return '快好了 · 需要看清楚：$parts';
  }

  @override
  String get cameraLabJointShoulder => '肩膀';

  @override
  String get cameraLabJointElbow => '手肘';

  @override
  String get cameraLabJointWrist => '手腕';

  @override
  String get cameraLabJointHip => '臀部';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first、$rest';
  }

  @override
  String get cameraLabStarting => '正在啟動鏡頭……';

  @override
  String get cameraLabDenied => '相機權限已關閉。請在應用程式設定中允許，再試一次。';

  @override
  String cameraLabFailed(String error) {
    return '鏡頭無法啟動：$error';
  }

  @override
  String get cameraLabStopped => '鏡頭已停止。點「啟動鏡頭」重新校準。';

  @override
  String get cameraLabBack => '鏡頭實驗室 · 回主畫面';

  @override
  String get cameraLabStepShow => '1. 拍到你的手臂和臀部';

  @override
  String get cameraLabStepPushUps => '2. 做兩下伏地挺身';

  @override
  String get cameraLabStepMove => '3. 動動你的鳥兒！';

  @override
  String get cameraLabStepSquat => '找出你的深蹲幅度';

  @override
  String get cameraLabStepJump => '找好你的站立位置';

  @override
  String get cameraLabPushUpHelp =>
      '手機放低，面向你或放在你旁邊。\n面向手機？讓雙肩、一隻手臂和臀部入鏡。\n照自己的節奏，下去、上來兩次。';

  @override
  String get cameraLabSquatHelp => '站好不動，舒服地蹲下並停一下，再站起來。蹲下就下降；站起就上升。';

  @override
  String get cameraLabJumpHelp => '面向手機站好，讓全身和雙腳都入鏡。先靜止不動，再輕輕地小跳。跳一次 = 一次大加速。';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '校準\n已校準 $done / $total',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return '校準\n已校準 $percent%';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '操作測試\n$count 下伏地挺身',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '操作測試\n$count 下深蹲',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '操作測試\n$count 次跳躍',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Hz · p95 $ms 毫秒';
  }

  @override
  String get cameraLabStartingButton => '啟動中……';

  @override
  String get cameraLabRecalibrate => '重新校準';

  @override
  String get cameraLabStartCamera => '啟動鏡頭';

  @override
  String get cameraLabTapStart => '點「啟動鏡頭」';

  @override
  String cameraLabTry(String mode) {
    return '試試$mode';
  }

  @override
  String get cameraBadgeWaking => '喚醒中';

  @override
  String get cameraBadgeLive => '即時';

  @override
  String get cameraBadgeLockedOn => '已鎖定';

  @override
  String get cameraBadgeOffline => '離線';

  @override
  String get trackingCatchingUp => '鏡頭正在跟上';

  @override
  String get trackingStepIntoOutline => '站進人形輪廓裡';

  @override
  String get trackingKeepShoulders => '讓雙肩保持入鏡';

  @override
  String get trackingShowSide => '從側面拍到一邊的肩膀、手肘、手腕和臀部';

  @override
  String get trackingMoveCloser => '再靠近一點';

  @override
  String get trackingGetDown => '趴下來，擺好伏地挺身姿勢';

  @override
  String get trackingHandsOnFloor => '雙手撐地，身體往後伸直';

  @override
  String get trackingExtendBody => '身體再往手的後方伸直一點';

  @override
  String get trackingComfortableRange => '保持在舒服的伏地挺身幅度內';

  @override
  String get trackingPlaceHands => '雙手撐地，身體在手的後方';

  @override
  String get trackingFrontTracked => '已追蹤到正面 · 讓雙手保持入鏡';

  @override
  String get trackingBodyInView => '身體已入鏡 · 臉可以朝下';

  @override
  String get trackingArmsTracked => '已追蹤到手臂 · 腿部偵測有限';

  @override
  String get trackingFindTop => '找到舒服的最高點';

  @override
  String get trackingCalibrated => '校準完成！試著操控你的鳥兒。';

  @override
  String get trackingFreshFrame => '正在等待新的畫面';

  @override
  String get trackingDistanceChanged => '鏡頭距離變了 · 請重新校準';

  @override
  String get trackingKeepArm => '讓一隻手臂保持入鏡';

  @override
  String get trackingSquatStepBack => '往後退，讓肩膀、臀部、膝蓋和雙腳都入鏡';

  @override
  String get trackingSquatFaceCamera => '面向鏡頭，雙腳踩在地上';

  @override
  String get trackingSquatControls => '蹲下就下降 · 站起就上升';

  @override
  String get trackingStartingDistance => '回到起始距離面向鏡頭 · 移動過的話請重新校準';

  @override
  String get trackingFeetPlanted => '雙腳穩穩踩在起始位置';

  @override
  String get trackingSquatStandTall => '站直不動，讓雙腳入鏡';

  @override
  String get trackingStandStill => '站直，先不要動';

  @override
  String get trackingSquatDepth => '蹲到舒服的深度，停一下';

  @override
  String get trackingSquatHold => '舒服地蹲下，然後停一下';

  @override
  String get trackingSquatHoldBriefly => '保持這個舒服的蹲姿一下';

  @override
  String get trackingSquatStandUp => '站起來就完成校準';

  @override
  String get trackingSquatReady => '好了！蹲下就下降 · 站起就上升';

  @override
  String get trackingJumpStepBack => '往後退，讓肩膀、臀部和雙腳都入鏡';

  @override
  String get trackingJumpFaceCamera => '面向鏡頭站好，頭上要留跳躍的空間';

  @override
  String get trackingJumpSmall => '小小跳就夠了 · 落地後再跳';

  @override
  String get trackingJumpStandStill => '站好不動，讓全身和雙腳都入鏡';

  @override
  String get trackingJumpReady => '好了！小跳一下，就能大大加速。';

  @override
  String get trackingFindPosition => '找好你的位置';

  @override
  String get trackingInterrupted => '追蹤中斷';

  @override
  String get trackingCameraInterrupted => '鏡頭中斷了。請檢查相機權限後再試一次。';

  @override
  String get trackingCameraAway => '離開遊戲時，鏡頭停止了';

  @override
  String get trackingJumpBoost => '跳一下，大加速';

  @override
  String get trackingJumpLand => '落地，準備下一跳';

  @override
  String trackingLowerMore(int step, int total) {
    return '再往下一點 · $step／$total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return '舒服地往下 · $step／$total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return '撐回上方 · $step／$total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return '做到跟第一下一樣的幅度 · $step／$total';
  }

  @override
  String commonSaveFailed(String error) {
    return '無法儲存這項變更，請再試一次。（$error）';
  }

  @override
  String get commonDelete => '刪除';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還差 $count 顆',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => '你的鳥巢需要一點時間。';

  @override
  String get homeSettings => '設定';

  @override
  String homeGreetingFirst(String bird) {
    return '嗨，我是$bird！準備好起飛了嗎？';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '冒險完成！$bird以你為榮。',
      'female': '冒險完成！$bird以你為榮。',
      'other': '冒險完成！$bird以你為榮。',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird準備好了。你呢？',
      'female': '$bird準備好了。你呢？',
      'other': '$bird準備好了。你呢？',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => '無盡模式';

  @override
  String get homeEndlessDetail => '能飛多遠就飛多遠';

  @override
  String get homeEndlessSemantics => '無盡模式。能飛多遠就飛多遠。';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: '無盡模式。能飛多遠就飛多遠。最佳：$best 星星分。',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => '最佳';

  @override
  String get homeBestNone => '創下你的第一個紀錄';

  @override
  String get homeCampaignTitle => '故事模式';

  @override
  String get homeCampaignDone => '封封送達';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '故事模式。下一關：$level。已得 $stars／$total 顆星。',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '故事模式。封封送達。已得 $stars／$total 顆星。',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => '小遊戲';

  @override
  String get homeMiniGamesDetail => '運動 · 雙人';

  @override
  String get homeMiniGamesSemantics => '小遊戲。伏地挺身、深蹲、跳躍，或雙人遊戲。';

  @override
  String get homeBuilderTitle => '關卡編輯器';

  @override
  String get homeBuilderDetail => '製作 · 飛行 · 分享';

  @override
  String get homeBuilderSemantics => '關卡編輯器。製作你自己的關卡，飛一飛，再分享出去。';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再飛 $count 次解鎖',
      one: '再飛 1 次解鎖',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '關卡編輯器。未解鎖。再飛 $count 次就能解鎖。',
      one: '關卡編輯器。未解鎖。再飛 1 次就能解鎖。',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => '冒險';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '今日冒險。已完成 $done／3 個目標。',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => '鳥兒';

  @override
  String homeDockBirdsSemantics(String bird) {
    return '鳥兒。目前和$bird一起飛。';
  }

  @override
  String get homeDockUpgrades => '升級';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '升級。有 $stars 顆星星可用。',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => '護照';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: '護照。已得 $earned／$total 面獎牌。',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => '紀錄';

  @override
  String get homeMiniGamesPickerTitle => '小遊戲';

  @override
  String get homeMiniGamesPickerIntro => '動起來飛，或和朋友共用一支手機。';

  @override
  String get homeMiniGamesCloseSemantics => '關閉小遊戲';

  @override
  String get homeMiniGamesPushUpCard => '往下就俯衝。\n撐起就高飛。';

  @override
  String get homeMiniGamesSquatCard => '蹲低一點。\n站起就高飛。';

  @override
  String get homeMiniGamesJumpCard => '跳躍來升空。\n滑翔吃星星。';

  @override
  String get homeMiniGamesCoopCard => '兩位玩家，一支手機。\n合作或對決。';

  @override
  String get homeMiniGamesCamera => '鏡頭';

  @override
  String get homeMiniGamesPlayers => '雙人';

  @override
  String get homeMiniGamesCoop => '一起飛';

  @override
  String get birdsTitle => '認識你的飛行夥伴。';

  @override
  String birdsFlownTag(int flown, int total) {
    return '已飛過 $flown／$total';
  }

  @override
  String get birdsStatusCopilot => '你的副駕駛';

  @override
  String get birdsStatusReady => '準備起飛';

  @override
  String get birdsStatusLocked => '未解鎖';

  @override
  String get birdsNotFlown => '還沒飛過';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '飛過 $count 次',
      one: '飛過 1 次',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return '和$bird一起飛';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return '改和$bird一起飛，不再和$current';
  }

  @override
  String birdsUnlock(String bird) {
    return '解鎖$bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '用 $price 顆星星解鎖$bird',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '用 $price 顆星星解鎖$bird，星星還不夠',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => '正和你一起飛';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird，正和你一起飛';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird，正和你一起飛，新夥伴';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird，未解鎖，$price 顆星星',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird，新夥伴';
  }

  @override
  String get birdsTagFlying => '飛行中';

  @override
  String get birdsTagNew => '新';

  @override
  String get bird_0_description => '小小鳥，大大天。';

  @override
  String get bird_0_trail => '陽光泡泡';

  @override
  String get bird_1_description => '粉嫩臉頰、捲捲羽冠、滿滿愛心。';

  @override
  String get bird_1_trail => '蜜桃愛心';

  @override
  String get bird_2_description => '小小蜂鳥，清新薄荷，全速衝刺。';

  @override
  String get bird_2_trail => '薄荷葉';

  @override
  String get bird_3_description => '乘著星光飛翔的愛睏小貓頭鷹。';

  @override
  String get bird_3_trail => '星塵閃閃';

  @override
  String get upgradesWalletLabel => '你的\n星星';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '有 $stars 顆星星可用',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => '幫你的鳥兒升級吧。';

  @override
  String get upgradesIntro => '點一下齒輪，看看它的功能。飛行中撿到的每顆星星，都能拿來花。';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power，等級 $level／$max。下一級需要 $cost 顆星星',
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
      other: '$power，等級 $level／$max。下一級需要 $cost 顆星星，星星還不夠',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power，等級 $level／$max。已滿級';
  }

  @override
  String get upgradesMax => '滿級';

  @override
  String upgradesLevel(int level) {
    return '等級 $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return '等級 $level，已達最高';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now，下一級 $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value%';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value 秒';
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
      other: '你會剩下 $count 顆星星。',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => '升級';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '用 $cost 顆星星升級',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '用 $cost 顆星星升級，星星還不夠',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => '已滿級';

  @override
  String get power_shot_name => '射擊力';

  @override
  String get power_shot_blurb => '按住射擊，蓄力丟出更大、更硬的石頭。';

  @override
  String get power_sprint_name => '衝刺';

  @override
  String get power_sprint_blurb => '一陣加速衝刺，撞碎擋路的敵人。';

  @override
  String get power_shield_name => '護盾';

  @override
  String get power_shield_blurb => '幫你擋下一次攻擊。飛行中收集星星就能補滿。';

  @override
  String get power_magnet_name => '磁鐵';

  @override
  String get power_magnet_blurb => '完美穿越門就能獲得。它會把星星吸過來。';

  @override
  String get power_stat_maxCharge => '最大蓄力';

  @override
  String get power_stat_burstLength => '衝刺時間';

  @override
  String get power_stat_cooldown => '冷卻時間';

  @override
  String get power_stat_starsToRefill => '補滿所需星星';

  @override
  String get power_stat_safeTime => '護盾破後的無敵時間';

  @override
  String get power_stat_perfectGates => '所需完美穿越次數';

  @override
  String get power_stat_lasts => '持續時間';

  @override
  String get power_stat_reach => '吸引範圍';

  @override
  String get passportTitle => '你的天空護照。';

  @override
  String get passportDailyCard => '每日卡片';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total 面獎牌';
  }

  @override
  String get passportIntro => '小小冒險，永遠的紀念。每個戳章都有銅牌、銀牌和金牌。';

  @override
  String get passportNoMedal => '還沒有獎牌';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': '銅牌',
      'silver': '銀牌',
      'other': '金牌',
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
    return '$stamp。$held。下一面是$next：$goal（$current／$target）。';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp。金牌。$goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': '邁向銅牌',
      'silver': '邁向銀牌',
      'other': '邁向金牌',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => '已蓋章';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp：$medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp：尚無獎牌';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => '銅牌';

  @override
  String get passportMedal_silver => '銀牌';

  @override
  String get passportMedal_gold => '金牌';

  @override
  String get stamp_frequentFlyer_name => '飛行常客';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '完成 $n 趟計分飛行。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => '分毫不差';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '沿著準心完成 $n 次完美穿越。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => '追星族';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '收集 $n 顆星星。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => '星座';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在一次不中斷的連擊中收集 $n 顆星星。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => '天空機長';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在一趟無盡飛行中拿到 $n 分。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => '開路先鋒';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '完成 $n 趟至少 60 秒的無盡飛行。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => '物以類聚';

  @override
  String get stamp_allRounder_name => '全能好手';

  @override
  String get stamp_flockTogether_goalBronze => '帶兩隻不同的鳥兒進行計分飛行。';

  @override
  String get stamp_flockTogether_goalSilver => '帶全部四隻鳥兒進行計分飛行。';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '每隻鳥兒都完成 $n 趟計分飛行。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze => '玩一次伏地挺身、深蹲或跳躍小遊戲。';

  @override
  String get stamp_allRounder_goalSilver => '三種小遊戲都玩過：伏地挺身、深蹲、跳躍。';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '每種小遊戲都完成 $n 趟計分飛行。',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals 面獎牌 · 目前 $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => '你的冒險需要一點時間。';

  @override
  String get dailyTitle => '今天的小小冒險。';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · 目標 $done/3';
  }

  @override
  String get dailyIntro => '三個目標，任何操作方式都行。一趟無盡飛行就能同時達成三個。';

  @override
  String get dailyLaunchEndless => '無盡模式';

  @override
  String get dailyPostcardKicker => '天空俱樂部明信片';

  @override
  String get dailyStamped => '明信片蓋章了！';

  @override
  String dailyGoalsComplete(int done) {
    return '目標完成 $done / 3';
  }

  @override
  String get dailyDoneNote => '小小的冒險，全都屬於你。';

  @override
  String get dailyOpenNote => '完成全部三個目標，就能在卡片蓋章。';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal 已完成';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current／$target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date：明信片已蓋章';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date：$done/3 個目標';
  }

  @override
  String get dailyNoStreak => '每天都是新目標，沒有連續紀錄要守。';

  @override
  String get dailyTheme_0 => '日出送信';

  @override
  String get dailyTheme_1 => '蜜桃野餐';

  @override
  String get dailyTheme_2 => '月光郵件';

  @override
  String get dailyTheme_3 => '雲朵遊行';

  @override
  String get dailyTheme_4 => '暮光寶藏';

  @override
  String get dailyTheme_5 => '花園派對';

  @override
  String get task_flights_title => '展翅高飛';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今天完成 $count 趟計分飛行。',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => '海闊天空';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在今天的計分飛行中通過 $count 道門。',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => '星星滿口袋';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在今天的飛行中收集 $count 顆星星。',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => '閃亮不停';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在一次不中斷的連擊中收集 $count 顆星星。',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => '正中紅心';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今天完成 $count 次完美穿越。',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => '一路飛到底';

  @override
  String get task_finishTrail_goal => '在一趟無盡飛行中飛至少 60 秒。';

  @override
  String get recordsTitle => '你的小小勝利。';

  @override
  String get recordsBestsTitle => '等你超越的星星分數';

  @override
  String get recordsSectionMain => '主要遊戲';

  @override
  String get recordsSectionMini => '小遊戲';

  @override
  String get recordsEndless => '無盡模式 · 點擊飛行';

  @override
  String get recordsCampaignStars => '故事模式星星';

  @override
  String recordsCoopName(String mode) {
    return '一起飛 · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '趟計分飛行',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '道門',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '次一起飛',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '場對決',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '下伏地挺身',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '下深蹲',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => '最近的飛行';

  @override
  String get recordsEmptyTitle => '天空很大，一切從零開始。';

  @override
  String get recordsEmptyBody => '你的第一趟計分飛行，將揭開故事的序幕。';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds 秒';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return '經典 · $date · $seconds 秒';
  }

  @override
  String get replaySavedSessions => '已存的飛行';

  @override
  String get replayBackToRecordsSemantics => '回到紀錄';

  @override
  String get replaySessionsLoadFailed => '無法載入已存的飛行。重試';

  @override
  String get replayEmptyTitle => '你的飛行都會放在這裡';

  @override
  String get replayEmptyBody => '飛行結束後點「儲存飛行」，就能在這裡觀看。';

  @override
  String get replayEmptyButton => '選一趟飛行';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds 秒 · $score 星星分',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds 秒 · $score 道門',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => '刪除飛行';

  @override
  String get replayDeleteTitle => '要刪除這趟飛行嗎？';

  @override
  String get replayDeleteBody => '鏡頭影片和重播會被刪除。你的分數仍會留在「紀錄」裡。';

  @override
  String get replayDeleteFailed => '無法刪除這趟飛行。請再試一次。';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return '第 $id 關';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · 無盡模式';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · 練習';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · 無盡模式 · 練習';
  }

  @override
  String get replayOpenFailed => '無法開啟這趟飛行。';

  @override
  String get replayBackToSessions => '回到已存的飛行';

  @override
  String get replayCameraPaused => '這段飛行期間，鏡頭暫停了';

  @override
  String get replayCameraUnavailable => '無法播放鏡頭片段 · 遊戲畫面照常播放';

  @override
  String get replayCameraLoading => '正在載入鏡頭畫面……';

  @override
  String get replayPaused => '正在喘口氣';

  @override
  String get replayHideControlsSemantics => '隱藏重播控制項';

  @override
  String get replayShowControlsSemantics => '顯示重播控制項';

  @override
  String get replayBackToSavedSemantics => '回到已存的飛行';

  @override
  String get replayTitle => '重播';

  @override
  String replayTitleSession(String session) {
    return '重播 · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return '分數：$score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts 顆愛心',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return '愛心 P1 $p1 · P2 $p2 · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String replayMagnet(int seconds) {
    return '磁鐵 · $seconds秒';
  }

  @override
  String get replayPauseSemantics => '暫停重播';

  @override
  String get replayPlaySemantics => '播放重播';

  @override
  String get replayRestartSemantics => '從頭重播';

  @override
  String get replayBack5Semantics => '倒退 5 秒';

  @override
  String get replayForward5Semantics => '快轉 5 秒';

  @override
  String get replayHighlightsFinding => '正在尋找飛行精彩片段';

  @override
  String get replayHighlightsNone => '沒有飛行精彩片段';

  @override
  String get replayHighlights => '飛行精彩片段';

  @override
  String get replayHighlightsCloseSemantics => '關閉精彩片段';

  @override
  String get replayHighlightsHint => '選一個時刻，從它發生前一點點開始看。';

  @override
  String get replayViewCorner => '角落鏡頭';

  @override
  String get replayViewBackground => '鏡頭當背景';

  @override
  String get replayViewGameplay => '只看遊戲畫面';

  @override
  String get replayMoveCornerSemantics => '移動鏡頭小視窗';

  @override
  String get replayMuteRecordedSemantics => '靜音錄下的聲音';

  @override
  String get replayUnmuteRecordedSemantics => '開啟錄下的聲音';

  @override
  String get replayMuteGameSemantics => '靜音遊戲音效';

  @override
  String get replayUnmuteGameSemantics => '開啟遊戲音效';

  @override
  String get replayFullScreenSemantics => '隱藏控制項／全螢幕';

  @override
  String get replayMomentTakeoff => '起飛';

  @override
  String get replayMomentTakeoffDetail => '天空是你的。';

  @override
  String get replayMomentMagnet => '星星磁鐵';

  @override
  String get replayMomentMagnetDetail => '三次完美穿越，讓星星靠過來。';

  @override
  String get replayMomentStarTrio => '第一個三星組';

  @override
  String get replayMomentStarTrioDetail => '三顆星星連成星座。+5 分！';

  @override
  String get replayMomentStarTrioSubtleDetail => '這組星星全部收集到了。+5 分！';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier× 星星倍率';
  }

  @override
  String get replayMomentStreakDetail => '一串閃閃發亮的星星連擊。';

  @override
  String get replayMomentShield => '護盾擋下';

  @override
  String get replayMomentShieldDetail => '好險，又多一次機會。';

  @override
  String get replayMomentPerfect => '第一次完美穿越';

  @override
  String get replayMomentPerfectDetail => '正好穿過準心。';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '通過 $count 道門',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => '又往天空深處飛了一點。';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '毫髮無傷。+$points 分！',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '衝刺環帶你脫險。+$points 分！',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => '撐過狂風';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '躲過了飛來的雜物。+$points 分！',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => '航線完成';

  @override
  String get replayMomentFinal => '最後一刻';

  @override
  String get replayMomentCompleteDetail => '你飛到了航線的終點。';

  @override
  String get replayMomentCollisionDetail => '看看最後的那段飛行。';

  @override
  String get replayMomentEndDetail => '這趟飛行的終點。';

  @override
  String get welcomeTitle => '選擇你的語言';

  @override
  String get welcomeContinue => '起飛囉！';

  @override
  String get welcomeHint => '之後隨時可以在設定中更改。';

  @override
  String get welcomeDevice => '手機的語言';

  @override
  String get tutorialTitle => '飛行學校';

  @override
  String get tutorialSkip => '跳過課程';

  @override
  String get tutorialSkipTitle => '要跳過飛行學校嗎？';

  @override
  String get tutorialSkipBody => '你隨時可以在設定中重新上這堂課。';

  @override
  String get tutorialSkipConfirm => '跳過';

  @override
  String get tutorialSkipCancel => '繼續學習';

  @override
  String get tutorialRestart => '重新開始';

  @override
  String get tutorialGoalFlaps => '拍翅';

  @override
  String get tutorialGoalStars => '收集星星';

  @override
  String get tutorialGoalGates => '穿過門';

  @override
  String get tutorialGoalBats => '打暈蝙蝠';

  @override
  String get tutorialGoalDoor => '打碎石門';

  @override
  String get tutorialGoalSprint => '衝刺';

  @override
  String get tutorialGoalBoss => '打敗船長';

  @override
  String get tutorialPromptTap => '點一下！';

  @override
  String get tutorialPromptShoot => '點射擊';

  @override
  String get tutorialPromptHoldShoot => '按住射擊';

  @override
  String get tutorialPromptSprint => '點衝刺';

  @override
  String get tutorialPraiseNice => '不錯！';

  @override
  String get tutorialPraiseGreat => '很棒！';

  @override
  String get tutorialPraiseSuper => '太厲害了！';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return '課程正在等你：$prompt';
  }

  @override
  String get licenceTitle => '郵差執照';

  @override
  String get licenceIssuer => '天空俱樂部郵局';

  @override
  String get licenceHolder => '郵差';

  @override
  String get licenceRank => '等級';

  @override
  String get licenceRankRookie => '菜鳥郵差';

  @override
  String get licenceSkills => '技能';

  @override
  String get licenceStamp => '認證';

  @override
  String licenceSignedBy(String name) {
    return '簽名：$name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 顆星',
      one: '1 顆星',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => '出發送第一趟信！';

  @override
  String get licenceAgain => '再飛一次';

  @override
  String get settingsTutorial => '飛行學校';

  @override
  String get settingsTutorialDetail => '重新上第一堂課';
}
