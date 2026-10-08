// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
}

/// The translations for Spanish Castilian, as used in Latin America and the Caribbean (`es_419`).
class AppLocalizationsEs419 extends AppLocalizationsEs {
  AppLocalizationsEs419() : super('es_419');

  @override
  String get commonTryAgain => 'Reintentar';

  @override
  String get languageKeyLabel => 'Idioma';

  @override
  String languageKeySemantics(String language) {
    return 'Idioma: $language. Cambia el idioma del juego.';
  }

  @override
  String get languageSystemDefault => 'Idioma del teléfono';

  @override
  String languageSystemDetail(String language) {
    return 'Como tu teléfono: $language';
  }

  @override
  String get languageCurrent => 'Idioma actual';

  @override
  String get languageName_en => 'Inglés';

  @override
  String get languageName_es_419 => 'Español (Latinoamérica)';

  @override
  String get languageName_pt_br => 'Portugués (Brasil)';

  @override
  String get languageName_id => 'Indonesio';

  @override
  String get languageName_fr => 'Francés';

  @override
  String get languageName_de => 'Alemán';

  @override
  String get languageName_ja => 'Japonés';

  @override
  String get languageName_ko => 'Coreano';

  @override
  String get languageName_tr => 'Turco';

  @override
  String get languageName_zh_hant => 'Chino tradicional';

  @override
  String get languageName_ru => 'Ruso';

  @override
  String get languageName_ar => 'Árabe';

  @override
  String get voicePackReady => 'Voces listas';

  @override
  String get voicePackDownload => 'Descargar voces';

  @override
  String voicePackDownloading(int percent) {
    return 'Voces $percent%';
  }

  @override
  String get voicePackStarting => 'Preparando voces';

  @override
  String get voicePackEnglish => 'Voces en inglés';

  @override
  String get voicePackFailed => 'Error de voces';

  @override
  String get settingsTitle => 'Estás en tu casa.';

  @override
  String get settingsSectionSound => 'Sonido';

  @override
  String get settingsSectionComfort => 'Comodidad';

  @override
  String get settingsMusicTitle => 'Música del Club';

  @override
  String get settingsMusicDetail => 'Temas del menú, la aventura y los jefes.';

  @override
  String get settingsEffectsTitle => 'Efectos de sonido';

  @override
  String get settingsEffectsDetail =>
      'Vuelo, combate, objetos y sonidos del menú.';

  @override
  String get settingsVoicesTitle => 'Voces de los personajes';

  @override
  String get settingsVoicesDetail =>
      'Historia, agradecimientos y gritos de turbo.';

  @override
  String get settingsReducedMotionTitle => 'Reducir movimiento';

  @override
  String get settingsReducedMotionDetail =>
      'Menús más calmados y menos adornos.';

  @override
  String get settingsSwitchOn => 'SÍ';

  @override
  String get settingsSwitchOff => 'NO';

  @override
  String get settingsUnavailable => 'Tus ajustes necesitan un momento.';

  @override
  String get settingsPrivacyKicker => 'SOLO EN TU TELÉFONO.';

  @override
  String get settingsPrivacyTitle => 'Tu cámara es solo tuya.';

  @override
  String get settingsPrivacyBody =>
      'El video y el audio opcional del micrófono no salen de este teléfono. Lo no guardado se borra. Nada se sube.';

  @override
  String get settingsCameraLab => 'Laboratorio de cámara';

  @override
  String get settingsAbout => 'Info y licencias';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'Información y licencias, versión $version';
  }

  @override
  String get settingsReset => 'Borrar progreso local';

  @override
  String settingsResetDone(String bird) {
    return 'Borrón y cuenta nueva. $bird te espera.';
  }

  @override
  String get settingsResetTitle => '¿Empezar una nueva aventura?';

  @override
  String get settingsResetBody =>
      'Esto borra de este teléfono tus videos guardados, repeticiones, puntajes, partidas, niveles creados y ajustes. No se puede deshacer.';

  @override
  String get settingsResetBodyCloud =>
      'Esto borra de este teléfono tus videos guardados, repeticiones, puntajes, partidas, niveles creados y ajustes, y tu partida en la nube de Play Juegos. No se puede deshacer.';

  @override
  String get settingsResetConfirm => 'Borrar todo';

  @override
  String get settingsResetKeep => 'Mantener mi progreso';

  @override
  String get playGamesName => 'Play Juegos';

  @override
  String get playGamesConnected => 'Conectado';

  @override
  String get playGamesNotConnected => 'Sin conectar';

  @override
  String get playGamesConnecting => 'Conectando…';

  @override
  String get playGamesConnectFailed => 'No se pudo conectar';

  @override
  String get playGamesIdle => 'Guardado en la nube y logros';

  @override
  String get playGamesSaving => 'Guardando en la nube…';

  @override
  String get playGamesOfflineUnsaved => 'Sin red · aún sin guardar';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'Sin red · guardado hace $ago';
  }

  @override
  String get playGamesUpdateNeeded => 'Actualiza para sincronizar';

  @override
  String get playGamesUnreadable => 'No se puede leer la nube';

  @override
  String get playGamesOn => 'Guardado en la nube activo';

  @override
  String get playGamesResetElsewhere => 'Borrado en otro teléfono';

  @override
  String playGamesRestored(String ago) {
    return 'Nube recuperada hace $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'Guardado en la nube hace $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Logros de Play Juegos';

  @override
  String get playGamesConnectSemantics => 'Conectar Play Juegos';

  @override
  String get playGamesAchievements => 'Logros';

  @override
  String get playGamesConnect => 'Conectar';

  @override
  String get timeAgoJustNow => 'un momento';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours h',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '$days día',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '¡+1 VIDA!';

  @override
  String calloutStarTrio(int points) {
    return '¡TRÍO +$points!';
  }

  @override
  String get calloutNiceShot => '¡BUEN TIRO!';

  @override
  String calloutNiceShotPoints(int points) {
    return '¡BUEN TIRO +$points!';
  }

  @override
  String get calloutSmash => '¡ZAS!';

  @override
  String calloutSmashPoints(int points) {
    return '¡ZAS +$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return '¡ZAS ×$count!';
  }

  @override
  String get calloutBossDown => '¡JEFE VENCIDO!';

  @override
  String calloutBossDownPoints(int points) {
    return '¡JEFE KO +$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return 'PODER ESTELAR $multiplier×';
  }

  @override
  String get calloutPerfect => '¡PERFECTO!';

  @override
  String calloutPerfectChain(int count) {
    return 'PERFECTO ×$count';
  }

  @override
  String get calloutShieldReady => 'ESCUDO LISTO';

  @override
  String get calloutShieldSave => '¡BLOQUEO!';

  @override
  String get calloutKeepFlying => '¡TÚ PUEDES!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡$count PUERTAS!',
      one: '¡$count PUERTA!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '¡QUEDAN $seconds SEG!',
      one: '¡QUEDA $seconds SEG!',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => '¡IMÁN ESTELAR!';

  @override
  String get calloutSprintRing => '¡ARO TURBO!';

  @override
  String calloutRushChain(int count) {
    return '¡AROS ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return '¡METEORO +$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return '¡MURCI +$points!';
  }

  @override
  String get calloutScorched => '¡AY, QUEMA!';

  @override
  String get region_jungle => 'Selva';

  @override
  String get region_antarctica => 'Antártida';

  @override
  String get region_aztec => 'Azteca';

  @override
  String get region_paris => 'París';

  @override
  String get region_egypt => 'Egipto';

  @override
  String get region_cyberpunk => 'Ciudad Cyberpunk';

  @override
  String get region_china => 'China';

  @override
  String get region_brazil => 'Brasil';

  @override
  String get region_newYork => 'Nueva York';

  @override
  String get region_arabia => 'Antigua Arabia';

  @override
  String get region_rome => 'Antigua Roma';

  @override
  String get region_mexico => 'México';

  @override
  String get region_sea => 'Mar abierto';

  @override
  String get boss_baronBat_name => 'Barón Murciélago';

  @override
  String get boss_spitterBeetle_name => 'Rey Escupidor';

  @override
  String get boss_duskMoth_name => 'Emperatriz del Ocaso';

  @override
  String get boss_pirate_name => 'Capitán Pirata';

  @override
  String get boss_dragon_name => 'Dragón de las Brasas';

  @override
  String get boss_kingCoo_name => 'Rey Currucú';

  @override
  String get boss_searchlightGargoyle_name => 'Gárgola del Reflector';

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
  String get playMode_pushUp => 'Vuelo de flexiones';

  @override
  String get playMode_jump => 'Salta y vuela';

  @override
  String get playMode_touch => 'Toca y vuela';

  @override
  String get playMode_squat => 'Sentadilla y vuela';

  @override
  String get chapter_1_route => 'La Ruta de la Selva';

  @override
  String get chapter_1_postmark => 'RUTA DE LA SELVA';

  @override
  String get chapter_1_postcard =>
      '¡Las cartas vuelven a llegar a las copas de los árboles! Los tucanes te dan las gracias (a gritos). La corona del Barón está en nuestra repisa.';

  @override
  String get chapter_1_postscript =>
      'En el Camino Antiguo huele a que algo burbujea.';

  @override
  String get chapter_2_route => 'El Camino Antiguo';

  @override
  String get chapter_2_postmark => 'CAMINO ANTIGUO';

  @override
  String get chapter_2_postcard =>
      'Las caravanas avanzan y lo único que se cocina es té de menta. Usamos la corona de matraces del Rey como florero.';

  @override
  String get chapter_2_postscript =>
      'Anoche se apagaron los faroles de la ciudad. Trae una luz.';

  @override
  String get chapter_3_route => 'La Línea de los Faroles';

  @override
  String get chapter_3_postmark => 'LÍNEA DE LOS FAROLES';

  @override
  String get chapter_3_postcard =>
      '¡Los faroles están encendidos y el correo nocturno, bien despierto! París te manda un cruasán. Nueva York, un pretzel.';

  @override
  String get chapter_3_postscript =>
      'Las campanas del puerto dejaron de sonar.';

  @override
  String get chapter_4_route => 'La Ruta de la Marea';

  @override
  String get chapter_4_postmark => 'RUTA DE LA MAREA';

  @override
  String get chapter_4_postcard =>
      'Las campanas del puerto vuelven a sonar por las cartas, no por los cañones. El loro se quedó. Te manda saludos.';

  @override
  String get chapter_4_postscript =>
      'Dicen que el cielo del borde del mapa está en llamas.';

  @override
  String get chapter_5_route => 'El Borde del Mapa';

  @override
  String get chapter_5_postmark => 'BORDE DEL MAPA';

  @override
  String get chapter_5_postcard =>
      'El cielo está despejado de polo a polo y todas las rutas funcionan. Todo el Club del Cielo está orgulloso de ti.';

  @override
  String get chapter_5_postscript =>
      'El cielo infinito sigue ahí, para cuando quieras volver.';

  @override
  String get level_1_1_name => 'Primera entrega';

  @override
  String get level_1_1_cargo =>
      'Una tarjeta de cumpleaños para los tucanes gemelos';

  @override
  String get level_1_1_sender => 'Los tucanes gemelos';

  @override
  String get level_1_1_hint =>
      'Toca para aletear. Vuela a través de las estrellas.';

  @override
  String get level_1_2_name => 'Racha de estrellas';

  @override
  String get level_1_2_cargo => 'Cartas estelares para el perezoso astrónomo';

  @override
  String get level_1_2_sender => 'El perezoso astrónomo';

  @override
  String get level_1_2_hint =>
      'Encadena estrellas para 3×; tres puertas perfectas te dan un imán.';

  @override
  String get level_1_3_name => 'Patrulla de murciélagos';

  @override
  String get level_1_3_cargo => 'Lamparitas para la guardería de luciérnagas';

  @override
  String get level_1_3_sender => 'La guardería de luciérnagas';

  @override
  String get level_1_3_hint =>
      'Disparar: toca Disparar para noquear a los murciélagos.';

  @override
  String get level_1_4_name => 'Cielos de carnaval';

  @override
  String get level_1_4_cargo => 'Boas de plumas para el desfile de carnaval';

  @override
  String get level_1_4_sender => 'Las guacamayas sambistas';

  @override
  String get level_1_4_hint =>
      '¡Vendaval! Fíjate en el ! y esquiva los balones.';

  @override
  String get level_1_5_name => 'Correo exprés';

  @override
  String get level_1_5_cargo =>
      'Una invitación urgente para el maestro de tambores';

  @override
  String get level_1_5_sender => 'El maestro de tambores';

  @override
  String get level_1_5_hint =>
      'El Turbo arrasa con los murciélagos y te lanza hacia adelante.';

  @override
  String get level_1_6_name => 'Escalones del templo';

  @override
  String get level_1_6_cargo => 'Granos de cacao para los cocineros del templo';

  @override
  String get level_1_6_sender => 'Los cocineros del templo';

  @override
  String get level_1_7_name => 'Percha del amanecer';

  @override
  String get level_1_7_cargo => 'Un reloj de sol para el cuidador del alba';

  @override
  String get level_1_7_sender => 'El cuidador del alba';

  @override
  String get level_1_8_name => 'Barón Murciélago';

  @override
  String get level_1_8_cargo => 'Un último aviso para el Barón Murciélago';

  @override
  String get level_1_8_sender => 'Barón Murciélago';

  @override
  String get level_2_1_name => 'Camino de escarabajos';

  @override
  String get level_2_1_cargo =>
      'Coronas de laurel para los corredores de cuadrigas';

  @override
  String get level_2_1_sender => 'Los corredores de cuadrigas';

  @override
  String get level_2_1_hint =>
      'Los escarabajos escupen semillas. Derríbalas con Disparar.';

  @override
  String get level_2_2_name => 'Puertas selladas';

  @override
  String get level_2_2_cargo => 'Un cincel nuevo para el escultor';

  @override
  String get level_2_2_sender => 'El escultor';

  @override
  String get level_2_2_hint =>
      'Mantén Disparar para lanzar una piedra grande que rompe la piedra.';

  @override
  String get level_2_3_name => 'Carrera del incendio';

  @override
  String get level_2_3_cargo => 'Cubetas de agua para los bomberos';

  @override
  String get level_2_3_sender => 'Los bomberos';

  @override
  String get level_2_3_hint =>
      '¡Pasa por los aros dorados para dejar atrás el fuego!';

  @override
  String get level_2_4_name => 'Zigzag del Nilo';

  @override
  String get level_2_4_cargo => 'Un libro de acertijos nuevos para la Esfinge';

  @override
  String get level_2_4_sender => 'La Esfinge';

  @override
  String get level_2_5_name => 'Cae el cielo';

  @override
  String get level_2_5_cargo =>
      'Un telescopio para el astrónomo de la pirámide';

  @override
  String get level_2_5_sender => 'El astrónomo de la pirámide';

  @override
  String get level_2_5_hint => 'El turbo de aro destroza meteoros.';

  @override
  String get level_2_6_name => 'Devuélvase al remitente';

  @override
  String get level_2_6_cargo => 'Un plumero para la cuidadora';

  @override
  String get level_2_6_sender => 'La cuidadora de la pirámide';

  @override
  String get level_2_6_hint =>
      'Dispara a sus cartas para devolverlas. ¡Devuélvase al remitente!';

  @override
  String get level_2_7_name => 'Bazar de los faroles';

  @override
  String get level_2_7_cargo => 'Aceite para los vendedores de faroles';

  @override
  String get level_2_7_sender => 'Los vendedores de faroles';

  @override
  String get level_2_8_name => 'La larga caravana';

  @override
  String get level_2_8_cargo => 'Cantimploras para la larga caravana';

  @override
  String get level_2_8_sender => 'El jefe de la caravana';

  @override
  String get level_2_9_name => 'Rey Escupidor';

  @override
  String get level_2_9_cargo =>
      'Una orden de dejar de cocinar para el Rey Escupidor';

  @override
  String get level_2_9_sender => 'Rey Escupidor';

  @override
  String get level_3_1_name => 'Luz de polillas';

  @override
  String get level_3_1_cargo => 'Focos para la marquesina del teatro';

  @override
  String get level_3_1_sender => 'El director de escena';

  @override
  String get level_3_1_hint =>
      'Las polillas lanzan abanicos de tres. Cuélate entre ellos.';

  @override
  String get level_3_2_name => 'Ruedas bajo la lluvia';

  @override
  String get level_3_2_cargo => 'Paraguas para las palomas del quiosco';

  @override
  String get level_3_2_sender => 'Las palomas del quiosco';

  @override
  String get level_3_2_hint =>
      'Las palomas de callejón bajan a robar estrellas. ¡Dispárales primero!';

  @override
  String get level_3_3_name => 'Callejón del Vapor';

  @override
  String get level_3_3_cargo =>
      'Pretzels calientes para los taxistas nocturnos';

  @override
  String get level_3_3_sender => 'Los taxistas nocturnos';

  @override
  String get level_3_3_hint =>
      'Los géiseres silban y luego estallan. Salta los calientes, súbete a los suaves.';

  @override
  String get level_3_4_name => 'Alerta de tormenta';

  @override
  String get level_3_4_cargo => 'Una veleta para la torre más alta';

  @override
  String get level_3_4_sender => 'El cuidador de la torre';

  @override
  String get level_3_4_hint =>
      'No entres en la luz. ¡Dispara a la lámpara cuando se abra! Aquí no hay Turbo.';

  @override
  String get level_3_5_name => 'Tejados de cristal';

  @override
  String get level_3_5_cargo => 'Cruasanes para los pintores de los tejados';

  @override
  String get level_3_5_sender => 'Los pintores de los tejados';

  @override
  String get level_3_6_name => 'Tras el vendaval';

  @override
  String get level_3_6_cargo => 'Partituras para el acordeonista';

  @override
  String get level_3_6_sender => 'El acordeonista';

  @override
  String get level_3_6_hint =>
      '¡Vendaval! Fíjate en el ! y ve por el lado libre.';

  @override
  String get level_3_7_name => 'Expreso de medianoche';

  @override
  String get level_3_7_cargo =>
      'Una carta de amor de medianoche para la panadera';

  @override
  String get level_3_7_sender => 'La panadera';

  @override
  String get level_3_7_hint => 'Atraviesa las bandadas con el Turbo.';

  @override
  String get level_3_8_name => 'Emperatriz del Ocaso';

  @override
  String get level_3_8_cargo =>
      'Una llamada de atención a la Emperatriz del Ocaso';

  @override
  String get level_3_8_sender => 'Emperatriz del Ocaso';

  @override
  String get level_4_1_name => 'Luces del puerto';

  @override
  String get level_4_1_cargo => 'Un lente nuevo para la guardafaros';

  @override
  String get level_4_1_sender => 'La guardafaros';

  @override
  String get level_4_2_name => 'Paso del volcán';

  @override
  String get level_4_2_cargo =>
      'Guantes de cocina para la pastelera del volcán';

  @override
  String get level_4_2_sender => 'La pastelera del volcán';

  @override
  String get level_4_2_hint => 'Salta sobre los chorros de lava.';

  @override
  String get level_4_3_name => 'Costa abajo';

  @override
  String get level_4_3_cargo => 'Hilo de cometa para el festival de playa';

  @override
  String get level_4_3_sender => 'Los voladores de cometas';

  @override
  String get level_4_4_name => 'Marea baja';

  @override
  String get level_4_4_cargo => 'Una respuesta para el ermitaño de la isla';

  @override
  String get level_4_4_sender => 'El ermitaño de la isla';

  @override
  String get level_4_4_hint => 'No toques el agua.';

  @override
  String get level_4_5_name => 'Marea viva';

  @override
  String get level_4_5_cargo =>
      'Una tabla de mareas para la tripulación del ferry';

  @override
  String get level_4_5_sender => 'La tripulación del ferry';

  @override
  String get level_4_5_hint => 'Cuando suene la campana, vuela alto.';

  @override
  String get level_4_6_name => 'Bahía de las Andanadas';

  @override
  String get level_4_6_cargo =>
      'Galletas de pescado para la colonia de gaviotas';

  @override
  String get level_4_6_sender => 'La colonia de gaviotas';

  @override
  String get level_4_7_name => 'Travesía tormentosa';

  @override
  String get level_4_7_cargo =>
      'Calcetines secos para los marineros de guardia';

  @override
  String get level_4_7_sender => 'La guardia de tormentas';

  @override
  String get level_4_8_name => 'Capitán Pirata';

  @override
  String get level_4_8_cargo =>
      'Una orden de devolver el correo para el Capitán';

  @override
  String get level_4_8_sender => 'Capitán Pirata';

  @override
  String get level_5_1_name => 'Correo de la aurora';

  @override
  String get level_5_1_cargo => 'Gorros de lana para el coro de pingüinos';

  @override
  String get level_5_1_sender => 'El coro de pingüinos';

  @override
  String get level_5_1_hint =>
      'Ahora puede venir cualquier carrera. ¡Lee el cartel!';

  @override
  String get level_5_2_name => 'Noche polar';

  @override
  String get level_5_2_cargo => 'Chocolate caliente para la estación polar';

  @override
  String get level_5_2_sender => 'La estación polar';

  @override
  String get level_5_3_name => 'Expreso de neón';

  @override
  String get level_5_3_cargo =>
      'Fusibles de repuesto para el letrero de fideos';

  @override
  String get level_5_3_sender => 'El cocinero de fideos';

  @override
  String get level_5_4_name => 'Tormenta de datos';

  @override
  String get level_5_4_cargo => 'Una carta de papel para un robot curioso';

  @override
  String get level_5_4_sender => 'Unidad 7';

  @override
  String get level_5_5_name => 'Turbo entre rascacielos';

  @override
  String get level_5_5_cargo => 'Boletos para los corredores de las azoteas';

  @override
  String get level_5_5_sender => 'Los corredores de las azoteas';

  @override
  String get level_5_6_name => 'Festival de los Faroles';

  @override
  String get level_5_6_cargo => 'Faroles de papel para el festival';

  @override
  String get level_5_6_sender => 'Los fabricantes de faroles';

  @override
  String get level_5_7_name => 'La recta final';

  @override
  String get level_5_7_cargo => 'Té de montaña para el monasterio';

  @override
  String get level_5_7_sender => 'Los monjes de la montaña';

  @override
  String get level_5_8_name => 'Dragón de las Brasas';

  @override
  String get level_5_8_cargo => 'La primera carta enviada al Dragón';

  @override
  String get level_5_8_sender => 'Dragón de las Brasas';

  @override
  String get storyPostmasterName => 'Jefe de correos Bill';

  @override
  String get storySkip => 'Saltar';

  @override
  String get storyNextLineSemantics => 'Siguiente';

  @override
  String get storyFinishSemantics => 'Terminar';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => 'Toda carta llega.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => '¡Vuela!';

  @override
  String levelIntroRunUp(int seconds) {
    return '$seconds s de carrera previa';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'Unos $seconds s hasta la meta';
  }

  @override
  String get campaignGuardian => 'GUARDIÁN';

  @override
  String get levelIntroBossFight => 'JEFE FINAL';

  @override
  String get levelIntroNew => 'NUEVO';

  @override
  String get levelIntroTip => 'CONSEJO';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Vence al $boss',
      'spitterBeetle': 'Vence al $boss',
      'duskMoth': 'Vence a la $boss',
      'pirate': 'Vence al $boss',
      'dragon': 'Vence al $boss',
      'kingCoo': 'Vence al $boss',
      'searchlightGargoyle': 'Vence a la $boss',
      'other': 'Vence a $boss',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroGoalFinish => 'Llega a la meta';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reúne $count estrellas',
      one: 'Reúne 1 estrella',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Una estrella: $goal.',
      'two': 'Dos estrellas: $goal.',
      'other': 'Tres estrellas: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Una estrella: $goal. Conseguida.',
      'two': 'Dos estrellas: $goal. Conseguidas.',
      'other': 'Tres estrellas: $goal. Conseguidas.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Récord: $count estrellas',
      one: 'Récord: 1 estrella',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'Aún sin entregar';

  @override
  String get levelIntroFirstFlight => 'Primer vuelo';

  @override
  String get levelIntroControlFlap => 'Aletear';

  @override
  String get levelIntroControlShoot => 'Disparar';

  @override
  String get levelIntroControlSprint => 'Turbo';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Controles: Aletear.',
      'shoot': 'Controles: Aletear, Disparar.',
      'sprint': 'Controles: Aletear, Turbo.',
      'other': 'Controles: Aletear, Disparar, Turbo.',
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
    return 'Nivel $level, $name. $region.';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return 'Nivel $level, $name. $region. Nivel con guardián: $boss.';
  }

  @override
  String get levelIntroStory => 'Historia';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonHome => 'Inicio';

  @override
  String get commonBackHome => 'Ir al inicio';

  @override
  String get campaignComingSoon => 'Próximamente';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — próximamente';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Vence al $boss para desbloquear',
      'spitterBeetle': 'Vence al $boss para desbloquear',
      'duskMoth': 'Vence a la $boss para desbloquear',
      'pirate': 'Vence al $boss para desbloquear',
      'dragon': 'Vence al $boss para desbloquear',
      'kingCoo': 'Vence al $boss para desbloquear',
      'searchlightGargoyle': 'Vence a la $boss para desbloquear',
      'other': 'Vence a $boss para desbloquear',
    });
    return '$_temp0';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'Termina el $level para desbloquear';
  }

  @override
  String get campaignMapUnavailable => 'El mapa necesita un momento.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return 'Cerrar $name';
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
      'soon': '$region. Capítulo $chapter, $route. Próximamente.',
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
      'boss': '$level, $name, jefe',
      'guardian': 'Nivel $level, $name, guardián: $boss',
      'other': 'Nivel $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. Bloqueado.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. Bloqueado. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars de 3 estrellas',
    );
    return '$node. Siguiente. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars de 3 estrellas',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'Gárgola',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return 'Postal del capítulo $chapter';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars de $total estrellas de la campaña',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'Hola, ave mensajera:';

  @override
  String get campaignPostcardPs => 'P. D.';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'Postal de $route. Hola, ave mensajera: $body P. D.: $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'Saludos desde';

  @override
  String get campaignPostcardHeader => 'POSTAL DEL CLUB DEL CIELO';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'Ave mensajera';

  @override
  String get campaignPostcardAddressStreet => 'Club del Cielo';

  @override
  String get campaignPostcardAddressCity => 'Allá en el cielo';

  @override
  String get campaignPostmarkDelivered => 'ENTREGADO';

  @override
  String get campaignPostmarkClub => 'CLUB DEL CIELO';

  @override
  String get campaignStampSkyClub => 'CLUB CIELO';

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
    return 'Nota de agradecimiento de $sender: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'Un poco de preparación. Mucho cielo.';

  @override
  String get flightSetupTitleSquat => 'Pies firmes. Alas abiertas.';

  @override
  String get flightSetupTitleJump => 'Saltos pequeños. Alas grandes.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'NIVEL · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · CON PUNTAJE';
  }

  @override
  String get flightSetupRoomPushUp => 'Haz un poco de espacio para moverte.';

  @override
  String get flightSetupRoomBody => 'Muestra todo tu cuerpo.';

  @override
  String get flightSetupTipsPushUp =>
      'Teléfono abajo. Muestra un brazo y la cadera.\n¿De frente? Deja ambos hombros a la vista.';

  @override
  String get flightSetupTipsSquat =>
      'Agáchate para bajar. Párate para subir.\nMantén los dos pies en el suelo.';

  @override
  String get flightSetupTipsJump =>
      'Salta para impulsarte + 3 s de planeo.\nAterriza antes de volver a saltar.';

  @override
  String get flightSetupHowToFly => 'CÓMO VOLAR';

  @override
  String get flightSetupStep1PushUp => 'Muestra tu brazo y tu cadera';

  @override
  String get flightSetupStep1Squat => 'Haz espacio para agacharte';

  @override
  String get flightSetupStep1Jump => 'Haz espacio para saltar';

  @override
  String get flightSetupStep1DetailPushUp =>
      '¿De frente al teléfono? Muestra ambos hombros, un brazo y una cadera.';

  @override
  String get flightSetupStep1DetailBody =>
      'Teléfono en horizontal. Muestra tu cuerpo y ambos pies.';

  @override
  String get flightSetupStep2PushUp => 'Encuentra tu recorrido';

  @override
  String get flightSetupStep2Squat => 'Encuentra tu sentadilla cómoda';

  @override
  String get flightSetupStep2Jump => 'Ponte de pie, sin moverte';

  @override
  String get flightSetupStep2DetailPushUp =>
      'Busca una altura cómoda arriba y luego baja y sube dos veces.';

  @override
  String get flightSetupStep2DetailSquat =>
      'Sin moverte, agáchate, aguanta un momento y vuelve a pararte.';

  @override
  String get flightSetupStep2DetailJump =>
      'No te muevas un momento. Luego salta para un gran impulso.';

  @override
  String get flightSetupStep3Stars => 'Reúne estrellas';

  @override
  String get flightSetupStep3DetailJump =>
      'Cada estrella suma 0.75 s de planeo, hasta 5 s. Reúne tríos para +5 puntos.';

  @override
  String get flightSetupLivesEndless =>
      'Tres corazones + un escudo. Puedes pausar cuando quieras.';

  @override
  String get flightSetupLivesClassic =>
      'Un choque o perder tu posición termina un vuelo con puntaje. Puedes pausar cuando quieras.';

  @override
  String get flightSetupCameraButton => 'Preparar mi cámara';

  @override
  String get flightMicTitle => 'Grabar micrófono';

  @override
  String get flightMicOn => 'Activado';

  @override
  String get flightMicOptional => 'Opcional';

  @override
  String get flightMicDetail =>
      'Agrega tu voz y el sonido del lugar a las repeticiones. Usa el micrófono solo durante el vuelo. Se guarda en este teléfono.';

  @override
  String get flightMicSemantics => 'Grabar micrófono para las repeticiones';

  @override
  String get flightMicSettings => 'Permiso del micrófono';

  @override
  String get flightCalibrationTitleReady => '¡Encontraste tus alas!';

  @override
  String get flightCalibrationTitleWaking => 'Despertando tu cámara…';

  @override
  String get flightCalibrationTitleError => 'Volvamos a conectar tu cámara.';

  @override
  String get flightCalibrationTitleRange => 'Encuentra tu recorrido.';

  @override
  String get flightCalibrationTitleStill => 'Ponte de pie, sin moverte.';

  @override
  String get flightCalibrationStepTry => 'Intenta mover a tu ave.';

  @override
  String get flightCalibrationStepTop => 'Busca una altura cómoda.';

  @override
  String get flightCalibrationStepLower => 'Baja despacio.';

  @override
  String get flightCalibrationStepPushBack => 'Vuelve a subir.';

  @override
  String get flightCalibrationStepStill => 'Ponte de pie, sin moverte.';

  @override
  String get flightCalibrationStepSquat => 'Agáchate con comodidad.';

  @override
  String get flightCalibrationStepStandUp => 'Vuelve a pararte.';

  @override
  String get flightCalibrationStepDone => '¡Encontraste tus alas!';

  @override
  String get flightCalibrationReadyPushUp =>
      'Sube para elevarte. Baja para planear.';

  @override
  String get flightCalibrationReadySquat =>
      'Agáchate para bajar. Párate para subir.';

  @override
  String get flightCalibrationReadyJump =>
      'Salta y descansa mientras tu ave planea.';

  @override
  String get flightCalibrationKeepPushUp =>
      'Deja a la vista los hombros, un brazo y una cadera. Muévete con comodidad.';

  @override
  String get flightCalibrationKeepBody =>
      'Deja a la vista los hombros, la cadera y ambos pies.';

  @override
  String get flightCalibrationLearning =>
      'Aprendiendo tu recorrido al moverte.';

  @override
  String get flightCalibrationAfter => 'Tu ave se mueve tras la calibración.';

  @override
  String get flightCalibrationJump => '¡Salta!';

  @override
  String get flightCalibrationTagCheck => 'PRUEBA DE CONTROL';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '$count / 2 FLEXIONES';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '$percent% CALIBRADO';
  }

  @override
  String get flightCalibrationTakeoff => '¡A despegar!';

  @override
  String get flightCalibrationStarting => 'Iniciando…';

  @override
  String get flightCalibrationRestart => 'Calibrar de nuevo';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate act./s · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate act./s · $p95 ms p95 (solo procesamiento)';
  }

  @override
  String get flightCalibrationStatusReady => 'LISTO';

  @override
  String get flightCalibrationStatusStarting => 'INICIANDO';

  @override
  String get flightCalibrationStatusCameraOff => 'SIN CÁMARA';

  @override
  String get flightCalibrationStatusCalibrating => 'CALIBRANDO';

  @override
  String get flightSwitchCameraSemantics => 'Cambiar de cámara';

  @override
  String get flightCalibrationStepIntoView => 'Ponte frente a la cámara';

  @override
  String get flightCameraTroubleTitle => 'Empezar de nuevo suele ayudar.';

  @override
  String get flightCameraTroubleAllow => 'Permite la cámara en Configuración.';

  @override
  String get flightCameraTroubleClose =>
      'Cierra cualquier otra app de cámara y vuelve a intentarlo.';

  @override
  String get flightCameraPermissionSemantics => 'Permiso de la cámara';

  @override
  String get flightNoteRememberFailed =>
      'Cambiado para este vuelo. No se pudo recordar tu preferencia.';

  @override
  String get flightNoteMicUnavailable =>
      'Micrófono no disponible. El video y el juego siguen funcionando.';

  @override
  String get flightNoteMicBlocked =>
      'Micrófono bloqueado. Puedes permitirlo en la configuración del teléfono; el video sigue funcionando.';

  @override
  String get flightNoteMicOff =>
      'Micrófono apagado. Puedes jugar y guardar el video igual.';

  @override
  String get flightNoteVideoUnavailable =>
      'Video de la cámara no disponible. La partida se puede guardar igual.';

  @override
  String get flightNoteMicAudioLost =>
      'El audio del micrófono no estuvo disponible. Tu video y la partida se pueden guardar igual.';

  @override
  String get flightNoteVideoInterrupted =>
      'Video de la cámara interrumpido. Puedes guardar lo grabado y la partida igual.';

  @override
  String get flightNoteSessionSaveFailed =>
      'No se pudo guardar la sesión. Toca Guardar sesión para reintentar.';

  @override
  String get flightNoteWakingCamera => 'Despertando tu cámara…';

  @override
  String get flightNoteCameraOff =>
      'El acceso a la cámara está apagado. Permítelo en la configuración de Android, vuelve e inténtalo otra vez.';

  @override
  String get flightNoteCameraFailed =>
      'La cámara no pudo iniciar. Vuelve a intentarlo o cambia de cámara.';

  @override
  String get flightNotePreparing => 'Preparando tu sesión…';

  @override
  String get flightNoteSaveFailed =>
      'No se pudo guardar tu vuelo. Toca para reintentar.';

  @override
  String get flightNoteWelcomeBack =>
      'Hola de nuevo. Revisemos otra vez tu posición.';

  @override
  String get flightNoteCameraInterrupted =>
      'Cámara interrumpida. Revisa el permiso de cámara y vuelve a intentarlo.';

  @override
  String get flightNoteTrackingInterrupted => 'Seguimiento interrumpido';

  @override
  String get flightFindPosition => 'Busca tu posición';

  @override
  String get flightTapSemantics => 'Toca para aletear';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'Toca para aletear. $group llegan antes que su jefe';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'Toca para aletear. $boss: $hp de $maxHp de vida';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'Toca para aletear. $boss: $hp de $maxHp de vida. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'Ir a los resultados';

  @override
  String get hudPauseSemantics => 'Pausar el vuelo';

  @override
  String get flightHintTestSteerKeys =>
      'Vuelo de prueba: Arriba y Abajo para dirigir.';

  @override
  String get flightHintTestSteerDrag =>
      'Vuelo de prueba: arrastra arriba y abajo para dirigir.';

  @override
  String get flightHintTestJumpKeys => 'Vuelo de prueba: Espacio para saltar.';

  @override
  String get flightHintTestJumpTap => 'Vuelo de prueba: toca para saltar.';

  @override
  String get flightHintKeysStars =>
      'Espacio para aletear. Vuela a través de las estrellas.';

  @override
  String get flightHintKeysShoot =>
      'Espacio para aletear. Mantén D para cargar un tiro.';

  @override
  String get flightHintKeysCombat =>
      'Espacio para aletear. Mantén D para cargar un tiro. ¡A para el Turbo!';

  @override
  String get flightHintKeysPause => 'Espacio para aletear. Esc para pausar.';

  @override
  String get flightHintTapStars =>
      'Toca el cielo para aletear. Vuela a través de las estrellas.';

  @override
  String get flightHintTapShoot =>
      'Toca el cielo para aletear. Mantén Disparar para cargar.';

  @override
  String get flightHintTapCombat =>
      'Toca el cielo para aletear. Mantén Disparar para cargar. ¡Turbo para arrasar!';

  @override
  String get flightHintTapRelease => 'Toca para aletear. Suelta entre toques.';

  @override
  String get flightHintTrail => 'Sigue las estrellas. Tu escudo está listo.';

  @override
  String get flightHintSky => 'El cielo es tuyo.';

  @override
  String hudClockSemantics(String time) {
    return 'Quedan $time';
  }

  @override
  String flightSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Imán de estrellas: quedan $seconds segundos',
      one: 'Imán de estrellas: queda $seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Imán cargando: $charge de $gates puertas perfectas',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'Buscándote…';

  @override
  String get hudShoot => 'Disparar';

  @override
  String get hudSprint => 'Turbo';

  @override
  String get flightTestNothingSaved => 'no se guarda nada';

  @override
  String get flightCountdownReady => 'En sus marcas, listos…';

  @override
  String get flightPauseTitle => 'Tómate un respiro.';

  @override
  String get flightPauseKeepFlying => 'Seguir volando';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. Tu ave está posada, esperándote.';
  }

  @override
  String flightPausedTest(String name) {
    return 'Vuelo de prueba de $name. No se guarda nada.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. Tu ave está posada, esperándote.';
  }

  @override
  String get flightPausedTouch =>
      'Tu ave está posada, esperándote. Haremos la cuenta regresiva al volver.';

  @override
  String get flightPausedCamera =>
      'Sacúdete un poco y vuelve a tu posición. Haremos la cuenta regresiva.';

  @override
  String get flightPauseEdit => 'Editar';

  @override
  String get flightPauseBuilder => 'Creador';

  @override
  String get flightPauseFinish => 'Terminar vuelo';

  @override
  String get hudShieldRecovering => 'Recuperándose';

  @override
  String get hudShieldReady => 'Escudo listo';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Escudo cargando: $charge de $stars estrellas',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count corazones',
      one: 'Queda $count corazón',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'Turbo activo';

  @override
  String get hudSprintReady => 'Listo';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Recargando, $seconds segundos',
      one: 'Recargando, $seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint =>
      'Acelera para arrasar murciélagos y paneles de piedra';

  @override
  String get hudShotReloading => 'Recargando…';

  @override
  String hudShotFullCharge(int ms) {
    return 'Carga completa, quedan $ms ms';
  }

  @override
  String hudShotCharging(int percent) {
    return 'Cargando $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'Munición $percent%';
  }

  @override
  String get hudShotHint => 'Mantén para cargar una piedra más grande';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas logradas',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas con $at',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars estrellas reunidas',
      one: '$stars estrella reunida',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'MÁX';

  @override
  String hudRouteSemantics(int percent) {
    return 'Ruta recorrida al $percent%';
  }

  @override
  String hudGlideCompact(String time) {
    return 'Planeo · $time';
  }

  @override
  String get hudJumpToGlide => 'Salta y planea';

  @override
  String get hudJump => 'Salta';

  @override
  String hudGlideSemantics(String time) {
    return 'Planeo, quedan $time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'El planeo termina, quedan $time';
  }

  @override
  String get hudJumpChargeSemantics => 'Salta para cargar 3 segundos de planeo';

  @override
  String get hudRecordNewBest => '¡Nuevo récord!';

  @override
  String get hudRecordMatched => '¡Igualado!';

  @override
  String hudRecordBest(int best) {
    return 'Récord $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '+$points sobre tu récord';
  }

  @override
  String get hudRecordOneMore => 'Uno más para el récord';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count para el récord',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'Puntaje $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'Puntaje $score, multiplicador ×$multiplier';
  }

  @override
  String get commonBusySemantics => 'Ocupado';

  @override
  String get flightResultBumpClouds => 'Un pequeño tropiezo entre las nubes.';

  @override
  String get flightResultPersonalBest => 'RÉCORD PERSONAL';

  @override
  String get flightResultNewPersonalBest => '¡NUEVO RÉCORD!';

  @override
  String get flightResultStarsCollected => 'ESTRELLAS REUNIDAS';

  @override
  String get flightResultDailyStamped => '¡Postal de hoy sellada!';

  @override
  String flightResultNextStamp(String stamp) {
    return 'Siguiente: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'Guardado en este teléfono';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Guardado · $total puertas en total',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'Guardando tu vuelo…';

  @override
  String get flightResultSessionSaved => 'Sesión guardada · Mírala en Récords';

  @override
  String get flightResultWatchReplay => 'Ver repetición';

  @override
  String get flightResultPreparing => 'Preparando…';

  @override
  String get flightResultSavingShort => 'Guardando…';

  @override
  String get flightResultSaveSession => 'Guardar sesión';

  @override
  String get flightResultFlyAgain => 'Volar otra vez';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonMap => 'Mapa';

  @override
  String get commonNext => 'Siguiente';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flexiones',
      one: 'flexión',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sentadillas',
      one: 'sentadilla',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'saltos',
      one: 'salto',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'aleteos',
      one: 'aleteo',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'de vuelo';

  @override
  String get flightStatPerfect => 'perfectas';

  @override
  String get flightStatBestStreak => 'mejor racha';

  @override
  String get flightStatRank => 'rango';

  @override
  String get flightRankSkyCaptain => 'As del cielo';

  @override
  String get flightRankCloudExplorer => 'Exploranubes';

  @override
  String get flightRankFirstWings => 'Primeras alas';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => '¡Un choque, pero con récord nuevo!';

  @override
  String get gameOverCaptionSea => 'Un pequeño chapuzón en el mar.';

  @override
  String get gameOverSplash => '¡Chapuzón!';

  @override
  String get gameOverBonk => '¡Pum!';

  @override
  String get gameOverEveryMarkSemantics => 'Todas las marcas logradas';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan $count estrellas para $mark estrellas',
      one: 'Falta $count estrella para $mark estrellas',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: le quedan $hp de $maxHp de vida';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '$percent por ciento de la ruta recorrida';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: LE QUEDAN $hp PV';
  }

  @override
  String gameOverBossLeft(String boss) {
    return 'VIDA DE $boss';
  }

  @override
  String get gameOverRouteFlown => 'RUTA RECORRIDA';

  @override
  String gameOverHp(int hp) {
    return '$hp PV';
  }

  @override
  String gameOverMoreFor(int count) {
    return '$count más para';
  }

  @override
  String get gameOverBothMarks => 'Ambas marcas logradas';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Marcas logradas. ¡Vence al $boss!',
      'spitterBeetle': 'Marcas logradas. ¡Vence al $boss!',
      'duskMoth': 'Marcas logradas. ¡Vence a la $boss!',
      'pirate': 'Marcas logradas. ¡Vence al $boss!',
      'dragon': 'Marcas logradas. ¡Vence al $boss!',
      'kingCoo': 'Marcas logradas. ¡Vence al $boss!',
      'searchlightGargoyle': 'Marcas logradas. ¡Vence a la $boss!',
      'other': 'Marcas logradas. ¡Vence a $boss!',
    });
    return '$_temp0';
  }

  @override
  String get miniResultTitle => 'Cada vuelo cuenta.';

  @override
  String get miniResultComplete => 'VUELO COMPLETO';

  @override
  String get miniResultCheerBest => '¡Mira cómo vuelas!';

  @override
  String get miniResultCheerComplete => '¡Vuelo completo!';

  @override
  String get miniResultCheerNice => 'Buen vuelo.';

  @override
  String get miniResultNew => 'NUEVO';

  @override
  String get flightEndTrackingLost => 'Te perdimos de vista un momento.';

  @override
  String get flightEndPostureLost => 'Tu posición salió del rango.';

  @override
  String get flightEndBackgrounded => 'Te alejaste del cielo.';

  @override
  String get flightEndBreak => 'Un descanso bien merecido.';

  @override
  String get flightEndQuit => 'Hasta la próxima aventura.';

  @override
  String get flightEndStalled => 'El juego se interrumpió.';

  @override
  String get flightEndCompleted => 'Todo un cielo de estrellas. Todo tuyo.';

  @override
  String get levelResultTryAgain => '¡Otra vez!';

  @override
  String get levelResultVictory => '¡Victoria!';

  @override
  String get levelResultGuardianDown => '¡Guardián fuera!';

  @override
  String get levelResultDelivered => '¡Entregado!';

  @override
  String levelResultComingSoon(String region) {
    return '¡$region llega pronto!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned de 3 estrellas';
  }

  @override
  String levelResultBest(int best) {
    return 'Récord $best';
  }

  @override
  String get levelResultNoBest => 'Sin récord aún';

  @override
  String get levelResultFirstClear => '¡Primera vez!';

  @override
  String get levelResultNewBest => '¡NUEVO RÉCORD!';

  @override
  String get levelResultScore => 'PUNTAJE';

  @override
  String get levelResultGoalBoss => 'Jefe';

  @override
  String get levelResultGoalGuardian => 'Guardián';

  @override
  String get levelResultGoalFinish => 'Meta';

  @override
  String get levelResultGoalDone => 'Logrado';

  @override
  String get levelResultGoalNotYet => 'Aún no';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan $count',
      one: 'Falta $count',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'Falta la meta';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. Logrado.';
  }

  @override
  String get levelResultPostcardWaiting =>
      '¡Hay una postal esperándote en el mapa!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '¡$id $name ya está abierto!';
  }

  @override
  String get levelResultReachFinish => 'Llega a la meta para ganar estrellas.';

  @override
  String get course_classic_title => 'Clásico';

  @override
  String get course_starTrail_title => 'Infinito';

  @override
  String get course_classic_instructions =>
      'Encuentra los huecos. Sigue los puntos de mira para un pase perfecto.';

  @override
  String get course_starTrail_instructions =>
      'Reúne las 3 estrellas de un grupo para +5. Encadena estrellas hasta 3×. Las estrellas recargan tu escudo; las puertas perfectas dan un imán de estrellas. ¡Mejora ambos con estrellas!';

  @override
  String get course_classic_scoreLabel => 'OBSTÁCULOS';

  @override
  String get course_starTrail_scoreLabel => 'PUNTOS ESTELARES';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'puertas',
      one: 'puerta',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'puntos',
      one: 'punto',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics =>
      'Clásico: vuela entre los huecos.';

  @override
  String get course_starTrail_previewSemantics =>
      'Infinito: reúne estrellas con tres corazones y un escudo.';

  @override
  String get obstacle_garden_name => 'Puerta de jardín';

  @override
  String get obstacle_windLift_name => 'Impulso de viento';

  @override
  String get obstacle_petalGate_name => 'Puertas de pétalos';

  @override
  String get obstacle_switchback_name => 'Zigzag';

  @override
  String get obstacle_lanternDrift_name => 'Faroles flotantes';

  @override
  String get obstacle_sunWheels_name => 'Ruedas solares';

  @override
  String get obstacle_crystalSteps_name => 'Escalón de cristal';

  @override
  String get rush_wildfire_name => 'Incendio';

  @override
  String get rush_wildfire_escape => 'Escapaste del incendio';

  @override
  String get rush_skyfall_name => 'Cae el cielo';

  @override
  String get rush_skyfall_escape => 'Sobreviviste a la caída';

  @override
  String get rush_eruption_name => 'Erupción';

  @override
  String get rush_eruption_escape => 'Le ganaste a la erupción';

  @override
  String get rush_swarm_name => 'Enjambre';

  @override
  String get rush_swarm_escape => 'Atravesaste el enjambre';

  @override
  String get boss_baronBat_title => 'SEÑOR DE LA TORMENTA';

  @override
  String get boss_spitterBeetle_title => 'ALQUIMISTA DEL ENJAMBRE';

  @override
  String get boss_duskMoth_title => 'DAMA DEL VELO CREPUSCULAR';

  @override
  String get boss_pirate_title => 'TERROR DE LA MAREA ALTA';

  @override
  String get boss_dragon_title => 'SOBERANO DEL CIELO EN LLAMAS';

  @override
  String get boss_kingCoo_title => 'COMISIONADO DE LA CALLE';

  @override
  String get boss_searchlightGargoyle_title => 'VIGÍA DE LA TORRE MÁS ALTA';

  @override
  String get boss_neferhoo_title => 'CUSTODIO DE LA CARTA PERDIDA';

  @override
  String get boss_baronBat_returnTitle => 'VUELVE LA TORMENTA';

  @override
  String get boss_baronBat_barName => 'BARÓN MURCIÉLAGO';

  @override
  String get boss_spitterBeetle_barName => 'REY ESCUPIDOR';

  @override
  String get boss_duskMoth_barName => 'EMPERATRIZ';

  @override
  String get boss_pirate_barName => 'CAPITÁN PIRATA';

  @override
  String get boss_dragon_barName => 'DRAGÓN';

  @override
  String get boss_kingCoo_barName => 'REY CURRUCÚ';

  @override
  String get boss_searchlightGargoyle_barName => 'GÁRGOLA';

  @override
  String get boss_neferhoo_barName => 'NEFERHOO';

  @override
  String get vanguard_baronBat_title => 'LOS MURCIÉLAGOS DEL BARÓN';

  @override
  String get vanguard_baronBat_call =>
      '¡Ahí vienen! El Barón viene justo detrás.';

  @override
  String get vanguard_spitterBeetle_title => 'LA PROLE DEL REY ESCUPIDOR';

  @override
  String get vanguard_spitterBeetle_call =>
      '¡Ahí vienen! El Rey Escupidor viene justo detrás.';

  @override
  String get vanguard_duskMoth_title => 'LAS POLILLAS DE LA EMPERATRIZ';

  @override
  String get vanguard_duskMoth_call =>
      '¡Ahí vienen! La Emperatriz viene justo detrás.';

  @override
  String get vanguard_kingCoo_title => 'EL ESCUADRÓN DEL REY CURRUCÚ';

  @override
  String get vanguard_kingCoo_call =>
      '¡Ahí vienen! El Rey Currucú viene justo detrás.';

  @override
  String get vanguard_kingCoo_callCrusts =>
      '¡Ahí vienen! ¡Esquiva las cortezas!';

  @override
  String get vanguard_kingCoo_callReturns =>
      '¡Esquiva las cortezas! ¡La paloma que se escape, vuelve!';

  @override
  String get bossVanguardClear => '¡LISTO!';

  @override
  String get bossVanguardLeft => 'MÁS';

  @override
  String get bossStragglersCaught => '¡NINGUNA SUELTA!';

  @override
  String get bossHint_strongerBaronBat =>
      'MÁS FUERTE · ¡Tiros triples, y sus murciélagos se unen!';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'MÁS FUERTE · ¡Abanicos completos, y sus escarabajos se unen!';

  @override
  String get bossHint_strongerDuskMoth =>
      'MÁS FUERTE · ¡Abanicos de siete, y sus polillas se unen!';

  @override
  String get bossHint_strongerPirate =>
      'MÁS FUERTE · ¡La marea está cambiando!';

  @override
  String get bossHint_strongerDragon =>
      'MÁS FUERTE · ¡Cuidado con el aliento y las bandadas!';

  @override
  String get bossHint_strongerKingCoo =>
      'MÁS FUERTE · ¡Llama a su escuadrón con un silbido!';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'MÁS FUERTE · ¡Caen plumas con la lámpara abierta!';

  @override
  String get bossHint_strongerGargoyle =>
      'MÁS FUERTE · ¡Caen plumas de piedra!';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'MÁS FUERTE · ¡El anj y sus murciélagos momia!';

  @override
  String get bossHint_strongerNeferhoo =>
      'MÁS FUERTE · ¡El anj dorado regresa!';

  @override
  String get bossHint_tideRising => 'SUBE LA MAREA · ¡Vuela alto!';

  @override
  String get bossHint_highTide => 'MAREA ALTA · Mantente sobre el agua';

  @override
  String get bossHint_tideFury => 'FURIA · Andanadas entre las oleadas';

  @override
  String get bossHint_tideCalm =>
      'Esquiva las balas de cañón · No toques el agua';

  @override
  String get bossHint_dragonSwarm =>
      'ENJAMBRE · Esquiva los murciélagos o atraviésalos con Turbo';

  @override
  String get bossHint_dragonFuryDebut => 'FURIA · Bolas de fuego más rápidas';

  @override
  String get bossHint_dragonFury =>
      'FURIA · Las bolas de fuego estallan en brasas';

  @override
  String get bossHint_dragonCalm =>
      'Esquiva las bolas de fuego · Cuidado con el aliento';

  @override
  String get bossHint_screechFury =>
      'FURIA · Bolas de fuego más rápidas, más murciélagos';

  @override
  String get bossHint_screechCalm =>
      'Esquiva las bolas de fuego y los murciélagos · Cuidado con el chillido';

  @override
  String get bossHint_cooPopped => '¡PAF! · Sin escuadrón';

  @override
  String get bossHint_cooSquadron => 'ESCUADRÓN · ¡Sigue el carril libre!';

  @override
  String get bossHint_cooPuffed => 'INFLADO · ¡Dispara a su pecho (x2)!';

  @override
  String get bossHint_cooCrumbBomb => 'BOMBA DE MIGAJAS · ¡Sal del anillo!';

  @override
  String get bossHint_cooFury => 'FURIA · Quédate entre los anillos';

  @override
  String get bossHint_cooCalm =>
      'Esquiva las bombas de migajas · Dispara a su pecho cuando se infle';

  @override
  String get bossHint_beamOn => 'HAZ DE LUZ · Quédate en la oscuridad';

  @override
  String get bossHint_beamFury => 'FURIA · Cuélate entre los haces';

  @override
  String get bossHint_beamIncomingHigh => 'HAZ EN CAMINO · ¡Vuela bajo!';

  @override
  String get bossHint_beamIncomingLow => 'HAZ EN CAMINO · ¡Vuela alto!';

  @override
  String get bossHint_lampOpen => 'LÁMPARA ABIERTA · ¡Dispara a la lámpara!';

  @override
  String get bossHint_shuttersClosed => 'PERSIANAS CERRADAS · Guarda tus tiros';

  @override
  String get bossHint_mothFuryNoVeil =>
      'FURIA · Abanicos de siete. ¡Aún sin velo!';

  @override
  String get bossHint_mothNoVeil =>
      'Aún sin velo · ¡Dispara entre los abanicos!';

  @override
  String get bossHint_mothShielded =>
      'CON ESCUDO · Esquiva hasta que caiga el velo';

  @override
  String get bossHint_mothShieldForming =>
      'SE FORMA EL ESCUDO · Prepárate para esquivar';

  @override
  String get bossHint_mothFury => 'FURIA · Abanicos de siete. ¡El velo cayó!';

  @override
  String get bossHint_mothCalm => 'El velo cayó · ¡Dispara entre los abanicos!';

  @override
  String get bossHint_neferhooMailCall =>
      '¡LLEGÓ EL CORREO! · ¡Devuélvelas a tiros!';

  @override
  String get bossHint_neferhooReturn => '¡DEVUÉLVASE AL REMITENTE! · −25';

  @override
  String get bossHint_neferhooReturnFaster => '¡DEVUÉLVASE AL REMITENTE! · −18';

  @override
  String get bossHint_neferhooAnkh => 'EL ANJ · ¡Regresa!';

  @override
  String get bossHint_neferhooExpress =>
      'CORREO EXPRÉS · Cinco cartas, más rápido';

  @override
  String get bossHint_neferhooTwoAnkhs => 'DOS ANJ · Evita ambos carriles';

  @override
  String get bossHint_neferhooBats => 'MURCIÉLAGOS MOMIA · ¡Derríbalos!';

  @override
  String get bossHint_neferhooScuff =>
      'Las piedras solo raspan sus vendas. ¡Devuélvele sus CARTAS a tiros!';

  @override
  String get bossHint_neferhooWarmUp =>
      'Devuelve sus cartas a tiros · Devuélvase al remitente';

  @override
  String get bossHint_neferhooCalm =>
      'Devuelve sus cartas a tiros · Esquiva el anj dorado';

  @override
  String get bossHint_neferhooFury => 'FURIA · Correo exprés y dos anj';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'ALIENTO DE DRAGÓN · ¡Vuela bajo! Su corazón está abierto',
      'middle': 'ALIENTO DE DRAGÓN · ¡Sube o baja! Su corazón está abierto',
      'other': 'ALIENTO DE DRAGÓN · ¡Vuela alto! Su corazón está abierto',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'FUEGO · ¡Vuela bajo! Golpea el corazón brillante',
      'middle': 'FUEGO · ¡Sube o baja! Golpea el corazón brillante',
      'other': 'FUEGO · ¡Vuela alto! Golpea el corazón brillante',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'CHILLIDO SÓNICO · ¡Vuela al hueco de arriba!',
      'middle': 'CHILLIDO SÓNICO · ¡Vuela al hueco del medio!',
      'other': 'CHILLIDO SÓNICO · ¡Vuela al hueco de abajo!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'CHILLIDO · Quédate en el hueco de arriba',
      'middle': 'CHILLIDO · Quédate en el hueco del medio',
      'other': 'CHILLIDO · Quédate en el hueco de abajo',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'ESQUIVA LOS ABANICOS  ·  DISPARA CUANDO CAIGA EL VELO';

  @override
  String get encounterCaption_pirate =>
      'ESQUIVA EL CAÑÓN  ·  NO TOQUES EL AGUA';

  @override
  String get encounterCaption_dragon =>
      'ESQUIVA LAS BOLAS DE FUEGO  ·  HUYE DEL ALIENTO';

  @override
  String get encounterCaption_kingCoo =>
      'SAL DE LOS ANILLOS  ·  DISPARA A SU PECHO CUANDO SE INFLE';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'NO ENTRES EN LA LUZ  ·  DISPARA A LA LÁMPARA CUANDO SE ABRA';

  @override
  String get encounterCaption_neferhoo =>
      'PREPÁRATE  ·  DEVUELVE SUS CARTAS A TIROS';

  @override
  String get encounterCaption_screech => 'CUANDO CHILLE  ·  VUELA AL HUECO';

  @override
  String get encounterCaption_default =>
      'PREPÁRATE  ·  ALETEA, ESQUIVA, DISPARA';

  @override
  String get encounterCoasting => 'Tu ave planea a salvo';

  @override
  String get encounterOpenSky => 'De vuelta al cielo abierto';

  @override
  String get encounterOmenTitle_duskMoth => 'EL OCASO ALZA EL VUELO';

  @override
  String get encounterOmenLine_duskMoth =>
      'Un velo de seda se teje en el ocaso…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'ALGO SE ESTÁ COCINANDO';

  @override
  String get encounterOmenLine_spitterBeetle => 'El aire empieza a burbujear…';

  @override
  String get encounterOmenTitle_dragon => 'EL CIELO SE INCENDIA';

  @override
  String get encounterOmenLine_dragon => 'Grandes alas baten sobre las nubes…';

  @override
  String get encounterOmenTitle_kingCoo => 'LA CALLE ESTÁ CERRADA';

  @override
  String get encounterOmenLine_kingCoo =>
      'Alguien está muy enojado por el carrito del pan…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => 'ALERTA DE TORMENTA';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      'Algo en la cornisa está mirando…';

  @override
  String get encounterOmenTitle_neferhoo => 'LA PIRÁMIDE DESPIERTA';

  @override
  String get encounterOmenLine_neferhoo => 'El polvo de la pirámide se agita…';

  @override
  String get encounterOmenTitle_baronReturns => 'VUELVE EL BARÓN';

  @override
  String get encounterOmenLine_baronReturns => 'Volvió, y mucho más ruidoso…';

  @override
  String get encounterOmenTitle_default => 'SE ACERCA UNA SOMBRA';

  @override
  String get encounterOmenLine_default =>
      'El cielo le pertenece a alguien más…';

  @override
  String get encounterOmenTitle_pirate => '¡BARCO A LA VISTA!';

  @override
  String get encounterOmenLine_pirate =>
      'Un barco llega con la marea que sube…';

  @override
  String get bossGuardianEyebrow => 'GUARDIÁN';

  @override
  String bossEncounterEyebrow(String number) {
    return 'ENCUENTRO $number';
  }

  @override
  String get bossGuardianDown => '¡GUARDIÁN FUERA!';

  @override
  String get bossSkyReclaimed => 'CIELO RECUPERADO';

  @override
  String bossVictoryPoints(int points) {
    return '+$points PUNTOS   ·   ESCUDO RECUPERADO';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'BARÓN MURCIÉLAGO VENCIDO',
      'spitterBeetle': 'REY ESCUPIDOR VENCIDO',
      'duskMoth': 'EMPERATRIZ DEL OCASO VENCIDA',
      'pirate': 'CAPITÁN PIRATA VENCIDO',
      'dragon': 'DRAGÓN DE LAS BRASAS VENCIDO',
      'kingCoo': 'REY CURRUCÚ VENCIDO',
      'searchlightGargoyle': 'GÁRGOLA DEL REFLECTOR VENCIDA',
      'other': 'NEFERHOO VENCIDO',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '“$line”';
  }

  @override
  String get bossPirateRoar => '¡ARRR!';

  @override
  String get bossGargoyleCardSmall => 'DEL REFLECTOR';

  @override
  String get bossGargoyleCardBig => 'GÁRGOLA';

  @override
  String get bossGargoyleCardOrder => 'big-small';

  @override
  String get bossDodgeFlyLow => 'VUELA BAJO';

  @override
  String get bossDodgeFlyHigh => 'VUELA ALTO';

  @override
  String get bossDodgeClimbOrDive => 'SUBE O BAJA';

  @override
  String get bossDodgeSlipBetween => 'CUÉLATE ENTRE\nLOS HACES';

  @override
  String get bossSpotted => '¡TE VI!';

  @override
  String get bossShieldLost => 'SIN ESCUDO';

  @override
  String get bossHeartLost => '-1 CORAZÓN';

  @override
  String get bossGargoyleLampOpen => 'LÁMPARA';

  @override
  String get bossGargoyleShoot => '¡FUEGO!';

  @override
  String get bossScreechFlyToGap => 'VUELA AL HUECO';

  @override
  String get bossScreechHoldGap => 'QUÉDATE AHÍ';

  @override
  String get bossPirateHighTide => 'MAREA ALTA';

  @override
  String get bossBarDefeated => 'KO';

  @override
  String get bossBarIncoming => 'LLEGANDO';

  @override
  String get bossBarFury => 'FURIA';

  @override
  String get bossBarHeartDouble => 'CORAZÓN ×2';

  @override
  String get bossStronger => '¡MÁS FUERTE!';

  @override
  String get bossKingCooPuffed => 'INFLADO';

  @override
  String get bossKingCooShout => '¡CURRÚ!';

  @override
  String get bossKingCooPop => '¡PAF!';

  @override
  String get bossKingCooPoof => '¡PUF!';

  @override
  String get bossSquadOpenLane => 'VE POR LO LIBRE';

  @override
  String get bossSquadUseGap => 'USA EL HUECO';

  @override
  String get bossSquadThenV => 'LUEGO: V';

  @override
  String get bossSquadThenGap => 'LUEGO: HUECO';

  @override
  String get bossSquadCancelled => 'SIN ESCUADRÓN';

  @override
  String get bossNeferhooFound => '¡APARECIÓ LA CARTA PERDIDA!';

  @override
  String get bossNeferhooHoo => 'HUU';

  @override
  String get bossNeferhooPoo => 'PUU';

  @override
  String get bossNeferhooMailCall => '¡CORREO!';

  @override
  String get bossNeferhooExpressPost => 'CORREO EXPRÉS';

  @override
  String get bossNeferhooShootBack => '¡Devuélvelas a tiros!';

  @override
  String get bossNeferhooAnkh => 'EL ANJ';

  @override
  String get bossNeferhooTwoAnkhs => 'DOS ANJ';

  @override
  String get bossNeferhooComesBack => '¡Regresa!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '¡INCENDIO!',
      'skyfall': '¡CAE EL CIELO!',
      'eruption': '¡ERUPCIÓN!',
      'other': '¡ENJAMBRE!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '¡Toma los aros turbo y déjalo atrás!',
      'skyfall': '¡Toma los aros turbo y gánales a los meteoros!',
      'eruption': '¡Toma los aros turbo y esquiva las explosiones!',
      'other': '¡Toma los aros turbo y atraviésalo!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return '¡ESCAPASTE! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return '¡IMPECABLE! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Escapaste del incendio',
      'skyfall': 'Sobreviviste a la caída del cielo',
      'eruption': 'Le ganaste a la erupción',
      'other': 'Atravesaste el enjambre',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => '¡VENDAVAL!';

  @override
  String encounterGaleDetail(String mark) {
    return '¡Esquiva los cachivaches donde parpadea el $mark!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return '¡AGUANTASTE! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail => 'Resististe el vendaval';

  @override
  String get encounterAllRings => '¡AROS AL 100%!';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'Turbo extra +$seconds s';
  }

  @override
  String get encounterFinish => 'META';

  @override
  String get builderMode_pushUp => 'Flexiones';

  @override
  String get builderMode_squat => 'Sentadillas';

  @override
  String get builderMode_jump => 'Saltos';

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
      other: '$count flexiones',
      one: '1 flexión',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sentadillas',
      one: '1 sentadilla',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'Nivel de toques';

  @override
  String get builderNewLevel_pushUp => 'Nivel de flexiones';

  @override
  String get builderNewLevel_squat => 'Nivel de sentadillas';

  @override
  String get builderNewLevel_jump => 'Nivel de saltos';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'Mi nivel';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Vuela mi nivel de Beakbound “$name” ($mode): $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$earned de $total estrellas';
  }

  @override
  String get builderBackSemantics => 'Atrás';

  @override
  String get builderKeepIt => 'Conservarlo';

  @override
  String builderLessSemantics(String name) {
    return 'Menos $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'Más $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => 'Duplicar';

  @override
  String get builderCopy => 'Copiar';

  @override
  String get builderDeleteSemantics => 'Borrar';

  @override
  String get builderDelete => 'Borrar';

  @override
  String get builderMoreBelow => 'Hay más abajo';

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
  String get builderLane => 'Carril';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'arriba o abajo de la sentadilla',
      'other': 'arriba o abajo de la flexión',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'Arriba';

  @override
  String get builderLaneBottom => 'Abajo';

  @override
  String get builderHeight => 'Altura';

  @override
  String get builderHeightHint => 'del cielo';

  @override
  String get builderLowerSemantics => 'Bajar';

  @override
  String get builderHigherSemantics => 'Subir';

  @override
  String get builderOpening => 'Abertura';

  @override
  String builderOpeningHint(int percent) {
    return 'al menos $percent %';
  }

  @override
  String get builderNarrowerSemantics => 'Más estrecha';

  @override
  String get builderWiderSemantics => 'Más ancha';

  @override
  String get builderMotion => 'Movimiento';

  @override
  String get builderMotionGardenHint => 'las puertas de jardín no se mueven';

  @override
  String get builderMotionStill => 'Quieta';

  @override
  String get builderMotionGentle => 'Suave';

  @override
  String get builderMotionLively => 'Animada';

  @override
  String get builderMotionGardenToast =>
      'Las puertas de jardín no se mueven: elige otro tipo de puerta para que se mueva.';

  @override
  String get builderSway => 'Vaivén';

  @override
  String builderSwayHint(String seconds) {
    return 'un vaivén: $seconds';
  }

  @override
  String get builderSwayFast => 'Rápido';

  @override
  String get builderSwayMedium => 'Medio';

  @override
  String get builderSwaySlow => 'Lento';

  @override
  String get builderPhase => 'Al llegar';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position de $count';
  }

  @override
  String get builderPhaseHint => 'en qué punto del vaivén está';

  @override
  String get builderPhaseEarlierSemantics => 'Antes en su vaivén';

  @override
  String get builderPhaseLaterSemantics => 'Después en su vaivén';

  @override
  String get builderLook => 'Aspecto';

  @override
  String builderLookSemantics(int number) {
    return 'Aspecto $number';
  }

  @override
  String get builderDoor => 'Losa de piedra';

  @override
  String get builderDoorHint => 'ábrela a tiros';

  @override
  String get builderDoorNone => 'Sin losa';

  @override
  String get builderDoorNeedsShootToast =>
      'Activa Disparar en los ajustes del nivel para usar losas.';

  @override
  String get builderPlace => 'Posición';

  @override
  String get builderPlaceHint => 'desde la salida';

  @override
  String get builderEarlierSemantics => 'Antes';

  @override
  String get builderLaterSemantics => 'Después';

  @override
  String builderFamilySemantics(String family) {
    return 'Tipo de puerta: $family. Cambiar';
  }

  @override
  String get builderChangeFamily => 'Cambiar tipo';

  @override
  String get builderItemStar => 'Estrella';

  @override
  String get builderItemTrio => 'Trío estelar';

  @override
  String get builderItemHeart => 'Corazón';

  @override
  String get builderItemEnemy => 'Enemigo';

  @override
  String get builderItemGate => 'Puerta';

  @override
  String get builderItemStarDetail => 'Una estrella para reunir';

  @override
  String get builderItemTrioDetail => 'Las tres dan puntos extra';

  @override
  String get builderItemHeartDetail => 'Devuelve un corazón';

  @override
  String get builderEnemyKind => 'Tipo';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'El ave vuela arriba y abajo de cada sentadilla: pon los objetos sobre las líneas amarillas o entre ellas.',
      'other':
          'El ave vuela arriba y abajo de cada flexión: pon los objetos sobre las líneas amarillas o entre ellas.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'Murciélago morado';

  @override
  String get builderEnemy_caveBat => 'Murciélago de cueva';

  @override
  String get builderEnemy_spitterBeetle => 'Escarabajo escupidor';

  @override
  String get builderEnemy_duskMoth => 'Polilla del ocaso';

  @override
  String get builderEnemy_alleyPigeon => 'Paloma de callejón';

  @override
  String get builderEnemy_mummyBat => 'Murciélago momia';

  @override
  String get builderSummaryTitle => 'Este nivel';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'Duración';

  @override
  String get builderFactStars => 'Estrellas';

  @override
  String get builderFactMarks => 'Marcas';

  @override
  String get builderFactWorkout => 'Ejercicio';

  @override
  String get builderFactPace => 'Ritmo';

  @override
  String get builderFactBoss => 'Jefe';

  @override
  String get builderPace_relaxed => 'Tranquilo';

  @override
  String get builderPace_steady => 'Constante';

  @override
  String get builderPace_brisk => 'Rápido';

  @override
  String get builderSummaryStarterNote =>
      'Un nivel inicial para volarlo tal cual o hacerle un remix a tu gusto.';

  @override
  String get builderSummaryClearedNote =>
      'Superado por ti: lo volaste hasta el final.';

  @override
  String get builderSummaryClearNote =>
      'Haz un vuelo de prueba hasta la meta para marcarlo como superado.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat':
          'Haz un vuelo de prueba, vence al $boss y cruza la meta para marcarlo como superado.',
      'spitterBeetle':
          'Haz un vuelo de prueba, vence al $boss y cruza la meta para marcarlo como superado.',
      'duskMoth':
          'Haz un vuelo de prueba, vence a la $boss y cruza la meta para marcarlo como superado.',
      'pirate':
          'Haz un vuelo de prueba, vence al $boss y cruza la meta para marcarlo como superado.',
      'dragon':
          'Haz un vuelo de prueba, vence al $boss y cruza la meta para marcarlo como superado.',
      'kingCoo':
          'Haz un vuelo de prueba, vence al $boss y cruza la meta para marcarlo como superado.',
      'searchlightGargoyle':
          'Haz un vuelo de prueba, vence a la $boss y cruza la meta para marcarlo como superado.',
      'other':
          'Haz un vuelo de prueba, vence a $boss y cruza la meta para marcarlo como superado.',
    });
    return '$_temp0';
  }

  @override
  String get builderSummaryHowTo =>
      'Elige una herramienta a la izquierda y toca el cielo. Toca algo para cambiarlo; arrástralo para moverlo.';

  @override
  String get builderFamily_garden_detail =>
      'No se mueve. Puede llevar una losa de piedra.';

  @override
  String get builderFamily_windLift_detail => 'La abertura sube y baja.';

  @override
  String get builderFamily_petalGate_detail =>
      'La abertura se estrecha y se ensancha.';

  @override
  String get builderFamily_switchback_detail => 'Dos aberturas que se separan.';

  @override
  String get builderFamily_lanternDrift_detail =>
      'Faroles colgantes que se mecen.';

  @override
  String get builderFamily_sunWheels_detail =>
      'Ruedas que se cierran y se abren.';

  @override
  String get builderFamily_crystalSteps_detail => 'Tres escalones en onda.';

  @override
  String get builderFamiliesCloseSemantics => 'Cerrar tipos de puerta';

  @override
  String get builderFamiliesTitle => 'Tipo de puerta';

  @override
  String get builderFamiliesSubtitle => 'Cómo se ve y se mueve la puerta.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ponle al nivel un nombre de hasta $count letras.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort => 'Aleja la meta: el nivel es demasiado corto.';

  @override
  String get reach_tooLong => 'Acerca la meta: el nivel es demasiado largo.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Demasiadas cosas: un nivel admite hasta $count.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap =>
      'Solo los niveles de Toca y vuela terminan con un jefe.';

  @override
  String get reach_noGates => 'Agrega puertas para que el ave pase por ellas.';

  @override
  String get reach_startZone =>
      'Demasiado cerca de la salida: muévelo más allá de la zona de salida.';

  @override
  String get reach_finishRoom =>
      'Deja espacio antes de la meta después de esta puerta.';

  @override
  String get reach_overlap => 'Dos puertas se superponen: sepáralas.';

  @override
  String get reach_gateHeight =>
      'Esta puerta está demasiado alta o demasiado baja.';

  @override
  String get reach_gateMotion => 'Esta puerta no puede moverse así.';

  @override
  String get reach_gateLook => 'Esta puerta tiene un aspecto desconocido.';

  @override
  String get reach_gateNarrow => 'Abre más esta puerta: el ave no cabe.';

  @override
  String get reach_gateWide => 'Esta puerta está demasiado abierta.';

  @override
  String get reach_doorNeedsShoot =>
      'Una losa de piedra necesita Toca y vuela con Disparar activado.';

  @override
  String get reach_doorNeedsGarden =>
      'Solo una puerta de jardín puede llevar una losa de piedra.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Cambio justo: una sentadilla a ritmo constante quizá no llegue a tiempo.',
      'other':
          'Cambio justo: una flexión a ritmo constante quizá no llegue a tiempo.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'Subida empinada: deja más espacio para saltar hasta esta puerta.';

  @override
  String get reach_enemyNeedsTap =>
      'Los enemigos solo vuelan en niveles de Toca y vuela.';

  @override
  String get reach_outsideSky => 'Mantenlo dentro del cielo.';

  @override
  String get reach_pastFinish => 'Ponlo antes de la meta.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Fuera del alcance de una sentadilla: acércalo a los carriles.',
      'other': 'Fuera del alcance de una flexión: acércalo a los carriles.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'Dentro de un muro: muévelo a la abertura.';

  @override
  String get reach_noStars => 'Pon al menos una estrella.';

  @override
  String get reach_marks =>
      'Las marcas de estrella piden más estrellas de las que tiene el nivel.';

  @override
  String reach_cannotFly(String problem) {
    return 'Este nivel aún no puede volar ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'El nivel no se guardó, así que aún no puede volar. Toca su nombre para reintentar.';

  @override
  String get builderShareBlockedToast =>
      'Primero corrige las banderas rojas: luego podrás compartir el nivel.';

  @override
  String get builderEditorBackSemantics => 'Volver al creador';

  @override
  String get builderSettingsSemantics => 'Ajustes del nivel';

  @override
  String get builderFly => 'VOLAR';

  @override
  String get builderTestFly => 'PROBAR';

  @override
  String get builderFlySemantics => 'Volar este nivel';

  @override
  String get builderTestFlySemantics => 'Probar todo el nivel en vuelo';

  @override
  String get builderUndoSemantics => 'Deshacer';

  @override
  String get builderRedoSemantics => 'Rehacer';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice consejos',
      one: '$advice consejo',
    );
    return '$blocking por corregir, $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice consejos',
      one: '$advice consejo',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => 'Listo para volar';

  @override
  String get builderShareSemantics => 'Compartir código';

  @override
  String get builderFromHereSemantics => 'Probar desde aquí';

  @override
  String get builderFromHere => 'Desde aquí';

  @override
  String get builderStatusStarter => 'Nivel inicial · vuela o haz un remix';

  @override
  String get builderStatusSaveFailed => 'No se guardó · toca para reintentar';

  @override
  String get builderStatusSaving => 'Guardando…';

  @override
  String get builderStatusSaved => 'Cambios guardados';

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
    return '$name. $mode. $status. Toca para cambiar el nombre.';
  }

  @override
  String get builderStarterBanner => 'Haz un remix para que sea tuyo';

  @override
  String get builderRemix => 'Remix';

  @override
  String get builderRemixSemantics => 'Hacer remix';

  @override
  String get builderIssuesCloseSemantics => 'Cerrar problemas y consejos';

  @override
  String get builderIssuesReadyTitle => '¡Listo para volar!';

  @override
  String get builderIssuesFixTitle => 'Por corregir antes de volar';

  @override
  String get builderIssuesTipsTitle => 'Listo, con algunos consejos';

  @override
  String get builderIssuesReadyDetail =>
      'Nada que corregir. Pruébalo hasta la meta para superarlo.';

  @override
  String get builderIssuesDetail => 'Toca uno para ir a su lugar en la ruta.';

  @override
  String get builderSettingsCloseSemantics => 'Cerrar ajustes';

  @override
  String get builderSettingsTitle => 'Ajustes del nivel';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · los cambios se guardan al instante';
  }

  @override
  String get builderSettingsName => 'Nombre';

  @override
  String get builderRename => 'Renombrar';

  @override
  String get builderRenameSemantics => 'Cambiar nombre';

  @override
  String get builderSettingsRegion => 'Región';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugares · desliza para más',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'Ritmo';

  @override
  String get builderSettingsPaceHint => 'qué tan rápido avanza el cielo';

  @override
  String get builderSettingsMarks => 'Marcas';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas puestas',
      one: '1 estrella puesta',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'marca de 2 estrellas';

  @override
  String get builderMarkThreeSemantics => 'marca de 3 estrellas';

  @override
  String get builderMarksAuto => 'Auto: según las estrellas';

  @override
  String get builderMarksByHand => 'Fijar a mano';

  @override
  String get builderSettingsControls => 'Controles';

  @override
  String get builderShootOn => 'Disparar activado';

  @override
  String get builderShootOff => 'Disparar apagado';

  @override
  String get builderSprintOn => 'Turbo activado';

  @override
  String get builderSprintOff => 'Turbo apagado';

  @override
  String get builderSettingsBoss => 'Final con jefe';

  @override
  String get builderSettingsBossHint => 'espera al final';

  @override
  String get builderNoBossSemantics => 'Sin jefe: una meta';

  @override
  String get builderNoBoss => 'Ninguno';

  @override
  String get builderBossShort_baronBat => 'Barón';

  @override
  String get builderBossShort_spitterBeetle => 'Escupidor';

  @override
  String get builderBossShort_duskMoth => 'Emperatriz';

  @override
  String get builderBossShort_pirate => 'Pirata';

  @override
  String get builderBossShort_dragon => 'Dragón';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'El ave vuela dos carriles: arriba y abajo de cada sentadilla. Quien vaya más lento juega el mismo nivel a una velocidad más suave. Aquí no hay disparos, turbo ni jefes.',
      'other':
          'El ave vuela dos carriles: arriba y abajo de cada flexión. Quien vaya más lento juega el mismo nivel a una velocidad más suave. Aquí no hay disparos, turbo ni jefes.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'Cada salto eleva al ave, que planea entre uno y otro. Aquí no hay disparos, turbo ni jefes.';

  @override
  String get builderStartZoneToast =>
      'Deja libre la zona de salida: pon las cosas a la derecha de la línea punteada.';

  @override
  String get builderSkySemantics =>
      'Cielo del nivel. Toca para poner algo, arrastra para moverlo o para desplazarte.';

  @override
  String get builderSkyReadOnlySemantics =>
      'Cielo del nivel. Toca algo para verlo.';

  @override
  String get builderCoachTitle => 'Crea tu nivel';

  @override
  String get builderCoachPickTool => 'Elige herramienta a la izquierda';

  @override
  String get builderCoachTapSky => 'Toca el cielo para ponerla';

  @override
  String get builderCoachTestFly => '¡Pruébalo en vuelo!';

  @override
  String get builderCoachDrag =>
      'Arrastra algo para moverlo · arrastra el cielo para desplazarte';

  @override
  String get builderTipDrag =>
      'Arrástralo para moverlo · arrastra el cielo para desplazarte';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'ARRIBA DE LA SENTADILLA',
      'other': 'ARRIBA DE LA FLEXIÓN',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'ARRIBA';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'ABAJO DE LA SENTADILLA',
      'other': 'ABAJO DE LA FLEXIÓN',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'ABAJO';

  @override
  String get builderCanvasStartZoneFull => 'ZONA DE SALIDA · DEJAR LIBRE';

  @override
  String get builderCanvasStartZone => 'ZONA DE SALIDA';

  @override
  String get builderCanvasFinishHere => 'META AQUÍ';

  @override
  String get builderTool_select => 'Elegir';

  @override
  String get builderToolHint_select =>
      'Elegir: toca algo para cambiarlo, arrastra para moverlo';

  @override
  String get builderTool_gate => 'Puerta';

  @override
  String get builderToolHint_gate =>
      'Puerta: toca el cielo para poner una puerta';

  @override
  String get builderTool_star => 'Estrella';

  @override
  String get builderToolHint_star =>
      'Estrella: toca el cielo para poner una estrella';

  @override
  String get builderTool_trio => 'Trío';

  @override
  String get builderToolHint_trio =>
      'Trío de estrellas: toca el cielo para poner tres estrellas';

  @override
  String get builderTool_heart => 'Corazón';

  @override
  String get builderToolHint_heart =>
      'Corazón: toca el cielo para poner un corazón';

  @override
  String get builderTool_enemy => 'Enemigo';

  @override
  String get builderToolHint_enemy =>
      'Enemigo: toca el cielo para poner un enemigo';

  @override
  String get builderTool_finish => 'Meta';

  @override
  String get builderToolHint_finish => 'Meta: toca el cielo para mover la meta';

  @override
  String get builderTool_boss => 'Jefe';

  @override
  String get builderToolHint_boss =>
      'Marca del jefe: toca el cielo para mover dónde espera el jefe';

  @override
  String get builderStarterToolsToast =>
      'Los niveles iniciales no se cambian: haz un remix para modificarlo.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Vista de la ruta. $length hasta el jefe. Arrastra para recorrer la ruta.',
      'other':
          'Vista de la ruta. $length hasta la meta. Arrastra para recorrer la ruta.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Vista de la ruta. $length hasta el jefe. $reps. Arrastra para recorrer la ruta.',
      'other':
          'Vista de la ruta. $length hasta la meta. $reps. Arrastra para recorrer la ruta.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '$length hasta el jefe';
  }

  @override
  String get builtResultTestFlight => 'PRUEBA';

  @override
  String get builtResultCleared => '¡Superado!';

  @override
  String get builtResultBonk => '¡Pum!';

  @override
  String get builtResultLanded => 'Aterrizaje';

  @override
  String get builtResultTestTab => 'PRUEBA';

  @override
  String get builtResultGoalFinish => 'Meta';

  @override
  String get builtResultGoalBoss => 'Jefe';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. Logrado.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reúne $count estrellas.',
      one: 'Reúne $count estrella.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reúne $count estrellas. Logrado.',
      one: 'Reúne $count estrella. Logrado.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'Logrado';

  @override
  String get builtResultNotYet => 'Aún no';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan $count',
      one: 'Falta $count',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'Falta la meta';

  @override
  String get builtResultClearedByYou => 'SUPERADO POR TI';

  @override
  String get builtResultNewBest => '¡NUEVO RÉCORD!';

  @override
  String get builtResultPractice => 'Práctica';

  @override
  String builtResultBest(int count) {
    return 'Récord $count';
  }

  @override
  String get builtResultFirstClear => '¡Primera vez!';

  @override
  String get builtResultStarsCollected => 'ESTRELLAS REUNIDAS';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de 3 estrellas del nivel',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'PIDE';

  @override
  String get builtResultWorkout => 'EJERCICIO';

  @override
  String get builtResultGotTo => 'LLEGASTE A';

  @override
  String get builtResultScore => 'PUNTAJE';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flexiones',
      one: 'flexión',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sentadillas',
      one: 'sentadilla',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'saltos',
      one: 'salto',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flexiones con cámara',
      one: 'flexión con cámara',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sentadillas con cámara',
      one: 'sentadilla con cámara',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'de $length';
  }

  @override
  String get builtResultNotKept => 'No se guarda';

  @override
  String get builtResultNoBest => 'Sin récord aún';

  @override
  String get builtResultClearedStrip =>
      'Superado por ti · ¡listo para compartir!';

  @override
  String builtResultFlownFrom(String from) {
    return 'Desde $from. Vuélalo completo para superarlo.';
  }

  @override
  String get builtResultTestNothingSaved =>
      'Vuelo de prueba · no se guarda nada';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'Vuelo de prueba · llegaste a $reached de $length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return 'Llegaste a $reached de $length. La meta da estrellas.';
  }

  @override
  String get builtResultReachFinish => 'Llega a la meta para ganar estrellas.';

  @override
  String get builtResultSaved => 'Guardado en este teléfono';

  @override
  String get builtResultSaving => 'Guardando tu vuelo…';

  @override
  String get builtResultBuilder => 'Creador';

  @override
  String get builtResultEditLevel => 'Editar nivel';

  @override
  String get builtResultEdit => 'Editar';

  @override
  String get builtResultFlyAgain => 'Volar otra vez';

  @override
  String get builtResultWatchReplay => 'Ver repetición';

  @override
  String get builtResultPreparing => 'Preparando…';

  @override
  String get builtResultSessionSaving => 'Guardando…';

  @override
  String get builtResultSaveSession => 'Guardar sesión';

  @override
  String get builderShelfTitle => 'Creador de niveles';

  @override
  String get builderShelfPasteCode => 'Pegar código';

  @override
  String get builderShelfNewLevel => 'Nivel nuevo';

  @override
  String get builderShelfSaveFailed => 'No se guardó. Inténtalo otra vez.';

  @override
  String builderShelfDeleteTitle(String name) {
    return '¿Borrar “$name”?';
  }

  @override
  String get builderShelfDeleteBody =>
      'Sus récords se van con él. Las flexiones, sentadillas y saltos que hiciste en él siguen contando.';

  @override
  String get builderShelfDelete => 'Borrar';

  @override
  String builderShelfDeleted(String name) {
    return 'Se borró “$name”.';
  }

  @override
  String get builderShelfFixFirst =>
      'Corrige lo marcado en rojo antes de compartir: toca Corregir.';

  @override
  String get builderShelfCodeCopied =>
      '¡Código copiado! Compártelo con tus amigos.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      '¡Código copiado! Vuélalo también hasta la meta, para que tus amigos sepan que se puede.';

  @override
  String get builderShelfNotReady =>
      'Este nivel aún no puede volar: toca Corregir.';

  @override
  String get builderShelfPasteMissingTitle =>
      'No hay código de nivel para pegar';

  @override
  String get builderShelfPasteNewerTitle =>
      'Un nivel de un Beakbound más nuevo';

  @override
  String get builderShelfPasteDamagedTitle => 'Ese código llegó revuelto';

  @override
  String get builderShelfPasteMissingBody =>
      'Copia el código de nivel de un amigo (empieza con BEAK1.) y vuelve a tocar Pegar código.';

  @override
  String get builderShelfPasteNewerBody =>
      'Actualiza Beakbound para volarlo y vuelve a pegar el código.';

  @override
  String get builderShelfPasteDamagedBody =>
      'Le falta una parte o tiene un error. Pídele a tu amigo que copie el código completo otra vez.';

  @override
  String builderShelfImported(String name) {
    return '¡“$name” ya está en tu estante!';
  }

  @override
  String get builderShelfUnavailable => 'Tus niveles necesitan un momento.';

  @override
  String get builderShelfMine => 'Mis niveles';

  @override
  String get builderShelfStarters => 'Niveles iniciales';

  @override
  String get builderShelfStartersHint =>
      'Vuela uno o haz un remix para crear tu propio nivel';

  @override
  String get builderShelfEmptyTitle => 'Crea tu primer nivel';

  @override
  String get builderShelfEmptyBody =>
      'Pon a mano puertas, estrellas y corazones, marca la meta y haz un vuelo de prueba.';

  @override
  String get builderShelfPasteFriend => 'Pegar el código de un amigo';

  @override
  String get builderShelfNeedsWork => 'Necesita arreglos';

  @override
  String get builderShelfClearedByYou => 'Superado por ti';

  @override
  String get builderShelfFromFriend => 'De un amigo';

  @override
  String get builderShelfFly => 'Volar';

  @override
  String builderShelfFlySemantics(String name) {
    return 'Volar $name';
  }

  @override
  String get builderShelfFixIt => 'Corregir';

  @override
  String builderShelfFixSemantics(String name) {
    return 'Corrige $name';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return 'Editar $name';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return 'Compartir $name';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return 'Compartir $name: lo superaste';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'Más opciones de $name';
  }

  @override
  String get builderShelfRemix => 'Remix';

  @override
  String builderShelfRemixSemantics(String name) {
    return 'Remix de $name';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cosas por corregir en el editor',
      one: '1 cosa por corregir en el editor',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '$count estrella',
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
    return '$name. $mode en $region. $length.';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Récord: $stars de 3 estrellas.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Necesita arreglos: $count cosas por corregir.',
      one: 'Necesita arreglos: 1 cosa por corregir.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'Superado por ti.';

  @override
  String get builderShelfFromFriendSemantics => 'De un amigo.';

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
  String get builderShelfCopySuffix => 'copia';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get starter_t_tap_1_name => 'Jardín saltarín';

  @override
  String get starter_t_push_1_name => 'Diez flexiones';

  @override
  String get starter_t_squat_1_name => 'Sube y baja';

  @override
  String get starter_t_jump_1_name => 'Bahía de rebotes';

  @override
  String get starter_t_tap_boss_name => 'Puente del Barón';

  @override
  String get builderPickCloseNewLevel => 'Cerrar nivel nuevo';

  @override
  String get builderPickModeTitle => '¿Qué va a ser?';

  @override
  String get builderPickRegionTitle => '¿Dónde se vuela?';

  @override
  String get builderPickModeSubtitle =>
      'Elige cómo se vuela (no se puede cambiar después). Todos los niveles se prueban tocando la pantalla.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · elige dónde se vuela. Puedes cambiarlo después.';
  }

  @override
  String get builderPickTouchLine =>
      'Toca para aletear. Puertas, estrellas, enemigos y un jefe.';

  @override
  String get builderPickPushUpLine =>
      'Un carril alto y uno bajo: cada bajada es una flexión.';

  @override
  String get builderPickSquatLine =>
      'Un carril alto y uno bajo: cada bajada es una sentadilla.';

  @override
  String get builderPickJumpLine =>
      'Salta para elevarte. Puertas en cualquier parte del cielo.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'Cámara';

  @override
  String get builderPickSuggested => 'Sugerida';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, sugerida';
  }

  @override
  String get builderPickClose => 'Cerrar';

  @override
  String get builderPickNotYet => 'Aún no: primero corrige lo marcado en rojo.';

  @override
  String get builderPickShare => 'Compartir código';

  @override
  String get builderPickShareLine =>
      'Copia un código que un amigo pueda pegar en su Beakbound.';

  @override
  String get builderPickDuplicate => 'Duplicar';

  @override
  String get builderPickDuplicateLine => 'Haz una copia para probar otra idea.';

  @override
  String get builderPickDeleteLine =>
      'Borra el nivel. Antes te lo preguntaremos.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'Cancelar importación';

  @override
  String get builderPickImportTitle => '¡Un nivel para volar!';

  @override
  String get builderPickImportSubtitle =>
      'Alguien compartió este nivel contigo.';

  @override
  String get builderPickClearedByMaker => 'Superado por quien lo creó';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas para reunir',
      one: '$count estrella para reunir',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Termina con el $boss',
      'spitterBeetle': 'Termina con el $boss',
      'duskMoth': 'Termina con la $boss',
      'pirate': 'Termina con el $boss',
      'dragon': 'Termina con el $boss',
      'kingCoo': 'Termina con el $boss',
      'searchlightGargoyle': 'Termina con la $boss',
      'other': 'Termina con $boss',
    });
    return '$_temp0';
  }

  @override
  String get builderPickNotFlown =>
      'Quien lo creó aún no lo voló hasta el final.';

  @override
  String get builderPickRoute => 'La ruta';

  @override
  String builderPickAlreadyHave(String name) {
    return 'Ya tienes este nivel: “$name”.';
  }

  @override
  String get builderPickImportCopy => 'Importar una copia';

  @override
  String get builderPickOpenYours => 'Abrir el tuyo';

  @override
  String get builderPickImport => 'Importar';

  @override
  String get builderShelfRenameCancelSemantics => 'No cambiar el nombre';

  @override
  String get builderShelfRenameTitle => 'Ponle nombre a tu nivel';

  @override
  String get builderShelfRenameEmpty => 'Un nombre necesita una letra o dos';

  @override
  String get builderShelfRenameSaveSemantics => 'Guardar nombre';

  @override
  String get builderShelfRenameSave => 'Guardar';

  @override
  String get coopMode_roped => 'Con cuerda';

  @override
  String get coopMode_free => 'Sin cuerda';

  @override
  String get coopMode_duel => '1 contra 1';

  @override
  String get coopTitle => 'Vuelen juntos';

  @override
  String get coopPlayersTag => 'DOS JUGADORES · UN TELÉFONO';

  @override
  String coopBestTag(String mode, int best) {
    return 'RÉCORD $mode $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: SIN RÉCORD AÚN';
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
    return '$mode: PRIMER DUELO';
  }

  @override
  String get coopRopedLead => 'Sus aves comparten una cuerda.';

  @override
  String get coopRopedBody =>
      'Aleteen juntos para subir alto: un ave que aletea sola levanta a las dos, pero solo un poco. Usen el Turbo para arrastrar a la otra ave.';

  @override
  String get coopFreeLead => 'Sin cuerda:';

  @override
  String get coopFreeBody =>
      'cada ave vuela por su cuenta y solo choca con la otra. Los corazones, el escudo y el puntaje se siguen compartiendo.';

  @override
  String get duelLead => '¡A pelear!';

  @override
  String get duelBody =>
      'Cada ave tiene sus propios corazones. Tomen las cajas sorpresa: unas lanzan murciélagos, un escupidor o meteoros contra su rival; otras dan un corazón, un escudo o poder estelar. Gana la última ave en vuelo.';

  @override
  String get coopStart => 'Volar juntos';

  @override
  String get duelStart => '¡A pelear!';

  @override
  String get coopFlightSemantics =>
      'El jugador 1 toca la mitad izquierda para aletear; el jugador 2, la derecha';

  @override
  String get coopPauseSemantics => 'Pausar el vuelo';

  @override
  String coopShootSemantics(int player) {
    return 'Jugador $player: disparar';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'Jugador $player: turbo';
  }

  @override
  String coopPlayerShort(int player) {
    return 'J$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'JUGADOR $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Imán de estrellas: quedan $seconds segundos',
      one: 'Imán de estrellas: queda $seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Imán cargando: $charge de $gates puertas perfectas',
    );
    return '$_temp0';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds s',
    );
    return '$_temp0';
  }

  @override
  String get coopCountdownRoped => 'Cuerda lista. En sus marcas, listos…';

  @override
  String get coopCountdownFree => 'En sus marcas, listos…';

  @override
  String get duelCountdown => 'Listos para el duelo…';

  @override
  String get coopCountdownRopedHint =>
      'Aleteen juntos para subir alto.\n¡Usen el Turbo para arrastrar a la otra ave!';

  @override
  String get coopCountdownFreeHint =>
      'Cada ave vuela por su cuenta.\n¡Compartan los corazones y superen las puertas!';

  @override
  String get duelCountdownHint =>
      '¡Tomen las cajas sorpresa!\nGana la última ave en vuelo.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Poder estelar del jugador $player: quedan $seconds segundos',
      one: 'Poder estelar del jugador $player: queda $seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'Inicio';

  @override
  String get coopChangeBirds => 'Cambiar aves';

  @override
  String get coopSaved => 'Guardado';

  @override
  String get coopSaving => 'Guardando…';

  @override
  String get coopSaveSession => 'Guardar sesión';

  @override
  String get duelRematch => 'Revancha';

  @override
  String get coopFlyAgain => 'Volar otra vez';

  @override
  String duelWinner(int player) {
    return '¡Gana el jugador $player!';
  }

  @override
  String get duelDraw => '¡Empate!';

  @override
  String get duelStopped => 'Duelo detenido';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first vs. $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner venció a $loser';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '¡$prize contra J$rival!';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '¡$prize!';
  }

  @override
  String get duelPrize_batSwarm => 'Murciélagos';

  @override
  String get duelPrize_spitter => 'Escupidor';

  @override
  String get duelPrize_meteorShower => 'Meteoros';

  @override
  String get duelPrize_heart => 'Corazón';

  @override
  String get duelPrize_shield => 'Escudo';

  @override
  String get duelPrize_starPower => 'Poder estelar';

  @override
  String get coopTapLeftHalf => 'Toca la mitad izquierda';

  @override
  String get coopTapRightHalf => 'Toca la mitad derecha';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'Jugador $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'J$player · toca este lado';
  }

  @override
  String get coopKeysP1 => 'J1 · W vuela, D tira, A turbo';

  @override
  String get coopKeysP2 => 'J2 · Arriba vuela, Der. tira, Izq. turbo';

  @override
  String get coopRopedSemantics => 'Con cuerda: las aves comparten una cuerda';

  @override
  String get coopFreeSemantics => 'Sin cuerda: cada ave vuela por su cuenta';

  @override
  String get duelModeSemantics => '1 contra 1: las aves pelean entre sí';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'Sesión guardada · Mírala en Récords';

  @override
  String get coopNewTeamBest => '¡Nuevo récord de equipo!';

  @override
  String get coopWhatATeam => '¡Qué equipo!';

  @override
  String coopPairCaption(String first, String second) {
    return '$first y $second';
  }

  @override
  String get coopTeamScore => 'PUNTAJE DE EQUIPO';

  @override
  String get coopTeamBest => 'RÉCORD DE EQUIPO';

  @override
  String get coopNewTeamBestRibbon => '¡RÉCORD DE EQUIPO!';

  @override
  String get coopStatFlightTime => 'tiempo de vuelo';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'estrellas',
      one: 'estrella',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'puertas',
      one: 'puerta',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'REPARTO DE ALETEOS';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'aleteos de J$player',
      one: 'aleteo de J$player',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'Duración del duelo: $time';
  }

  @override
  String get duelSeries => 'SERIE';

  @override
  String get duelHeartsLeft => 'corazones restantes';

  @override
  String get duelBoxesOpened => 'cajas abiertas';

  @override
  String get duelHitsLanded => 'golpes acertados';

  @override
  String get coopPauseSubtitle =>
      'Las dos aves están posadas, esperando. Les haremos la cuenta regresiva a los dos.';

  @override
  String get coopFinishFlight => 'Terminar vuelo';

  @override
  String get cameraLabIntro =>
      'Apoya tu teléfono abajo, en horizontal, frente a ti o a tu lado.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'Ya casi · necesito ver mejor: $parts';
  }

  @override
  String get cameraLabJointShoulder => 'hombro';

  @override
  String get cameraLabJointElbow => 'codo';

  @override
  String get cameraLabJointWrist => 'muñeca';

  @override
  String get cameraLabJointHip => 'cadera';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => 'Iniciando la cámara…';

  @override
  String get cameraLabDenied =>
      'El acceso a la cámara está apagado. Permítelo en la configuración de la app y vuelve a intentarlo.';

  @override
  String cameraLabFailed(String error) {
    return 'La cámara no pudo iniciar: $error';
  }

  @override
  String get cameraLabStopped =>
      'Cámara detenida. Toca Iniciar cámara para recalibrar.';

  @override
  String get cameraLabBack => 'LAB DE CÁMARA · Volver al inicio';

  @override
  String get cameraLabStepShow => '1. Muestra brazos y cadera';

  @override
  String get cameraLabStepPushUps => '2. Haz dos flexiones';

  @override
  String get cameraLabStepMove => '3. ¡Mueve a tu ave!';

  @override
  String get cameraLabStepSquat => 'Encuentra tu sentadilla';

  @override
  String get cameraLabStepJump => 'Busca tu posición de pie';

  @override
  String get cameraLabPushUpHelp =>
      'Teléfono abajo, frente a ti o a tu lado.\n¿De frente? Muestra ambos hombros, un brazo y la cadera.\nBaja y sube dos veces a tu ritmo.';

  @override
  String get cameraLabSquatHelp =>
      'Sin moverte, agáchate con comodidad y aguanta un momento; luego vuelve a pararte. Agáchate para bajar; párate para subir.';

  @override
  String get cameraLabJumpHelp =>
      'Ponte frente al teléfono con todo el cuerpo y los pies a la vista. No te muevas y luego da saltos pequeños. Un salto = un gran impulso.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'CALIBRACIÓN\n$done / $total calibradas',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'CALIBRACIÓN\n$percent% calibrado';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PRUEBA DE CONTROL\n$count flexiones',
      one: 'PRUEBA DE CONTROL\n$count flexión',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PRUEBA DE CONTROL\n$count sentadillas',
      one: 'PRUEBA DE CONTROL\n$count sentadilla',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PRUEBA DE CONTROL\n$count saltos',
      one: 'PRUEBA DE CONTROL\n$count salto',
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
  String get cameraLabStartCamera => 'Iniciar cámara';

  @override
  String get cameraLabTapStart => 'Toca Iniciar cámara';

  @override
  String cameraLabTry(String mode) {
    return 'Probar $mode';
  }

  @override
  String get cameraBadgeWaking => 'DESPERTANDO';

  @override
  String get cameraBadgeLive => 'EN VIVO';

  @override
  String get cameraBadgeLockedOn => 'FIJADO';

  @override
  String get cameraBadgeOffline => 'APAGADA';

  @override
  String get trackingCatchingUp => 'La cámara se está poniendo al día';

  @override
  String get trackingStepIntoOutline => 'Entra en la silueta del cuerpo';

  @override
  String get trackingKeepShoulders => 'Deja ambos hombros a la vista';

  @override
  String get trackingShowSide =>
      'Muestra de lado un hombro, un codo, una muñeca y la cadera';

  @override
  String get trackingMoveCloser => 'Acércate un poco';

  @override
  String get trackingGetDown => 'Ponte en posición de flexión';

  @override
  String get trackingHandsOnFloor =>
      'Pon las manos en el suelo y estira el cuerpo hacia atrás';

  @override
  String get trackingExtendBody =>
      'Estira el cuerpo un poco más detrás de las manos';

  @override
  String get trackingComfortableRange => 'Mantén un rango de flexión cómodo';

  @override
  String get trackingPlaceHands =>
      'Apoya las manos en el suelo con el cuerpo detrás';

  @override
  String get trackingFrontTracked =>
      'Vista frontal detectada · mantén las manos a la vista';

  @override
  String get trackingBodyInView => 'Cuerpo a la vista · puedes mirar al suelo';

  @override
  String get trackingArmsTracked => 'Brazos detectados · piernas poco visibles';

  @override
  String get trackingFindTop => 'Busca una posición alta cómoda';

  @override
  String get trackingCalibrated => '¡Calibrado! Intenta mover a tu ave.';

  @override
  String get trackingFreshFrame => 'Esperando una imagen nueva';

  @override
  String get trackingDistanceChanged =>
      'Cambió la distancia a la cámara · recalibra';

  @override
  String get trackingKeepArm => 'Deja un brazo a la vista';

  @override
  String get trackingSquatStepBack =>
      'Retrocede para que se vean tus hombros, caderas, rodillas y pies';

  @override
  String get trackingSquatFaceCamera =>
      'Ponte frente a la cámara con los dos pies en el suelo';

  @override
  String get trackingSquatControls => 'Agáchate para bajar · párate para subir';

  @override
  String get trackingStartingDistance =>
      'Ponte frente a la cámara a tu distancia inicial · recalibra si te moviste';

  @override
  String get trackingFeetPlanted => 'Mantén los dos pies en tu lugar inicial';

  @override
  String get trackingSquatStandTall =>
      'Ponte de pie, sin moverte, con los dos pies a la vista';

  @override
  String get trackingStandStill => 'Ponte de pie y no te muevas por un momento';

  @override
  String get trackingSquatDepth =>
      'Agáchate hasta una profundidad cómoda y aguanta un momento';

  @override
  String get trackingSquatHold => 'Agáchate con comodidad y aguanta un momento';

  @override
  String get trackingSquatHoldBriefly =>
      'Aguanta un momento esta sentadilla cómoda';

  @override
  String get trackingSquatStandUp =>
      'Vuelve a pararte para terminar la calibración';

  @override
  String get trackingSquatReady =>
      '¡Listo! Agáchate para bajar · párate para subir';

  @override
  String get trackingJumpStepBack =>
      'Retrocede para que se vean tus hombros, caderas y ambos pies';

  @override
  String get trackingJumpFaceCamera =>
      'Ponte frente a la cámara con espacio arriba para saltar';

  @override
  String get trackingJumpSmall =>
      'Bastan saltos pequeños · aterriza antes de volver a saltar';

  @override
  String get trackingJumpStandStill =>
      'No te muevas y deja a la vista todo el cuerpo y ambos pies';

  @override
  String get trackingJumpReady =>
      '¡Listo! Un salto pequeño da un gran impulso.';

  @override
  String get trackingFindPosition => 'Busca tu posición';

  @override
  String get trackingInterrupted => 'Seguimiento interrumpido';

  @override
  String get trackingCameraInterrupted =>
      'Cámara interrumpida. Revisa el permiso de cámara y vuelve a intentarlo.';

  @override
  String get trackingCameraAway =>
      'La cámara se detuvo mientras la app estaba en segundo plano';

  @override
  String get trackingJumpBoost => 'Salta para un gran impulso';

  @override
  String get trackingJumpLand => 'Aterriza para el próximo salto';

  @override
  String trackingLowerMore(int step, int total) {
    return 'Baja un poco más · $step de $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'Baja con comodidad · $step de $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'Vuelve a subir · $step de $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'Iguala tu primer rango cómodo · $step de $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'No se pudo guardar este cambio. Inténtalo otra vez. ($error)';
  }

  @override
  String get commonDelete => 'Borrar';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan $count',
      one: 'Falta $count',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'Tu nido necesita un momento.';

  @override
  String get homeSettings => 'Ajustes';

  @override
  String homeGreetingFirst(String bird) {
    return '¡Hola, soy $bird! ¿Volamos?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '¡Aventura completada! $bird está orgulloso.',
      'female': '¡Aventura completada! $bird está orgullosa.',
      'other': '¡Aventura completada! $bird está feliz.',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird está listo. ¿Y tú?',
      'female': '$bird está lista. ¿Y tú?',
      'other': '$bird ya puede volar. ¿Y tú?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'INFINITO';

  @override
  String get homeEndlessDetail => 'Vuela lo más lejos que puedas';

  @override
  String get homeEndlessSemantics => 'Infinito. Vuela lo más lejos que puedas.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other:
          'Infinito. Vuela lo más lejos que puedas. Récord: $best estrellas.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'Récord';

  @override
  String get homeBestNone => 'Marca tu primer récord';

  @override
  String get homeCampaignTitle => 'CAMPAÑA';

  @override
  String get homeCampaignDone => 'Toda carta, entregada';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Campaña. Siguiente: $level. $stars de $total estrellas.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Campaña. Toda carta, entregada. $stars de $total estrellas.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'MINIJUEGOS';

  @override
  String get homeMiniGamesDetail => 'Ejercicios · 2 jugadores';

  @override
  String get homeMiniGamesSemantics =>
      'Minijuegos. Flexiones, sentadillas, saltos o dos jugadores.';

  @override
  String get homeBuilderTitle => 'CREA NIVELES';

  @override
  String get homeBuilderDetail => 'Arma · vuela · comparte';

  @override
  String get homeBuilderSemantics =>
      'Creador de niveles. Crea tus propios niveles, vuélalos y compártelos.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se abre en $count vuelos',
      one: 'Se abre en 1 vuelo',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Creador de niveles. Bloqueado. Se abre en $count vuelos.',
      one: 'Creador de niveles. Bloqueado. Se abre en 1 vuelo.',
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
      other: 'Aventura de hoy. $done de 3 metas cumplidas.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'Aves';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'Aves. Vuelas con $bird.';
  }

  @override
  String get homeDockUpgrades => 'Mejoras';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Mejoras. $stars estrellas para gastar.',
      one: 'Mejoras. $stars estrella para gastar.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'Pasaporte';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Pasaporte. $earned de $total medallas.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'Récords';

  @override
  String get homeMiniGamesPickerTitle => 'Minijuegos';

  @override
  String get homeMiniGamesPickerIntro =>
      'Muévete para volar o comparte el teléfono con alguien.';

  @override
  String get homeMiniGamesCloseSemantics => 'Cerrar minijuegos';

  @override
  String get homeMiniGamesPushUpCard => 'Baja y pica.\nSube y vuela alto.';

  @override
  String get homeMiniGamesSquatCard => 'Agáchate.\nPárate y vuela alto.';

  @override
  String get homeMiniGamesJumpCard =>
      'Salta para subir.\nPlanea por estrellas.';

  @override
  String get homeMiniGamesCoopCard =>
      'Dos jugadores, un teléfono.\nEquipo o duelo.';

  @override
  String get homeMiniGamesCamera => 'Cámara';

  @override
  String get homeMiniGamesPlayers => 'Para dos';

  @override
  String get homeMiniGamesCoop => 'Vuelen juntos';

  @override
  String get birdsTitle => 'Conoce a tu tripulación.';

  @override
  String birdsFlownTag(int flown, int total) {
    return '$flown DE $total PROBADAS';
  }

  @override
  String get birdsStatusCopilot => 'TU COPILOTO';

  @override
  String get birdsStatusReady => 'DISPONIBLE';

  @override
  String get birdsStatusLocked => 'SIN DESBLOQUEAR';

  @override
  String get birdsNotFlown => 'Aún sin volar';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vuelos',
      one: '1 vuelo',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return 'Volar con $bird';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return 'Volar con $bird en lugar de $current';
  }

  @override
  String birdsUnlock(String bird) {
    return 'Desbloquear a $bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Desbloquear a $bird por $price estrellas',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Desbloquear a $bird por $price estrellas; aún no te alcanza',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'Vuela contigo';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, vuela contigo';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, vuela contigo, sin estrenar';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, sin desbloquear, $price estrellas',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return 'Nuevo: $bird';
  }

  @override
  String get birdsTagFlying => 'EN VUELO';

  @override
  String get birdsTagNew => 'NUEVO';

  @override
  String get bird_0_description => 'Pájaro pequeño. Cielo grande.';

  @override
  String get bird_0_trail => 'Burbujas de sol';

  @override
  String get bird_1_description =>
      'Mejillas rosadas, cresta rizada, puro corazón.';

  @override
  String get bird_1_trail => 'Corazones de durazno';

  @override
  String get bird_2_description =>
      'Colibrí diminuto. Ramita fresca. A toda máquina.';

  @override
  String get bird_2_trail => 'Hojas de menta';

  @override
  String get bird_3_description =>
      'Lechucita soñadora que vuela bajo las estrellas.';

  @override
  String get bird_3_trail => 'Polvo de estrellas';

  @override
  String get upgradesWalletLabel => 'TU\nSALDO';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars estrellas para gastar',
      one: '$stars estrella para gastar',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'Mejora a tu ave.';

  @override
  String get upgradesIntro =>
      'Toca un engranaje para ver qué hace. Cada estrella que atrapas en vuelo es una para gastar.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, nivel $level de $max. Siguiente nivel: $cost estrellas',
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
          '$power, nivel $level de $max. Siguiente nivel: $cost estrellas; aún no te alcanza',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, nivel $level de $max. Al máximo';
  }

  @override
  String get upgradesMax => 'MÁX';

  @override
  String upgradesLevel(int level) {
    return 'Nivel $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'Nivel $level, el máximo';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now, siguiente nivel $next';
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
      other: 'Te quedarán $count estrellas.',
      one: 'Te quedará $count estrella.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'Mejorar';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Mejorar por $cost estrellas',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Mejorar por $cost estrellas; aún no te alcanza',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'Al máximo';

  @override
  String get power_shot_name => 'Tiro potente';

  @override
  String get power_shot_blurb =>
      'Mantén Disparar para cargar una piedra más grande y dura.';

  @override
  String get power_sprint_name => 'Turbo';

  @override
  String get power_sprint_blurb =>
      'Un arranque de velocidad que arrasa a los enemigos en tu camino.';

  @override
  String get power_shield_name => 'Escudo';

  @override
  String get power_shield_blurb =>
      'Bloquea un golpe por ti. Reúne estrellas en vuelo para recargarlo.';

  @override
  String get power_magnet_name => 'Imán';

  @override
  String get power_magnet_blurb =>
      'Pasa perfecto por las puertas para ganarlo. Te atrae las estrellas.';

  @override
  String get power_stat_maxCharge => 'Carga máxima';

  @override
  String get power_stat_burstLength => 'Duración del turbo';

  @override
  String get power_stat_cooldown => 'Tiempo de recarga';

  @override
  String get power_stat_starsToRefill => 'Estrellas para recargar';

  @override
  String get power_stat_safeTime => 'Protección tras romperse';

  @override
  String get power_stat_perfectGates => 'Puertas perfectas necesarias';

  @override
  String get power_stat_lasts => 'Duración';

  @override
  String get power_stat_reach => 'Alcance';

  @override
  String get passportTitle => 'Tu pasaporte del cielo.';

  @override
  String get passportDailyCard => 'Postal del día';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total MEDALLAS';
  }

  @override
  String get passportIntro =>
      'Pequeñas aventuras. Recuerdos que duran. Bronce, plata y oro en cada sello.';

  @override
  String get passportNoMedal => 'Aún sin medalla';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Medalla de bronce',
      'silver': 'Medalla de plata',
      'other': 'Medalla de oro',
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
    return '$stamp. $held. Siguiente, $next: $goal $current de $target.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. Medalla de oro. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'PARA BRONCE',
      'silver': 'PARA PLATA',
      'other': 'PARA ORO',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'SELLADO';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: aún ninguna';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'Bronce';

  @override
  String get passportMedal_silver => 'Plata';

  @override
  String get passportMedal_gold => 'Oro';

  @override
  String get stamp_frequentFlyer_name => 'Pasajero frecuente';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Termina $n vuelos con puntaje.',
      one: 'Termina $n vuelo con puntaje.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'Dar en el blanco';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Haz $n pases perfectos por los puntos de mira.',
      one: 'Haz $n pase perfecto por los puntos de mira.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'Cazaestrellas';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reúne $n estrellas.',
      one: 'Reúne $n estrella.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => 'Constelación';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reúne $n estrellas en una sola racha.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'Capitán del cielo';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Consigue $n puntos en un solo vuelo infinito.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'Abrecaminos';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vuela al menos 60 segundos en $n vuelos infinitos.',
      one: 'Vuela al menos 60 segundos en $n vuelo infinito.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'Todos en bandada';

  @override
  String get stamp_allRounder_name => 'Todoterreno';

  @override
  String get stamp_flockTogether_goalBronze =>
      'Lleva dos aves distintas en vuelos con puntaje.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'Lleva a las cuatro aves en vuelos con puntaje.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Haz $n vuelos con puntaje con cada ave.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'Juega un minijuego de flexiones, sentadillas o saltos.';

  @override
  String get stamp_allRounder_goalSilver =>
      'Juega los tres minijuegos: flexiones, sentadillas y saltos.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Haz $n vuelos con puntaje en cada minijuego.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals medallas · en $level',
      one: '$stars★ · $medals medalla · en $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'Tu aventura necesita un momento.';

  @override
  String get dailyTitle => 'La pequeña aventura de hoy.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · $done/3 METAS';
  }

  @override
  String get dailyIntro =>
      'Tres metas. Cualquier control. Un vuelo infinito sirve para las tres.';

  @override
  String get dailyLaunchEndless => 'Infinito';

  @override
  String get dailyPostcardKicker => 'POSTAL DEL CLUB';

  @override
  String get dailyStamped => '¡POSTAL SELLADA!';

  @override
  String dailyGoalsComplete(int done) {
    return '$done / 3 METAS CUMPLIDAS';
  }

  @override
  String get dailyDoneNote => 'Una pequeña aventura, toda tuya.';

  @override
  String get dailyOpenNote => 'Cumple las tres para sellar esta postal.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal Cumplida';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current de $target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: postal sellada';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: $done/3 metas';
  }

  @override
  String get dailyNoStreak => 'Metas nuevas. Sin racha que perder.';

  @override
  String get dailyTheme_0 => 'Entrega al amanecer';

  @override
  String get dailyTheme_1 => 'Picnic de durazno';

  @override
  String get dailyTheme_2 => 'Correo de luna';

  @override
  String get dailyTheme_3 => 'Desfile de nubes';

  @override
  String get dailyTheme_4 => 'Tesoro del ocaso';

  @override
  String get dailyTheme_5 => 'Fiesta en el jardín';

  @override
  String get task_flights_title => 'Despliega tus alas';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Termina $count vuelos con puntaje hoy.',
      one: 'Termina $count vuelo con puntaje hoy.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'Horizontes abiertos';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pasa $count puertas en tus vuelos con puntaje de hoy.',
      one: 'Pasa $count puerta en tus vuelos con puntaje de hoy.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'Bolsillo de estrellas';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reúne $count estrellas en tus vuelos de hoy.',
      one: 'Reúne $count estrella en tus vuelos de hoy.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'Sigue brillando';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reúne $count estrellas en una sola racha.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'Justo en la marca';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Haz $count pases perfectos hoy.',
      one: 'Haz $count pase perfecto hoy.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'El viaje completo';

  @override
  String get task_finishTrail_goal =>
      'Vuela al menos 60 segundos en un solo vuelo infinito.';

  @override
  String get recordsTitle => 'Tus pequeñas victorias.';

  @override
  String get recordsBestsTitle => 'Tus puntos estelares a superar';

  @override
  String get recordsSectionMain => 'JUEGO PRINCIPAL';

  @override
  String get recordsSectionMini => 'MINIJUEGOS';

  @override
  String get recordsEndless => 'Infinito · Toca y vuela';

  @override
  String get recordsCampaignStars => 'Estrellas de campaña';

  @override
  String recordsCoopName(String mode) {
    return 'Vuelen juntos · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vuelos con puntaje',
      one: 'vuelo con puntaje',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'puertas',
      one: 'puerta',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en equipo',
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
      other: 'flexiones',
      one: 'flexión',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sentadillas',
      one: 'sentadilla',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'Vuelos recientes';

  @override
  String get recordsEmptyTitle => 'Cielo grande. Hoja en blanco.';

  @override
  String get recordsEmptyBody =>
      'Tu primer vuelo con puntaje inicia la historia.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds s';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'Clásico · $date · $seconds s';
  }

  @override
  String get replaySavedSessions => 'Sesiones guardadas';

  @override
  String get replayBackToRecordsSemantics => 'Volver a Récords';

  @override
  String get replaySessionsLoadFailed =>
      'No se cargaron las sesiones. Reintentar';

  @override
  String get replayEmptyTitle => 'Aquí van tus vuelos';

  @override
  String get replayEmptyBody =>
      'Guarda una sesión después de un vuelo para verla aquí.';

  @override
  String get replayEmptyButton => 'Elige un vuelo';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds s · $score puntos estelares',
      one: '$date · $seconds s · $score punto estelar',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds s · $score puertas',
      one: '$date · $seconds s · $score puerta',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'Borrar sesión';

  @override
  String get replayDeleteTitle => '¿Borrar esta sesión?';

  @override
  String get replayDeleteBody =>
      'Se borrarán el video de la cámara y la repetición. Tus puntajes se quedan en Récords.';

  @override
  String get replayDeleteFailed =>
      'No se pudo borrar la sesión. Inténtalo otra vez.';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return 'Nivel $id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · Infinito';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · Práctica';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · Infinito · Práctica';
  }

  @override
  String get replayOpenFailed => 'No se pudo abrir esta sesión.';

  @override
  String get replayBackToSessions => 'Volver a sesiones';

  @override
  String get replayCameraPaused =>
      'La cámara estuvo en pausa durante esta parte de la sesión';

  @override
  String get replayCameraUnavailable =>
      'Clip de cámara no disponible · El juego se reproduce igual';

  @override
  String get replayCameraLoading => 'Cargando cámara…';

  @override
  String get replayPaused => 'Tomando un respiro';

  @override
  String get replayHideControlsSemantics => 'Ocultar controles';

  @override
  String get replayShowControlsSemantics => 'Mostrar controles';

  @override
  String get replayBackToSavedSemantics => 'Volver a las sesiones guardadas';

  @override
  String get replayTitle => 'REPETICIÓN';

  @override
  String replayTitleSession(String session) {
    return 'REPETICIÓN · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'Puntaje: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts corazones',
      one: '$hearts corazón',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'J1 $p1 · J2 $p2 corazones · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String replayMagnet(int seconds) {
    return 'Imán · $seconds s';
  }

  @override
  String get replayPauseSemantics => 'Pausar repetición';

  @override
  String get replayPlaySemantics => 'Reproducir';

  @override
  String get replayRestartSemantics => 'Reiniciar repetición';

  @override
  String get replayBack5Semantics => 'Atrás 5 segundos';

  @override
  String get replayForward5Semantics => 'Adelante 5 segundos';

  @override
  String get replayHighlightsFinding => 'Buscando los mejores momentos';

  @override
  String get replayHighlightsNone => 'No hay mejores momentos';

  @override
  String get replayHighlights => 'Mejores momentos';

  @override
  String get replayHighlightsCloseSemantics => 'Cerrar mejores momentos';

  @override
  String get replayHighlightsHint =>
      'Elige un momento. Míralo desde justo antes.';

  @override
  String get replayViewCorner => 'Cámara en esquina';

  @override
  String get replayViewBackground => 'Cámara de fondo';

  @override
  String get replayViewGameplay => 'Solo el juego';

  @override
  String get replayMoveCornerSemantics => 'Mover la cámara de esquina';

  @override
  String get replayMuteRecordedSemantics => 'Silenciar audio grabado';

  @override
  String get replayUnmuteRecordedSemantics => 'Activar audio grabado';

  @override
  String get replayMuteGameSemantics => 'Silenciar el juego';

  @override
  String get replayUnmuteGameSemantics => 'Activar sonido del juego';

  @override
  String get replayFullScreenSemantics =>
      'Ocultar controles / pantalla completa';

  @override
  String get replayMomentTakeoff => 'Despegue';

  @override
  String get replayMomentTakeoffDetail => 'El cielo es tuyo.';

  @override
  String get replayMomentMagnet => 'Imán estelar';

  @override
  String get replayMomentMagnetDetail =>
      'Tres pases perfectos acercan las estrellas.';

  @override
  String get replayMomentStarTrio => 'Primer trío de estrellas';

  @override
  String get replayMomentStarTrioDetail =>
      'Tres estrellas forman una constelación. ¡+5 puntos!';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'Reuniste todas las estrellas del grupo. ¡+5 puntos!';

  @override
  String replayMomentStreak(int multiplier) {
    return 'Poder estelar $multiplier×';
  }

  @override
  String get replayMomentStreakDetail => 'Una racha brillante de estrellas.';

  @override
  String get replayMomentShield => 'Bloqueo del escudo';

  @override
  String get replayMomentShieldDetail => 'Por poco, y otra oportunidad.';

  @override
  String get replayMomentPerfect => 'Primer pase perfecto';

  @override
  String get replayMomentPerfectDetail => 'Justo por el punto de mira.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puertas superadas',
      one: '$count puerta superada',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'Un poco más lejos en el cielo.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Ni un rasguño. ¡+$points puntos!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Los aros turbo te salvaron. ¡+$points puntos!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'Resististe el vendaval';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Esquivaste los cachivaches. ¡+$points puntos!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'Ruta completa';

  @override
  String get replayMomentFinal => 'Momento final';

  @override
  String get replayMomentCompleteDetail => 'Llegaste al final de la ruta.';

  @override
  String get replayMomentCollisionDetail => 'Mira la recta final.';

  @override
  String get replayMomentEndDetail => 'El final de este vuelo.';
}
