import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('de'),
    Locale('en', 'XA'),
    Locale('es'),
    Locale('es', '419'),
    Locale('fr'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Common: button that retries something that failed to load or save.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// Settings header: the globe key that opens the language picker, and the picker's title. One or two words.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageKeyLabel;

  /// Screen reader label of the Settings language key. {language} is the current language's own name, such as "Deutsch".
  ///
  /// In en, this message translates to:
  /// **'Language: {language}. Change the game\'s language.'**
  String languageKeySemantics(String language);

  /// Language picker: the first choice, which follows the phone's language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Language picker: under "System default", the language that choice gives right now (its own name, e.g. "Deutsch").
  ///
  /// In en, this message translates to:
  /// **'Follows your phone: {language}'**
  String languageSystemDetail(String language);

  /// Screen reader: added to the language that is selected now.
  ///
  /// In en, this message translates to:
  /// **'Current language'**
  String get languageCurrent;

  /// Language picker: the name of English in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName_en;

  /// Language picker: the name of Spanish (Latin America) in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Spanish (Latin America)'**
  String get languageName_es_419;

  /// Language picker: the name of Portuguese (Brazil) in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Portuguese (Brazil)'**
  String get languageName_pt_br;

  /// Language picker: the name of Indonesian in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageName_id;

  /// Language picker: the name of French in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageName_fr;

  /// Language picker: the name of German in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageName_de;

  /// Language picker: the name of Japanese in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageName_ja;

  /// Language picker: the name of Korean in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageName_ko;

  /// Language picker: the name of Turkish in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageName_tr;

  /// Language picker: the name of Traditional Chinese in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get languageName_zh_hant;

  /// Language picker: the name of Russian in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageName_ru;

  /// Language picker: the name of Arabic in YOUR language, shown small under its own name. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageName_ar;

  /// Language picker badge: this language's character voices are installed.
  ///
  /// In en, this message translates to:
  /// **'Voices ready'**
  String get voicePackReady;

  /// Language picker badge: this language's voices can be downloaded (a button).
  ///
  /// In en, this message translates to:
  /// **'Get voices'**
  String get voicePackDownload;

  /// Language picker badge: voice download progress. {percent} is 0-100.
  ///
  /// In en, this message translates to:
  /// **'Voices {percent}%'**
  String voicePackDownloading(int percent);

  /// Language picker badge, shown with a spinning ring: the voice download has started but its size is not known yet (no percent).
  ///
  /// In en, this message translates to:
  /// **'Getting voices'**
  String get voicePackStarting;

  /// Language picker badge: no voices in this language yet; the characters speak English under translated captions.
  ///
  /// In en, this message translates to:
  /// **'English voices'**
  String get voicePackEnglish;

  /// Language picker badge: the voice download failed; tapping retries.
  ///
  /// In en, this message translates to:
  /// **'Voices failed'**
  String get voicePackFailed;

  /// Settings screen title, a friendly heading in the top bar. It shrinks to fit, but keep it short.
  ///
  /// In en, this message translates to:
  /// **'Make yourself at home.'**
  String get settingsTitle;

  /// Settings: small section label above the music, effects and voices switches. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSectionSound;

  /// Settings: small section label above the Reduced motion switch. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get settingsSectionComfort;

  /// Settings switch title: the game's music. "Sky Club" is the name of the birds' postal club.
  ///
  /// In en, this message translates to:
  /// **'Sky Club soundtrack'**
  String get settingsMusicTitle;

  /// Settings: one line under the music switch title.
  ///
  /// In en, this message translates to:
  /// **'Menu, adventure and boss themes.'**
  String get settingsMusicDetail;

  /// Settings switch title: sound effects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsEffectsTitle;

  /// Settings: one line under the sound effects switch title.
  ///
  /// In en, this message translates to:
  /// **'Flight, combat, pickups and menu feedback.'**
  String get settingsEffectsDetail;

  /// Settings switch title: the recorded voices of the story characters and birds.
  ///
  /// In en, this message translates to:
  /// **'Character voices'**
  String get settingsVoicesTitle;

  /// Settings: one line under the voices switch title.
  ///
  /// In en, this message translates to:
  /// **'Story scenes, thank-you notes and sprint calls.'**
  String get settingsVoicesDetail;

  /// Settings switch title: an accessibility option with fewer animations.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get settingsReducedMotionTitle;

  /// Settings: one line under the reduced motion switch title.
  ///
  /// In en, this message translates to:
  /// **'Quieter menus and fewer decorative effects.'**
  String get settingsReducedMotionDetail;

  /// Settings: the word beside a switch that is on. Capitals, very short.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get settingsSwitchOn;

  /// Settings: the word beside a switch that is off. Capitals, very short.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get settingsSwitchOff;

  /// Settings: heading shown when the settings could not be loaded, above a Try again button.
  ///
  /// In en, this message translates to:
  /// **'Your settings need a moment.'**
  String get settingsUnavailable;

  /// Settings privacy card: small capital kicker above the title.
  ///
  /// In en, this message translates to:
  /// **'ON-DEVICE. ALWAYS.'**
  String get settingsPrivacyKicker;

  /// Settings privacy card title (the camera is used by the push-up/squat/jump mini games).
  ///
  /// In en, this message translates to:
  /// **'Your camera stays yours.'**
  String get settingsPrivacyTitle;

  /// Settings privacy card: two short lines of body text.
  ///
  /// In en, this message translates to:
  /// **'Video and optional microphone audio stay on this phone. Unsaved clips are discarded. No uploads.'**
  String get settingsPrivacyBody;

  /// Settings button: opens a diagnostic screen for the camera tracking used by the movement mini games.
  ///
  /// In en, this message translates to:
  /// **'Camera & tracking lab'**
  String get settingsCameraLab;

  /// Settings button: opens the app's about page and open-source licenses.
  ///
  /// In en, this message translates to:
  /// **'About & licenses'**
  String get settingsAbout;

  /// Settings: the app version under the About button, such as "v1.0.0". Usually left as is.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String settingsVersion(String version);

  /// Screen reader label of the About button.
  ///
  /// In en, this message translates to:
  /// **'About & licenses, version {version}'**
  String settingsAboutSemantics(String version);

  /// Settings: the red button that erases this phone's progress (asks first).
  ///
  /// In en, this message translates to:
  /// **'Reset local progress'**
  String get settingsReset;

  /// Settings: message after progress was reset. {bird} is the first bird's name, e.g. "Minty".
  ///
  /// In en, this message translates to:
  /// **'A fresh start. {bird} is ready for you.'**
  String settingsResetDone(String bird);

  /// Reset dialog title (also read by screen readers).
  ///
  /// In en, this message translates to:
  /// **'Start a fresh adventure?'**
  String get settingsResetTitle;

  /// Reset dialog text when the phone never used the cloud save.
  ///
  /// In en, this message translates to:
  /// **'This deletes your saved videos, replays, scores, runs, built levels and settings from this phone. It cannot be undone.'**
  String get settingsResetBody;

  /// Reset dialog text when the phone has used the Play Games cloud save.
  ///
  /// In en, this message translates to:
  /// **'This deletes your saved videos, replays, scores, runs, built levels and settings from this phone, and your Play Games cloud save. It cannot be undone.'**
  String get settingsResetBodyCloud;

  /// Reset dialog: the destructive button.
  ///
  /// In en, this message translates to:
  /// **'Reset everything'**
  String get settingsResetConfirm;

  /// Reset dialog: the safe button that closes the dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep my progress'**
  String get settingsResetKeep;

  /// Google Play Games, as Google names it in your language (e.g. "Play Juegos", "Play Jeux", "Play Spiele"). Heading on the Settings cloud strip.
  ///
  /// In en, this message translates to:
  /// **'Play Games'**
  String get playGamesName;

  /// Play Games strip: status when signed in.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get playGamesConnected;

  /// Play Games strip: status when not signed in.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get playGamesNotConnected;

  /// Play Games strip: status line while signing in.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get playGamesConnecting;

  /// Play Games strip: status line after sign-in failed or was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t connect'**
  String get playGamesConnectFailed;

  /// Play Games strip: status line before connecting (what Play Games offers).
  ///
  /// In en, this message translates to:
  /// **'Cloud save & achievements'**
  String get playGamesIdle;

  /// Play Games strip: status line while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving to cloud…'**
  String get playGamesSaving;

  /// Play Games strip: no internet and nothing saved to the cloud yet.
  ///
  /// In en, this message translates to:
  /// **'Offline · not saved yet'**
  String get playGamesOfflineUnsaved;

  /// Play Games strip: no internet; {ago} is how long ago the last save was, e.g. "3 h ago".
  ///
  /// In en, this message translates to:
  /// **'Offline · saved {ago}'**
  String playGamesOfflineSaved(String ago);

  /// Play Games strip: the cloud save is from a newer game version.
  ///
  /// In en, this message translates to:
  /// **'Update Beakbound to sync'**
  String get playGamesUpdateNeeded;

  /// Play Games strip: the cloud save is damaged.
  ///
  /// In en, this message translates to:
  /// **'Cloud save can’t be read'**
  String get playGamesUnreadable;

  /// Play Games strip: connected, nothing saved yet.
  ///
  /// In en, this message translates to:
  /// **'Cloud save is on'**
  String get playGamesOn;

  /// Play Games strip: progress was reset on another phone.
  ///
  /// In en, this message translates to:
  /// **'Reset on another phone'**
  String get playGamesResetElsewhere;

  /// Play Games strip: progress was restored from the cloud {ago} (e.g. "2 min ago").
  ///
  /// In en, this message translates to:
  /// **'Cloud restored · {ago}'**
  String playGamesRestored(String ago);

  /// Play Games strip: last cloud save {ago} (e.g. "2 min ago").
  ///
  /// In en, this message translates to:
  /// **'Saved to cloud · {ago}'**
  String playGamesSaved(String ago);

  /// Screen reader label of the Achievements button.
  ///
  /// In en, this message translates to:
  /// **'Play Games achievements'**
  String get playGamesAchievementsSemantics;

  /// Screen reader label of the Connect button.
  ///
  /// In en, this message translates to:
  /// **'Connect Play Games'**
  String get playGamesConnectSemantics;

  /// Play Games strip button: opens Google's achievements screen.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get playGamesAchievements;

  /// Play Games strip button: signs in to Play Games.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get playGamesConnect;

  /// How long ago something happened: under a minute. Lower case, follows "saved".
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeAgoJustNow;

  /// How long ago, in minutes (abbreviated). Follows "saved" / "Saved to cloud ·".
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, other{{minutes} min ago}}'**
  String timeAgoMinutes(int minutes);

  /// How long ago, in hours (abbreviated).
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, other{{hours} h ago}}'**
  String timeAgoHours(int hours);

  /// How long ago, in days (abbreviated).
  ///
  /// In en, this message translates to:
  /// **'{days, plural, other{{days} d ago}}'**
  String timeAgoDays(int days);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A heart pickup gave one extra life.
  ///
  /// In en, this message translates to:
  /// **'+1 LIFE!'**
  String get calloutLife;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. Three stars collected together.
  ///
  /// In en, this message translates to:
  /// **'STAR TRIO +{points}!'**
  String calloutStarTrio(int points);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A shot hit an enemy.
  ///
  /// In en, this message translates to:
  /// **'NICE SHOT!'**
  String get calloutNiceShot;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A shot hit an enemy, with its points.
  ///
  /// In en, this message translates to:
  /// **'NICE SHOT +{points}!'**
  String calloutNiceShotPoints(int points);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The bird rammed an enemy.
  ///
  /// In en, this message translates to:
  /// **'SMASH!'**
  String get calloutSmash;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The bird rammed something, with its points.
  ///
  /// In en, this message translates to:
  /// **'SMASH +{points}!'**
  String calloutSmashPoints(int points);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. Several things smashed in a row; {count} is how many.
  ///
  /// In en, this message translates to:
  /// **'SMASH ×{count}!'**
  String calloutSmashChain(int count);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A boss was beaten.
  ///
  /// In en, this message translates to:
  /// **'BOSS DOWN!'**
  String get calloutBossDown;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A boss was beaten, with its points.
  ///
  /// In en, this message translates to:
  /// **'BOSS DOWN +{points}!'**
  String calloutBossDownPoints(int points);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The star multiplier went up; {multiplier} is 2, 3, ...
  ///
  /// In en, this message translates to:
  /// **'{multiplier}× STAR POWER!'**
  String calloutStarPower(int multiplier);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The bird flew through the middle of a gate.
  ///
  /// In en, this message translates to:
  /// **'PERFECT!'**
  String get calloutPerfect;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. Several perfect gates in a row.
  ///
  /// In en, this message translates to:
  /// **'PERFECT ×{count}'**
  String calloutPerfectChain(int count);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The bird's shield is charged.
  ///
  /// In en, this message translates to:
  /// **'SHIELD READY'**
  String get calloutShieldReady;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The shield absorbed a hit.
  ///
  /// In en, this message translates to:
  /// **'SHIELD SAVE!'**
  String get calloutShieldSave;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The bird lost a heart but flies on.
  ///
  /// In en, this message translates to:
  /// **'KEEP FLYING!'**
  String get calloutKeepFlying;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A milestone: {count} gates passed (10, 20, ...).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} GATES!}}'**
  String calloutGates(int count);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The final countdown of a timed flight; {seconds} is 10.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, other{{seconds} SECONDS LEFT}}'**
  String calloutFinalStretch(int seconds);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A magnet power-up that pulls stars in.
  ///
  /// In en, this message translates to:
  /// **'STAR MAGNET!'**
  String get calloutStarMagnet;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The bird flew through a golden sprint ring.
  ///
  /// In en, this message translates to:
  /// **'SPRINT RING!'**
  String get calloutSprintRing;

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. Several sprint rings in a row.
  ///
  /// In en, this message translates to:
  /// **'RUSH ×{count}!'**
  String calloutRushChain(int count);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A falling meteor smashed while sprinting.
  ///
  /// In en, this message translates to:
  /// **'METEOR +{points}!'**
  String calloutMeteorPoints(int points);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. A bat smashed while sprinting.
  ///
  /// In en, this message translates to:
  /// **'BAT +{points}!'**
  String calloutBatPoints(int points);

  /// Flight callout: a short shout that pops up beside the bird for a moment, in capitals, heading font. Keep it very short; words may stay in capitals or use your script's emphasis. The dragon's fire hit the bird.
  ///
  /// In en, this message translates to:
  /// **'SCORCHED!'**
  String get calloutScorched;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'Jungle'**
  String get region_jungle;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'Antarctica'**
  String get region_antarctica;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short. The Aztec temples of ancient Mexico.
  ///
  /// In en, this message translates to:
  /// **'Aztec'**
  String get region_aztec;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'Paris'**
  String get region_paris;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'Egypt'**
  String get region_egypt;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short. A neon city of the future.
  ///
  /// In en, this message translates to:
  /// **'Cyberpunk City'**
  String get region_cyberpunk;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get region_china;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get region_brazil;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'New York'**
  String get region_newYork;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'Ancient Arabia'**
  String get region_arabia;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'Ancient Rome'**
  String get region_rome;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short.
  ///
  /// In en, this message translates to:
  /// **'Mexico'**
  String get region_mexico;

  /// Name of a region of the world the courier bird flies through: on the campaign map, level cards, postcards and the Level Builder. A place name; short. The ocean far from land.
  ///
  /// In en, this message translates to:
  /// **'Open Sea'**
  String get region_sea;

  /// A boss's name: on its entrance card, health bar, results, the Level Builder and the campaign. A character name: translate the meaning where the English is descriptive (Spitter King, Dusk Empress), keep or transliterate a proper name. A bat baron.
  ///
  /// In en, this message translates to:
  /// **'Baron Bat'**
  String get boss_baronBat_name;

  /// A boss's name: on its entrance card, health bar, results, the Level Builder and the campaign. A character name: translate the meaning where the English is descriptive (Spitter King, Dusk Empress), keep or transliterate a proper name. A beetle king who spits seeds.
  ///
  /// In en, this message translates to:
  /// **'Spitter King'**
  String get boss_spitterBeetle_name;

  /// A boss's name: on its entrance card, health bar, results, the Level Builder and the campaign. A character name: translate the meaning where the English is descriptive (Spitter King, Dusk Empress), keep or transliterate a proper name. A giant moth empress of twilight.
  ///
  /// In en, this message translates to:
  /// **'Dusk Empress'**
  String get boss_duskMoth_name;

  /// A boss's name: on its entrance card, health bar, results, the Level Builder and the campaign. A character name: translate the meaning where the English is descriptive (Spitter King, Dusk Empress), keep or transliterate a proper name.
  ///
  /// In en, this message translates to:
  /// **'Pirate Captain'**
  String get boss_pirate_name;

  /// A boss's name: on its entrance card, health bar, results, the Level Builder and the campaign. A character name: translate the meaning where the English is descriptive (Spitter King, Dusk Empress), keep or transliterate a proper name.
  ///
  /// In en, this message translates to:
  /// **'Ember Dragon'**
  String get boss_dragon_name;

  /// A boss's name: on its entrance card, health bar, results, the Level Builder and the campaign. A character name: translate the meaning where the English is descriptive (Spitter King, Dusk Empress), keep or transliterate a proper name. A pigeon king; "Coo" is the pigeon sound.
  ///
  /// In en, this message translates to:
  /// **'King Coo'**
  String get boss_kingCoo_name;

  /// A boss's name: on its entrance card, health bar, results, the Level Builder and the campaign. A character name: translate the meaning where the English is descriptive (Spitter King, Dusk Empress), keep or transliterate a proper name. A stone gargoyle with a searchlight.
  ///
  /// In en, this message translates to:
  /// **'Searchlight Gargoyle'**
  String get boss_searchlightGargoyle_name;

  /// A boss's name: on its entrance card, health bar, results, the Level Builder and the campaign. A character name: translate the meaning where the English is descriptive (Spitter King, Dusk Empress), keep or transliterate a proper name. A mummy owl courier from Egypt; the name plays on Nefer- and "hoo" (an owl's call). Keep or transliterate.
  ///
  /// In en, this message translates to:
  /// **'Neferhoo'**
  String get boss_neferhoo_name;

  /// The name of one of the four player birds (a small sparrow-like bird). A pet name: keep it, transliterate it, or use an equally cute local name.
  ///
  /// In en, this message translates to:
  /// **'Pip'**
  String get bird_0_name;

  /// The name of one of the four player birds (a rosy-cheeked bird with a curly crest). A pet name: keep it, transliterate it, or use an equally cute local name.
  ///
  /// In en, this message translates to:
  /// **'Peaches'**
  String get bird_1_name;

  /// The name of one of the four player birds (a tiny mint-green hummingbird). A pet name: keep it, transliterate it, or use an equally cute local name.
  ///
  /// In en, this message translates to:
  /// **'Minty'**
  String get bird_2_name;

  /// The name of one of the four player birds (a dreamy owl). A pet name: keep it, transliterate it, or use an equally cute local name.
  ///
  /// In en, this message translates to:
  /// **'Orbit'**
  String get bird_3_name;

  /// The name of a way to fly, on menus, records and results. The bird follows the player's push-ups on camera.
  ///
  /// In en, this message translates to:
  /// **'Push-Up Flight'**
  String get playMode_pushUp;

  /// The name of a way to fly, on menus, records and results. Each small jump in front of the camera boosts the bird.
  ///
  /// In en, this message translates to:
  /// **'Jump & Fly'**
  String get playMode_jump;

  /// The name of a way to fly, on menus, records and results. The main game: tap the screen to flap.
  ///
  /// In en, this message translates to:
  /// **'Tap & Fly'**
  String get playMode_touch;

  /// The name of a way to fly, on menus, records and results. The bird follows the player's squats on camera.
  ///
  /// In en, this message translates to:
  /// **'Squat & Fly'**
  String get playMode_squat;

  /// The name of campaign chapter 1, a mail route (its boss: Baron Bat). On the map's chapter ribbon (in capitals there), the postcard's signature ("— The Canopy Route") and screen-reader labels. A route name, like the name of a railway line; glossary "chapter".
  ///
  /// In en, this message translates to:
  /// **'The Canopy Route'**
  String get chapter_1_route;

  /// Chapter 1's route name as the round postmark on its postcard prints it, curved along the upper rim: capitals, without a leading article where your language can drop it. The same route as "The Canopy Route". It shrinks to fit the ring; short is better.
  ///
  /// In en, this message translates to:
  /// **'CANOPY ROUTE'**
  String get chapter_1_postmark;

  /// The message on chapter 1's postcard, which arrives after Baron Bat is beaten, written by the friends along the route to the courier (the player's bird). It follows the greeting "Dear courier," on its own line, so it starts as a new sentence. Warm, funny, short: it must fit about seven short lines of the card (keep within 150 characters).
  ///
  /// In en, this message translates to:
  /// **'Letters are landing in the treetops again! The toucans say thank you (very loudly). Baron Bat’s crown is on our mantelpiece.'**
  String get chapter_1_postcard;

  /// The postscript on chapter 1's postcard, after the label "P.S.": a hint about where the next route has gone wrong. One or two short lines (keep within 64 characters).
  ///
  /// In en, this message translates to:
  /// **'The ancient road smells like something is bubbling.'**
  String get chapter_1_postscript;

  /// The name of campaign chapter 2, a mail route (its boss: Spitter King). On the map's chapter ribbon (in capitals there), the postcard's signature ("— The Canopy Route") and screen-reader labels. A route name, like the name of a railway line; glossary "chapter".
  ///
  /// In en, this message translates to:
  /// **'The Ancient Road'**
  String get chapter_2_route;

  /// Chapter 2's route name as the round postmark on its postcard prints it, curved along the upper rim: capitals, without a leading article where your language can drop it. The same route as "The Ancient Road". It shrinks to fit the ring; short is better.
  ///
  /// In en, this message translates to:
  /// **'ANCIENT ROAD'**
  String get chapter_2_postmark;

  /// The message on chapter 2's postcard, which arrives after Spitter King is beaten, written by the friends along the route to the courier (the player's bird). It follows the greeting "Dear courier," on its own line, so it starts as a new sentence. Warm, funny, short: it must fit about seven short lines of the card (keep within 150 characters).
  ///
  /// In en, this message translates to:
  /// **'The caravans are rolling and the only thing brewing is mint tea. We kept the King’s flask crown as a vase.'**
  String get chapter_2_postcard;

  /// The postscript on chapter 2's postcard, after the label "P.S.": a hint about where the next route has gone wrong. One or two short lines (keep within 64 characters).
  ///
  /// In en, this message translates to:
  /// **'The city lamps went dark last night. Bring a light.'**
  String get chapter_2_postscript;

  /// The name of campaign chapter 3, a mail route (its boss: Dusk Empress). On the map's chapter ribbon (in capitals there), the postcard's signature ("— The Canopy Route") and screen-reader labels. A route name, like the name of a railway line; glossary "chapter".
  ///
  /// In en, this message translates to:
  /// **'The Lamplight Line'**
  String get chapter_3_route;

  /// Chapter 3's route name as the round postmark on its postcard prints it, curved along the upper rim: capitals, without a leading article where your language can drop it. The same route as "The Lamplight Line". It shrinks to fit the ring; short is better.
  ///
  /// In en, this message translates to:
  /// **'LAMPLIGHT LINE'**
  String get chapter_3_postmark;

  /// The message on chapter 3's postcard, which arrives after Dusk Empress is beaten, written by the friends along the route to the courier (the player's bird). It follows the greeting "Dear courier," on its own line, so it starts as a new sentence. Warm, funny, short: it must fit about seven short lines of the card (keep within 150 characters).
  ///
  /// In en, this message translates to:
  /// **'The lamps are lit and the night mail is wide awake! Paris sends a croissant. New York sends a pretzel.'**
  String get chapter_3_postcard;

  /// The postscript on chapter 3's postcard, after the label "P.S.": a hint about where the next route has gone wrong. One or two short lines (keep within 64 characters).
  ///
  /// In en, this message translates to:
  /// **'The harbour bells have stopped ringing.'**
  String get chapter_3_postscript;

  /// The name of campaign chapter 4, a mail route (its boss: Pirate Captain). On the map's chapter ribbon (in capitals there), the postcard's signature ("— The Canopy Route") and screen-reader labels. A route name, like the name of a railway line; glossary "chapter".
  ///
  /// In en, this message translates to:
  /// **'The Tide Route'**
  String get chapter_4_route;

  /// Chapter 4's route name as the round postmark on its postcard prints it, curved along the upper rim: capitals, without a leading article where your language can drop it. The same route as "The Tide Route". It shrinks to fit the ring; short is better.
  ///
  /// In en, this message translates to:
  /// **'TIDE ROUTE'**
  String get chapter_4_postmark;

  /// The message on chapter 4's postcard, which arrives after Pirate Captain is beaten, written by the friends along the route to the courier (the player's bird). It follows the greeting "Dear courier," on its own line, so it starts as a new sentence. Warm, funny, short: it must fit about seven short lines of the card (keep within 150 characters).
  ///
  /// In en, this message translates to:
  /// **'The harbour bells ring for letters again, not cannons. The parrot stayed. He says hello.'**
  String get chapter_4_postcard;

  /// The postscript on chapter 4's postcard, after the label "P.S.": a hint about where the next route has gone wrong. One or two short lines (keep within 64 characters).
  ///
  /// In en, this message translates to:
  /// **'They say the sky at the edge of the map is on fire.'**
  String get chapter_4_postscript;

  /// The name of campaign chapter 5, a mail route (its boss: Ember Dragon). On the map's chapter ribbon (in capitals there), the postcard's signature ("— The Canopy Route") and screen-reader labels. A route name, like the name of a railway line; glossary "chapter".
  ///
  /// In en, this message translates to:
  /// **'The Edge of the Map'**
  String get chapter_5_route;

  /// Chapter 5's route name as the round postmark on its postcard prints it, curved along the upper rim: capitals, without a leading article where your language can drop it. The same route as "The Edge of the Map". It shrinks to fit the ring; short is better.
  ///
  /// In en, this message translates to:
  /// **'EDGE OF THE MAP'**
  String get chapter_5_postmark;

  /// The message on chapter 5's postcard, which arrives after Ember Dragon is beaten, written by the friends along the route to the courier (the player's bird). It follows the greeting "Dear courier," on its own line, so it starts as a new sentence. Warm, funny, short: it must fit about seven short lines of the card (keep within 150 characters).
  ///
  /// In en, this message translates to:
  /// **'The sky is clear from pole to pole and every route is running. The whole Sky Club is proud of you.'**
  String get chapter_5_postcard;

  /// The postscript on chapter 5's postcard, after the label "P.S.": a hint about where the next route has gone wrong. One or two short lines (keep within 64 characters).
  ///
  /// In en, this message translates to:
  /// **'The endless sky is still out there, whenever you are.'**
  String get chapter_5_postscript;

  /// Campaign level 1-1 (Jungle): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'First Delivery'**
  String get level_1_1_name;

  /// Campaign level 1-1 (Jungle): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The toucan twins"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A birthday card for the toucan twins'**
  String get level_1_1_cargo;

  /// Campaign level 1-1 (Jungle): who signs the thank-you note on the level's result, after a dash ("— The toucan twins"). The recipients of "A birthday card for the toucan twins". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The toucan twins'**
  String get level_1_1_sender;

  /// Campaign level 1-1 (Jungle): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Tap to flap. Fly through the stars.'**
  String get level_1_1_hint;

  /// Campaign level 1-2 (Jungle): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Star Streak'**
  String get level_1_2_name;

  /// Campaign level 1-2 (Jungle): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The sloth stargazer"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Star charts for the sloth stargazer'**
  String get level_1_2_cargo;

  /// Campaign level 1-2 (Jungle): who signs the thank-you note on the level's result, after a dash ("— The sloth stargazer"). The recipients of "Star charts for the sloth stargazer". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The sloth stargazer'**
  String get level_1_2_sender;

  /// Campaign level 1-2 (Jungle): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Chain stars for 3×; three perfect gates earn a magnet.'**
  String get level_1_2_hint;

  /// Campaign level 1-3 (Jungle): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Bat Patrol'**
  String get level_1_3_name;

  /// Campaign level 1-3 (Jungle): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The firefly nursery"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Night-lights for the firefly nursery'**
  String get level_1_3_cargo;

  /// Campaign level 1-3 (Jungle): who signs the thank-you note on the level's result, after a dash ("— The firefly nursery"). The recipients of "Night-lights for the firefly nursery". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The firefly nursery'**
  String get level_1_3_sender;

  /// Campaign level 1-3 (Jungle): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Shoot. Tap Shoot to knock out bats.'**
  String get level_1_3_hint;

  /// Campaign level 1-4 (Brazil): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Carnival Skies'**
  String get level_1_4_name;

  /// Campaign level 1-4 (Brazil): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The samba macaws"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Feather boas for the carnival parade'**
  String get level_1_4_cargo;

  /// Campaign level 1-4 (Brazil): who signs the thank-you note on the level's result, after a dash ("— The samba macaws"). The recipients of "Feather boas for the carnival parade". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The samba macaws'**
  String get level_1_4_sender;

  /// Campaign level 1-4 (Brazil): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Gale! Watch the ! and dodge the footballs.'**
  String get level_1_4_hint;

  /// Campaign level 1-5 (Brazil): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Express Post'**
  String get level_1_5_name;

  /// Campaign level 1-5 (Brazil): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The drum captain"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A rush invitation for the drum captain'**
  String get level_1_5_cargo;

  /// Campaign level 1-5 (Brazil): who signs the thank-you note on the level's result, after a dash ("— The drum captain"). The recipients of "A rush invitation for the drum captain". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The drum captain'**
  String get level_1_5_sender;

  /// Campaign level 1-5 (Brazil): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Sprint smashes bats and surges ahead.'**
  String get level_1_5_hint;

  /// Campaign level 1-6 (Aztec): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Temple Steps'**
  String get level_1_6_name;

  /// Campaign level 1-6 (Aztec): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The temple cooks"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Cocoa beans for the temple cooks'**
  String get level_1_6_cargo;

  /// Campaign level 1-6 (Aztec): who signs the thank-you note on the level's result, after a dash ("— The temple cooks"). The recipients of "Cocoa beans for the temple cooks". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The temple cooks'**
  String get level_1_6_sender;

  /// Campaign level 1-7 (Aztec): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Sunrise Roost'**
  String get level_1_7_name;

  /// Campaign level 1-7 (Aztec): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The dawn keeper"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A sundial for the dawn keeper'**
  String get level_1_7_cargo;

  /// Campaign level 1-7 (Aztec): who signs the thank-you note on the level's result, after a dash ("— The dawn keeper"). The recipients of "A sundial for the dawn keeper". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The dawn keeper'**
  String get level_1_7_sender;

  /// Campaign level 1-8 (Aztec, the lair of Baron Bat): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home. This boss level is named after its boss: use the same words as the boss's name.
  ///
  /// In en, this message translates to:
  /// **'Baron Bat'**
  String get level_1_8_name;

  /// Campaign level 1-8 (Aztec, the lair of Baron Bat): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "Baron Bat"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A final notice for Baron Bat'**
  String get level_1_8_cargo;

  /// Campaign level 1-8 (Aztec, the lair of Baron Bat): who signs the thank-you note on the level's result, after a dash ("— Baron Bat"). The recipients of "A final notice for Baron Bat". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Baron Bat'**
  String get level_1_8_sender;

  /// Campaign level 2-1 (Ancient Rome): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Beetle Road'**
  String get level_2_1_name;

  /// Campaign level 2-1 (Ancient Rome): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The chariot racers"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Laurel wreaths for the chariot racers'**
  String get level_2_1_cargo;

  /// Campaign level 2-1 (Ancient Rome): who signs the thank-you note on the level's result, after a dash ("— The chariot racers"). The recipients of "Laurel wreaths for the chariot racers". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The chariot racers'**
  String get level_2_1_sender;

  /// Campaign level 2-1 (Ancient Rome): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Beetles spit seeds. Shoot the seeds down.'**
  String get level_2_1_hint;

  /// Campaign level 2-2 (Ancient Rome): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Sealed Gates'**
  String get level_2_2_name;

  /// Campaign level 2-2 (Ancient Rome): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The statue carver"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A new chisel for the statue carver'**
  String get level_2_2_cargo;

  /// Campaign level 2-2 (Ancient Rome): who signs the thank-you note on the level's result, after a dash ("— The statue carver"). The recipients of "A new chisel for the statue carver". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The statue carver'**
  String get level_2_2_sender;

  /// Campaign level 2-2 (Ancient Rome): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Hold Shoot for a big rock that breaks stone.'**
  String get level_2_2_hint;

  /// Campaign level 2-3 (Ancient Rome): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Wildfire Run'**
  String get level_2_3_name;

  /// Campaign level 2-3 (Ancient Rome): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The fire brigade"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Water buckets for the fire brigade'**
  String get level_2_3_cargo;

  /// Campaign level 2-3 (Ancient Rome): who signs the thank-you note on the level's result, after a dash ("— The fire brigade"). The recipients of "Water buckets for the fire brigade". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The fire brigade'**
  String get level_2_3_sender;

  /// Campaign level 2-3 (Ancient Rome): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Fly through the gold rings to outrun the fire!'**
  String get level_2_3_hint;

  /// Campaign level 2-4 (Egypt): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Nile Switchbacks'**
  String get level_2_4_name;

  /// Campaign level 2-4 (Egypt): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The Sphinx"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A book of new riddles for the Sphinx'**
  String get level_2_4_cargo;

  /// Campaign level 2-4 (Egypt): who signs the thank-you note on the level's result, after a dash ("— The Sphinx"). The recipients of "A book of new riddles for the Sphinx". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The Sphinx'**
  String get level_2_4_sender;

  /// Campaign level 2-5 (Egypt): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Skyfall'**
  String get level_2_5_name;

  /// Campaign level 2-5 (Egypt): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The pyramid astronomer"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A telescope for the pyramid astronomer'**
  String get level_2_5_cargo;

  /// Campaign level 2-5 (Egypt): who signs the thank-you note on the level's result, after a dash ("— The pyramid astronomer"). The recipients of "A telescope for the pyramid astronomer". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The pyramid astronomer'**
  String get level_2_5_sender;

  /// Campaign level 2-5 (Egypt): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Ring sprints smash meteors.'**
  String get level_2_5_hint;

  /// Campaign level 2-6 (Egypt, guarded by Neferhoo): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home. "Return to sender!" is Neferhoo's catchphrase (glossary catchphrase): echo it.
  ///
  /// In en, this message translates to:
  /// **'Return to Sender'**
  String get level_2_6_name;

  /// Campaign level 2-6 (Egypt, guarded by Neferhoo): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The pyramid caretaker"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A feather duster for the caretaker'**
  String get level_2_6_cargo;

  /// Campaign level 2-6 (Egypt, guarded by Neferhoo): who signs the thank-you note on the level's result, after a dash ("— The pyramid caretaker"). The recipients of "A feather duster for the caretaker". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The pyramid caretaker'**
  String get level_2_6_sender;

  /// Campaign level 2-6 (Egypt, guarded by Neferhoo): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Shoot his letters to send them back. Return to sender!'**
  String get level_2_6_hint;

  /// Campaign level 2-7 (Ancient Arabia): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Lantern Bazaar'**
  String get level_2_7_name;

  /// Campaign level 2-7 (Ancient Arabia): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The lantern sellers"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Lamp oil for the lantern sellers'**
  String get level_2_7_cargo;

  /// Campaign level 2-7 (Ancient Arabia): who signs the thank-you note on the level's result, after a dash ("— The lantern sellers"). The recipients of "Lamp oil for the lantern sellers". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The lantern sellers'**
  String get level_2_7_sender;

  /// Campaign level 2-8 (Ancient Arabia): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'The Long Caravan'**
  String get level_2_8_name;

  /// Campaign level 2-8 (Ancient Arabia): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The caravan leader"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Water flasks for the long caravan'**
  String get level_2_8_cargo;

  /// Campaign level 2-8 (Ancient Arabia): who signs the thank-you note on the level's result, after a dash ("— The caravan leader"). The recipients of "Water flasks for the long caravan". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The caravan leader'**
  String get level_2_8_sender;

  /// Campaign level 2-9 (Ancient Arabia, the lair of Spitter King): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home. This boss level is named after its boss: use the same words as the boss's name.
  ///
  /// In en, this message translates to:
  /// **'Spitter King'**
  String get level_2_9_name;

  /// Campaign level 2-9 (Ancient Arabia, the lair of Spitter King): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "Spitter King"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A stop-brewing order for the Spitter King'**
  String get level_2_9_cargo;

  /// Campaign level 2-9 (Ancient Arabia, the lair of Spitter King): who signs the thank-you note on the level's result, after a dash ("— Spitter King"). The recipients of "A stop-brewing order for the Spitter King". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Spitter King'**
  String get level_2_9_sender;

  /// Campaign level 3-1 (New York): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Moth Light'**
  String get level_3_1_name;

  /// Campaign level 3-1 (New York): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The stage manager"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Light bulbs for the theatre marquee'**
  String get level_3_1_cargo;

  /// Campaign level 3-1 (New York): who signs the thank-you note on the level's result, after a dash ("— The stage manager"). The recipients of "Light bulbs for the theatre marquee". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The stage manager'**
  String get level_3_1_sender;

  /// Campaign level 3-1 (New York): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Moths fire fans of three. Slip between them.'**
  String get level_3_1_hint;

  /// Campaign level 3-2 (New York, guarded by King Coo): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Wheels in the Rain'**
  String get level_3_2_name;

  /// Campaign level 3-2 (New York, guarded by King Coo): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The newsstand pigeons"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Umbrellas for the newsstand pigeons'**
  String get level_3_2_cargo;

  /// Campaign level 3-2 (New York, guarded by King Coo): who signs the thank-you note on the level's result, after a dash ("— The newsstand pigeons"). The recipients of "Umbrellas for the newsstand pigeons". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The newsstand pigeons'**
  String get level_3_2_sender;

  /// Campaign level 3-2 (New York, guarded by King Coo): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Alley pigeons swoop in to grab stars. Shoot them first!'**
  String get level_3_2_hint;

  /// Campaign level 3-3 (New York): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Steam Alley'**
  String get level_3_3_name;

  /// Campaign level 3-3 (New York): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The night cabbies"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Hot pretzels for the night-shift cabbies'**
  String get level_3_3_cargo;

  /// Campaign level 3-3 (New York): who signs the thank-you note on the level's result, after a dash ("— The night cabbies"). The recipients of "Hot pretzels for the night-shift cabbies". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The night cabbies'**
  String get level_3_3_sender;

  /// Campaign level 3-3 (New York): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Vents hiss, then burst. Hop the hot ones, ride the soft ones.'**
  String get level_3_3_hint;

  /// Campaign level 3-4 (New York, guarded by Searchlight Gargoyle): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Storm Warning'**
  String get level_3_4_name;

  /// Campaign level 3-4 (New York, guarded by Searchlight Gargoyle): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The tower keeper"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A weather vane for the tallest tower'**
  String get level_3_4_cargo;

  /// Campaign level 3-4 (New York, guarded by Searchlight Gargoyle): who signs the thank-you note on the level's result, after a dash ("— The tower keeper"). The recipients of "A weather vane for the tallest tower". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The tower keeper'**
  String get level_3_4_sender;

  /// Campaign level 3-4 (New York, guarded by Searchlight Gargoyle): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Stay out of the light. Shoot the lamp when it opens! No Sprint here.'**
  String get level_3_4_hint;

  /// Campaign level 3-5 (Paris): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Crystal Rooftops'**
  String get level_3_5_name;

  /// Campaign level 3-5 (Paris): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The rooftop painters"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Croissants for the rooftop painters'**
  String get level_3_5_cargo;

  /// Campaign level 3-5 (Paris): who signs the thank-you note on the level's result, after a dash ("— The rooftop painters"). The recipients of "Croissants for the rooftop painters". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The rooftop painters'**
  String get level_3_5_sender;

  /// Campaign level 3-6 (Paris): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'After the Gale'**
  String get level_3_6_name;

  /// Campaign level 3-6 (Paris): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The accordion player"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Sheet music for the accordion player'**
  String get level_3_6_cargo;

  /// Campaign level 3-6 (Paris): who signs the thank-you note on the level's result, after a dash ("— The accordion player"). The recipients of "Sheet music for the accordion player". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The accordion player'**
  String get level_3_6_sender;

  /// Campaign level 3-6 (Paris): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Gale! Watch the ! and take the open side.'**
  String get level_3_6_hint;

  /// Campaign level 3-7 (Paris): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Midnight Express'**
  String get level_3_7_name;

  /// Campaign level 3-7 (Paris): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The baker"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A midnight love letter for the baker'**
  String get level_3_7_cargo;

  /// Campaign level 3-7 (Paris): who signs the thank-you note on the level's result, after a dash ("— The baker"). The recipients of "A midnight love letter for the baker". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The baker'**
  String get level_3_7_sender;

  /// Campaign level 3-7 (Paris): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Sprint through the flocks.'**
  String get level_3_7_hint;

  /// Campaign level 3-8 (Paris, the lair of Dusk Empress): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home. This boss level is named after its boss: use the same words as the boss's name.
  ///
  /// In en, this message translates to:
  /// **'Dusk Empress'**
  String get level_3_8_name;

  /// Campaign level 3-8 (Paris, the lair of Dusk Empress): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "Dusk Empress"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A wake-up call for the Dusk Empress'**
  String get level_3_8_cargo;

  /// Campaign level 3-8 (Paris, the lair of Dusk Empress): who signs the thank-you note on the level's result, after a dash ("— Dusk Empress"). The recipients of "A wake-up call for the Dusk Empress". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Dusk Empress'**
  String get level_3_8_sender;

  /// Campaign level 4-1 (Mexico): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Harbour Lights'**
  String get level_4_1_name;

  /// Campaign level 4-1 (Mexico): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The lighthouse keeper"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A new lens for the lighthouse keeper'**
  String get level_4_1_cargo;

  /// Campaign level 4-1 (Mexico): who signs the thank-you note on the level's result, after a dash ("— The lighthouse keeper"). The recipients of "A new lens for the lighthouse keeper". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The lighthouse keeper'**
  String get level_4_1_sender;

  /// Campaign level 4-2 (Mexico): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Volcano Pass'**
  String get level_4_2_name;

  /// Campaign level 4-2 (Mexico): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The volcano baker"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Oven mitts for the volcano baker'**
  String get level_4_2_cargo;

  /// Campaign level 4-2 (Mexico): who signs the thank-you note on the level's result, after a dash ("— The volcano baker"). The recipients of "Oven mitts for the volcano baker". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The volcano baker'**
  String get level_4_2_sender;

  /// Campaign level 4-2 (Mexico): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Hop over the lava plumes.'**
  String get level_4_2_hint;

  /// Campaign level 4-3 (Mexico): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Down the Coast'**
  String get level_4_3_name;

  /// Campaign level 4-3 (Mexico): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The kite flyers"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Kite string for the beach festival'**
  String get level_4_3_cargo;

  /// Campaign level 4-3 (Mexico): who signs the thank-you note on the level's result, after a dash ("— The kite flyers"). The recipients of "Kite string for the beach festival". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The kite flyers'**
  String get level_4_3_sender;

  /// Campaign level 4-4 (Open Sea): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Low Water'**
  String get level_4_4_name;

  /// Campaign level 4-4 (Open Sea): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The island hermit"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A reply for the island hermit'**
  String get level_4_4_cargo;

  /// Campaign level 4-4 (Open Sea): who signs the thank-you note on the level's result, after a dash ("— The island hermit"). The recipients of "A reply for the island hermit". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The island hermit'**
  String get level_4_4_sender;

  /// Campaign level 4-4 (Open Sea): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Don\'t touch the water.'**
  String get level_4_4_hint;

  /// Campaign level 4-5 (Open Sea): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Spring Tide'**
  String get level_4_5_name;

  /// Campaign level 4-5 (Open Sea): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The ferry crew"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A tide table for the ferry crew'**
  String get level_4_5_cargo;

  /// Campaign level 4-5 (Open Sea): who signs the thank-you note on the level's result, after a dash ("— The ferry crew"). The recipients of "A tide table for the ferry crew". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The ferry crew'**
  String get level_4_5_sender;

  /// Campaign level 4-5 (Open Sea): the one-line lesson on the level card, under a NEW tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'When the bell rings, fly high.'**
  String get level_4_5_hint;

  /// Campaign level 4-6 (Open Sea): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Broadside Bay'**
  String get level_4_6_name;

  /// Campaign level 4-6 (Open Sea): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The gull colony"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Fish biscuits for the gull colony'**
  String get level_4_6_cargo;

  /// Campaign level 4-6 (Open Sea): who signs the thank-you note on the level's result, after a dash ("— The gull colony"). The recipients of "Fish biscuits for the gull colony". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The gull colony'**
  String get level_4_6_sender;

  /// Campaign level 4-7 (Open Sea): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Stormy Crossing'**
  String get level_4_7_name;

  /// Campaign level 4-7 (Open Sea): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The storm watch"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Dry socks for the storm-watch sailors'**
  String get level_4_7_cargo;

  /// Campaign level 4-7 (Open Sea): who signs the thank-you note on the level's result, after a dash ("— The storm watch"). The recipients of "Dry socks for the storm-watch sailors". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The storm watch'**
  String get level_4_7_sender;

  /// Campaign level 4-8 (Open Sea, the lair of Pirate Captain): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home. This boss level is named after its boss: use the same words as the boss's name.
  ///
  /// In en, this message translates to:
  /// **'Pirate Captain'**
  String get level_4_8_name;

  /// Campaign level 4-8 (Open Sea, the lair of Pirate Captain): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "Pirate Captain"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A return-the-mail order for the Captain'**
  String get level_4_8_cargo;

  /// Campaign level 4-8 (Open Sea, the lair of Pirate Captain): who signs the thank-you note on the level's result, after a dash ("— Pirate Captain"). The recipients of "A return-the-mail order for the Captain". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Pirate Captain'**
  String get level_4_8_sender;

  /// Campaign level 5-1 (Antarctica): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Aurora Post'**
  String get level_5_1_name;

  /// Campaign level 5-1 (Antarctica): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The penguin choir"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Woolly hats for the penguin choir'**
  String get level_5_1_cargo;

  /// Campaign level 5-1 (Antarctica): who signs the thank-you note on the level's result, after a dash ("— The penguin choir"). The recipients of "Woolly hats for the penguin choir". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The penguin choir'**
  String get level_5_1_sender;

  /// Campaign level 5-1 (Antarctica): the one-line lesson on the level card, under a TIP tag: what is new in this level and how to play it. Short imperative sentences; two lines at most on the card. Keep game terms as in the glossary (Shoot, Sprint, gale, ring sprint, perfect gate).
  ///
  /// In en, this message translates to:
  /// **'Any rush can come now. Read the banner!'**
  String get level_5_1_hint;

  /// Campaign level 5-2 (Antarctica): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Polar Night'**
  String get level_5_2_name;

  /// Campaign level 5-2 (Antarctica): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The polar station"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Hot cocoa for the polar station'**
  String get level_5_2_cargo;

  /// Campaign level 5-2 (Antarctica): who signs the thank-you note on the level's result, after a dash ("— The polar station"). The recipients of "Hot cocoa for the polar station". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The polar station'**
  String get level_5_2_sender;

  /// Campaign level 5-3 (Cyberpunk City): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Neon Express'**
  String get level_5_3_name;

  /// Campaign level 5-3 (Cyberpunk City): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The noodle chef"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Spare fuses for the noodle bar sign'**
  String get level_5_3_cargo;

  /// Campaign level 5-3 (Cyberpunk City): who signs the thank-you note on the level's result, after a dash ("— The noodle chef"). The recipients of "Spare fuses for the noodle bar sign". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The noodle chef'**
  String get level_5_3_sender;

  /// Campaign level 5-4 (Cyberpunk City): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Data Storm'**
  String get level_5_4_name;

  /// Campaign level 5-4 (Cyberpunk City): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "Unit 7"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'A paper letter for a curious robot'**
  String get level_5_4_cargo;

  /// Campaign level 5-4 (Cyberpunk City): who signs the thank-you note on the level's result, after a dash ("— Unit 7"). The recipients of "A paper letter for a curious robot". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Unit 7'**
  String get level_5_4_sender;

  /// Campaign level 5-5 (Cyberpunk City): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Skyline Sprint'**
  String get level_5_5_name;

  /// Campaign level 5-5 (Cyberpunk City): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The rooftop runners"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Race tickets for the rooftop runners'**
  String get level_5_5_cargo;

  /// Campaign level 5-5 (Cyberpunk City): who signs the thank-you note on the level's result, after a dash ("— The rooftop runners"). The recipients of "Race tickets for the rooftop runners". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The rooftop runners'**
  String get level_5_5_sender;

  /// Campaign level 5-6 (China): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'Lantern Festival'**
  String get level_5_6_name;

  /// Campaign level 5-6 (China): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The lantern makers"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Paper lanterns for the festival'**
  String get level_5_6_cargo;

  /// Campaign level 5-6 (China): who signs the thank-you note on the level's result, after a dash ("— The lantern makers"). The recipients of "Paper lanterns for the festival". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The lantern makers'**
  String get level_5_6_sender;

  /// Campaign level 5-7 (China): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home.
  ///
  /// In en, this message translates to:
  /// **'The Last Leg'**
  String get level_5_7_name;

  /// Campaign level 5-7 (China): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "The mountain monks"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'Mountain tea for the monastery'**
  String get level_5_7_cargo;

  /// Campaign level 5-7 (China): who signs the thank-you note on the level's result, after a dash ("— The mountain monks"). The recipients of "Mountain tea for the monastery". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'The mountain monks'**
  String get level_5_7_sender;

  /// Campaign level 5-8 (China, the lair of Ember Dragon): the level's name, a short title. On the level card (large heading), the map's name tag, the result screen, Records and Home. This boss level is named after its boss: use the same words as the boss's name.
  ///
  /// In en, this message translates to:
  /// **'Ember Dragon'**
  String get level_5_8_name;

  /// Campaign level 5-8 (China, the lair of Ember Dragon): what the courier delivers there, handwritten on the level card's SPECIAL DELIVERY parcel tag (two short lines). A noun phrase, sentence case, no full stop. The recipients sign the thank-you as "Ember Dragon"; keep the two consistent.
  ///
  /// In en, this message translates to:
  /// **'The first letter ever sent to the Dragon'**
  String get level_5_8_cargo;

  /// Campaign level 5-8 (China, the lair of Ember Dragon): who signs the thank-you note on the level's result, after a dash ("— Ember Dragon"). The recipients of "The first letter ever sent to the Dragon". Capital first letter, no full stop; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Ember Dragon'**
  String get level_5_8_sender;

  /// Story scenes: the name tag under the Sky Club's postmaster, a kindly old bird, whenever he speaks. A name and title (glossary "Postmaster Bill": keep Bill).
  ///
  /// In en, this message translates to:
  /// **'Postmaster Bill'**
  String get storyPostmasterName;

  /// Story scenes: the key in the top corner that skips the rest of the scene, and its screen-reader label. One short verb.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get storySkip;

  /// Story scenes, screen reader: tapping the scene moves to the next line of the conversation.
  ///
  /// In en, this message translates to:
  /// **'Next line'**
  String get storyNextLineSemantics;

  /// Story scenes, screen reader: tapping the scene on its last line ends it.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get storyFinishSemantics;

  /// Story scenes, screen reader: a spoken line, read with its speaker's name first.
  ///
  /// In en, this message translates to:
  /// **'{name}: {line}'**
  String storyLineSemantics(String name, String line);

  /// The Sky Club's motto, which opens and closes the story: under the game's logo on the launch and home screens. Short, proud, like a slogan (glossary motto "Every letter lands.": the story's lines use the same words).
  ///
  /// In en, this message translates to:
  /// **'Every letter lands.'**
  String get campaignMotto;

  /// Screen reader label of the logo on the launch and home screens: the game's name ({brand}, "Beakbound", never translated) and its motto.
  ///
  /// In en, this message translates to:
  /// **'{brand}. {motto}'**
  String launchSemantics(String brand, String motto);

  /// Level card: the big button that starts the flight. One short verb, an eager command.
  ///
  /// In en, this message translates to:
  /// **'Fly!'**
  String get levelIntroFly;

  /// Level card, boss level: how long the flight runs before the boss appears, on a small pill. "s" is seconds.
  ///
  /// In en, this message translates to:
  /// **'A {seconds} s run-up first'**
  String levelIntroRunUp(int seconds);

  /// Level card: roughly how long the flight takes, on a small pill. "s" is seconds.
  ///
  /// In en, this message translates to:
  /// **'About {seconds} s to the finish'**
  String levelIntroLength(int seconds);

  /// The label of a guardian (a mini-boss that blocks the route before the chapter's boss): on the level card's ribbon and on the plaque under its shield on the map. Capitals, one word (glossary "GUARDIAN").
  ///
  /// In en, this message translates to:
  /// **'GUARDIAN'**
  String get campaignGuardian;

  /// Level card of a chapter's boss level: the tag on its colourful band. Capitals, very short.
  ///
  /// In en, this message translates to:
  /// **'BOSS FIGHT'**
  String get levelIntroBossFight;

  /// Level card: the small tag before a hint that teaches something new. Capitals, very short.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get levelIntroNew;

  /// Level card: the small tag before a hint that reminds of something already taught. Capitals, very short.
  ///
  /// In en, this message translates to:
  /// **'TIP'**
  String get levelIntroTip;

  /// Level card and result: the one-star goal of a boss level. {boss} is the boss's name ("Baron Bat"). {bossId} is the boss's id (baronBat, spitterBeetle, duskMoth, pirate, dragon, kingCoo, searchlightGargoyle, neferhoo): select on it for the article or case the name takes in your language, e.g. "{bossId, select, duskMoth{die {boss}} dragon{den Glutdrachen} other{den {boss}}}"; keep {boss} wherever the name is written as is, and always end with other{…} for a boss added later.
  ///
  /// In en, this message translates to:
  /// **'{bossId, select, other{Beat {boss}}}'**
  String levelIntroGoalBeat(String boss, String bossId);

  /// Level card and result: the one-star goal of an ordinary level (fly to the finish line).
  ///
  /// In en, this message translates to:
  /// **'Reach the finish'**
  String get levelIntroGoalFinish;

  /// Level card and result: a two- or three-star goal, collect this many stars in the flight.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Collect 1 star} other{Collect {count} stars}}'**
  String levelIntroGoalCollect(int count);

  /// Level card and result, screen reader: one of the three star goals (one, two or three stars) and what earns it ({goal}, a goal such as "Collect 25 stars").
  ///
  /// In en, this message translates to:
  /// **'{stars, select, one{One star: {goal}.} two{Two stars: {goal}.} other{Three stars: {goal}.}}'**
  String levelIntroGoalSemantics(String stars, String goal);

  /// Level card and result, screen reader: a star goal already earned in an earlier flight.
  ///
  /// In en, this message translates to:
  /// **'{stars, select, one{One star: {goal}. Earned.} two{Two stars: {goal}. Earned.} other{Three stars: {goal}. Earned.}}'**
  String levelIntroGoalEarnedSemantics(String stars, String goal);

  /// Level card: the most stars collected in a finished flight of this level, beside the Fly key.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Best: 1 star} other{Best: {count} stars}}'**
  String levelIntroBest(int count);

  /// Level card: the level was flown but never finished (the mail is not delivered yet), beside the Fly key.
  ///
  /// In en, this message translates to:
  /// **'Not delivered yet'**
  String get levelIntroNotDelivered;

  /// Level card: the level has never been flown, beside the Fly key.
  ///
  /// In en, this message translates to:
  /// **'First flight'**
  String get levelIntroFirstFlight;

  /// Level card: a chip naming a control the level offers (tap to flap the wings). One short word.
  ///
  /// In en, this message translates to:
  /// **'Flap'**
  String get levelIntroControlFlap;

  /// Level card: a chip naming the Shoot control (glossary "Shoot"). One short word, the same as the Shoot key in flight.
  ///
  /// In en, this message translates to:
  /// **'Shoot'**
  String get levelIntroControlShoot;

  /// Level card: a chip naming the Sprint control (glossary "Sprint"). One short word, the same as the Sprint key in flight.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get levelIntroControlSprint;

  /// Level card, screen reader: the controls a level offers (the chips above). Use the same words as the chips.
  ///
  /// In en, this message translates to:
  /// **'{controls, select, flap{Controls: Flap.} shoot{Controls: Flap, Shoot.} sprint{Controls: Flap, Sprint.} other{Controls: Flap, Shoot, Sprint.}}'**
  String levelIntroControlsSemantics(String controls);

  /// Level card: printed at the top of the parcel tag, above the cargo written by hand. Capitals, small print (glossary "SPECIAL DELIVERY").
  ///
  /// In en, this message translates to:
  /// **'SPECIAL DELIVERY'**
  String get levelIntroSpecialDelivery;

  /// Level card, screen reader: the parcel tag, with what the courier delivers.
  ///
  /// In en, this message translates to:
  /// **'Special delivery: {cargo}.'**
  String levelIntroCargoSemantics(String cargo);

  /// Level card, screen reader: the card's heading. {level} is the number such as "1-3".
  ///
  /// In en, this message translates to:
  /// **'Level {level}, {name}. {region}.'**
  String levelIntroSemantics(String level, String name, String region);

  /// Level card of a guardian's level, screen reader: the card's heading and the guardian who waits at its end.
  ///
  /// In en, this message translates to:
  /// **'Level {level}, {name}. {region}. Guardian level: {boss}.'**
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  );

  /// Level card: tooltip and screen-reader label of the speech-bubble key that plays the level's story scene again.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get levelIntroStory;

  /// Tooltip and screen-reader label of a round close key (an X).
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// A button that moves on (after a postcard, a result). One short word.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// A button that goes back to the home screen. One short word.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get commonHome;

  /// Tooltip and screen-reader label of the round back key (an arrow) that returns to the home screen.
  ///
  /// In en, this message translates to:
  /// **'Back home'**
  String get commonBackHome;

  /// Campaign map: the yellow ribbon across a stop that this version of the game does not have yet, and the notice when one of its levels is tapped.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get campaignComingSoon;

  /// Campaign map: the yellow ribbon across a stop that is not open yet while the rest of its chapter is ("Paris — coming soon").
  ///
  /// In en, this message translates to:
  /// **'{region} — coming soon'**
  String campaignStopComingSoon(String region);

  /// Campaign map: the notice when a locked level is tapped and the level before it ends in a boss. {bossId} is the boss's id (baronBat, spitterBeetle, duskMoth, pirate, dragon, kingCoo, searchlightGargoyle, neferhoo): select on it for the article or case the name takes in your language, e.g. "{bossId, select, duskMoth{die {boss}} dragon{den Glutdrachen} other{den {boss}}}"; keep {boss} wherever the name is written as is, and always end with other{…} for a boss added later.
  ///
  /// In en, this message translates to:
  /// **'{bossId, select, other{Beat {boss} to unlock}}'**
  String campaignLockedBeat(String boss, String bossId);

  /// Campaign map: the notice when a locked level is tapped; {level} is the number of the level before it, such as "3-1".
  ///
  /// In en, this message translates to:
  /// **'Finish {level} to unlock'**
  String campaignLockedFinish(String level);

  /// Campaign map: the heading when the saved progress cannot be read; buttons Home and Try again follow. Calm and friendly.
  ///
  /// In en, this message translates to:
  /// **'The map needs a moment.'**
  String get campaignMapUnavailable;

  /// Campaign map, screen reader: the dimmed area around a level card; tapping it closes the card of level {name}.
  ///
  /// In en, this message translates to:
  /// **'Close {name}'**
  String campaignCloseLevelSemantics(String name);

  /// Campaign map: tooltip and screen-reader label of the arrow key that turns the map to the previous stop (region) on the route.
  ///
  /// In en, this message translates to:
  /// **'Previous stop'**
  String get campaignMapPreviousStop;

  /// Campaign map: tooltip and screen-reader label of the arrow key that turns the map to the next stop (region) on the route.
  ///
  /// In en, this message translates to:
  /// **'Next stop'**
  String get campaignMapNextStop;

  /// Campaign map, screen reader: the heading of a stop (a region) with its chapter and route, and whether it is not in the game yet (soon) or still locked.
  ///
  /// In en, this message translates to:
  /// **'{state, select, soon{{region}. Chapter {chapter}, {route}. Coming soon.} locked{{region}. Chapter {chapter}, {route}. Locked.} other{{region}. Chapter {chapter}, {route}.}}'**
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  );

  /// Campaign map: the ribbon above each stop's name. {route} is the chapter's route name, which the game sets in capitals. Capitals.
  ///
  /// In en, this message translates to:
  /// **'CHAPTER {chapter} · {route}'**
  String campaignMapChapterBanner(int chapter, String route);

  /// Campaign map, screen reader: a level's button, by kind: a chapter's boss lair, a level guarded by a guardian (a mini-boss, {boss} is its name), or an ordinary level. A state follows (Locked, Next up, stars).
  ///
  /// In en, this message translates to:
  /// **'{kind, select, boss{{level}, {name}, boss} guardian{Level {level}, {name}, guardian {boss}} other{Level {level}, {name}}}'**
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  );

  /// Campaign map, screen reader: a locked level. {node} is the level label above ("Level 1-3, Bat Patrol").
  ///
  /// In en, this message translates to:
  /// **'{node}. Locked.'**
  String campaignMapNodeLocked(String node);

  /// Campaign map, screen reader: a locked level and what unlocks it. {note} is the notice "Beat King Coo to unlock".
  ///
  /// In en, this message translates to:
  /// **'{node}. Locked. {note}.'**
  String campaignMapNodeLockedNote(String node, String note);

  /// Campaign map, screen reader: the level to fly next (where the bird perches) and its best stars out of three.
  ///
  /// In en, this message translates to:
  /// **'{node}. Next up. {stars, plural, other{{stars} of 3 stars}}.'**
  String campaignMapNodeNext(String node, int stars);

  /// Campaign map, screen reader: an open level and its best stars out of three.
  ///
  /// In en, this message translates to:
  /// **'{node}. {stars, plural, other{{stars} of 3 stars}}.'**
  String campaignMapNodeStars(String node, int stars);

  /// Campaign map on a narrow phone: a guardian's name set short on the plaque under its shield. {name} is the full name; give a shorter form only where the full name is long (Searchlight Gargoyle → Gargoyle).
  ///
  /// In en, this message translates to:
  /// **'{boss, select, searchlightGargoyle{Gargoyle} other{{name}}}'**
  String campaignMapGuardianShort(String boss, String name);

  /// Campaign map, screen reader: the postcard waiting beside a beaten boss's lair; tapping it shows the postcard again.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter} postcard'**
  String campaignMapPostcardSemantics(int chapter);

  /// Campaign map, screen reader: the star total in the top corner (stars earned of all the campaign's level stars).
  ///
  /// In en, this message translates to:
  /// **'{total, plural, other{{stars} of {total} campaign stars}}'**
  String campaignStarTotalSemantics(int stars, int total);

  /// Chapter postcard: the greeting written by hand above the message, to the player's bird (glossary "courier", "Dear courier"). The message follows on the next line.
  ///
  /// In en, this message translates to:
  /// **'Dear courier,'**
  String get campaignPostcardGreeting;

  /// Chapter postcard: the label before the postscript, as in a letter ("P.S."). Very short.
  ///
  /// In en, this message translates to:
  /// **'P.S.'**
  String get campaignPostcardPs;

  /// Chapter postcard, screen reader: the whole card read aloud: who sends it ({route}, the chapter's route), the greeting, the message and the postscript. Use the same greeting and P.S. label as the card.
  ///
  /// In en, this message translates to:
  /// **'Postcard from {route}. Dear courier, {body} P.S. {postscript}'**
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  );

  /// Chapter postcard, picture side: the small ribbon above the big region name, as on a holiday postcard ("Greetings from / AZTEC").
  ///
  /// In en, this message translates to:
  /// **'Greetings from'**
  String get campaignPostcardGreetingsFrom;

  /// Chapter postcard, message side: printed small across the top of the card. Capitals (glossary "Sky Club").
  ///
  /// In en, this message translates to:
  /// **'SKY CLUB POSTCARD'**
  String get campaignPostcardHeader;

  /// Chapter postcard: the handwritten signature at the foot of the message; the friends along the route ({route}) sign it. Keep the dash or use your language's sign-off mark.
  ///
  /// In en, this message translates to:
  /// **'— {route}'**
  String campaignPostcardSignature(String route);

  /// Chapter postcard: the first handwritten address line, the addressee (the player's bird, glossary "courier").
  ///
  /// In en, this message translates to:
  /// **'The courier'**
  String get campaignPostcardAddressName;

  /// Chapter postcard: the second address line, the post office where the courier works (glossary "Sky Club post").
  ///
  /// In en, this message translates to:
  /// **'Sky Club post'**
  String get campaignPostcardAddressStreet;

  /// Chapter postcard: the third address line, playfully where the post office is.
  ///
  /// In en, this message translates to:
  /// **'Up in the sky'**
  String get campaignPostcardAddressCity;

  /// Chapter postcard: the word in the middle of the round postmark (the mail was delivered). Capitals, tiny print.
  ///
  /// In en, this message translates to:
  /// **'DELIVERED'**
  String get campaignPostmarkDelivered;

  /// Chapter postcard: the words curved along the lower rim of the round postmark (glossary "Sky Club post"). Capitals; it shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'SKY CLUB POST'**
  String get campaignPostmarkClub;

  /// The postage stamp of a beaten boss (on its postcard and in the collection): the club's name printed on the stamp's band. Capitals, tiny (glossary "Sky Club").
  ///
  /// In en, this message translates to:
  /// **'SKY CLUB'**
  String get campaignStampSkyClub;

  /// Level result: a thank-you note's words ({thanks}) in your language's quotation marks, handwritten on the note.
  ///
  /// In en, this message translates to:
  /// **'“{thanks}”'**
  String campaignThanksQuoted(String thanks);

  /// Level result: the signature under a thank-you note; {sender} signs it ("The toucan twins"). Keep the dash or use your language's sign-off mark.
  ///
  /// In en, this message translates to:
  /// **'— {sender}'**
  String campaignThanksSignature(String sender);

  /// Level result, screen reader: the thank-you note, its signer and its words.
  ///
  /// In en, this message translates to:
  /// **'Thank-you note from {sender}: {thanks}'**
  String campaignThanksSemantics(String sender, String thanks);

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Screen title for the push-up flight, one line beside the back key; shrinks to fit. Playful, two short sentences.
  ///
  /// In en, this message translates to:
  /// **'A little setup. A lot of sky.'**
  String get flightSetupTitlePushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Screen title for Squat & Fly, one line; shrinks to fit. Playful, two short sentences.
  ///
  /// In en, this message translates to:
  /// **'Feet planted. Wings open.'**
  String get flightSetupTitleSquat;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Screen title for Jump & Fly, one line; shrinks to fit. Playful, two short sentences.
  ///
  /// In en, this message translates to:
  /// **'Small jumps. Big wings.'**
  String get flightSetupTitleJump;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Small capital tag in the title row when the flight is a Level Builder level. {name} is the level name the player typed, in capitals (never translated).
  ///
  /// In en, this message translates to:
  /// **'LEVEL · {name}'**
  String flightSetupBuiltTag(String name);

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Small capital tag in the title row: the course name in capitals ({course}, e.g. ENDLESS) and that the flight is scored.
  ///
  /// In en, this message translates to:
  /// **'{course} · SCORED'**
  String flightSetupScoredTag(String course);

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Big line under the picture of the player and the phone (push-ups); one line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Make a little room to move.'**
  String get flightSetupRoomPushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Big line under the picture of the player and the phone (squats and jumps); one line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Show your whole body.'**
  String get flightSetupRoomBody;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Two short centred lines (keep the line break) under the big line: where to put the phone for push-ups.
  ///
  /// In en, this message translates to:
  /// **'Phone low. Show an arm and hip.\nFacing it? Keep both shoulders in view.'**
  String get flightSetupTipsPushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Two short centred lines (keep the line break): how squats steer the bird.
  ///
  /// In en, this message translates to:
  /// **'Squat to descend. Stand to rise.\nKeep both feet on the floor.'**
  String get flightSetupTipsSquat;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Two short centred lines (keep the line break): how jumps steer the bird. "3s" = 3 seconds.
  ///
  /// In en, this message translates to:
  /// **'Jump for a boost + 3s glide.\nLand before jumping again.'**
  String get flightSetupTipsJump;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Small capital heading over the three numbered steps.
  ///
  /// In en, this message translates to:
  /// **'HOW TO FLY'**
  String get flightSetupHowToFly;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 1 title (push-ups), one line in a small card; the steps shrink together if long.
  ///
  /// In en, this message translates to:
  /// **'Show your arm and hip'**
  String get flightSetupStep1PushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 1 title (squats).
  ///
  /// In en, this message translates to:
  /// **'Make room to squat'**
  String get flightSetupStep1Squat;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 1 title (jumps).
  ///
  /// In en, this message translates to:
  /// **'Make room to jump'**
  String get flightSetupStep1Jump;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 1 detail under its title (push-ups); one or two short lines.
  ///
  /// In en, this message translates to:
  /// **'Facing the phone? Show both shoulders, one arm and a hip.'**
  String get flightSetupStep1DetailPushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 1 detail under its title (squats and jumps); one or two short lines.
  ///
  /// In en, this message translates to:
  /// **'Phone in landscape. Show your body and both feet.'**
  String get flightSetupStep1DetailBody;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 2 title (push-ups).
  ///
  /// In en, this message translates to:
  /// **'Find your movement range'**
  String get flightSetupStep2PushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 2 title (squats).
  ///
  /// In en, this message translates to:
  /// **'Find your comfortable squat'**
  String get flightSetupStep2Squat;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 2 title (jumps).
  ///
  /// In en, this message translates to:
  /// **'Stand tall and still'**
  String get flightSetupStep2Jump;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 2 detail (push-ups): calibration takes two push-ups.
  ///
  /// In en, this message translates to:
  /// **'Find a comfortable top, then move down and up twice.'**
  String get flightSetupStep2DetailPushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 2 detail (squats).
  ///
  /// In en, this message translates to:
  /// **'Stand still, squat and hold briefly, then stand back up.'**
  String get flightSetupStep2DetailSquat;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 2 detail (jumps).
  ///
  /// In en, this message translates to:
  /// **'Hold still briefly. Then jump for a big boost.'**
  String get flightSetupStep2DetailJump;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 3 title on the endless course: the aim of the flight.
  ///
  /// In en, this message translates to:
  /// **'Collect stars'**
  String get flightSetupStep3Stars;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Step 3 detail for Jump & Fly. "0.75s" and "5s" are seconds; a trio is three stars collected together (star trio).
  ///
  /// In en, this message translates to:
  /// **'Stars add 0.75s of glide, up to 5s. Collect trios for +5 points.'**
  String get flightSetupStep3DetailJump;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Line beside the hearts picture under the steps (endless course): the lives you have.
  ///
  /// In en, this message translates to:
  /// **'Three hearts + a shield. You can pause any time.'**
  String get flightSetupLivesEndless;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Line under the steps on the old Classic course (no hearts).
  ///
  /// In en, this message translates to:
  /// **'A collision or losing your position ends a scored flight. You can pause any time.'**
  String get flightSetupLivesClassic;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. The big button that starts the camera; one line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Set up my camera'**
  String get flightSetupCameraButton;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Title of the optional microphone switch; followed by " · On" or " · Optional" on one line.
  ///
  /// In en, this message translates to:
  /// **'Record microphone'**
  String get flightMicTitle;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. State after "Record microphone ·" when the microphone will record.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get flightMicOn;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. State after "Record microphone ·" when it is off: recording sound is optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get flightMicOptional;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Small print under the microphone switch, two or three short lines.
  ///
  /// In en, this message translates to:
  /// **'Add your voice and room sound to replays. Uses the microphone during flight only. Saved on this phone.'**
  String get flightMicDetail;

  /// Screen-reader label (TalkBack), never shown. The microphone switch on the camera setup screen.
  ///
  /// In en, this message translates to:
  /// **'Record microphone for replays'**
  String get flightMicSemantics;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Setup screen before the camera starts. Small text button that opens the phone's microphone permission, shown when the microphone is blocked.
  ///
  /// In en, this message translates to:
  /// **'Microphone settings'**
  String get flightMicSettings;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Screen title once calibration is done; one line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'You found your wings!'**
  String get flightCalibrationTitleReady;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Screen title while the camera starts.
  ///
  /// In en, this message translates to:
  /// **'Waking up your camera…'**
  String get flightCalibrationTitleWaking;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Screen title when the camera could not start.
  ///
  /// In en, this message translates to:
  /// **'Let’s reconnect your camera.'**
  String get flightCalibrationTitleError;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Screen title while learning push-up or squat range.
  ///
  /// In en, this message translates to:
  /// **'Find your movement range.'**
  String get flightCalibrationTitleRange;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Screen title while learning a standing pose (jumps).
  ///
  /// In en, this message translates to:
  /// **'Stand tall and still.'**
  String get flightCalibrationTitleStill;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Current step (3 of 3) beside its number, calibration done: try the controls.
  ///
  /// In en, this message translates to:
  /// **'Try moving your bird.'**
  String get flightCalibrationStepTry;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Push-up step 1: the top of a push-up.
  ///
  /// In en, this message translates to:
  /// **'Find a comfortable top.'**
  String get flightCalibrationStepTop;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Push-up step 2: going down.
  ///
  /// In en, this message translates to:
  /// **'Lower yourself slowly.'**
  String get flightCalibrationStepLower;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Push-up step 3: coming back up.
  ///
  /// In en, this message translates to:
  /// **'Push back up.'**
  String get flightCalibrationStepPushBack;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Squat or jump step 1: stand still.
  ///
  /// In en, this message translates to:
  /// **'Stand tall and still.'**
  String get flightCalibrationStepStill;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Squat step 2.
  ///
  /// In en, this message translates to:
  /// **'Squat comfortably.'**
  String get flightCalibrationStepSquat;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Squat step 3.
  ///
  /// In en, this message translates to:
  /// **'Stand back up.'**
  String get flightCalibrationStepStandUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Squat step 3 once complete.
  ///
  /// In en, this message translates to:
  /// **'You found your wings!'**
  String get flightCalibrationStepDone;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Line under the step once ready (push-ups): how to steer; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Push up to rise. Lower to glide.'**
  String get flightCalibrationReadyPushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Line under the step once ready (squats); at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Squat to descend. Stand to rise.'**
  String get flightCalibrationReadySquat;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Line under the step once ready (jumps); at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Jump, then rest while your bird glides.'**
  String get flightCalibrationReadyJump;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Line under the step while calibrating push-ups; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Keep your shoulders, one arm and a hip in view. Move comfortably.'**
  String get flightCalibrationKeepPushUp;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Line under the step while calibrating squats or jumps; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Keep your shoulders, hips and both feet in view.'**
  String get flightCalibrationKeepBody;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Caption in the small preview sky where the bird follows you (push-ups, squats).
  ///
  /// In en, this message translates to:
  /// **'Learning your range as you move.'**
  String get flightCalibrationLearning;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Caption in the small preview sky (jumps).
  ///
  /// In en, this message translates to:
  /// **'Your bird moves after calibration.'**
  String get flightCalibrationAfter;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Caption in the preview sky the moment a jump is seen.
  ///
  /// In en, this message translates to:
  /// **'Jump!'**
  String get flightCalibrationJump;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Small capital tag beside the full meter once calibration is done.
  ///
  /// In en, this message translates to:
  /// **'CONTROL CHECK'**
  String get flightCalibrationTagCheck;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Small capital tag beside the meter: push-ups done out of the 2 calibration needs.
  ///
  /// In en, this message translates to:
  /// **'{count} / 2 PUSH-UPS'**
  String flightCalibrationTagPushUps(int count);

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Small capital tag beside the meter: how far calibration has come (squats, jumps).
  ///
  /// In en, this message translates to:
  /// **'{percent}% CALIBRATED'**
  String flightCalibrationTagPercent(int percent);

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Big button that starts the flight once calibrated; one line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Ready for takeoff'**
  String get flightCalibrationTakeoff;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. The restart button while the camera starts.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get flightCalibrationStarting;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Button that restarts calibration; one line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Start calibration again'**
  String get flightCalibrationRestart;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Tiny technical line under the buttons: camera tracking rate and latency ("p95" = 95th percentile; keep it).
  ///
  /// In en, this message translates to:
  /// **'{rate} updates/s · {p95} ms p95'**
  String flightCalibrationMetrics(String rate, String p95);

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Same tiny technical line when the camera gives no frame timestamps (latency counts processing only).
  ///
  /// In en, this message translates to:
  /// **'{rate} updates/s · {p95} ms p95 (processing only)'**
  String flightCalibrationMetricsProcessing(String rate, String p95);

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Small capital status tag in the title row.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get flightCalibrationStatusReady;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Small capital status tag: the camera is starting.
  ///
  /// In en, this message translates to:
  /// **'STARTING'**
  String get flightCalibrationStatusStarting;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Small capital status tag: the camera is not working.
  ///
  /// In en, this message translates to:
  /// **'CAMERA OFF'**
  String get flightCalibrationStatusCameraOff;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Small capital status tag while calibrating.
  ///
  /// In en, this message translates to:
  /// **'CALIBRATING'**
  String get flightCalibrationStatusCalibrating;

  /// Screen-reader label (TalkBack), never shown. Round button that switches between the front and back camera (also its tooltip).
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get flightSwitchCameraSemantics;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Note at the foot of the camera picture before the camera has said anything.
  ///
  /// In en, this message translates to:
  /// **'Step into view'**
  String get flightCalibrationStepIntoView;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Big line on the card shown when the camera would not start; shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'A fresh start usually helps.'**
  String get flightCameraTroubleTitle;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. First tip on that card.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in Settings.'**
  String get flightCameraTroubleAllow;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Calibration screen while the camera learns your movement. Second tip on that card.
  ///
  /// In en, this message translates to:
  /// **'Close any other camera app, then try again.'**
  String get flightCameraTroubleClose;

  /// Screen-reader label (TalkBack), never shown. Round button that opens the phone's camera permission (also its tooltip).
  ///
  /// In en, this message translates to:
  /// **'Camera permission settings'**
  String get flightCameraPermissionSemantics;

  /// A short status message the flight screen shows (camera, microphone or saving). Under the microphone switch: the choice applies now but could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Changed for this flight. Could not remember your preference.'**
  String get flightNoteRememberFailed;

  /// A short status message the flight screen shows (camera, microphone or saving). Under the microphone switch.
  ///
  /// In en, this message translates to:
  /// **'Microphone unavailable. Video and gameplay still work.'**
  String get flightNoteMicUnavailable;

  /// A short status message the flight screen shows (camera, microphone or saving). Under the microphone switch: permission was denied for good.
  ///
  /// In en, this message translates to:
  /// **'Microphone blocked. You can allow it in Settings; video still works.'**
  String get flightNoteMicBlocked;

  /// A short status message the flight screen shows (camera, microphone or saving). Under the microphone switch: permission was not given.
  ///
  /// In en, this message translates to:
  /// **'Microphone off. You can still play and save video.'**
  String get flightNoteMicOff;

  /// A short status message the flight screen shows (camera, microphone or saving). On the results: the camera clip could not be recorded.
  ///
  /// In en, this message translates to:
  /// **'Camera video unavailable. Gameplay can still be saved.'**
  String get flightNoteVideoUnavailable;

  /// A short status message the flight screen shows (camera, microphone or saving). On the results: the clip has no sound.
  ///
  /// In en, this message translates to:
  /// **'Microphone audio was unavailable. Your video and gameplay can still be saved.'**
  String get flightNoteMicAudioLost;

  /// A short status message the flight screen shows (camera, microphone or saving). On the results: recording stopped early.
  ///
  /// In en, this message translates to:
  /// **'Camera video interrupted. Available footage and gameplay can still be saved.'**
  String get flightNoteVideoInterrupted;

  /// A short status message the flight screen shows (camera, microphone or saving). On the results: saving the replay failed. "Save session" is the button's name (flightResultSaveSession): use the same words.
  ///
  /// In en, this message translates to:
  /// **'Could not save the session. Tap Save session to retry.'**
  String get flightNoteSessionSaveFailed;

  /// A short status message the flight screen shows (camera, microphone or saving). At the foot of the camera picture while the camera starts.
  ///
  /// In en, this message translates to:
  /// **'Waking up your camera…'**
  String get flightNoteWakingCamera;

  /// A short status message the flight screen shows (camera, microphone or saving). At the foot of the camera picture: camera permission was refused.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Allow it in Android settings, then come back and try again.'**
  String get flightNoteCameraOff;

  /// A short status message the flight screen shows (camera, microphone or saving). At the foot of the camera picture.
  ///
  /// In en, this message translates to:
  /// **'The camera could not start. Try again or switch cameras.'**
  String get flightNoteCameraFailed;

  /// A short status message the flight screen shows (camera, microphone or saving). At the foot of the camera picture just before the flight starts.
  ///
  /// In en, this message translates to:
  /// **'Preparing your session…'**
  String get flightNotePreparing;

  /// A short status message the flight screen shows (camera, microphone or saving). On the results, as a button: saving the flight failed; tapping retries.
  ///
  /// In en, this message translates to:
  /// **'Could not save your flight. Tap to retry.'**
  String get flightNoteSaveFailed;

  /// A short status message the flight screen shows (camera, microphone or saving). After returning to the app mid-flight (camera modes).
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Let’s check your position again.'**
  String get flightNoteWelcomeBack;

  /// A short status message the flight screen shows (camera, microphone or saving). The camera stopped unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Camera interrupted. Check camera permission and try again.'**
  String get flightNoteCameraInterrupted;

  /// A short status message the flight screen shows (camera, microphone or saving). Body tracking stopped unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Tracking interrupted'**
  String get flightNoteTrackingInterrupted;

  /// Camera mini game (push-up / squat / jump flight, a side mode). Countdown card title while the camera looks for the player, and the hint under it; heading, one line.
  ///
  /// In en, this message translates to:
  /// **'Find your position'**
  String get flightFindPosition;

  /// Screen-reader label (TalkBack), never shown. The whole sky during a Tap & Fly flight is one big button: tap to flap the wings.
  ///
  /// In en, this message translates to:
  /// **'Tap to flap'**
  String get flightTapSemantics;

  /// Screen-reader label (TalkBack), never shown. The sky during a flight, while a boss's helpers (a vanguard group, {group}, e.g. "the bat brigade") fly in.
  ///
  /// In en, this message translates to:
  /// **'Tap to flap. {group} fly in ahead of their boss'**
  String flightTapVanguardSemantics(String group);

  /// Screen-reader label (TalkBack), never shown. The sky during a boss fight: the boss's name and health.
  ///
  /// In en, this message translates to:
  /// **'Tap to flap. {boss}: {hp} of {maxHp} health'**
  String flightTapBossSemantics(String boss, int hp, int maxHp);

  /// Screen-reader label (TalkBack), never shown. The sky during a boss fight with a tip about the boss's current attack ({hint}, a full sentence).
  ///
  /// In en, this message translates to:
  /// **'Tap to flap. {boss}: {hp} of {maxHp} health. {hint}'**
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  );

  /// Screen-reader label (TalkBack), never shown. Tapping anywhere after a knockout or the finish-line celebration skips to the results.
  ///
  /// In en, this message translates to:
  /// **'Skip to results'**
  String get flightSkipToResultsSemantics;

  /// Screen-reader label (TalkBack), never shown. The pause button in the flight HUD (also its tooltip).
  ///
  /// In en, this message translates to:
  /// **'Pause flight'**
  String get hudPauseSemantics;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown on a Level Builder test flight of a push-up or squat level, with a keyboard. "Up" and "Down" are the arrow keys.
  ///
  /// In en, this message translates to:
  /// **'Test flight: Up and Down steer.'**
  String get flightHintTestSteerKeys;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown on a test flight of a push-up or squat level, on a touch screen.
  ///
  /// In en, this message translates to:
  /// **'Test flight: drag up and down to steer.'**
  String get flightHintTestSteerDrag;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown on a test flight of a jump level, with a keyboard. "Space" is the key name.
  ///
  /// In en, this message translates to:
  /// **'Test flight: Space for a jump.'**
  String get flightHintTestJumpKeys;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown on a test flight of a jump level, on a touch screen.
  ///
  /// In en, this message translates to:
  /// **'Test flight: tap for a jump.'**
  String get flightHintTestJumpTap;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (keyboard). Keep the key name "Space" as the key is labelled.
  ///
  /// In en, this message translates to:
  /// **'Space to flap. Fly through the stars.'**
  String get flightHintKeysStars;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (keyboard). Keep the key names "Space" and "D".
  ///
  /// In en, this message translates to:
  /// **'Space to flap. Hold D to charge a shot.'**
  String get flightHintKeysShoot;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (keyboard). Keep the key names "Space", "D" and "A".
  ///
  /// In en, this message translates to:
  /// **'Space to flap. Hold D to charge a shot. A to sprint!'**
  String get flightHintKeysCombat;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (keyboard). Keep the key names "Space" and "Esc".
  ///
  /// In en, this message translates to:
  /// **'Space to flap. Esc pauses.'**
  String get flightHintKeysPause;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (touch).
  ///
  /// In en, this message translates to:
  /// **'Tap the sky to flap. Fly through the stars.'**
  String get flightHintTapStars;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (touch). "Shoot" is the button's name (hudShoot): same word.
  ///
  /// In en, this message translates to:
  /// **'Tap the sky to flap. Hold Shoot to charge.'**
  String get flightHintTapShoot;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (touch). "Shoot" and "Sprint" are the buttons' names (hudShoot, hudSprint): same words.
  ///
  /// In en, this message translates to:
  /// **'Tap the sky to flap. Hold Shoot to charge. Sprint to smash!'**
  String get flightHintTapCombat;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (touch, old Classic course).
  ///
  /// In en, this message translates to:
  /// **'Tap to flap. Release between taps.'**
  String get flightHintTapRelease;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (camera modes, endless course).
  ///
  /// In en, this message translates to:
  /// **'Follow the stars. Your shield is ready.'**
  String get flightHintTrail;

  /// Flight HUD (heads-up display over the sky during play). Hint under the countdown (camera modes, Classic course).
  ///
  /// In en, this message translates to:
  /// **'The sky is yours.'**
  String get flightHintSky;

  /// Screen-reader label (TalkBack), never shown. The flight clock; {time} reads like 0:42.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String hudClockSemantics(String time);

  /// A number of seconds, abbreviated: the star magnet's time left in the HUD, the glide time, and "flight time" on the results. {seconds} is digits (e.g. 12 or 1.5). Use your usual short unit.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String flightSeconds(String seconds);

  /// Screen-reader label (TalkBack), never shown. The star magnet meter in the HUD while the magnet pulls stars in.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, other{Star magnet: {seconds} seconds remaining}}'**
  String hudMagnetActiveSemantics(int seconds);

  /// Screen-reader label (TalkBack), never shown. The star magnet meter while it charges: perfect gates passed so far out of those needed.
  ///
  /// In en, this message translates to:
  /// **'{gates, plural, other{Magnet charging: {charge} of {gates} perfect gates}}'**
  String hudMagnetChargingSemantics(int charge, int gates);

  /// Flight HUD (heads-up display over the sky during play). Yellow plate in the bottom corner when the camera has lost the player mid-flight; heading, one line beside an eye icon.
  ///
  /// In en, this message translates to:
  /// **'Finding you…'**
  String get hudFindingYou;

  /// Screen-reader label (TalkBack), never shown. The Shoot button in the flight HUD (it throws a rock; hold to charge a bigger one); also its tooltip. One short word, the same as in the hints and Bill's tips.
  ///
  /// In en, this message translates to:
  /// **'Shoot'**
  String get hudShoot;

  /// Screen-reader label (TalkBack), never shown. The Sprint button in the flight HUD (a burst of speed that smashes through); also its tooltip. One short word, the same as in the hints.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get hudSprint;

  /// Flight HUD (heads-up display over the sky during play). Small words after the TEST FLIGHT tag on the countdown card of a Level Builder test flight (shown as "TEST FLIGHT · nothing is saved").
  ///
  /// In en, this message translates to:
  /// **'nothing is saved'**
  String get flightTestNothingSaved;

  /// Flight HUD (heads-up display over the sky during play). Countdown card title over the big 3-2-1 numbers; heading, one line.
  ///
  /// In en, this message translates to:
  /// **'Ready, steady…'**
  String get flightCountdownReady;

  /// Pause card over the frozen flight. Big friendly title of the pause card; heading, one line.
  ///
  /// In en, this message translates to:
  /// **'Take a breather.'**
  String get flightPauseTitle;

  /// Pause card over the frozen flight. The big button that resumes the flight; shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Keep flying'**
  String get flightPauseKeepFlying;

  /// Pause card over the frozen flight. Line under the title on a campaign level: the level number ({id}, e.g. 1-3) and name ({name}).
  ///
  /// In en, this message translates to:
  /// **'{id} · {name}. Your bird is perched and waiting.'**
  String flightPausedLevel(String id, String name);

  /// Pause card over the frozen flight. Line under the title on a Level Builder test flight; {name} is the level name the player typed.
  ///
  /// In en, this message translates to:
  /// **'Test flight of {name}. Nothing is saved.'**
  String flightPausedTest(String name);

  /// Pause card over the frozen flight. Line under the title on a built level; {name} is its player-typed name.
  ///
  /// In en, this message translates to:
  /// **'{name}. Your bird is perched and waiting.'**
  String flightPausedBuilt(String name);

  /// Pause card over the frozen flight. Line under the title on an endless Tap & Fly flight: the countdown runs again on resume.
  ///
  /// In en, this message translates to:
  /// **'Your bird is perched and waiting. We’ll count you back in.'**
  String get flightPausedTouch;

  /// Pause card over the frozen flight. Line under the title on a camera mini game.
  ///
  /// In en, this message translates to:
  /// **'Shake it out, then get back in position. We’ll count you in.'**
  String get flightPausedCamera;

  /// Pause card over the frozen flight. Small button on a test flight: back to the Level Builder editor.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get flightPauseEdit;

  /// Pause card over the frozen flight. Small button on a built level: back to the Level Builder.
  ///
  /// In en, this message translates to:
  /// **'Builder'**
  String get flightPauseBuilder;

  /// Pause card over the frozen flight. Small button on an endless flight: end it now and see the results.
  ///
  /// In en, this message translates to:
  /// **'Finish flight'**
  String get flightPauseFinish;

  /// Screen-reader label (TalkBack), never shown. The shield meter in the HUD right after a hit (the bird blinks, safe for a moment).
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get hudShieldRecovering;

  /// Screen-reader label (TalkBack), never shown. The shield meter when the shield is up.
  ///
  /// In en, this message translates to:
  /// **'Shield ready'**
  String get hudShieldReady;

  /// Screen-reader label (TalkBack), never shown. The shield meter while stars recharge it.
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, other{Shield charging: {charge} of {stars} stars}}'**
  String hudShieldChargingSemantics(int charge, int stars);

  /// Screen-reader label (TalkBack), never shown. The hearts (lives) in the HUD.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} hearts remaining}}'**
  String hudHeartsSemantics(int count);

  /// Screen-reader label (TalkBack), never shown. State of the Sprint button during a sprint.
  ///
  /// In en, this message translates to:
  /// **'Sprinting'**
  String get hudSprinting;

  /// Screen-reader label (TalkBack), never shown. State of the Sprint button when it can be used.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get hudSprintReady;

  /// Screen-reader label (TalkBack), never shown. State of the Sprint button while it recharges.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, other{Recharging, {seconds} seconds}}'**
  String hudSprintRecharging(int seconds);

  /// Screen-reader label (TalkBack), never shown. What the Sprint button does (screen-reader hint).
  ///
  /// In en, this message translates to:
  /// **'Rush ahead to smash bats and stone panels'**
  String get hudSprintHint;

  /// Flight HUD (heads-up display over the sky during play). On the Shoot button when out of rocks, small white letters inside the round button (shrinks to fit), and its screen-reader state.
  ///
  /// In en, this message translates to:
  /// **'Reloading…'**
  String get hudShotReloading;

  /// Screen-reader label (TalkBack), never shown. State of the Shoot button while a full charge is held: milliseconds before it fires itself.
  ///
  /// In en, this message translates to:
  /// **'Full charge, {ms} ms left'**
  String hudShotFullCharge(int ms);

  /// Screen-reader label (TalkBack), never shown. State of the Shoot button while charging.
  ///
  /// In en, this message translates to:
  /// **'Charging {percent}%'**
  String hudShotCharging(int percent);

  /// Screen-reader label (TalkBack), never shown. State of the Shoot button: how many rocks are left, as a percentage.
  ///
  /// In en, this message translates to:
  /// **'Ammo {percent}%'**
  String hudShotAmmo(int percent);

  /// Screen-reader label (TalkBack), never shown. What holding the Shoot button does (screen-reader hint).
  ///
  /// In en, this message translates to:
  /// **'Hold to charge a bigger rock'**
  String get hudShotHint;

  /// Screen-reader label (TalkBack), never shown. Level HUD: a star mark (2 or 3 stars rating) already reached. Part of hudLevelStarsSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} stars reached}}'**
  String hudMarkReachedSemantics(int count);

  /// Screen-reader label (TalkBack), never shown. Level HUD: a star mark (the 2- or 3-star rating) and how many collected stars earn it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} stars at {at}}}'**
  String hudMarkAtSemantics(int count, int at);

  /// Screen-reader label (TalkBack), never shown. Level HUD star counter: stars collected, then the two rating marks ({two} and {three} are hudMarkReachedSemantics or hudMarkAtSemantics).
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, other{{stars} stars collected}}. {two}. {three}.'**
  String hudLevelStarsSemantics(int stars, String two, String three);

  /// Flight HUD (heads-up display over the sky during play). Level star counter, after the count once both star marks are reached (where it showed "/30"); very short, capitals.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get hudMax;

  /// Screen-reader label (TalkBack), never shown. The route meter in a level's HUD.
  ///
  /// In en, this message translates to:
  /// **'Route {percent}% flown'**
  String hudRouteSemantics(int percent);

  /// Jump & Fly glide meter, compact text (replay screen): glide time left ({time}, e.g. "1.5s").
  ///
  /// In en, this message translates to:
  /// **'Glide · {time}'**
  String hudGlideCompact(String time);

  /// Jump & Fly glide meter, compact text (replay screen) when no glide is charged.
  ///
  /// In en, this message translates to:
  /// **'Jump to glide'**
  String get hudJumpToGlide;

  /// Flight HUD (heads-up display over the sky during play). Jump & Fly glide meter: the short word beside the meter when no glide is charged (a jump charges one); very short.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get hudJump;

  /// Screen-reader label (TalkBack), never shown. Jump & Fly glide meter while gliding.
  ///
  /// In en, this message translates to:
  /// **'Glide, {time} remaining'**
  String hudGlideSemantics(String time);

  /// Screen-reader label (TalkBack), never shown. Jump & Fly glide meter when the glide is about to end.
  ///
  /// In en, this message translates to:
  /// **'Glide ending, {time} remaining'**
  String hudGlideEndingSemantics(String time);

  /// Screen-reader label (TalkBack), never shown. Jump & Fly glide meter when no glide is charged.
  ///
  /// In en, this message translates to:
  /// **'Jump to charge a 3-second glide'**
  String get hudJumpChargeSemantics;

  /// Flight HUD (heads-up display over the sky during play). Record chase plate: the score has beaten the best; heading, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'New best!'**
  String get hudRecordNewBest;

  /// Flight HUD (heads-up display over the sky during play). Record chase plate: the score equals the best.
  ///
  /// In en, this message translates to:
  /// **'Best matched!'**
  String get hudRecordMatched;

  /// Flight HUD (heads-up display over the sky during play). Record chase plate: the best score to beat.
  ///
  /// In en, this message translates to:
  /// **'Best {best}'**
  String hudRecordBest(int best);

  /// Flight HUD (heads-up display over the sky during play). Record chase plate, small line: how far past the best.
  ///
  /// In en, this message translates to:
  /// **'+{points} beyond your best'**
  String hudRecordBeyond(int points);

  /// Flight HUD (heads-up display over the sky during play). Record chase plate, small line: one point to a new record.
  ///
  /// In en, this message translates to:
  /// **'One more for a record'**
  String get hudRecordOneMore;

  /// Flight HUD (heads-up display over the sky during play). Record chase plate, small line: points to a new record.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} to a new record}}'**
  String hudRecordToGo(int count);

  /// Screen-reader label (TalkBack), never shown. Record chase plate: its title (e.g. "Best 42") and small line joined.
  ///
  /// In en, this message translates to:
  /// **'{title}. {detail}.'**
  String hudRecordSemantics(String title, String detail);

  /// Screen-reader label (TalkBack), never shown. The score in the flight HUD.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String hudScoreSemantics(int score);

  /// Screen-reader label (TalkBack), never shown. The score in the flight HUD with a star multiplier running.
  ///
  /// In en, this message translates to:
  /// **'Score {score}, {multiplier} times multiplier'**
  String hudScoreMultiplierSemantics(int score, int multiplier);

  /// Screen-reader label (TalkBack), never shown. State of a button that is working (saving, preparing).
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get commonBusySemantics;

  /// Flight results. Caption after a flight ended in a collision (game-over stage plate and endless results).
  ///
  /// In en, this message translates to:
  /// **'A little bump in the clouds.'**
  String get flightResultBumpClouds;

  /// Flight results. Small capital label over the endless record on the score plaque.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL BEST'**
  String get flightResultPersonalBest;

  /// Flight results. Ribbon stamped over the label when the flight beat the record; capitals.
  ///
  /// In en, this message translates to:
  /// **'NEW PERSONAL BEST!'**
  String get flightResultNewPersonalBest;

  /// Flight results. Small capital label over the number of stars collected in a level.
  ///
  /// In en, this message translates to:
  /// **'STARS COLLECTED'**
  String get flightResultStarsCollected;

  /// Flight results. News strip/chip: this flight completed today's daily Adventure postcard.
  ///
  /// In en, this message translates to:
  /// **'Today’s postcard stamped!'**
  String get flightResultDailyStamped;

  /// Flight results. Passport chip: the next stamp/medal to earn ({stamp} is its title).
  ///
  /// In en, this message translates to:
  /// **'Next: {stamp}'**
  String flightResultNextStamp(String stamp);

  /// Flight results. Quiet line: the flight is saved on this device.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get flightResultSavedOnPhone;

  /// Flight results. Quiet line: saved, and how many gates the player has flown through in all.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, other{Saved on this phone · {total} total gates}}'**
  String flightResultSavedGates(int total);

  /// Flight results. Quiet line while the flight is being saved.
  ///
  /// In en, this message translates to:
  /// **'Saving your flight…'**
  String get flightResultSaving;

  /// Flight results. Line once the replay session is saved: it can be watched from the Records screen ("Records" is that screen's name).
  ///
  /// In en, this message translates to:
  /// **'Session saved · Watch in Records'**
  String get flightResultSessionSaved;

  /// Flight results. Button: watch the saved replay of this flight; one line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Watch replay'**
  String get flightResultWatchReplay;

  /// Flight results. The replay button while the replay is being prepared.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get flightResultPreparing;

  /// Flight results. The replay button while the session saves.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get flightResultSavingShort;

  /// Flight results. Button: save this flight's replay (camera video and moves) to watch later.
  ///
  /// In en, this message translates to:
  /// **'Save session'**
  String get flightResultSaveSession;

  /// Flight results. The big button that starts another flight; shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Fly again'**
  String get flightResultFlyAgain;

  /// Button: try the level (or flight) again. Pause card, level result, game-over keys and a built level's result; short.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Button: back to the campaign map. Pause card, level result and game-over keys; short.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get commonMap;

  /// Button: on to the next level. Level result's big key; short.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Flight results. Small word beside or under a number on the results: how many push-ups ({count} is drawn before it in bigger digits, not in the text; agree with it).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{push-ups}}'**
  String flightStatPushUps(int count);

  /// Flight results. Small word beside or under a number on the results: how many squats ({count} is drawn before it, not in the text).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{squats}}'**
  String flightStatSquats(int count);

  /// Flight results. Small word beside or under a number on the results: how many jumps ({count} is drawn before it, not in the text).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{jumps}}'**
  String flightStatJumps(int count);

  /// Flight results. Small word beside or under a number on the results: how many wing flaps (taps) ({count} is drawn before it, not in the text).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{flaps}}'**
  String flightStatFlaps(int count);

  /// Flight results. Small word beside or under the flight's duration (e.g. "42s") on the results.
  ///
  /// In en, this message translates to:
  /// **'flight time'**
  String get flightStatFlightTime;

  /// Flight results. Small word beside or under the number of perfect gates (perfect passes) on the results.
  ///
  /// In en, this message translates to:
  /// **'perfect'**
  String get flightStatPerfect;

  /// Flight results. Small word beside or under the longest star streak on the results.
  ///
  /// In en, this message translates to:
  /// **'best streak'**
  String get flightStatBestStreak;

  /// Flight results. Small word under the rank on the game-over stage (old Classic course).
  ///
  /// In en, this message translates to:
  /// **'rank'**
  String get flightStatRank;

  /// Flight results. A rank for 25+ points on the old Classic course; at most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Sky captain'**
  String get flightRankSkyCaptain;

  /// Flight results. A rank for 10+ points on the old Classic course.
  ///
  /// In en, this message translates to:
  /// **'Cloud explorer'**
  String get flightRankCloudExplorer;

  /// Flight results. A rank for 5+ points on the old Classic course; short and cute.
  ///
  /// In en, this message translates to:
  /// **'First wings'**
  String get flightRankFirstWings;

  /// Flight results. A percentage (route flown); digits stay Western. Use your usual percent form.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String flightPercent(int percent);

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Caption on a plate under the big word: the flight ended in a bump but set a new record.
  ///
  /// In en, this message translates to:
  /// **'Bumped out on a brand-new best!'**
  String get gameOverCaptionBest;

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Caption on a plate under the big word: the bird fell into the sea.
  ///
  /// In en, this message translates to:
  /// **'A little splash in the sea.'**
  String get gameOverCaptionSea;

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). The big cartoon word dropping in letter by letter after falling into the sea (comic water sound).
  ///
  /// In en, this message translates to:
  /// **'Splash!'**
  String get gameOverSplash;

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). The big cartoon word dropping in letter by letter after a bump (comic bump sound).
  ///
  /// In en, this message translates to:
  /// **'Bonk!'**
  String get gameOverBonk;

  /// Screen-reader label (TalkBack), never shown. Game-over stage of a level: both star marks were reached.
  ///
  /// In en, this message translates to:
  /// **'Every mark reached'**
  String get gameOverEveryMarkSemantics;

  /// Screen-reader label (TalkBack), never shown. Game-over stage of a level: stars still needed for the next rating ({mark} is 2 or 3).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} more stars for {mark} stars}}'**
  String gameOverMoreStarsSemantics(int count, int mark);

  /// Screen-reader label (TalkBack), never shown. Game-over stage of a boss level: the boss's health left.
  ///
  /// In en, this message translates to:
  /// **'{boss}: {hp} of {maxHp} health left'**
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp);

  /// Screen-reader label (TalkBack), never shown. Game-over stage of a level: how far along the route the bird got.
  ///
  /// In en, this message translates to:
  /// **'{percent} percent of the route flown'**
  String gameOverRouteSemantics(int percent);

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Small capital label on the scoreboard of a guardian level: the guardian's name in capitals and its health points left. HP = health points (keep a short form).
  ///
  /// In en, this message translates to:
  /// **'{boss}: {hp} HP LEFT'**
  String gameOverGuardianHpLeft(String boss, int hp);

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Small capital label on the scoreboard of a chapter boss level, over its health left: the boss's name in capitals and "left" (= remaining health, not "went away").
  ///
  /// In en, this message translates to:
  /// **'{boss} LEFT'**
  String gameOverBossLeft(String boss);

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Small capital label over the percentage of the level's route flown. Same "route" word as the mail routes.
  ///
  /// In en, this message translates to:
  /// **'ROUTE FLOWN'**
  String get gameOverRouteFlown;

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Big number of health points the boss has left (HP = health points; keep a short form).
  ///
  /// In en, this message translates to:
  /// **'{hp} HP'**
  String gameOverHp(int hp);

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Beside a small meter, followed by the 2- or 3-star rating drawn as stars: "4 more for ★★". The stars come after the text in every language.
  ///
  /// In en, this message translates to:
  /// **'{count} more for'**
  String gameOverMoreFor(int count);

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Beside ★★★: both star marks of the level were reached (only the finish is missing).
  ///
  /// In en, this message translates to:
  /// **'Both marks reached'**
  String get gameOverBothMarks;

  /// Game-over stage (after the bird is bumped out of an endless flight or a level). Beside ★★★ on a guardian level: what is left to do is beat the guardian ({boss}). {bossId} is the boss's id (baronBat, spitterBeetle, duskMoth, pirate, dragon, kingCoo, searchlightGargoyle, neferhoo): select on it for the article or case the name takes in your language, e.g. "{bossId, select, duskMoth{die {boss}} dragon{den Glutdrachen} other{den {boss}}}"; keep {boss} wherever the name is written as is, and always end with other{…} for a boss added later.
  ///
  /// In en, this message translates to:
  /// **'{bossId, select, other{Both marks reached. Beat {boss}!}}'**
  String gameOverBothMarksBeat(String boss, String bossId);

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Screen title beside the back key; heading, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Every flight counts.'**
  String get miniResultTitle;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Small capital tag in the title row.
  ///
  /// In en, this message translates to:
  /// **'FLIGHT COMPLETE'**
  String get miniResultComplete;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Big cheer over the bird after a new record; heading, one line.
  ///
  /// In en, this message translates to:
  /// **'Look at you go!'**
  String get miniResultCheerBest;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Big cheer over the bird after a whole flight.
  ///
  /// In en, this message translates to:
  /// **'Flight complete!'**
  String get miniResultCheerComplete;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Big cheer over the bird otherwise.
  ///
  /// In en, this message translates to:
  /// **'Nice flying.'**
  String get miniResultCheerNice;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Tiny coral tag on the corner of a new postcard/medal chip; capitals.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get miniResultNew;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Why the flight ended: the camera lost the player.
  ///
  /// In en, this message translates to:
  /// **'We lost sight of you for a moment.'**
  String get flightEndTrackingLost;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Why the flight ended: the player left the camera's range.
  ///
  /// In en, this message translates to:
  /// **'Your position moved out of range.'**
  String get flightEndPostureLost;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Why the flight ended: the app was left.
  ///
  /// In en, this message translates to:
  /// **'You stepped away from the sky.'**
  String get flightEndBackgrounded;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Why the flight ended: a break was taken.
  ///
  /// In en, this message translates to:
  /// **'A well-earned breather.'**
  String get flightEndBreak;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Why the flight ended: the player finished it from the pause card.
  ///
  /// In en, this message translates to:
  /// **'Until the next adventure.'**
  String get flightEndQuit;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Why the flight ended: it stalled.
  ///
  /// In en, this message translates to:
  /// **'The game was interrupted.'**
  String get flightEndStalled;

  /// Endless results screen (a flight that ended without a bump: finished from the pause menu, or a camera mini game). Why the flight ended: the whole course was flown.
  ///
  /// In en, this message translates to:
  /// **'A whole sky of stars. All yours.'**
  String get flightEndCompleted;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). The big word dropping in letter by letter over the courier when the flight ended before the finish; encouraging.
  ///
  /// In en, this message translates to:
  /// **'Try again!'**
  String get levelResultTryAgain;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). The big word after beating a chapter's boss.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get levelResultVictory;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). The big word after beating a guardian (a mini-boss). Same "guardian" word everywhere (GUARDIAN DOWN! on its card).
  ///
  /// In en, this message translates to:
  /// **'Guardian down!'**
  String get levelResultGuardianDown;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). The big word after finishing a delivery (the mail got there). Prefer a form that needs no gender agreement.
  ///
  /// In en, this message translates to:
  /// **'Delivered!'**
  String get levelResultDelivered;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). News strip: the rest of this chapter is not in this version yet; {region} is the next region's name.
  ///
  /// In en, this message translates to:
  /// **'{region} is coming soon!'**
  String levelResultComingSoon(String region);

  /// Screen-reader label (TalkBack), never shown. The three big rating stars over the scoreboard.
  ///
  /// In en, this message translates to:
  /// **'{earned} of 3 stars'**
  String levelResultStarsSemantics(int earned);

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Tag beside a count (stars or score): the best so far.
  ///
  /// In en, this message translates to:
  /// **'Best {best}'**
  String levelResultBest(int best);

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Tag beside a count: no best saved yet.
  ///
  /// In en, this message translates to:
  /// **'No best yet'**
  String get levelResultNoBest;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Tag beside the stars count: the first time this level was finished.
  ///
  /// In en, this message translates to:
  /// **'First clear!'**
  String get levelResultFirstClear;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Ribbon stamped over a count when it beat the best; capitals.
  ///
  /// In en, this message translates to:
  /// **'NEW BEST!'**
  String get levelResultNewBest;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Small capital label over the score.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get levelResultScore;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Goal tag under the first rating star on a chapter boss level (beat the boss).
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get levelResultGoalBoss;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Goal tag under the first rating star on a guardian level.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get levelResultGoalGuardian;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Goal tag under the first rating star: reach the finish line.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get levelResultGoalFinish;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Small line under a goal tag, ticked: the goal was met.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get levelResultGoalDone;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Small line under a goal tag: not met.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get levelResultGoalNotYet;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Small line under a star-mark goal: stars still needed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} to go}}'**
  String levelResultGoalToGo(int count);

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). Small line under a star-mark goal reached in stars but not earned, because the finish was missed.
  ///
  /// In en, this message translates to:
  /// **'Finish first'**
  String get levelResultGoalFinishFirst;

  /// Screen-reader label (TalkBack), never shown. A goal tag ({goal} is the goal as the level card says it).
  ///
  /// In en, this message translates to:
  /// **'{goal}.'**
  String levelResultGoalSemantics(String goal);

  /// Screen-reader label (TalkBack), never shown. A goal tag that was met.
  ///
  /// In en, this message translates to:
  /// **'{goal}. Done.'**
  String levelResultGoalDoneSemantics(String goal);

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). News strip after a chapter's boss: its postcard can be opened on the map.
  ///
  /// In en, this message translates to:
  /// **'A postcard is waiting on the map!'**
  String get levelResultPostcardWaiting;

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). News strip: the next level ({id}, e.g. 1-4, and its name) is now unlocked.
  ///
  /// In en, this message translates to:
  /// **'{id} {name} is open!'**
  String levelResultLevelOpen(String id, String name);

  /// Level result stage (after a campaign level, the courier bird on a cloud beside a scoreboard). News strip when the flight ended before the finish line.
  ///
  /// In en, this message translates to:
  /// **'Reach the finish to earn stars.'**
  String get levelResultReachFinish;

  /// Flight course (way to play the endless flight). Name of the old course (fly through gaps, one chance); rarely seen: old replays and records. A plain "classic" label.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get course_classic_title;

  /// Flight course (way to play the endless flight). Name of the endless course every flight flies (stars, three hearts). Also shown in capitals on tags. The usual word for an endless mode.
  ///
  /// In en, this message translates to:
  /// **'Endless'**
  String get course_starTrail_title;

  /// Flight course (way to play the endless flight). How to play the Classic course (camera setup steps).
  ///
  /// In en, this message translates to:
  /// **'Find the gaps. Follow the aiming marks for a perfect pass.'**
  String get course_classic_instructions;

  /// Flight course (way to play the endless flight). How to play the endless course (camera setup steps). Keep "+5" and "3×".
  ///
  /// In en, this message translates to:
  /// **'Collect all 3 stars in a group for +5. Chain stars for up to 3×. Stars restore your shield; perfect gates earn a star magnet. Upgrade both with stars!'**
  String get course_starTrail_instructions;

  /// Flight course (way to play the endless flight). Small capital label over the score on results and replays (Classic counts gates passed).
  ///
  /// In en, this message translates to:
  /// **'OBSTACLES'**
  String get course_classic_scoreLabel;

  /// Flight course (way to play the endless flight). Small capital label over the score on results and replays (endless).
  ///
  /// In en, this message translates to:
  /// **'STAR POINTS'**
  String get course_starTrail_scoreLabel;

  /// Flight course (way to play the endless flight). Word after a score in a replay list ("12 gates").
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{gates}}'**
  String course_classic_scoreUnit(int count);

  /// Flight course (way to play the endless flight). Word after a score in a replay list ("42 star points").
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{star points}}'**
  String course_starTrail_scoreUnit(int count);

  /// Screen-reader label (TalkBack), never shown. The home screen's picture of the Classic course.
  ///
  /// In en, this message translates to:
  /// **'Classic: fly through the gaps.'**
  String get course_classic_previewSemantics;

  /// Screen-reader label (TalkBack), never shown. The home screen's picture of the endless course.
  ///
  /// In en, this message translates to:
  /// **'Endless: collect stars with three hearts and a shield.'**
  String get course_starTrail_previewSemantics;

  /// Gate family (obstacle type) name, shown in the Level Builder. A garden gate (hedge or fence gate).
  ///
  /// In en, this message translates to:
  /// **'Garden gate'**
  String get obstacle_garden_name;

  /// Gate family (obstacle type) name, shown in the Level Builder. An updraft that lifts the opening.
  ///
  /// In en, this message translates to:
  /// **'Wind lift'**
  String get obstacle_windLift_name;

  /// Gate family (obstacle type) name, shown in the Level Builder. Shutters made of petals (Bill calls them "petal gates": keep the petal word).
  ///
  /// In en, this message translates to:
  /// **'Petal shutters'**
  String get obstacle_petalGate_name;

  /// Gate family (obstacle type) name, shown in the Level Builder. Like a zigzag mountain road: up one gap, down the next.
  ///
  /// In en, this message translates to:
  /// **'Switchback'**
  String get obstacle_switchback_name;

  /// Gate family (obstacle type) name, shown in the Level Builder. Floating lanterns drifting across.
  ///
  /// In en, this message translates to:
  /// **'Lantern drift'**
  String get obstacle_lanternDrift_name;

  /// Gate family (obstacle type) name, shown in the Level Builder. Spinning sun-shaped wheels.
  ///
  /// In en, this message translates to:
  /// **'Sun wheels'**
  String get obstacle_sunWheels_name;

  /// Gate family (obstacle type) name, shown in the Level Builder. Crystal stairs; same crystal word as level 3-5.
  ///
  /// In en, this message translates to:
  /// **'Crystal steps'**
  String get obstacle_crystalSteps_name;

  /// Rush path (a short dash between bosses, with sprint rings and danger from one side). Its name: a forest fire chasing from behind. Shown in capitals with "!" on the banner; same word as level 2-3's name.
  ///
  /// In en, this message translates to:
  /// **'Wildfire'**
  String get rush_wildfire_name;

  /// Rush path (a short dash between bosses, with sprint rings and danger from one side). Escape banner and replay highlight after surviving it.
  ///
  /// In en, this message translates to:
  /// **'Outran the wildfire'**
  String get rush_wildfire_escape;

  /// Rush path (a short dash between bosses, with sprint rings and danger from one side). Its name: the sky falling (meteors). A short punchy coined word; the same word is level 2-5's name.
  ///
  /// In en, this message translates to:
  /// **'Skyfall'**
  String get rush_skyfall_name;

  /// Rush path (a short dash between bosses, with sprint rings and danger from one side). Escape banner and replay highlight.
  ///
  /// In en, this message translates to:
  /// **'Survived the skyfall'**
  String get rush_skyfall_escape;

  /// Rush path (a short dash between bosses, with sprint rings and danger from one side). Its name: a volcanic eruption blasting lava from below.
  ///
  /// In en, this message translates to:
  /// **'Eruption'**
  String get rush_eruption_name;

  /// Rush path (a short dash between bosses, with sprint rings and danger from one side). Escape banner and replay highlight.
  ///
  /// In en, this message translates to:
  /// **'Beat the eruption'**
  String get rush_eruption_escape;

  /// Rush path (a short dash between bosses, with sprint rings and danger from one side). Its name: a swarm of bats streaming in from ahead.
  ///
  /// In en, this message translates to:
  /// **'Swarm'**
  String get rush_swarm_name;

  /// Rush path (a short dash between bosses, with sprint rings and danger from one side). Escape banner and replay highlight.
  ///
  /// In en, this message translates to:
  /// **'Plowed through the swarm'**
  String get rush_swarm_escape;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the epithet of Baron Bat, the chapter boss. A grand, slightly comic title in capitals, set small with wide letter spacing. His second, louder meeting in endless uses boss_baronBat_returnTitle instead. Glossary: title.*.
  ///
  /// In en, this message translates to:
  /// **'LORD OF THE STORM'**
  String get boss_baronBat_title;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the epithet of Spitter King, the chapter boss. A grand, slightly comic title in capitals, set small with wide letter spacing. Glossary: title.*.
  ///
  /// In en, this message translates to:
  /// **'BREWER OF THE SWARM'**
  String get boss_spitterBeetle_title;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the epithet of Dusk Empress, the chapter boss. A grand, slightly comic title in capitals, set small with wide letter spacing. Glossary: title.*.
  ///
  /// In en, this message translates to:
  /// **'KEEPER OF THE TWILIGHT VEIL'**
  String get boss_duskMoth_title;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the epithet of Pirate Captain, the chapter boss. A grand, slightly comic title in capitals, set small with wide letter spacing. Glossary: title.*.
  ///
  /// In en, this message translates to:
  /// **'TERROR OF THE HIGH TIDE'**
  String get boss_pirate_title;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the epithet of Ember Dragon, the chapter boss. A grand, slightly comic title in capitals, set small with wide letter spacing. Glossary: title.*.
  ///
  /// In en, this message translates to:
  /// **'SOVEREIGN OF THE BURNING SKY'**
  String get boss_dragon_title;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the epithet of King Coo, the guardian (mini-boss). A grand, slightly comic title in capitals, set small with wide letter spacing. Glossary: title.*.
  ///
  /// In en, this message translates to:
  /// **'COMMISSIONER OF THE CURB'**
  String get boss_kingCoo_title;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the epithet of Searchlight Gargoyle, the guardian (mini-boss). A grand, slightly comic title in capitals, set small with wide letter spacing. Glossary: title.*.
  ///
  /// In en, this message translates to:
  /// **'WATCHMAN OF THE TALLEST TOWER'**
  String get boss_searchlightGargoyle_title;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the epithet of Neferhoo, the guardian (mini-boss). A grand, slightly comic title in capitals, set small with wide letter spacing. Also on his papyrus card and in the story ("Keeper of the Lost Letter"). Glossary: title.*.
  ///
  /// In en, this message translates to:
  /// **'KEEPER OF THE LOST LETTER'**
  String get boss_neferhoo_title;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: Baron Bat's epithet when he comes back stronger (and louder: a sonic screech) in endless. Capitals; echoes boss_baronBat_title "LORD OF THE STORM".
  ///
  /// In en, this message translates to:
  /// **'THE STORM RETURNS'**
  String get boss_baronBat_returnTitle;

  /// Boss health bar during the fight (top centre of the screen): Baron Bat's name in capitals in a small fixed name field left of the gauge. Same name as boss_baronBat_name; use a shorter form if it is long (it is set smaller past the budget).
  ///
  /// In en, this message translates to:
  /// **'BARON BAT'**
  String get boss_baronBat_barName;

  /// Boss health bar during the fight (top centre of the screen): Spitter King's name in capitals in a small fixed name field left of the gauge. Same name as boss_spitterBeetle_name; use a shorter form if it is long (it is set smaller past the budget).
  ///
  /// In en, this message translates to:
  /// **'SPITTER KING'**
  String get boss_spitterBeetle_barName;

  /// Boss health bar during the fight (top centre of the screen): Dusk Empress's name in capitals in a small fixed name field left of the gauge. Same name as boss_duskMoth_name; use a shorter form if it is long (it is set smaller past the budget).
  ///
  /// In en, this message translates to:
  /// **'DUSK EMPRESS'**
  String get boss_duskMoth_barName;

  /// Boss health bar during the fight (top centre of the screen): Pirate Captain's name in capitals in a small fixed name field left of the gauge. Same name as boss_pirate_name; use a shorter form if it is long (it is set smaller past the budget).
  ///
  /// In en, this message translates to:
  /// **'PIRATE CAPTAIN'**
  String get boss_pirate_barName;

  /// Boss health bar during the fight (top centre of the screen): Ember Dragon's name in capitals in a small fixed name field left of the gauge. Same name as boss_dragon_name; use a shorter form if it is long (it is set smaller past the budget).
  ///
  /// In en, this message translates to:
  /// **'EMBER DRAGON'**
  String get boss_dragon_barName;

  /// Boss health bar during the fight (top centre of the screen): King Coo's name in capitals in a small fixed name field left of the gauge. Same name as boss_kingCoo_name; use a shorter form if it is long (it is set smaller past the budget).
  ///
  /// In en, this message translates to:
  /// **'KING COO'**
  String get boss_kingCoo_barName;

  /// Boss health bar during the fight (top centre of the screen): Searchlight Gargoyle's name in capitals in a small fixed name field left of the gauge. Same name as boss_searchlightGargoyle_name; use a shorter form if it is long (it is set smaller past the budget). English drops "Searchlight": the full name does not fit.
  ///
  /// In en, this message translates to:
  /// **'GARGOYLE'**
  String get boss_searchlightGargoyle_barName;

  /// Boss health bar during the fight (top centre of the screen): Neferhoo's name in capitals in a small fixed name field left of the gauge. Same name as boss_neferhoo_name; use a shorter form if it is long (it is set smaller past the budget).
  ///
  /// In en, this message translates to:
  /// **'NEFERHOO'**
  String get boss_neferhoo_barName;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the big title naming the wave of small enemies Baron Bat sends ahead of himself. Capitals. Glossary: set-piece.vanguard, enemy.*.
  ///
  /// In en, this message translates to:
  /// **'BARON BAT\'S BATS'**
  String get vanguard_baronBat_title;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the line under vanguard_baronBat_title, an excited warning to the player. Sentence case, one line.
  ///
  /// In en, this message translates to:
  /// **'Here they come! The Baron is right behind.'**
  String get vanguard_baronBat_call;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the big title naming the wave of small enemies Spitter King sends ahead of himself. Capitals. Glossary: set-piece.vanguard, enemy.*.
  ///
  /// In en, this message translates to:
  /// **'THE SPITTER KING\'S BROOD'**
  String get vanguard_spitterBeetle_title;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the line under vanguard_spitterBeetle_title, an excited warning to the player. Sentence case, one line.
  ///
  /// In en, this message translates to:
  /// **'Here they come! The Spitter King is right behind.'**
  String get vanguard_spitterBeetle_call;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the big title naming the wave of small enemies Dusk Empress sends ahead of himself. Capitals. Glossary: set-piece.vanguard, enemy.*.
  ///
  /// In en, this message translates to:
  /// **'THE DUSK EMPRESS\'S MOTHS'**
  String get vanguard_duskMoth_title;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the line under vanguard_duskMoth_title, an excited warning to the player. Sentence case, one line.
  ///
  /// In en, this message translates to:
  /// **'Here they come! The Empress is right behind.'**
  String get vanguard_duskMoth_call;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the big title naming the wave of small enemies King Coo sends ahead of himself. Capitals. Glossary: set-piece.vanguard, enemy.*.
  ///
  /// In en, this message translates to:
  /// **'KING COO\'S SQUADRON'**
  String get vanguard_kingCoo_title;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the line under vanguard_kingCoo_title, an excited warning to the player. Sentence case, one line.
  ///
  /// In en, this message translates to:
  /// **'Here they come! King Coo is right behind.'**
  String get vanguard_kingCoo_call;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the line under vanguard_kingCoo_title when King Coo's pigeons throw stale crusts. "Duck" = dodge. One line.
  ///
  /// In en, this message translates to:
  /// **'Here they come! Duck the crusts!'**
  String get vanguard_kingCoo_callCrusts;

  /// In-flight vanguard banner (a title card dropping in at the top centre before a boss arrives; the card shrinks to fit the screen): the line under vanguard_kingCoo_title when a pigeon the player does not shoot comes back later in King Coo's fight. One line.
  ///
  /// In en, this message translates to:
  /// **'Duck the crusts! Miss one and it comes back!'**
  String get vanguard_kingCoo_callReturns;

  /// Vanguard progress strip (top centre, where the boss bar will be): shown at its right end once every small enemy of the vanguard is gone. Short shout, capitals.
  ///
  /// In en, this message translates to:
  /// **'CLEAR!'**
  String get bossVanguardClear;

  /// Vanguard progress strip (top centre): small dim word right after a gold count of the vanguard enemies still flying, read as "3 LEFT" (the number is drawn separately before it). One short word meaning "remaining".
  ///
  /// In en, this message translates to:
  /// **'LEFT'**
  String get bossVanguardLeft;

  /// King Coo's fight, a small tag under the health bar: every pigeon that escaped the vanguard ("straggler") has come back and been caught. Capitals.
  ///
  /// In en, this message translates to:
  /// **'ALL CAUGHT!'**
  String get bossStragglersCaught;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: Baron Bat.
  ///
  /// In en, this message translates to:
  /// **'STRONGER · Triple shots, and his bats join in!'**
  String get bossHint_strongerBaronBat;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: the Spitter King ("fans" = spreads of shots).
  ///
  /// In en, this message translates to:
  /// **'STRONGER · Full fans, and his beetles join in!'**
  String get bossHint_strongerSpitterBeetle;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: the Dusk Empress ("fans" = spreads of shots).
  ///
  /// In en, this message translates to:
  /// **'STRONGER · Seven-shot fans, and her moths join in!'**
  String get bossHint_strongerDuskMoth;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: the Pirate Captain (his sea rises in surges).
  ///
  /// In en, this message translates to:
  /// **'STRONGER · The tide is turning!'**
  String get bossHint_strongerPirate;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: the Ember Dragon (fire breath, flocks of bats).
  ///
  /// In en, this message translates to:
  /// **'STRONGER · Watch for the breath and the flocks!'**
  String get bossHint_strongerDragon;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: King Coo (a pigeon commissioner who whistles in a squadron of pigeons).
  ///
  /// In en, this message translates to:
  /// **'STRONGER · He whistles for his squadron!'**
  String get bossHint_strongerKingCoo;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: the Searchlight Gargoyle (stone feathers fall while his chest lamp is open).
  ///
  /// In en, this message translates to:
  /// **'STRONGER · Feathers fall on the open lamp!'**
  String get bossHint_strongerGargoyleFierce;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: the Searchlight Gargoyle.
  ///
  /// In en, this message translates to:
  /// **'STRONGER · Stone feathers fall!'**
  String get bossHint_strongerGargoyle;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: Neferhoo (his golden ankh boomerang and mummy bats).
  ///
  /// In en, this message translates to:
  /// **'STRONGER · The ankh, and his mummy bats!'**
  String get bossHint_strongerNeferhooTougher;

  /// Boss fight hint, at the moment the boss grows stronger (its health bar breaks a stage gem). Two parts joined by " · ": a tag in capitals (STRONGER), then what the full fight brings. KEEP the " · ": the part after it is shown alone on the small STRONGER! card under the health bar (up to two short lines); the whole line is read by the screen reader. This one: Neferhoo (a golden ankh he throws like a boomerang).
  ///
  /// In en, this message translates to:
  /// **'STRONGER · The golden ankh comes back!'**
  String get bossHint_strongerNeferhoo;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Pirate Captain: the sea is about to surge up.
  ///
  /// In en, this message translates to:
  /// **'TIDE RISING · Fly high!'**
  String get bossHint_tideRising;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Pirate Captain: the sea is up.
  ///
  /// In en, this message translates to:
  /// **'HIGH TIDE · Stay above the water'**
  String get bossHint_highTide;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Pirate Captain, enraged ("broadside" = all his cannons at once).
  ///
  /// In en, this message translates to:
  /// **'FURY · Broadsides between the surges'**
  String get bossHint_tideFury;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Pirate Captain, normal state.
  ///
  /// In en, this message translates to:
  /// **'Dodge the cannonballs · Keep out of the water'**
  String get bossHint_tideCalm;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Ember Dragon has called a swarm of bats.
  ///
  /// In en, this message translates to:
  /// **'SWARM · Dodge the bats or sprint through them'**
  String get bossHint_dragonSwarm;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Ember Dragon enraged, first meeting.
  ///
  /// In en, this message translates to:
  /// **'FURY · Faster fireballs'**
  String get bossHint_dragonFuryDebut;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Ember Dragon enraged.
  ///
  /// In en, this message translates to:
  /// **'FURY · Fireballs burst into embers'**
  String get bossHint_dragonFury;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Ember Dragon, normal state.
  ///
  /// In en, this message translates to:
  /// **'Dodge the fireballs · Watch for the breath'**
  String get bossHint_dragonCalm;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: Baron Bat (returning, louder) enraged.
  ///
  /// In en, this message translates to:
  /// **'FURY · Faster fireballs, more bats'**
  String get bossHint_screechFury;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: Baron Bat (returning), normal state; his sonic screech is a wall of sound with one gap.
  ///
  /// In en, this message translates to:
  /// **'Dodge the fireballs and bats · Watch for the screech'**
  String get bossHint_screechCalm;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: King Coo: his puffed chest was popped in time, so no pigeon squadron comes.
  ///
  /// In en, this message translates to:
  /// **'POP! · No squadron'**
  String get bossHint_cooPopped;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: King Coo: a squadron of pigeons is crossing; one lane is open.
  ///
  /// In en, this message translates to:
  /// **'SQUADRON · Follow the open lane!'**
  String get bossHint_cooSquadron;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: King Coo puffs his chest: hits there count double.
  ///
  /// In en, this message translates to:
  /// **'PUFFED · Shoot his chest (x2)!'**
  String get bossHint_cooPuffed;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: King Coo threw a crumb bomb; a ring marks where it bursts.
  ///
  /// In en, this message translates to:
  /// **'CRUMB BOMB · Leave the ring!'**
  String get bossHint_cooCrumbBomb;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: King Coo enraged.
  ///
  /// In en, this message translates to:
  /// **'FURY · Stay between the rings'**
  String get bossHint_cooFury;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: King Coo, normal state.
  ///
  /// In en, this message translates to:
  /// **'Dodge the crumb bombs · Shoot his chest when it puffs'**
  String get bossHint_cooCalm;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Searchlight Gargoyle's light beam is sweeping.
  ///
  /// In en, this message translates to:
  /// **'BEAM · Stay in the dark'**
  String get bossHint_beamOn;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Searchlight Gargoyle enraged: two beams with a dark slit between.
  ///
  /// In en, this message translates to:
  /// **'FURY · Slip between the beams'**
  String get bossHint_beamFury;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Gargoyle's beam is about to sweep the upper sky.
  ///
  /// In en, this message translates to:
  /// **'BEAM INCOMING · Fly low!'**
  String get bossHint_beamIncomingHigh;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Gargoyle's beam is about to sweep the lower sky.
  ///
  /// In en, this message translates to:
  /// **'BEAM INCOMING · Fly high!'**
  String get bossHint_beamIncomingLow;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Gargoyle's chest lamp is open: his weak point.
  ///
  /// In en, this message translates to:
  /// **'LAMP OPEN · Shoot the lamp!'**
  String get bossHint_lampOpen;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Gargoyle's lamp is shut: rocks just bounce off.
  ///
  /// In en, this message translates to:
  /// **'SHUTTERS CLOSED · Save your shots'**
  String get bossHint_shuttersClosed;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Dusk Empress enraged on her first meeting (no shield yet).
  ///
  /// In en, this message translates to:
  /// **'FURY · Seven-shot fans. No veil yet!'**
  String get bossHint_mothFuryNoVeil;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Dusk Empress on her first meeting.
  ///
  /// In en, this message translates to:
  /// **'No veil yet · Fire between the fans!'**
  String get bossHint_mothNoVeil;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Dusk Empress is behind her silk veil (shield).
  ///
  /// In en, this message translates to:
  /// **'SHIELDED · Dodge until the veil drops'**
  String get bossHint_mothShielded;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Dusk Empress is spinning her veil.
  ///
  /// In en, this message translates to:
  /// **'SHIELD FORMING · Get ready to dodge'**
  String get bossHint_mothShieldForming;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Dusk Empress enraged, veil down.
  ///
  /// In en, this message translates to:
  /// **'FURY · Seven-shot fans. Veil is down!'**
  String get bossHint_mothFury;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Dusk Empress, veil down.
  ///
  /// In en, this message translates to:
  /// **'Veil is down · Fire between the fans!'**
  String get bossHint_mothCalm;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: he sends a stream of letters: shoot them to send them back.
  ///
  /// In en, this message translates to:
  /// **'MAIL CALL · Shoot them back!'**
  String get bossHint_neferhooMailCall;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: a letter was shot back into him (−25 = health he lost; keep the number and the minus sign "−").
  ///
  /// In en, this message translates to:
  /// **'RETURN TO SENDER! · −25'**
  String get bossHint_neferhooReturn;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: as neferhooReturn, in his faster fight (keep −18).
  ///
  /// In en, this message translates to:
  /// **'RETURN TO SENDER! · −18'**
  String get bossHint_neferhooReturnFaster;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: his golden ankh is out; like a boomerang it comes back.
  ///
  /// In en, this message translates to:
  /// **'THE ANKH · It comes back!'**
  String get bossHint_neferhooAnkh;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: enraged: a faster stream of five letters.
  ///
  /// In en, this message translates to:
  /// **'EXPRESS POST · Five letters, faster'**
  String get bossHint_neferhooExpress;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: enraged: two ankhs, each on its own lane.
  ///
  /// In en, this message translates to:
  /// **'TWO ANKHS · Keep off both lanes'**
  String get bossHint_neferhooTwoAnkhs;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: his mummy bats are coming.
  ///
  /// In en, this message translates to:
  /// **'MUMMY BATS · Shoot them down!'**
  String get bossHint_neferhooBats;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: shown after many rocks hit him for little damage: teaches to shoot the letters back (LETTERS stressed in capitals).
  ///
  /// In en, this message translates to:
  /// **'Rocks only scuff his wraps. Shoot his LETTERS back!'**
  String get bossHint_neferhooScuff;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: his warm-up stage.
  ///
  /// In en, this message translates to:
  /// **'Shoot his letters back · Return to sender'**
  String get bossHint_neferhooWarmUp;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: normal state.
  ///
  /// In en, this message translates to:
  /// **'Shoot his letters back · Dodge the golden ankh'**
  String get bossHint_neferhooCalm;

  /// Neferhoo's fight (the mummy-owl guardian who mails letters at the bird): the one-line hint shown in a small pill under his health bar and read by the screen reader. Two parts joined by " · ": a tag in capitals and what to do. This one: enraged.
  ///
  /// In en, this message translates to:
  /// **'FURY · Express post and two ankhs'**
  String get bossHint_neferhooFury;

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Ember Dragon is about to breathe fire over one band of the sky (high: fly low; middle: climb or dive; low: fly high); while it inhales its glowing heart is its weak point.
  ///
  /// In en, this message translates to:
  /// **'{lane, select, high{DRAGON\'S BREATH · Fly low! Its heart is open} middle{DRAGON\'S BREATH · Climb or dive! Its heart is open} other{DRAGON\'S BREATH · Fly high! Its heart is open}}'**
  String bossHint_breathWarning(String lane);

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the Ember Dragon is breathing fire over one band of the sky.
  ///
  /// In en, this message translates to:
  /// **'{lane, select, high{FIRE · Fly low! Strike the glowing heart} middle{FIRE · Climb or dive! Strike the glowing heart} other{FIRE · Fly high! Strike the glowing heart}}'**
  String bossHint_breathFire(String lane);

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the returning Baron Bat is about to screech a wall of sound across the sky with one gap (high, middle or low).
  ///
  /// In en, this message translates to:
  /// **'{gap, select, high{SONIC SCREECH · Fly to the high gap!} middle{SONIC SCREECH · Fly to the middle gap!} other{SONIC SCREECH · Fly to the low gap!}}'**
  String bossHint_screechWarning(String gap);

  /// Boss fight hint read by the screen reader (the flight's accessibility label, updated as the fight changes). Two parts joined by " · ": a tag naming what is happening (capitals) and what to do. This one: the wall of sound is sweeping; stay in the gap.
  ///
  /// In en, this message translates to:
  /// **'{gap, select, high{SCREECH · Hold the high gap} middle{SCREECH · Hold the middle gap} other{SCREECH · Hold the low gap}}'**
  String bossHint_screechHold(String gap);

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar, once the boss has arrived: how to fight the Dusk Empress ("fans" = spreads of shots, "veil" = her silk shield). Capitals, two short orders joined by "  ·  " (two spaces each side).
  ///
  /// In en, this message translates to:
  /// **'DODGE THE FANS  ·  FIRE WHEN THE VEIL DROPS'**
  String get encounterCaption_duskMoth;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar, once the boss has arrived: how to fight the Pirate Captain. Capitals, two short orders joined by "  ·  " (two spaces each side).
  ///
  /// In en, this message translates to:
  /// **'DODGE THE CANNON  ·  STAY OUT OF THE WATER'**
  String get encounterCaption_pirate;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar, once the boss has arrived: how to fight the Ember Dragon. Capitals, two short orders joined by "  ·  " (two spaces each side).
  ///
  /// In en, this message translates to:
  /// **'DODGE THE FIREBALLS  ·  ESCAPE THE BREATH'**
  String get encounterCaption_dragon;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar, once the boss has arrived: how to fight King Coo (crumb bombs land in rings). Capitals, two short orders joined by "  ·  " (two spaces each side).
  ///
  /// In en, this message translates to:
  /// **'LEAVE THE RINGS  ·  SHOOT HIS CHEST WHEN IT PUFFS'**
  String get encounterCaption_kingCoo;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar, once the boss has arrived: how to fight the Searchlight Gargoyle. Capitals, two short orders joined by "  ·  " (two spaces each side).
  ///
  /// In en, this message translates to:
  /// **'STAY OUT OF THE LIGHT  ·  SHOOT THE LAMP WHEN IT OPENS'**
  String get encounterCaption_searchlightGargoyle;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar, once the boss has arrived: how to fight Neferhoo. Capitals, two short orders joined by "  ·  " (two spaces each side).
  ///
  /// In en, this message translates to:
  /// **'GET READY  ·  SHOOT HIS LETTERS BACK'**
  String get encounterCaption_neferhoo;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar, once the boss has arrived: how to fight the returning Baron Bat (sonic screech). Capitals, two short orders joined by "  ·  " (two spaces each side).
  ///
  /// In en, this message translates to:
  /// **'WHEN HE SCREECHES  ·  FLY TO THE GAP'**
  String get encounterCaption_screech;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar, once the boss has arrived: how to fight any other boss (Baron Bat, the Spitter King). Capitals, two short orders joined by "  ·  " (two spaces each side).
  ///
  /// In en, this message translates to:
  /// **'GET READY  ·  FLAP, DODGE, FIRE'**
  String get encounterCaption_default;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar while the boss makes its entrance: reassures the player that the bird is safe and needs no input yet. Sentence case, no full stop.
  ///
  /// In en, this message translates to:
  /// **'Your bird is coasting safely'**
  String get encounterCoasting;

  /// Boss arrival cutscene (film-style letterbox bars on the game canvas): the subtitle centred in the bottom bar after the boss is beaten, as the flight resumes. Sentence case, no full stop.
  ///
  /// In en, this message translates to:
  /// **'Back to the open sky'**
  String get encounterOpenSky;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title between two diamonds; the Dusk Empress (a moth queen) is coming. Ominous, capitals.
  ///
  /// In en, this message translates to:
  /// **'TWILIGHT TAKES WING'**
  String get encounterOmenTitle_duskMoth;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_duskMoth, trailing off with an ellipsis (…); the Dusk Empress (a moth queen) is coming.
  ///
  /// In en, this message translates to:
  /// **'A silken veil gathers in the dusk…'**
  String get encounterOmenLine_duskMoth;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title between two diamonds; the Spitter King (a beetle who brews a fizzy potion) is coming. Ominous, capitals.
  ///
  /// In en, this message translates to:
  /// **'SOMETHING IS BREWING'**
  String get encounterOmenTitle_spitterBeetle;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_spitterBeetle, trailing off with an ellipsis (…); the Spitter King (a beetle who brews a fizzy potion) is coming.
  ///
  /// In en, this message translates to:
  /// **'The air is starting to fizz…'**
  String get encounterOmenLine_spitterBeetle;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title between two diamonds; the Ember Dragon is coming. Ominous, capitals.
  ///
  /// In en, this message translates to:
  /// **'THE SKY CATCHES FIRE'**
  String get encounterOmenTitle_dragon;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_dragon, trailing off with an ellipsis (…); the Ember Dragon is coming.
  ///
  /// In en, this message translates to:
  /// **'Great wings beat above the clouds…'**
  String get encounterOmenLine_dragon;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title between two diamonds; King Coo (a pigeon "Commissioner of the Curb" in New York, furious about a lost bread cart) is coming. Ominous, capitals.
  ///
  /// In en, this message translates to:
  /// **'THE CURB IS CLOSED'**
  String get encounterOmenTitle_kingCoo;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_kingCoo, trailing off with an ellipsis (…); King Coo (a pigeon "Commissioner of the Curb" in New York, furious about a lost bread cart) is coming.
  ///
  /// In en, this message translates to:
  /// **'Somebody is very cross about the bread cart…'**
  String get encounterOmenLine_kingCoo;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title between two diamonds; the Searchlight Gargoyle (a stone statue on a skyscraper ledge) is coming. Ominous, capitals.
  ///
  /// In en, this message translates to:
  /// **'STORM WARNING'**
  String get encounterOmenTitle_searchlightGargoyle;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_searchlightGargoyle, trailing off with an ellipsis (…); the Searchlight Gargoyle (a stone statue on a skyscraper ledge) is coming.
  ///
  /// In en, this message translates to:
  /// **'Something on the ledge is watching…'**
  String get encounterOmenLine_searchlightGargoyle;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title between two diamonds; Neferhoo (a mummy owl from a pyramid) is coming. Ominous, capitals.
  ///
  /// In en, this message translates to:
  /// **'THE PYRAMID STIRS'**
  String get encounterOmenTitle_neferhoo;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_neferhoo, trailing off with an ellipsis (…); Neferhoo (a mummy owl from a pyramid) is coming.
  ///
  /// In en, this message translates to:
  /// **'The pyramid’s dust is stirring…'**
  String get encounterOmenLine_neferhoo;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title between two diamonds; Baron Bat comes back stronger and louder. Ominous, capitals.
  ///
  /// In en, this message translates to:
  /// **'THE BARON RETURNS'**
  String get encounterOmenTitle_baronReturns;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_baronReturns, trailing off with an ellipsis (…); Baron Bat comes back stronger and louder.
  ///
  /// In en, this message translates to:
  /// **'He is back, and he is much louder…'**
  String get encounterOmenLine_baronReturns;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title between two diamonds; a boss is coming (Baron Bat's first meeting). Ominous, capitals.
  ///
  /// In en, this message translates to:
  /// **'A SHADOW APPROACHES'**
  String get encounterOmenTitle_default;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_default, trailing off with an ellipsis (…); a boss is coming (Baron Bat's first meeting).
  ///
  /// In en, this message translates to:
  /// **'The sky belongs to someone else…'**
  String get encounterOmenLine_default;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the gold title for the Pirate Captain's ship (a lookout's cry on spotting a sail). Capitals.
  ///
  /// In en, this message translates to:
  /// **'SAIL HO!'**
  String get encounterOmenTitle_pirate;

  /// Boss arrival warning (a dark band across the upper middle of the game canvas, a few seconds before the boss appears): the line under encounterOmenTitle_pirate, trailing off with an ellipsis (…).
  ///
  /// In en, this message translates to:
  /// **'A ship rides in on the rising tide…'**
  String get encounterOmenLine_pirate;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), above the boss's big name: the small gold word over a guardian's name (King Coo, the Searchlight Gargoyle, Neferhoo: route-blocking mini-bosses), also on their card ribbons. Same word as the level card's and results' GUARDIAN everywhere. Capitals. Glossary: guardian.
  ///
  /// In en, this message translates to:
  /// **'GUARDIAN'**
  String get bossGuardianEyebrow;

  /// In-flight boss name card (painted on the game canvas, left to right in every language), above the boss's big name: the small gold words over a chapter boss's name: its number in the boss order. Capitals.
  ///
  /// In en, this message translates to:
  /// **'ENCOUNTER {number}'**
  String bossEncounterEyebrow(String number);

  /// Boss victory card (big cream title in the middle of the game canvas after the killing blow) for a guardian; also on Neferhoo's papyrus victory plate. Same words as the result screen. Capitals.
  ///
  /// In en, this message translates to:
  /// **'GUARDIAN DOWN!'**
  String get bossGuardianDown;

  /// Boss victory card (big title in the middle of the game canvas) after a chapter boss is beaten: the sky is free again. Capitals.
  ///
  /// In en, this message translates to:
  /// **'SKY RECLAIMED'**
  String get bossSkyReclaimed;

  /// Boss victory card, gold line under the title in endless mode: the boss bonus and that the bird's shield came back. Keep "+{points}" and the wide "   ·   " separator.
  ///
  /// In en, this message translates to:
  /// **'+{points} POINTS   ·   SHIELD RESTORED'**
  String bossVictoryPoints(int points);

  /// Boss victory card, gold line under the title in a campaign or level flight: the beaten boss, in capitals. One branch per boss so the word can agree with each name; use the same names as boss_*_name.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, baronBat{BARON BAT DEFEATED} spitterBeetle{SPITTER KING DEFEATED} duskMoth{DUSK EMPRESS DEFEATED} pirate{PIRATE CAPTAIN DEFEATED} dragon{EMBER DRAGON DEFEATED} kingCoo{KING COO DEFEATED} searchlightGargoyle{SEARCHLIGHT GARGOYLE DEFEATED} other{NEFERHOO DEFEATED}}'**
  String bossDefeatedBanner(String kind);

  /// In-flight boss name card (painted on the game canvas, left to right in every language), under the boss's big name: the boss's spoken line from the story, set under its epithet in quotation marks. Only the quotation marks are yours (use your language's: « », „ “, 「」…).
  ///
  /// In en, this message translates to:
  /// **'“{line}”'**
  String bossQuotedLine(String line);

  /// Pirate Captain: his roar as he arrives, in a speech bubble, each letter growing bigger than the last (a pirate's "Arr!", stretched). Adapt to how pirates growl in your language; capitals, about five characters.
  ///
  /// In en, this message translates to:
  /// **'ARRR!'**
  String get bossPirateRoar;

  /// The Searchlight Gargoyle's own name card (game canvas): his name on two lines, this small first line over bossGargoyleCardBig. Capitals. Together they read as boss_searchlightGargoyle_name.
  ///
  /// In en, this message translates to:
  /// **'THE SEARCHLIGHT'**
  String get bossGargoyleCardSmall;

  /// The Searchlight Gargoyle's own name card: the big second line of his name, under bossGargoyleCardSmall. Capitals.
  ///
  /// In en, this message translates to:
  /// **'GARGOYLE'**
  String get bossGargoyleCardBig;

  /// Not words: which of the Searchlight Gargoyle's two name-card lines comes first. "small-big" (English: THE SEARCHLIGHT over GARGOYLE) sets bossGargoyleCardSmall above bossGargoyleCardBig; "big-small" sets the big line on top and the small one under it, for a language that names the gargoyle first (GÁRGULA over DO HOLOFOTE). Write exactly one of the two values, untranslated.
  ///
  /// In en, this message translates to:
  /// **'small-big'**
  String get bossGargoyleCardOrder;

  /// Warning tag at the left edge of the game canvas before a sweep of fire (Ember Dragon) or light (Searchlight Gargoyle) over the upper sky: where to go. Very short order, capitals; it must stay left of the bird (set smaller if long).
  ///
  /// In en, this message translates to:
  /// **'FLY LOW'**
  String get bossDodgeFlyLow;

  /// Warning tag at the left edge of the game canvas before a sweep over the lower sky: where to go. Very short order, capitals.
  ///
  /// In en, this message translates to:
  /// **'FLY HIGH'**
  String get bossDodgeFlyHigh;

  /// Warning tag at the left edge of the game canvas before the Ember Dragon breathes fire across the middle of the sky: leave the middle, up or down. Very short, capitals.
  ///
  /// In en, this message translates to:
  /// **'CLIMB OR DIVE'**
  String get bossDodgeClimbOrDive;

  /// Warning tag at the left edge of the game canvas before the enraged Searchlight Gargoyle sweeps two beams with a dark slit between them. TWO lines (keep the line break), each at most 15 characters, capitals.
  ///
  /// In en, this message translates to:
  /// **'SLIP BETWEEN\nTHE BEAMS'**
  String get bossDodgeSlipBetween;

  /// Searchlight Gargoyle: shout over the bird when his beam catches it, and the hot tag under his health bar. Capitals, one word if possible.
  ///
  /// In en, this message translates to:
  /// **'SPOTTED!'**
  String get bossSpotted;

  /// Searchlight Gargoyle: small tag under SPOTTED! when the beam cost the bird its shield bubble. Capitals.
  ///
  /// In en, this message translates to:
  /// **'SHIELD LOST'**
  String get bossShieldLost;

  /// Searchlight Gargoyle: small tag under SPOTTED! when the beam cost the bird a heart (a life). Keep "-1". Capitals.
  ///
  /// In en, this message translates to:
  /// **'-1 HEART'**
  String get bossHeartLost;

  /// Searchlight Gargoyle: amber words on the tag under his health bar while his chest lamp (his weak point) is open; followed on the same tag by " · " and bossGargoyleShoot in white. Capitals.
  ///
  /// In en, this message translates to:
  /// **'LAMP OPEN'**
  String get bossGargoyleLampOpen;

  /// Searchlight Gargoyle: the white order after bossGargoyleLampOpen on the same tag ("LAMP OPEN · SHOOT!"). Capitals. Glossary: weapon.shoot.
  ///
  /// In en, this message translates to:
  /// **'SHOOT!'**
  String get bossGargoyleShoot;

  /// Returning Baron Bat: tag at the left edge of the game canvas, inside the gap of the coming wall of sound (his sonic screech): go there. Capitals, short (set smaller if long).
  ///
  /// In en, this message translates to:
  /// **'FLY TO THE GAP'**
  String get bossScreechFlyToGap;

  /// Returning Baron Bat: the same tag while the wall of sound sweeps past: stay in the gap. Capitals.
  ///
  /// In en, this message translates to:
  /// **'HOLD THE GAP'**
  String get bossScreechHoldGap;

  /// Pirate Captain: tag over the sea while a surge is up (a dashed line shows how high). Capitals.
  ///
  /// In en, this message translates to:
  /// **'HIGH TIDE'**
  String get bossPirateHighTide;

  /// Boss health bar: small tag on the empty gauge after the boss is beaten. Capitals; the gauge is small (hidden if it does not fit).
  ///
  /// In en, this message translates to:
  /// **'DEFEATED'**
  String get bossBarDefeated;

  /// Boss health bar: small tag on the gauge while the boss is still arriving. Capitals.
  ///
  /// In en, this message translates to:
  /// **'INCOMING'**
  String get bossBarIncoming;

  /// Boss health bar: small tag on the gauge for a moment when the boss turns enraged (fiercer attacks). Capitals. Same word as the FURY of the fight hints.
  ///
  /// In en, this message translates to:
  /// **'FURY'**
  String get bossBarFury;

  /// Ember Dragon's fight: tag on or under the health bar while its heart glows open (hits there count double). Keep "×2". Capitals.
  ///
  /// In en, this message translates to:
  /// **'HEART ×2'**
  String get bossBarHeartDouble;

  /// Small card hanging from the boss health bar when the boss grows stronger (a stage of its health is gone); what changes is written under it. Capitals.
  ///
  /// In en, this message translates to:
  /// **'STRONGER!'**
  String get bossStronger;

  /// King Coo: tag under his health bar while his chest is puffed up (hits count double, shown by a gold "×2" drawn right after this word). Capitals, one short word.
  ///
  /// In en, this message translates to:
  /// **'PUFFED'**
  String get bossKingCooPuffed;

  /// King Coo (a pompous pigeon): his big comic-book cry as he arrives, popping from his beak. A pigeon's coo; adapt to your language's pigeon sound. Capitals.
  ///
  /// In en, this message translates to:
  /// **'COO!'**
  String get bossKingCooShout;

  /// King Coo: comic-book sound word when his puffed chest is popped. Capitals.
  ///
  /// In en, this message translates to:
  /// **'POP!'**
  String get bossKingCooPop;

  /// King Coo: comic-book sound word as he bursts into a cloud of feathers when beaten. Capitals.
  ///
  /// In en, this message translates to:
  /// **'POOF!'**
  String get bossKingCooPoof;

  /// King Coo's squadron (a V of pigeons crossing the sky): tag at the left edge; fly where the lane is open. Capitals, very short; never name a colour.
  ///
  /// In en, this message translates to:
  /// **'OPEN LANE = GO'**
  String get bossSquadOpenLane;

  /// King Coo's squadron in a wall formation: tag at the left edge; fly through its gap. Capitals, very short.
  ///
  /// In en, this message translates to:
  /// **'USE THE GAP'**
  String get bossSquadUseGap;

  /// King Coo's squadron tag, small second line when two squadrons come: the next one flies in a V formation. Keep "V" (the letter shape). Capitals.
  ///
  /// In en, this message translates to:
  /// **'THEN: V'**
  String get bossSquadThenV;

  /// King Coo's squadron tag, small second line when two squadrons come: the next one is a wall with a gap. Capitals.
  ///
  /// In en, this message translates to:
  /// **'THEN: GAP'**
  String get bossSquadThenGap;

  /// King Coo's squadron tag when the player popped his puffed chest in time and the squadron is called off. Capitals, short.
  ///
  /// In en, this message translates to:
  /// **'SQUAD CANCELLED'**
  String get bossSquadCancelled;

  /// Neferhoo's victory plate (papyrus card on the game canvas): the line under GUARDIAN DOWN!. The Lost Letter is the story's missing letter he guarded. Capitals.
  ///
  /// In en, this message translates to:
  /// **'THE LOST LETTER IS FOUND'**
  String get bossNeferhooFound;

  /// Neferhoo (a mummy owl) roars as he arrives: three comic syllables pop from his beak, this one first, then bossNeferhooPoo twice ("HOO POO POO", an owl's hoot). Adapt the sound; capitals, one syllable.
  ///
  /// In en, this message translates to:
  /// **'HOO'**
  String get bossNeferhooHoo;

  /// Neferhoo's roar: the second and third syllable after bossNeferhooHoo ("HOO POO POO"). Capitals, one syllable.
  ///
  /// In en, this message translates to:
  /// **'POO'**
  String get bossNeferhooPoo;

  /// Neferhoo's fight: title of the tag beside the lane his stream of letters will fly down. Capitals. Glossary: attack.mail-call.
  ///
  /// In en, this message translates to:
  /// **'MAIL CALL'**
  String get bossNeferhooMailCall;

  /// Neferhoo's fight, enraged: title of the lane tag for his faster stream of letters. Capitals.
  ///
  /// In en, this message translates to:
  /// **'EXPRESS POST'**
  String get bossNeferhooExpressPost;

  /// Neferhoo's fight: the small line under the lane tag's title (MAIL CALL / EXPRESS POST): shoot the letters to send them back. Sentence case.
  ///
  /// In en, this message translates to:
  /// **'Shoot them back!'**
  String get bossNeferhooShootBack;

  /// Neferhoo's fight: title of the tag beside the path his golden ankh (Egyptian cross) flies, like a boomerang. Capitals.
  ///
  /// In en, this message translates to:
  /// **'THE ANKH'**
  String get bossNeferhooAnkh;

  /// Neferhoo's fight, enraged: title of the path tag when two ankhs fly. Capitals.
  ///
  /// In en, this message translates to:
  /// **'TWO ANKHS'**
  String get bossNeferhooTwoAnkhs;

  /// Neferhoo's fight: the small line under the ankh tag's title: the ankh returns like a boomerang. Sentence case.
  ///
  /// In en, this message translates to:
  /// **'It comes back!'**
  String get bossNeferhooComesBack;

  /// Rush banner (a title card dropping in at the top centre of the game canvas): a rush begins (a chase where something sweeps in from behind): its name as a shout. Glossary: set-piece.wildfire, .skyfall, .eruption, .swarm.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, wildfire{WILDFIRE!} skyfall{SKYFALL!} eruption{ERUPTION!} other{SWARM!}}'**
  String encounterRushWarning(String kind);

  /// Rush banner (a title card dropping in at the top centre of the game canvas): the line under encounterRushWarning: how to survive it (gold sprint rings give a burst of speed). One line. Glossary: pickup.sprint-ring.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, wildfire{Grab the sprint rings and outrun it!} skyfall{Grab the sprint rings and race the meteors!} eruption{Grab the sprint rings and beat the blasts!} other{Grab the sprint rings and plow through!}}'**
  String encounterRushDetail(String kind);

  /// Rush banner (a title card dropping in at the top centre of the game canvas): the bird escaped the rush, with the bonus points. Capitals; keep "+{points}".
  ///
  /// In en, this message translates to:
  /// **'ESCAPED! +{points}'**
  String encounterRushEscaped(int points);

  /// Rush banner (a title card dropping in at the top centre of the game canvas): the bird escaped the rush or rode out a gale without a single hit, with the bonus points. Capitals; keep "+{points}".
  ///
  /// In en, this message translates to:
  /// **'FLAWLESS! +{points}'**
  String encounterFlawless(int points);

  /// Rush banner (a title card dropping in at the top centre of the game canvas): the line under ESCAPED!/FLAWLESS!: which rush the bird escaped. Sentence case, no full stop.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, wildfire{You outran the wildfire} skyfall{You survived the skyfall} eruption{You beat the eruption} other{You plowed through the swarm}}'**
  String encounterRushEscapedDetail(String kind);

  /// Gale banner (a title card dropping in at the top centre of the game canvas): a gale (storm wind that blows debris across the sky) begins. Capitals. Glossary: set-piece.gale.
  ///
  /// In en, this message translates to:
  /// **'GALE!'**
  String get encounterGale;

  /// Gale banner (a title card dropping in at the top centre of the game canvas): the line under GALE!. {mark} is an orange "!" warning sign that flashes where debris will fly in; keep {mark} exactly once. One line.
  ///
  /// In en, this message translates to:
  /// **'Dodge the debris where the {mark} flashes!'**
  String encounterGaleDetail(String mark);

  /// Gale banner (a title card dropping in at the top centre of the game canvas): the bird rode out the gale, with the bonus points. Capitals; keep "+{points}".
  ///
  /// In en, this message translates to:
  /// **'WEATHERED! +{points}'**
  String encounterGaleWeathered(int points);

  /// Gale banner (a title card dropping in at the top centre of the game canvas): the line under WEATHERED!/FLAWLESS!. Sentence case, no full stop.
  ///
  /// In en, this message translates to:
  /// **'You rode out the gale'**
  String get encounterGaleWeatheredDetail;

  /// Rush banner (a title card dropping in at the top centre of the game canvas): the bird collected every sprint ring of a rush. Capitals.
  ///
  /// In en, this message translates to:
  /// **'ALL RINGS!'**
  String get encounterAllRings;

  /// Rush banner (a title card dropping in at the top centre of the game canvas): the line under ALL RINGS!: the extra seconds of ring sprint earned. "s" = seconds; {seconds} is like 2 or 1.5 (always with a dot).
  ///
  /// In en, this message translates to:
  /// **'Turbo boost +{seconds}s'**
  String encounterAllRingsDetail(String seconds);

  /// The finish line of a level flight, on the game canvas: the word on the swinging sign over the finish gate and on the small label at the arrival post. Capitals, one short word. Glossary: set-piece.finish-line.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get encounterFinish;

  /// Level Builder: the mode of a level flown with push-ups (camera mini game), on the level chips, cards and result plate. Short plural noun; "Tap & Fly" uses playMode_touch.
  ///
  /// In en, this message translates to:
  /// **'Push-ups'**
  String get builderMode_pushUp;

  /// Level Builder: the mode of a level flown with squats (camera mini game), on the level chips, cards and result plate. Short plural noun.
  ///
  /// In en, this message translates to:
  /// **'Squats'**
  String get builderMode_squat;

  /// Level Builder: the mode of a level flown with jumps (camera mini game), on the level chips, cards and result plate. Short plural noun.
  ///
  /// In en, this message translates to:
  /// **'Jumps'**
  String get builderMode_jump;

  /// Level Builder: a time in seconds: a place on the route ("12.4 s"), a level's length, the ruler under the sky. {seconds} is the number, already written with the language's decimal mark. Use the usual short unit symbol for seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String builderSeconds(String seconds);

  /// Level Builder: a level's length when it runs past a minute ("1 min 05 s"), on the shelf, the inspector and the route strip. Short unit symbols.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String builderMinutesSeconds(int minutes, String seconds);

  /// Level Builder: how many push-ups a push-up level asks for (its workout), on the shelf, the inspector and the route strip. Push-ups are a side mini game.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 push-up} other{{count} push-ups}}'**
  String builderRepsPushUp(int count);

  /// Level Builder: how many squats a squat level asks for (its workout), on the shelf, the inspector and the route strip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 squat} other{{count} squats}}'**
  String builderRepsSquat(int count);

  /// Level Builder: the name a new Tap & Fly level starts with, until the player renames it. It becomes the player's own data once saved (never translated again). A level name holds at most 24 characters, including a number the game may add after it ("My tap level 2").
  ///
  /// In en, this message translates to:
  /// **'My tap level'**
  String get builderNewLevel_touch;

  /// Level Builder: the name a new push-up level starts with, until the player renames it. It becomes the player's own data once saved (never translated again). A level name holds at most 24 characters, including a number the game may add after it ("My tap level 2").
  ///
  /// In en, this message translates to:
  /// **'My push-up level'**
  String get builderNewLevel_pushUp;

  /// Level Builder: the name a new squat level starts with, until the player renames it. It becomes the player's own data once saved (never translated again). A level name holds at most 24 characters, including a number the game may add after it ("My tap level 2").
  ///
  /// In en, this message translates to:
  /// **'My squat level'**
  String get builderNewLevel_squat;

  /// Level Builder: the name a new jump level starts with, until the player renames it. It becomes the player's own data once saved (never translated again). A level name holds at most 24 characters, including a number the game may add after it ("My tap level 2").
  ///
  /// In en, this message translates to:
  /// **'My jump level'**
  String get builderNewLevel_jump;

  /// Level Builder: a new level's starting name when the plain one is taken: "My tap level 2". {name} is builderNewLevel_*.
  ///
  /// In en, this message translates to:
  /// **'{name} {number}'**
  String builderNewLevelNumbered(String name, int number);

  /// Level Builder: the name a copied or remixed level falls back to when its own name cannot take the remix ending. Player data once saved.
  ///
  /// In en, this message translates to:
  /// **'My level'**
  String get builderFallbackName;

  /// Level Builder › Share code: the text copied for the player to paste to a friend. {name} is the level's own name as the player typed it (never translated), {mode} the level's mode (Tap & Fly, Push-Up Flight…), {code} the share code (BEAK1.…), which stays untouched, ideally at the end. Keep "Beakbound" in Latin letters; use your language's quotation marks.
  ///
  /// In en, this message translates to:
  /// **'Fly my Beakbound level “{name}” ({mode}): {code}'**
  String builderShareMessage(String name, String mode, String code);

  /// Level Builder: screen-reader label of a row of small star icons (stars earned of the level's three, or a star mark's two/three stars).
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} stars'**
  String builderStarsSemantics(int earned, int total);

  /// Level Builder: screen-reader label and tooltip of a sheet's back key (to the sheet's first step).
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get builderBackSemantics;

  /// Level Builder: the "no" answer of a confirmation such as "Delete this level?": keep the level. Key label.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get builderKeepIt;

  /// Level Builder: screen-reader label of the − key beside a value. {name} is the value's name ("two-star mark"). Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Less {name}'**
  String builderLessSemantics(String name);

  /// Level Builder: screen-reader label of the + key beside a value. {name} is the value's name ("two-star mark"). Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'More {name}'**
  String builderMoreSemantics(String name);

  /// Level Builder: screen-reader label of a value between − and + keys: "two-star mark 9".
  ///
  /// In en, this message translates to:
  /// **'{name} {value}'**
  String builderValueSemantics(String name, String value);

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that copies the selected gate, star, heart or enemy. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get builderDuplicateSemantics;

  /// Level Builder › editor › right panel (inspector): label of the key at the panel's foot that places a copy of the selected thing. One short word.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get builderCopy;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that removes the selected thing. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get builderDeleteSemantics;

  /// Level Builder › editor › right panel (inspector): label of the key at the panel's foot that removes the selected thing. One short word.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get builderDelete;

  /// Level Builder › editor › right panel (inspector): small tag at the foot of the panel when there is more to scroll to (with a down arrow).
  ///
  /// In en, this message translates to:
  /// **'More below'**
  String get builderMoreBelow;

  /// Level Builder › editor › right panel (inspector): screen-reader label of a value between two keys: "Height 55 %".
  ///
  /// In en, this message translates to:
  /// **'{caption} {value}'**
  String builderStepSemantics(String caption, String value);

  /// Level Builder › editor › right panel (inspector): screen-reader label of a value between two keys with its note: "Height 55 %, of the sky".
  ///
  /// In en, this message translates to:
  /// **'{caption} {value}, {hint}'**
  String builderStepHintSemantics(String caption, String value, String hint);

  /// Level Builder › editor › right panel (inspector): a share of the sky's height: a gate's height or its opening ("55 %"). Write it as your language writes percentages.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String builderPercent(int percent);

  /// Level Builder › editor › right panel (inspector): caption over the Top/Bottom choice for a gate in a push-up or squat level (the bird flies two lanes). Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Lane'**
  String get builderLane;

  /// Level Builder › editor › right panel (inspector): small note beside the Lane caption: which lane is which. {movement} is pushUp or squat (the level's camera mini game): keep both cases.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, squat{top or bottom of the squat} other{top or bottom of the push-up}}'**
  String builderLaneHint(String movement);

  /// Level Builder › editor › right panel (inspector): choice key: the gate stands on the top lane (the top of the push-up or squat).
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get builderLaneTop;

  /// Level Builder › editor › right panel (inspector): choice key: the gate stands on the bottom lane.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get builderLaneBottom;

  /// Level Builder › editor › right panel (inspector): caption of the selected thing's height in the sky, over its value ("55 %"). Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get builderHeight;

  /// Level Builder › editor › right panel (inspector): small note under the height value: "55 %" of the sky's height.
  ///
  /// In en, this message translates to:
  /// **'of the sky'**
  String get builderHeightHint;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that moves the selected thing down. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Lower'**
  String get builderLowerSemantics;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that moves the selected thing up. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Higher'**
  String get builderHigherSemantics;

  /// Level Builder › editor › right panel (inspector): caption of the size of a gate's opening (gap) the bird flies through. Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get builderOpening;

  /// Level Builder › editor › right panel (inspector): small note under the opening's size: the smallest the bird can fit through.
  ///
  /// In en, this message translates to:
  /// **'at least {percent} %'**
  String builderOpeningHint(int percent);

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that narrows the gate's opening. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Narrower'**
  String get builderNarrowerSemantics;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that widens the gate's opening. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Wider'**
  String get builderWiderSemantics;

  /// Level Builder › editor › right panel (inspector): caption over how much a gate moves (Still / Gentle / Lively). Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get builderMotion;

  /// Level Builder › editor › right panel (inspector): small note beside the Motion caption on a garden gate, which never moves. "Garden gate" is the still gate family.
  ///
  /// In en, this message translates to:
  /// **'garden gates stand still'**
  String get builderMotionGardenHint;

  /// Level Builder › editor › right panel (inspector): motion choice: the gate does not move. One of three narrow keys in a row.
  ///
  /// In en, this message translates to:
  /// **'Still'**
  String get builderMotionStill;

  /// Level Builder › editor › right panel (inspector): motion choice: the gate sways a little. One of three narrow keys in a row.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get builderMotionGentle;

  /// Level Builder › editor › right panel (inspector): motion choice: the gate sways a lot. One of three narrow keys in a row.
  ///
  /// In en, this message translates to:
  /// **'Lively'**
  String get builderMotionLively;

  /// Level Builder › editor: toast when the player tries to make a garden gate move. "Family" is the gate family (kind of gate).
  ///
  /// In en, this message translates to:
  /// **'Garden gates stand still: pick another family to make it move.'**
  String get builderMotionGardenToast;

  /// Level Builder › editor › right panel (inspector): caption over how fast a moving gate sways (Fast / Medium / Slow). Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Sway'**
  String get builderSway;

  /// Level Builder › editor › right panel (inspector): small note beside the Sway caption: how long one sway takes. {seconds} is builderSeconds ("2.2 s").
  ///
  /// In en, this message translates to:
  /// **'one sway: {seconds}'**
  String builderSwayHint(String seconds);

  /// Level Builder › editor › right panel (inspector): sway choice: a quick sway. One of three narrow keys in a row.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get builderSwayFast;

  /// Level Builder › editor › right panel (inspector): sway choice: a medium sway. One of three narrow keys in a row.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get builderSwayMedium;

  /// Level Builder › editor › right panel (inspector): sway choice: a slow sway. One of three narrow keys in a row.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get builderSwaySlow;

  /// Level Builder › editor › right panel (inspector): caption of where a moving gate is in its sway when the bird reaches it (shown over a little wave with a dot). Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'As you arrive'**
  String get builderPhase;

  /// Level Builder › editor › right panel (inspector): which of the sway's 8 steps the gate is at as the bird arrives: "3 of 8".
  ///
  /// In en, this message translates to:
  /// **'{position} of {count}'**
  String builderPhaseValue(int position, int count);

  /// Level Builder › editor › right panel (inspector): small note under the sway step.
  ///
  /// In en, this message translates to:
  /// **'where it is in its sway'**
  String get builderPhaseHint;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that sets the gate earlier in its sway. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Earlier in its sway'**
  String get builderPhaseEarlierSemantics;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that sets the gate later in its sway. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Later in its sway'**
  String get builderPhaseLaterSemantics;

  /// Level Builder › editor › right panel (inspector): caption over the gate's three looks (art variants). Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get builderLook;

  /// Level Builder › editor › right panel (inspector): screen-reader label of one of a gate's three looks. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Look {number}'**
  String builderLookSemantics(int number);

  /// Level Builder › editor › right panel (inspector): caption, and the choice key, for a breakable stone door that seals a garden gate's opening (the stone panel the bird breaks with a charged rock or Sprint).
  ///
  /// In en, this message translates to:
  /// **'Stone door'**
  String get builderDoor;

  /// Level Builder › editor › right panel (inspector): small note beside the Stone door caption. "Shoot" is the fire button.
  ///
  /// In en, this message translates to:
  /// **'shoot it open'**
  String get builderDoorHint;

  /// Level Builder › editor › right panel (inspector): choice key: the gate has no stone door.
  ///
  /// In en, this message translates to:
  /// **'No door'**
  String get builderDoorNone;

  /// Level Builder › editor: toast when the player picks a stone door in a level without the Shoot button. "Shoot" is the fire button's name.
  ///
  /// In en, this message translates to:
  /// **'Turn Shoot on in the level’s settings to use doors.'**
  String get builderDoorNeedsShootToast;

  /// Level Builder › editor › right panel (inspector): caption of where the selected thing is along the route, in seconds from the start. Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get builderPlace;

  /// Level Builder › editor › right panel (inspector): small note under the place value ("12.4 s" from the start).
  ///
  /// In en, this message translates to:
  /// **'from the start'**
  String get builderPlaceHint;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that moves the selected thing earlier on the route (to the left). Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get builderEarlierSemantics;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key that moves the selected thing later on the route (to the right). Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get builderLaterSemantics;

  /// Level Builder › editor › right panel (inspector): screen-reader label of the key at the top of a gate's panel that opens the gate families. {family} is the family name (obstacle_*_name).
  ///
  /// In en, this message translates to:
  /// **'Gate family: {family}. Change'**
  String builderFamilySemantics(String family);

  /// Level Builder › editor › right panel (inspector): small key-like tag under the gate family's name that opens the gate families.
  ///
  /// In en, this message translates to:
  /// **'Change family'**
  String get builderChangeFamily;

  /// Level Builder › editor › right panel (inspector): panel title: the selected thing is a star (pickup).
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get builderItemStar;

  /// Level Builder › editor › right panel (inspector): panel title: the selected thing is a star trio: three stars that pay a bonus together.
  ///
  /// In en, this message translates to:
  /// **'Star trio'**
  String get builderItemTrio;

  /// Level Builder › editor › right panel (inspector): panel title: the selected thing is a heart (a life).
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get builderItemHeart;

  /// Level Builder › editor › right panel (inspector): panel title: the selected thing is an enemy.
  ///
  /// In en, this message translates to:
  /// **'Enemy'**
  String get builderItemEnemy;

  /// Level Builder › editor › right panel (inspector): panel title: the selected thing is a gate.
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get builderItemGate;

  /// Level Builder › editor › right panel (inspector): line under the Star title.
  ///
  /// In en, this message translates to:
  /// **'One star to collect'**
  String get builderItemStarDetail;

  /// Level Builder › editor › right panel (inspector): line under the Star trio title: collecting all three stars pays a bonus.
  ///
  /// In en, this message translates to:
  /// **'All three pay a bonus'**
  String get builderItemTrioDetail;

  /// Level Builder › editor › right panel (inspector): line under the Heart title: it gives one heart (life) back.
  ///
  /// In en, this message translates to:
  /// **'One heart back'**
  String get builderItemHeartDetail;

  /// Level Builder › editor › right panel (inspector): caption over the enemy kinds to pick from. Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get builderEnemyKind;

  /// Level Builder › editor › right panel (inspector): tip under a star's or heart's settings in a push-up or squat level. {movement} is pushUp or squat (the level's camera mini game): keep both cases.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, squat{The bird flies the top and bottom of each squat: put pickups on or between the yellow lines.} other{The bird flies the top and bottom of each push-up: put pickups on or between the yellow lines.}}'**
  String builderPickupLanesNote(String movement);

  /// Level Builder › editor › right panel (inspector): name of an enemy kind a player can place: the basic purple bat. Under the Enemy title and on the kind keys.
  ///
  /// In en, this message translates to:
  /// **'Purple bat'**
  String get builderEnemy_simpleBat;

  /// Level Builder › editor › right panel (inspector): name of an enemy kind a player can place: a tougher cave bat. Under the Enemy title and on the kind keys.
  ///
  /// In en, this message translates to:
  /// **'Cave bat'**
  String get builderEnemy_caveBat;

  /// Level Builder › editor › right panel (inspector): name of an enemy kind a player can place: the beetle that spits seeds (same "spitter" word as the Spitter King). Under the Enemy title and on the kind keys.
  ///
  /// In en, this message translates to:
  /// **'Spitter beetle'**
  String get builderEnemy_spitterBeetle;

  /// Level Builder › editor › right panel (inspector): name of an enemy kind a player can place: the moth that fires pollen (same "dusk" word as the Dusk Empress). Under the Enemy title and on the kind keys.
  ///
  /// In en, this message translates to:
  /// **'Dusk moth'**
  String get builderEnemy_duskMoth;

  /// Level Builder › editor › right panel (inspector): name of an enemy kind a player can place: New York's star-thief pigeon. Under the Enemy title and on the kind keys.
  ///
  /// In en, this message translates to:
  /// **'Alley pigeon'**
  String get builderEnemy_alleyPigeon;

  /// Level Builder › editor › right panel (inspector): name of an enemy kind a player can place: a bat wrapped in linen like a mummy. Under the Enemy title and on the kind keys.
  ///
  /// In en, this message translates to:
  /// **'Mummy bat'**
  String get builderEnemy_mummyBat;

  /// Level Builder › editor › right panel (inspector): panel title when nothing is selected: the level at a glance.
  ///
  /// In en, this message translates to:
  /// **'This level'**
  String get builderSummaryTitle;

  /// Level Builder: a level's mode and region on one line: "Push-ups · Jungle".
  ///
  /// In en, this message translates to:
  /// **'{mode} · {region}'**
  String builderModeRegion(String mode, String region);

  /// Level Builder › editor › right panel (inspector): label of a fact in the level summary: how long the level takes to fly.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get builderFactLength;

  /// Level Builder › editor › right panel (inspector): label of a fact in the level summary: how many stars are placed.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get builderFactStars;

  /// Level Builder › editor › right panel (inspector): label of a fact in the level summary: the two star marks (stars needed for two and three stars).
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get builderFactMarks;

  /// Level Builder › editor › right panel (inspector): label of a fact in the level summary: how many push-ups or squats it asks for.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get builderFactWorkout;

  /// Level Builder › editor › right panel (inspector): label of a fact in the level summary: how fast the level scrolls.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get builderFactPace;

  /// Level Builder › editor › right panel (inspector): label of a fact in the level summary: the boss waiting at the end.
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get builderFactBoss;

  /// Level Builder: a level's pace (slowest of three, rising: Relaxed, Steady, Brisk), a choice key in the settings and a fact in the summary.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get builderPace_relaxed;

  /// Level Builder: a level's pace (medium of three, rising: Relaxed, Steady, Brisk), a choice key in the settings and a fact in the summary.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get builderPace_steady;

  /// Level Builder: a level's pace (fastest of three, rising: Relaxed, Steady, Brisk), a choice key in the settings and a fact in the summary.
  ///
  /// In en, this message translates to:
  /// **'Brisk'**
  String get builderPace_brisk;

  /// Level Builder › editor › right panel (inspector): note on a starter level (read-only template). "Remix" = copy it to edit as your own.
  ///
  /// In en, this message translates to:
  /// **'A starter level to fly as it is, or remix into a level of your own.'**
  String get builderSummaryStarterNote;

  /// Level Builder › editor › right panel (inspector): note when the player has flown their own level to the finish (needed to share it).
  ///
  /// In en, this message translates to:
  /// **'Cleared by you: you flew it to the end.'**
  String get builderSummaryClearedNote;

  /// Level Builder › editor › right panel (inspector): note on a level not yet cleared by its maker.
  ///
  /// In en, this message translates to:
  /// **'Test fly it all the way to the finish to mark it cleared.'**
  String get builderSummaryClearNote;

  /// Level Builder › editor › right panel (inspector): note on a level with a boss finale, not yet cleared. {boss} is the boss's name (Baron Bat…). {bossId} is the boss's id (baronBat, spitterBeetle, duskMoth, pirate, dragon, kingCoo, searchlightGargoyle, neferhoo): select on it for the article or case the name takes in your language, e.g. "{bossId, select, duskMoth{die {boss}} dragon{den Glutdrachen} other{den {boss}}}"; keep {boss} wherever the name is written as is, and always end with other{…} for a boss added later.
  ///
  /// In en, this message translates to:
  /// **'{bossId, select, other{Test fly it, beat {boss} and cross the line to mark it cleared.}}'**
  String builderSummaryClearBossNote(String boss, String bossId);

  /// Level Builder › editor › right panel (inspector): how-to note. The tools are always on the left of the editor, in every language.
  ///
  /// In en, this message translates to:
  /// **'Pick a tool on the left, then tap the sky. Tap a thing to change it; drag it to move it.'**
  String get builderSummaryHowTo;

  /// Level Builder › gate families sheet: what the Garden gate family does, under its name on its card.
  ///
  /// In en, this message translates to:
  /// **'Stands still. Can hold a stone door.'**
  String get builderFamily_garden_detail;

  /// Level Builder › gate families sheet: what the Wind lift family does, under its name on its card.
  ///
  /// In en, this message translates to:
  /// **'The opening rises and falls.'**
  String get builderFamily_windLift_detail;

  /// Level Builder › gate families sheet: what the Petal shutters family does, under its name on its card.
  ///
  /// In en, this message translates to:
  /// **'The opening narrows and widens.'**
  String get builderFamily_petalGate_detail;

  /// Level Builder › gate families sheet: what the Switchback family does, under its name on its card.
  ///
  /// In en, this message translates to:
  /// **'Two openings that slide apart.'**
  String get builderFamily_switchback_detail;

  /// Level Builder › gate families sheet: what the Lantern drift family does, under its name on its card.
  ///
  /// In en, this message translates to:
  /// **'Hanging lanterns that bob.'**
  String get builderFamily_lanternDrift_detail;

  /// Level Builder › gate families sheet: what the Sun wheels family does, under its name on its card.
  ///
  /// In en, this message translates to:
  /// **'Wheels that close in and back.'**
  String get builderFamily_sunWheels_detail;

  /// Level Builder › gate families sheet: what the Crystal steps family does, under its name on its card.
  ///
  /// In en, this message translates to:
  /// **'Three steps in a ripple.'**
  String get builderFamily_crystalSteps_detail;

  /// Level Builder › gate families sheet: screen-reader label of its close key. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Close gate families'**
  String get builderFamiliesCloseSemantics;

  /// Level Builder › gate families sheet: title.
  ///
  /// In en, this message translates to:
  /// **'Gate family'**
  String get builderFamiliesTitle;

  /// Level Builder › gate families sheet: line under the title.
  ///
  /// In en, this message translates to:
  /// **'How the gate looks and moves.'**
  String get builderFamiliesSubtitle;

  /// Level Builder › gate families sheet: screen-reader label of a family card.
  ///
  /// In en, this message translates to:
  /// **'{family}. {detail}'**
  String builderFamilyCardSemantics(String family, String detail);

  /// Level Builder › editor › problems and tips: problem: the level's name is empty or too long.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Give the level a name of up to {count} letters.}}'**
  String reach_name(int count);

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Move the finish line further on: the level is too short.'**
  String get reach_tooShort;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Bring the finish line closer: the level is too long.'**
  String get reach_tooLong;

  /// Level Builder › editor › problems and tips: problem: too many gates, stars, hearts and enemies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Too many things: a level holds up to {count}.}}'**
  String reach_tooMany(int count);

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Only Tap & Fly levels end with a boss.'**
  String get reach_bossNeedsTap;

  /// Level Builder › editor › problems and tips: tip.
  ///
  /// In en, this message translates to:
  /// **'Add gates for the bird to fly through.'**
  String get reach_noGates;

  /// Level Builder › editor › problems and tips: problem: something stands in the start zone, which must stay clear.
  ///
  /// In en, this message translates to:
  /// **'Too close to the start: move it past the start zone.'**
  String get reach_startZone;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Leave room before the finish line after this gate.'**
  String get reach_finishRoom;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Two gates overlap: move them apart.'**
  String get reach_overlap;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'This gate is too high or too low.'**
  String get reach_gateHeight;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'This gate cannot move that way.'**
  String get reach_gateMotion;

  /// Level Builder › editor › problems and tips: problem (a damaged level): a gate's look (art variant) is unknown.
  ///
  /// In en, this message translates to:
  /// **'This gate has an unknown look.'**
  String get reach_gateLook;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Open this gate wider: the bird cannot fit.'**
  String get reach_gateNarrow;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'This gate is open too wide.'**
  String get reach_gateWide;

  /// Level Builder › editor › problems and tips: problem. "Shoot" is the fire button; "Tap & Fly" the touch mode.
  ///
  /// In en, this message translates to:
  /// **'A stone door needs Tap & Fly with Shoot on.'**
  String get reach_doorNeedsShoot;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Only a garden gate can hold a stone door.'**
  String get reach_doorNeedsGarden;

  /// Level Builder › editor › problems and tips: tip: two gates on different lanes are close together. {movement} is pushUp or squat (the level's camera mini game): keep both cases.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, squat{Tight switch: a steady squat may not make it in time.} other{Tight switch: a steady push-up may not make it in time.}}'**
  String reach_tightSwitch(String movement);

  /// Level Builder › editor › problems and tips: tip in a jump level.
  ///
  /// In en, this message translates to:
  /// **'Steep climb: leave more room to jump up to this gate.'**
  String get reach_steepClimb;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Enemies only fly in Tap & Fly levels.'**
  String get reach_enemyNeedsTap;

  /// Level Builder › editor › problems and tips: problem: a star, heart or enemy is above or below the sky.
  ///
  /// In en, this message translates to:
  /// **'Keep it inside the sky.'**
  String get reach_outsideSky;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Place it before the finish line.'**
  String get reach_pastFinish;

  /// Level Builder › editor › problems and tips: tip: a pickup the bird cannot reach. {movement} is pushUp or squat (the level's camera mini game): keep both cases.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, squat{Out of a squat\'s reach: move it nearer the lanes.} other{Out of a push-up\'s reach: move it nearer the lanes.}}'**
  String reach_outOfReach(String movement);

  /// Level Builder › editor › problems and tips: tip: a pickup inside a gate's wall.
  ///
  /// In en, this message translates to:
  /// **'Inside a wall: move it into the opening.'**
  String get reach_inWall;

  /// Level Builder › editor › problems and tips: problem.
  ///
  /// In en, this message translates to:
  /// **'Place at least one star.'**
  String get reach_noStars;

  /// Level Builder › editor › problems and tips: problem. "Star marks" are the stars needed for two and three stars.
  ///
  /// In en, this message translates to:
  /// **'The star marks ask for more stars than the level has.'**
  String get reach_marks;

  /// Level Builder › editor › problems and tips: problem of a damaged level. {problem} is an internal code (such as "marks"): keep it as it is.
  ///
  /// In en, this message translates to:
  /// **'This level cannot fly yet ({problem}).'**
  String reach_cannotFly(String problem);

  /// Level Builder › editor: toast when saving failed and the player pressed fly.
  ///
  /// In en, this message translates to:
  /// **'The level didn’t save, so it can’t fly yet. Tap its name to retry.'**
  String get builderSaveFailedFlyToast;

  /// Level Builder › editor: toast when the player tries to share a level with problems (red flags on the route).
  ///
  /// In en, this message translates to:
  /// **'Fix the red flags first: then the level can be shared.'**
  String get builderShareBlockedToast;

  /// Level Builder › editor: screen-reader label and tooltip of the back key (to the Level Builder shelf).
  ///
  /// In en, this message translates to:
  /// **'Back to the builder'**
  String get builderEditorBackSemantics;

  /// Level Builder › editor: screen-reader label and tooltip of the key that opens the level's settings.
  ///
  /// In en, this message translates to:
  /// **'Level settings'**
  String get builderSettingsSemantics;

  /// Level Builder › editor: big mint key that flies a starter level. Capitals, one short verb.
  ///
  /// In en, this message translates to:
  /// **'FLY'**
  String get builderFly;

  /// Level Builder › editor: big mint key that test flies the player's own level. Capitals; "test fly" is the verb for flying your own level to try it.
  ///
  /// In en, this message translates to:
  /// **'TEST FLY'**
  String get builderTestFly;

  /// Level Builder › editor: screen-reader label of the FLY key.
  ///
  /// In en, this message translates to:
  /// **'Fly this level'**
  String get builderFlySemantics;

  /// Level Builder › editor: screen-reader label of the TEST FLY key.
  ///
  /// In en, this message translates to:
  /// **'Test fly the whole level'**
  String get builderTestFlySemantics;

  /// Level Builder › editor: undo key. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get builderUndoSemantics;

  /// Level Builder › editor: redo key. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get builderRedoSemantics;

  /// Level Builder › editor: screen-reader label of the key that lists the level's problems (to fix before it can fly) and tips. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'{blocking} to fix, {advice, plural, other{{advice} tips}}'**
  String builderIssuesSemantics(int blocking, int advice);

  /// Level Builder › editor: screen-reader label of the problems-and-tips key when there are only tips. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'{advice, plural, other{{advice} tips}}'**
  String builderTipsSemantics(int advice);

  /// Level Builder › editor: screen-reader label of the problems-and-tips key when there is nothing to fix. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Ready to fly'**
  String get builderReadySemantics;

  /// Level Builder › editor: screen-reader label of the key that copies the level's share code. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get builderShareSemantics;

  /// Level Builder › editor: screen-reader label of the key that test flies from the place on the route the sky shows. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Test fly from here'**
  String get builderFromHereSemantics;

  /// Level Builder › editor: label of the key that test flies from the place on the route the sky shows (beside TEST FLY).
  ///
  /// In en, this message translates to:
  /// **'From here'**
  String get builderFromHere;

  /// Level Builder › editor: line under a starter level's name.
  ///
  /// In en, this message translates to:
  /// **'Starter level · look, fly or remix'**
  String get builderStatusStarter;

  /// Level Builder › editor: line under the level's name when saving failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save · tap to retry'**
  String get builderStatusSaveFailed;

  /// Level Builder › editor: line under the level's name while changes save.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get builderStatusSaving;

  /// Level Builder › editor: line under the level's name once changes are saved.
  ///
  /// In en, this message translates to:
  /// **'All changes saved'**
  String get builderStatusSaved;

  /// Level Builder › editor: screen-reader label of the level's name plate. {name} is the player's level name (not translated), {mode} its mode, {status} one of builderStatus*.
  ///
  /// In en, this message translates to:
  /// **'{name}. {mode}. {status}.'**
  String builderNamePlateSemantics(String name, String mode, String status);

  /// Level Builder › editor: screen-reader label of the player's own level's name plate, which renames it.
  ///
  /// In en, this message translates to:
  /// **'{name}. {mode}. {status}. Tap to rename.'**
  String builderNamePlateRenameSemantics(
    String name,
    String mode,
    String status,
  );

  /// Level Builder › editor: banner beside a starter level's fly key: copy it to edit it.
  ///
  /// In en, this message translates to:
  /// **'Remix it to make it yours'**
  String get builderStarterBanner;

  /// Level Builder: key label: copy a starter or shared level to edit it as your own.
  ///
  /// In en, this message translates to:
  /// **'Remix'**
  String get builderRemix;

  /// Level Builder: screen-reader label of the Remix key. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Remix'**
  String get builderRemixSemantics;

  /// Level Builder › editor › problems and tips sheet: close key. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Close problems and tips'**
  String get builderIssuesCloseSemantics;

  /// Level Builder › editor › problems and tips sheet: title when nothing needs fixing.
  ///
  /// In en, this message translates to:
  /// **'Ready to fly!'**
  String get builderIssuesReadyTitle;

  /// Level Builder › editor › problems and tips sheet: title when there are problems.
  ///
  /// In en, this message translates to:
  /// **'To fix before it flies'**
  String get builderIssuesFixTitle;

  /// Level Builder › editor › problems and tips sheet: title when there are only tips.
  ///
  /// In en, this message translates to:
  /// **'Ready, with a few tips'**
  String get builderIssuesTipsTitle;

  /// Level Builder › editor › problems and tips sheet: line under the title when nothing needs fixing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to fix. Test fly it to the finish to clear it.'**
  String get builderIssuesReadyDetail;

  /// Level Builder › editor › problems and tips sheet: line under the title.
  ///
  /// In en, this message translates to:
  /// **'Tap one to go to its place on the route.'**
  String get builderIssuesDetail;

  /// Level Builder › Level settings sheet: close key. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Close settings'**
  String get builderSettingsCloseSemantics;

  /// Level Builder › Level settings sheet: title.
  ///
  /// In en, this message translates to:
  /// **'Level settings'**
  String get builderSettingsTitle;

  /// Level Builder › Level settings sheet: line under the title. {mode} is the level's flight mode (Tap & Fly, Push-Up Flight…).
  ///
  /// In en, this message translates to:
  /// **'{mode} · changes save as you make them'**
  String builderSettingsSubtitle(String mode);

  /// Level Builder › Level settings sheet: caption over the level's name. Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get builderSettingsName;

  /// Level Builder: key label: rename the level.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get builderRename;

  /// Level Builder: screen-reader label of the Rename key. Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get builderRenameSemantics;

  /// Level Builder › Level settings sheet: caption over the strip of world regions the level flies in. Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get builderSettingsRegion;

  /// Level Builder › Level settings sheet: small note beside the Region caption.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} places · swipe for more}}'**
  String builderSettingsRegionHint(int count);

  /// Level Builder › Level settings sheet: caption over the pace choice. Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get builderSettingsPace;

  /// Level Builder › Level settings sheet: small note beside the Pace caption.
  ///
  /// In en, this message translates to:
  /// **'how fast the sky scrolls'**
  String get builderSettingsPaceHint;

  /// Level Builder › Level settings sheet: caption over the two star marks (stars needed for two and three stars). Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Star marks'**
  String get builderSettingsMarks;

  /// Level Builder › Level settings sheet: small note beside the Star marks caption: stars placed in the level.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star placed} other{{count} stars placed}}'**
  String builderSettingsMarksHint(int count);

  /// Level Builder › Level settings sheet: spoken name of the two-star mark's value (stars needed for two stars), used in "Less two-star mark".
  ///
  /// In en, this message translates to:
  /// **'two-star mark'**
  String get builderMarkTwoSemantics;

  /// Level Builder › Level settings sheet: spoken name of the three-star mark's value (stars needed for three stars).
  ///
  /// In en, this message translates to:
  /// **'three-star mark'**
  String get builderMarkThreeSemantics;

  /// Level Builder › Level settings sheet: choice key: the star marks follow the stars placed.
  ///
  /// In en, this message translates to:
  /// **'Auto: follow the stars'**
  String get builderMarksAuto;

  /// Level Builder › Level settings sheet: choice key: the player sets the star marks.
  ///
  /// In en, this message translates to:
  /// **'Set by hand'**
  String get builderMarksByHand;

  /// Level Builder › Level settings sheet: caption over the Shoot and Sprint switches. Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get builderSettingsControls;

  /// Level Builder › Level settings sheet: switch key: the Shoot (fire) button is on in this level.
  ///
  /// In en, this message translates to:
  /// **'Shoot on'**
  String get builderShootOn;

  /// Level Builder › Level settings sheet: switch key: the Shoot (fire) button is off in this level.
  ///
  /// In en, this message translates to:
  /// **'Shoot off'**
  String get builderShootOff;

  /// Level Builder › Level settings sheet: switch key: the Sprint (burst) button is on in this level.
  ///
  /// In en, this message translates to:
  /// **'Sprint on'**
  String get builderSprintOn;

  /// Level Builder › Level settings sheet: switch key: the Sprint (burst) button is off in this level.
  ///
  /// In en, this message translates to:
  /// **'Sprint off'**
  String get builderSprintOff;

  /// Level Builder › Level settings sheet: caption over the bosses that can wait at the level's end. Shown in capitals (the code capitalizes it).
  ///
  /// In en, this message translates to:
  /// **'Boss finale'**
  String get builderSettingsBoss;

  /// Level Builder › Level settings sheet: small note beside the Boss finale caption.
  ///
  /// In en, this message translates to:
  /// **'waits at the end'**
  String get builderSettingsBossHint;

  /// Level Builder › Level settings sheet: screen-reader label of the key for no boss (the level ends at a finish line). Screen-reader label (also a tooltip on a long press).
  ///
  /// In en, this message translates to:
  /// **'No boss: a finish line'**
  String get builderNoBossSemantics;

  /// Level Builder › Level settings sheet: label under the finish-flag key: no boss. A narrow key.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get builderNoBoss;

  /// Level Builder › Level settings sheet: short name of Baron Bat under its portrait on a narrow key (the glossary's short form).
  ///
  /// In en, this message translates to:
  /// **'Baron'**
  String get builderBossShort_baronBat;

  /// Level Builder › Level settings sheet: short name of Spitter King under its portrait on a narrow key (the glossary's short form).
  ///
  /// In en, this message translates to:
  /// **'Spitter'**
  String get builderBossShort_spitterBeetle;

  /// Level Builder › Level settings sheet: short name of Dusk Empress under its portrait on a narrow key (the glossary's short form).
  ///
  /// In en, this message translates to:
  /// **'Empress'**
  String get builderBossShort_duskMoth;

  /// Level Builder › Level settings sheet: short name of Pirate Captain under its portrait on a narrow key (the glossary's short form).
  ///
  /// In en, this message translates to:
  /// **'Pirate'**
  String get builderBossShort_pirate;

  /// Level Builder › Level settings sheet: short name of Ember Dragon under its portrait on a narrow key (the glossary's short form).
  ///
  /// In en, this message translates to:
  /// **'Dragon'**
  String get builderBossShort_dragon;

  /// Level Builder › Level settings sheet: note in a push-up or squat level instead of the controls and boss choices. {movement} is pushUp or squat (the level's camera mini game): keep both cases.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, squat{The bird flies two lanes: the top and the bottom of each squat. A slower player meets the same level at a gentler speed. No shooting, sprinting or bosses here.} other{The bird flies two lanes: the top and the bottom of each push-up. A slower player meets the same level at a gentler speed. No shooting, sprinting or bosses here.}}'**
  String builderSettingsLanesNote(String movement);

  /// Level Builder › Level settings sheet: note in a jump level instead of the controls and boss choices.
  ///
  /// In en, this message translates to:
  /// **'Each jump lifts the bird; it glides in between. No shooting, sprinting or bosses here.'**
  String get builderSettingsJumpNote;

  /// Level Builder › editor: toast when the player taps inside the start zone. The start zone is always on the left of the sky, in every language.
  ///
  /// In en, this message translates to:
  /// **'Keep the start zone clear: place things right of the dashed line.'**
  String get builderStartZoneToast;

  /// Level Builder › editor: screen-reader label of the sky the level is built on.
  ///
  /// In en, this message translates to:
  /// **'Level sky. Tap to place, drag to move or to scroll.'**
  String get builderSkySemantics;

  /// Level Builder › editor: screen-reader label of a starter level's sky.
  ///
  /// In en, this message translates to:
  /// **'Level sky. Tap something to look at it.'**
  String get builderSkyReadOnlySemantics;

  /// Level Builder › editor: title of the first-steps card over an empty level's sky.
  ///
  /// In en, this message translates to:
  /// **'Build your level'**
  String get builderCoachTitle;

  /// Level Builder › editor: first step under a numbered picture (up to three short lines). The tools are on the left in every language.
  ///
  /// In en, this message translates to:
  /// **'Pick a tool on the left'**
  String get builderCoachPickTool;

  /// Level Builder › editor: second step under a numbered picture (up to three short lines).
  ///
  /// In en, this message translates to:
  /// **'Tap the sky to place it'**
  String get builderCoachTapSky;

  /// Level Builder › editor: third step under a numbered picture (up to three short lines).
  ///
  /// In en, this message translates to:
  /// **'Test fly it!'**
  String get builderCoachTestFly;

  /// Level Builder › editor: line at the foot of the first-steps card.
  ///
  /// In en, this message translates to:
  /// **'Drag a thing to move it · drag the sky to scroll'**
  String get builderCoachDrag;

  /// Level Builder › editor: tip in the sky's corner after the first things are placed.
  ///
  /// In en, this message translates to:
  /// **'Drag it to move it · drag the sky to scroll'**
  String get builderTipDrag;

  /// Level Builder › editor: tag on the sky's upper aiming line in a push-up or squat level (where the bird is at the top of the movement). Capitals. {movement} is pushUp or squat (the level's camera mini game): keep both cases.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, squat{TOP OF THE SQUAT} other{TOP OF THE PUSH-UP}}'**
  String builderCanvasTopOf(String movement);

  /// Level Builder › editor: short form of builderCanvasTopOf once the start is scrolled away. Capitals.
  ///
  /// In en, this message translates to:
  /// **'TOP'**
  String get builderCanvasTop;

  /// Level Builder › editor: tag on the sky's lower aiming line in a push-up or squat level. Capitals. {movement} is pushUp or squat (the level's camera mini game): keep both cases.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, squat{BOTTOM OF THE SQUAT} other{BOTTOM OF THE PUSH-UP}}'**
  String builderCanvasBottomOf(String movement);

  /// Level Builder › editor: short form of builderCanvasBottomOf. Capitals.
  ///
  /// In en, this message translates to:
  /// **'BOTTOM'**
  String get builderCanvasBottom;

  /// Level Builder › editor: tag over the hatched start zone at the start of the route, which must stay empty. Capitals; shown only where it fits.
  ///
  /// In en, this message translates to:
  /// **'START ZONE · KEEP CLEAR'**
  String get builderCanvasStartZoneFull;

  /// Level Builder › editor: short form of the start zone tag. Capitals.
  ///
  /// In en, this message translates to:
  /// **'START ZONE'**
  String get builderCanvasStartZone;

  /// Level Builder › editor: tag on the dashed line where the finish line will go while the Finish tool is pressed. Capitals.
  ///
  /// In en, this message translates to:
  /// **'FINISH HERE'**
  String get builderCanvasFinishHere;

  /// Level Builder › editor › tools down the left edge: label of the Select tool key, under a small picture. A narrow key: one short word.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get builderTool_select;

  /// Level Builder › editor › tools down the left edge: screen-reader label and tooltip of the Select tool.
  ///
  /// In en, this message translates to:
  /// **'Select: tap something to change it, drag to move it'**
  String get builderToolHint_select;

  /// Level Builder › editor › tools down the left edge: label of the Gate tool key, under a small picture. A narrow key: one short word.
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get builderTool_gate;

  /// Level Builder › editor › tools down the left edge: screen-reader label and tooltip of the Gate tool.
  ///
  /// In en, this message translates to:
  /// **'Gate: tap the sky to place a gate'**
  String get builderToolHint_gate;

  /// Level Builder › editor › tools down the left edge: label of the Star tool key, under a small picture. A narrow key: one short word.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get builderTool_star;

  /// Level Builder › editor › tools down the left edge: screen-reader label and tooltip of the Star tool.
  ///
  /// In en, this message translates to:
  /// **'Star: tap the sky to place a star'**
  String get builderToolHint_star;

  /// Level Builder › editor › tools down the left edge: label of the Trio tool key, under a small picture. A narrow key: one short word.
  ///
  /// In en, this message translates to:
  /// **'Trio'**
  String get builderTool_trio;

  /// Level Builder › editor › tools down the left edge: screen-reader label and tooltip of the Trio tool.
  ///
  /// In en, this message translates to:
  /// **'Star trio: tap the sky to place three stars'**
  String get builderToolHint_trio;

  /// Level Builder › editor › tools down the left edge: label of the Heart tool key, under a small picture. A narrow key: one short word.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get builderTool_heart;

  /// Level Builder › editor › tools down the left edge: screen-reader label and tooltip of the Heart tool.
  ///
  /// In en, this message translates to:
  /// **'Heart: tap the sky to place a heart'**
  String get builderToolHint_heart;

  /// Level Builder › editor › tools down the left edge: label of the Enemy tool key, under a small picture. A narrow key: one short word.
  ///
  /// In en, this message translates to:
  /// **'Enemy'**
  String get builderTool_enemy;

  /// Level Builder › editor › tools down the left edge: screen-reader label and tooltip of the Enemy tool.
  ///
  /// In en, this message translates to:
  /// **'Enemy: tap the sky to place an enemy'**
  String get builderToolHint_enemy;

  /// Level Builder › editor › tools down the left edge: label of the Finish tool key, under a small picture. A narrow key: one short word.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get builderTool_finish;

  /// Level Builder › editor › tools down the left edge: screen-reader label and tooltip of the Finish tool.
  ///
  /// In en, this message translates to:
  /// **'Finish: tap the sky to move the finish line'**
  String get builderToolHint_finish;

  /// Level Builder › editor › tools down the left edge: label of the tool that moves where the boss waits (in place of Finish, in a level with a boss finale). One short word.
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get builderTool_boss;

  /// Level Builder › editor › tools down the left edge: screen-reader label and tooltip of the boss mark tool.
  ///
  /// In en, this message translates to:
  /// **'Boss mark: tap the sky to move where the boss waits'**
  String get builderToolHint_boss;

  /// Level Builder › editor: toast when a tool of a starter level (read-only) is pressed.
  ///
  /// In en, this message translates to:
  /// **'Starter levels stay as they are: remix it to change it.'**
  String get builderStarterToolsToast;

  /// Level Builder › editor: screen-reader label of the strip under the sky that shows the whole route. {length} is the level's length ("42 s"); {target} is boss or finish: keep both cases.
  ///
  /// In en, this message translates to:
  /// **'{target, select, boss{Route overview. {length} to the boss. Drag to move along the route.} other{Route overview. {length} to the finish. Drag to move along the route.}}'**
  String builderRouteSemantics(String target, String length);

  /// Level Builder › editor: as builderRouteSemantics, for a push-up or squat level: {reps} is its workout ("12 push-ups").
  ///
  /// In en, this message translates to:
  /// **'{target, select, boss{Route overview. {length} to the boss. {reps}. Drag to move along the route.} other{Route overview. {length} to the finish. {reps}. Drag to move along the route.}}'**
  String builderRouteRepsSemantics(String target, String length, String reps);

  /// Level Builder › editor: tag at the right end of the route strip: the level's length up to the boss ("42 s to the boss", or "12 push-ups · 42 s to the boss").
  ///
  /// In en, this message translates to:
  /// **'{length} to the boss'**
  String builderRouteToBoss(String length);

  /// Built level: tag on a test flight (the level's maker flying their own level to try it; nothing is kept), on the flight HUD and the result plate. Capitals.
  ///
  /// In en, this message translates to:
  /// **'TEST FLIGHT'**
  String get builtResultTestFlight;

  /// Built level › result stage (after flying a level made in the Level Builder): the big word over the bird when the level was flown to the end. Letters drop in one by one.
  ///
  /// In en, this message translates to:
  /// **'Cleared!'**
  String get builtResultCleared;

  /// Built level › result stage (after flying a level made in the Level Builder): the big word over the bird after a bump ended the flight (cartoon bump sound; see the glossary).
  ///
  /// In en, this message translates to:
  /// **'Bonk!'**
  String get builtResultBonk;

  /// Built level › result stage (after flying a level made in the Level Builder): the big word over the bird when the flight ended early another way.
  ///
  /// In en, this message translates to:
  /// **'Landed'**
  String get builtResultLanded;

  /// Built level › result stage (after flying a level made in the Level Builder): tab on the scoreboard of a test flight. Capitals.
  ///
  /// In en, this message translates to:
  /// **'TEST'**
  String get builtResultTestTab;

  /// Built level › result stage (after flying a level made in the Level Builder): the first goal under the first star: reach the finish line.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get builtResultGoalFinish;

  /// Built level › result stage (after flying a level made in the Level Builder): the first goal under the first star in a level with a boss: beat it.
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get builtResultGoalBoss;

  /// Built level › result stage (after flying a level made in the Level Builder): screen-reader label of the first goal. {goal} is builtResultGoalFinish or builtResultGoalBoss.
  ///
  /// In en, this message translates to:
  /// **'{goal}.'**
  String builtResultGoalSemantics(String goal);

  /// Built level › result stage (after flying a level made in the Level Builder): screen-reader label of the first goal once met.
  ///
  /// In en, this message translates to:
  /// **'{goal}. Done.'**
  String builtResultGoalDoneSemantics(String goal);

  /// Built level › result stage (after flying a level made in the Level Builder): screen-reader label of a star mark goal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Collect {count} stars.}}'**
  String builtResultMarkSemantics(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): screen-reader label of a star mark goal once met.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Collect {count} stars. Done.}}'**
  String builtResultMarkDoneSemantics(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): under a goal that was met.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get builtResultDone;

  /// Built level › result stage (after flying a level made in the Level Builder): under a goal not met yet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get builtResultNotYet;

  /// Built level › result stage (after flying a level made in the Level Builder): under a star mark goal: stars still missing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} to go}}'**
  String builtResultToGo(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): under a star mark goal when the stars are there but the level was not finished.
  ///
  /// In en, this message translates to:
  /// **'Finish first'**
  String get builtResultFinishFirst;

  /// Built level › result stage (after flying a level made in the Level Builder): ribbon stamped when the maker flew their own level to the end (it can now be shared). Capitals.
  ///
  /// In en, this message translates to:
  /// **'CLEARED BY YOU'**
  String get builtResultClearedByYou;

  /// Built level › result stage (after flying a level made in the Level Builder): ribbon for a new personal best (stars or score). Capitals.
  ///
  /// In en, this message translates to:
  /// **'NEW BEST!'**
  String get builtResultNewBest;

  /// Built level › result stage (after flying a level made in the Level Builder): tag on a test flight's stars: they are not kept.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get builtResultPractice;

  /// Built level › result stage (after flying a level made in the Level Builder): tag with the level's best (stars or score).
  ///
  /// In en, this message translates to:
  /// **'Best {count}'**
  String builtResultBest(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): tag on the first flight that reached the finish.
  ///
  /// In en, this message translates to:
  /// **'First clear!'**
  String get builtResultFirstClear;

  /// Built level › result stage (after flying a level made in the Level Builder): label over the stars collected. Capitals.
  ///
  /// In en, this message translates to:
  /// **'STARS COLLECTED'**
  String get builtResultStarsCollected;

  /// Built level › result stage (after flying a level made in the Level Builder): screen-reader label of the three big stars the flight earned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} of 3 level stars}}'**
  String builtResultRatingSemantics(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): label over a test flight's workout count: how many push-ups or squats the level asks for. Capitals.
  ///
  /// In en, this message translates to:
  /// **'ASKS FOR'**
  String get builtResultAsksFor;

  /// Built level › result stage (after flying a level made in the Level Builder): label over the push-ups, squats or jumps done. Capitals.
  ///
  /// In en, this message translates to:
  /// **'WORKOUT'**
  String get builtResultWorkout;

  /// Built level › result stage (after flying a level made in the Level Builder): label over how far a short flight got (in seconds). Capitals.
  ///
  /// In en, this message translates to:
  /// **'GOT TO'**
  String get builtResultGotTo;

  /// Built level › result stage (after flying a level made in the Level Builder): label over the flight's score. Capitals.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get builtResultScore;

  /// Built level › result stage (after flying a level made in the Level Builder): unit under the number of push-ups done.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{push-ups}}'**
  String builtResultPushUps(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): unit under the number of squats done.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{squats}}'**
  String builtResultSquats(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): unit under the number of jumps done.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{jumps}}'**
  String builtResultJumps(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): under a test flight's count: the push-ups the level asks for when flown on camera (a test is flown with a finger).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{push-ups on camera}}'**
  String builtResultPushUpsOnCamera(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): under a test flight's count: the squats the level asks for when flown on camera.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{squats on camera}}'**
  String builtResultSquatsOnCamera(int count);

  /// Built level › result stage (after flying a level made in the Level Builder): under how far a flight got: of the level's whole length. {length} is "42 s".
  ///
  /// In en, this message translates to:
  /// **'of {length}'**
  String builtResultOfLength(String length);

  /// Built level › result stage (after flying a level made in the Level Builder): under a test flight's score: it is not kept.
  ///
  /// In en, this message translates to:
  /// **'Not kept'**
  String get builtResultNotKept;

  /// Built level › result stage (after flying a level made in the Level Builder): under the score when the level has no best yet.
  ///
  /// In en, this message translates to:
  /// **'No best yet'**
  String get builtResultNoBest;

  /// Built level › result stage (after flying a level made in the Level Builder): strip when the maker flew their own level to the end.
  ///
  /// In en, this message translates to:
  /// **'Cleared by you · ready to share!'**
  String get builtResultClearedStrip;

  /// Built level › result stage (after flying a level made in the Level Builder): strip after a test flight started part-way: {from} is where it started ("12 s").
  ///
  /// In en, this message translates to:
  /// **'Flown from {from}. Fly it all to clear it.'**
  String builtResultFlownFrom(String from);

  /// Built level › result stage (after flying a level made in the Level Builder): strip after a test flight.
  ///
  /// In en, this message translates to:
  /// **'Test flight · nothing is saved'**
  String get builtResultTestNothingSaved;

  /// Built level › result stage (after flying a level made in the Level Builder): strip after a test flight of a camera level that ended early: {reached} and {length} are times ("12 s", "42 s").
  ///
  /// In en, this message translates to:
  /// **'Test flight · got to {reached} of {length}'**
  String builtResultTestGotTo(String reached, String length);

  /// Built level › result stage (after flying a level made in the Level Builder): strip after a camera level's flight ended early.
  ///
  /// In en, this message translates to:
  /// **'Got to {reached} of {length}. Reach the finish for stars.'**
  String builtResultGotToFinish(String reached, String length);

  /// Built level › result stage (after flying a level made in the Level Builder): strip after a Tap & Fly flight ended early.
  ///
  /// In en, this message translates to:
  /// **'Reach the finish to earn stars.'**
  String get builtResultReachFinish;

  /// Built level › result stage (after flying a level made in the Level Builder): quiet line once the flight is saved.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get builtResultSaved;

  /// Built level › result stage (after flying a level made in the Level Builder): quiet line while the flight saves.
  ///
  /// In en, this message translates to:
  /// **'Saving your flight…'**
  String get builtResultSaving;

  /// Built level › result stage (after flying a level made in the Level Builder): small key back to the Level Builder shelf.
  ///
  /// In en, this message translates to:
  /// **'Builder'**
  String get builtResultBuilder;

  /// Built level › result stage (after flying a level made in the Level Builder): big key back to the editor after a finished test flight.
  ///
  /// In en, this message translates to:
  /// **'Edit level'**
  String get builtResultEditLevel;

  /// Built level › result stage (after flying a level made in the Level Builder): small key back to the editor.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get builtResultEdit;

  /// Built level › result stage (after flying a level made in the Level Builder): big key to fly the level again after reaching the finish.
  ///
  /// In en, this message translates to:
  /// **'Fly again'**
  String get builtResultFlyAgain;

  /// Built level › result stage (after flying a level made in the Level Builder): small key to watch the saved flight (replay).
  ///
  /// In en, this message translates to:
  /// **'Watch replay'**
  String get builtResultWatchReplay;

  /// Built level › result stage (after flying a level made in the Level Builder): small key while the replay is being prepared.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get builtResultPreparing;

  /// Built level › result stage (after flying a level made in the Level Builder): small key while the flight is saved as a session.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get builtResultSessionSaving;

  /// Built level › result stage (after flying a level made in the Level Builder): small key that keeps this flight as a saved session to replay.
  ///
  /// In en, this message translates to:
  /// **'Save session'**
  String get builtResultSaveSession;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): the screen title in the header (heading font, shrinks to fit). Same words as the Home key (glossary mode.level-builder).
  ///
  /// In en, this message translates to:
  /// **'Level Builder'**
  String get builderShelfTitle;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): header key that reads a friend's level share code from the clipboard. Short verb + noun (glossary ui.share-code).
  ///
  /// In en, this message translates to:
  /// **'Paste code'**
  String get builderShelfPasteCode;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): key that starts building a new level (in the header and on the empty shelf); also what a screen reader says for it.
  ///
  /// In en, this message translates to:
  /// **'New level'**
  String get builderShelfNewLevel;

  /// Level Builder shelf: a short toast that pops up over the shelf for a moment, one sentence (it may wrap to two lines). Saving a level, a copy or a deletion failed.
  ///
  /// In en, this message translates to:
  /// **'That didn’t save. Please try again.'**
  String get builderShelfSaveFailed;

  /// Level Builder shelf: title of the sheet that asks before deleting one of the player's levels. {name} is the level's name as the player typed it; use your language's quotation marks.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String builderShelfDeleteTitle(String name);

  /// Level Builder shelf: the delete question's explanation, under its title (wraps). "Bests" are the level's best scores and stars; the exercise counts stay in the player's records.
  ///
  /// In en, this message translates to:
  /// **'Its bests go with it. Push-ups, squats and jumps you flew on it still count.'**
  String get builderShelfDeleteBody;

  /// Level Builder: the key that deletes a level (the delete question's yes key, and the title of the Delete card in a level's More sheet). One verb.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get builderShelfDelete;

  /// Level Builder shelf: a short toast that pops up over the shelf for a moment, one sentence (it may wrap to two lines). After a level was deleted. {name} is its name as the player typed it.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{name}”.'**
  String builderShelfDeleted(String name);

  /// Level Builder shelf: a short toast that pops up over the shelf for a moment, one sentence (it may wrap to two lines). Shown when the player tries to share a level that cannot be flown yet. "Fix it" is the card key builderShelfFixIt: use the same words.
  ///
  /// In en, this message translates to:
  /// **'Fix what’s marked in red before sharing: tap Fix it.'**
  String get builderShelfFixFirst;

  /// Level Builder shelf: a short toast that pops up over the shelf for a moment, one sentence (it may wrap to two lines). The level's share code was copied to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Code copied! Paste it to a friend.'**
  String get builderShelfCodeCopied;

  /// Level Builder shelf: a short toast that pops up over the shelf for a moment, one sentence (it may wrap to two lines). The share code was copied, but the maker has not flown the level to its finish yet (friends see that in their preview).
  ///
  /// In en, this message translates to:
  /// **'Code copied! Fly it to the finish too, so friends know it can be done.'**
  String get builderShelfCodeCopiedUncleared;

  /// Level Builder shelf: a short toast that pops up over the shelf for a moment, one sentence (it may wrap to two lines). The player tried to fly a level that still has problems. "Fix it" is builderShelfFixIt.
  ///
  /// In en, this message translates to:
  /// **'This level isn’t ready to fly yet: tap Fix it.'**
  String get builderShelfNotReady;

  /// Level Builder shelf: title of the notice when Paste code finds no level code on the clipboard (heading, wraps).
  ///
  /// In en, this message translates to:
  /// **'No level code to paste'**
  String get builderShelfPasteMissingTitle;

  /// Level Builder shelf: notice title when a pasted level code was made by a newer version of the game. Keep "Beakbound" in Latin letters.
  ///
  /// In en, this message translates to:
  /// **'A level from a newer Beakbound'**
  String get builderShelfPasteNewerTitle;

  /// Level Builder shelf: notice title when a pasted level code is damaged (incomplete or mistyped). Light, friendly tone.
  ///
  /// In en, this message translates to:
  /// **'That code got scrambled'**
  String get builderShelfPasteDamagedTitle;

  /// Level Builder shelf: the notice's line under builderShelfPasteMissingTitle (wraps). Keep "BEAK1." exactly as it is (the code's prefix, with its dot). "Paste code" is builderShelfPasteCode.
  ///
  /// In en, this message translates to:
  /// **'Copy a friend’s level code (it starts with BEAK1.) and tap Paste code again.'**
  String get builderShelfPasteMissingBody;

  /// Level Builder shelf: the notice's line under builderShelfPasteNewerTitle (wraps). Keep "Beakbound" in Latin letters.
  ///
  /// In en, this message translates to:
  /// **'Update Beakbound to fly it, then paste the code again.'**
  String get builderShelfPasteNewerBody;

  /// Level Builder shelf: the notice's line under builderShelfPasteDamagedTitle (wraps).
  ///
  /// In en, this message translates to:
  /// **'Part of it is missing or mistyped. Ask your friend to copy the whole code again.'**
  String get builderShelfPasteDamagedBody;

  /// Level Builder shelf: a short toast that pops up over the shelf for a moment, one sentence (it may wrap to two lines). A friend's level was imported. {name} is the level's name as its maker typed it.
  ///
  /// In en, this message translates to:
  /// **'“{name}” is on your shelf!'**
  String builderShelfImported(String name);

  /// Level Builder shelf: shown instead of the shelf when the saved levels could not be read, above a Try again key (heading).
  ///
  /// In en, this message translates to:
  /// **'Your levels need a moment.'**
  String get builderShelfUnavailable;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): title of the row of the player's own levels (heading, small capitals look not needed).
  ///
  /// In en, this message translates to:
  /// **'My levels'**
  String get builderShelfMine;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): title of the row of ready-made starter levels (glossary ui.starter-levels).
  ///
  /// In en, this message translates to:
  /// **'Starter levels'**
  String get builderShelfStarters;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): small print after the starter row's title, on one line. "Remix" is the key builderShelfRemix.
  ///
  /// In en, this message translates to:
  /// **'Fly one, or remix it into a level of your own'**
  String get builderShelfStartersHint;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): big title of the empty shelf, before the player has made a level. One line (shrinks to fit).
  ///
  /// In en, this message translates to:
  /// **'Build your first level'**
  String get builderShelfEmptyTitle;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): the empty shelf's two-line invitation under its title. "Test fly" = fly your own level to try it (glossary mode.test-flight).
  ///
  /// In en, this message translates to:
  /// **'Place gates, stars and hearts by hand, set the finish line and test fly it.'**
  String get builderShelfEmptyBody;

  /// Level Builder shelf (the list of the player's own levels and the starter levels): key on the empty shelf that pastes a level code a friend shared; also its screen-reader label.
  ///
  /// In en, this message translates to:
  /// **'Paste a friend’s code'**
  String get builderShelfPasteFriend;

  /// Level Builder shelf: sticker on a level card's picture when the level cannot be flown yet (it has problems marked in red in the editor). Tiny badge.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get builderShelfNeedsWork;

  /// Level Builder shelf: sticker on a level card's picture: its maker (the player) flew it to the finish (glossary ui.cleared-by-you). Tiny badge.
  ///
  /// In en, this message translates to:
  /// **'Cleared by you'**
  String get builderShelfClearedByYou;

  /// Level Builder shelf: sticker on a level card's picture: the level was imported from a friend's code. Tiny badge.
  ///
  /// In en, this message translates to:
  /// **'From a friend'**
  String get builderShelfFromFriend;

  /// Level Builder shelf: the key on a level or starter card that flies it. One very short verb (glossary ui.fly); the key is small and the word shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Fly'**
  String get builderShelfFly;

  /// Level Builder shelf: screen-reader label of a card's Fly key. {name} is the level's name.
  ///
  /// In en, this message translates to:
  /// **'Fly {name}'**
  String builderShelfFlySemantics(String name);

  /// Level Builder shelf: the key on a level card that cannot be flown yet; it opens the editor at the problems. Very short; it shrinks to fit a small key.
  ///
  /// In en, this message translates to:
  /// **'Fix it'**
  String get builderShelfFixIt;

  /// Level Builder shelf: screen-reader label of the Fix it key. {name} is the level's name.
  ///
  /// In en, this message translates to:
  /// **'Fix {name}'**
  String builderShelfFixSemantics(String name);

  /// Level Builder shelf: screen-reader label (and tooltip) of a level card's pencil key, which opens the editor. {name} is the level's name.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String builderShelfEditSemantics(String name);

  /// Level Builder shelf: screen-reader label (and tooltip) of a level card's share key, which copies its share code. {name} is the level's name.
  ///
  /// In en, this message translates to:
  /// **'Share {name}'**
  String builderShelfShareSemantics(String name);

  /// Level Builder shelf: screen-reader label of the share key on a level the player has flown to the finish (worth sharing). {name} is the level's name.
  ///
  /// In en, this message translates to:
  /// **'Share {name}: you cleared it'**
  String builderShelfShareClearedSemantics(String name);

  /// Level Builder shelf: screen-reader label (and tooltip) of a level card's "…" key, which opens Share code, Duplicate and Delete. {name} is the level's name.
  ///
  /// In en, this message translates to:
  /// **'More for {name}'**
  String builderShelfMoreSemantics(String name);

  /// Level Builder shelf: key on a starter level card that copies it into a level of the player's own to change (glossary ui.remix). Very short; small key, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Remix'**
  String get builderShelfRemix;

  /// Level Builder shelf: screen-reader label of a starter card's Remix key. {name} is the starter level's name.
  ///
  /// In en, this message translates to:
  /// **'Remix {name}'**
  String builderShelfRemixSemantics(String name);

  /// Level Builder shelf: one line on a level card that cannot be flown yet: how many problems are left to fix in the editor.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing to fix in the editor} other{{count} things to fix in the editor}}'**
  String builderShelfToFixInEditor(int count);

  /// Level Builder shelf: a starter level card's fact: how many stars the level holds (glossary pickup.star). Small one-line fact.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} stars}}'**
  String builderShelfStars(int count);

  /// Level Builder shelf: what a screen reader says for one of the player's level cards (first part). {name} is the level's name, {mode} its mode ("Tap & Fly", "Push-ups"), {region} its region ("Jungle"), {length} how long it takes ("42 s"). Further sentences follow (best stars, needs work...).
  ///
  /// In en, this message translates to:
  /// **'{name}. {mode} in {region}. {length}.'**
  String builderShelfLevelSemantics(
    String name,
    String mode,
    String region,
    String length,
  );

  /// Level Builder shelf: screen-reader sentence for a level's best result: {stars} of the 3 rating stars (0-3).
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, other{Best {stars} of 3 stars.}}'**
  String builderShelfBestSemantics(int stars);

  /// Level Builder shelf: screen-reader sentence for a level that cannot be flown yet: how many problems are left. "Needs work" is the badge builderShelfNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Needs work: 1 thing to fix.} other{Needs work: {count} things to fix.}}'**
  String builderShelfNeedsWorkSemantics(int count);

  /// Level Builder shelf: screen-reader sentence for a level the player flew to the finish (the badge builderShelfClearedByYou).
  ///
  /// In en, this message translates to:
  /// **'Cleared by you.'**
  String get builderShelfClearedSemantics;

  /// Level Builder shelf: screen-reader sentence for a level imported from a friend's code (the badge builderShelfFromFriend).
  ///
  /// In en, this message translates to:
  /// **'From a friend.'**
  String get builderShelfFromFriendSemantics;

  /// Level Builder shelf: screen-reader label of a starter level card (tapping it opens the level to look at). {name} is its name, {mode} its mode ("Push-ups"), {length} its length ("1 min 05 s"), {fact} its boss, exercise count or stars ("Baron Bat", "10 push-ups", "24 stars").
  ///
  /// In en, this message translates to:
  /// **'Look at {name}. {mode}, {length}, {fact}.'**
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  );

  /// Level Builder: the word added after a level's name to name a remix of it ("Garden Hop remix"); a space is put before it. The result is the new level's name, which the player can rename. Lower case unless your language capitalizes it; keep it short (it counts toward the 40-character name limit).
  ///
  /// In en, this message translates to:
  /// **'remix'**
  String get builderShelfRemixSuffix;

  /// Level Builder: the word added after a level's name to name its duplicate ("My tap level copy"); a space is put before it. Short (counts toward the 40-character name limit).
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get builderShelfCopySuffix;

  /// A key that closes a notice after reading it. Shared word: "OK" or your platform's usual word.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// A key that cancels: closes a sheet or dialog without doing anything. Shared word.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Level Builder: the name of a starter level, the Tap & Fly starter: a playful hop through garden gates in the Jungle (glossary level.starter-garden-hop). Title case like a level name; shown on the shelf's starter card (shrinks to fit a small card) and when flown.
  ///
  /// In en, this message translates to:
  /// **'Garden Hop'**
  String get starter_t_tap_1_name;

  /// Level Builder: the name of a starter level, the push-up starter over the Great Wall: literally ten push-ups; keep the number 10 (as a word or digits) and the push-up word of the Push-Up Flight mode. Title case like a level name; shown on the shelf's starter card (shrinks to fit a small card) and when flown.
  ///
  /// In en, this message translates to:
  /// **'Ten Push-Ups'**
  String get starter_t_push_1_name;

  /// Level Builder: the name of a starter level, the squat starter: stairs + squats; alliteration is a bonus. Title case like a level name; shown on the shelf's starter card (shrinks to fit a small card) and when flown.
  ///
  /// In en, this message translates to:
  /// **'Stair Squats'**
  String get starter_t_squat_1_name;

  /// Level Builder: the name of a starter level, the jump starter: bouncing (jumps) + bay; alliteration is a bonus. Title case like a level name; shown on the shelf's starter card (shrinks to fit a small card) and when flown.
  ///
  /// In en, this message translates to:
  /// **'Bounce Bay'**
  String get starter_t_jump_1_name;

  /// Level Builder: the name of a starter level, the Tap & Fly starter that ends with Baron Bat: the Baron's short name + bridge. Title case like a level name; shown on the shelf's starter card (shrinks to fit a small card) and when flown.
  ///
  /// In en, this message translates to:
  /// **'Baron’s Bridge'**
  String get starter_t_tap_boss_name;

  /// Level Builder, new level sheet: screen-reader label of its close key (and of the dimmed sky around it).
  ///
  /// In en, this message translates to:
  /// **'Close new level'**
  String get builderPickCloseNewLevel;

  /// Level Builder, new level sheet, step 1: big title over the four modes to build a level for. One line, it does not shrink.
  ///
  /// In en, this message translates to:
  /// **'What will it be?'**
  String get builderPickModeTitle;

  /// Level Builder, new level sheet, step 2: big title over the thirteen regions to choose from. One line, it does not shrink.
  ///
  /// In en, this message translates to:
  /// **'Where does it fly?'**
  String get builderPickRegionTitle;

  /// Level Builder, new level sheet, step 1: one line under the title. Even a push-up level is test flown by tapping in the editor. One line, it does not shrink: keep within the budget.
  ///
  /// In en, this message translates to:
  /// **'Pick how it’s flown (you can’t change it later). You test fly every level by touch.'**
  String get builderPickModeSubtitle;

  /// Level Builder, new level sheet, step 2: one line under the title. {mode} is the mode picked in step 1 ("Tap & Fly", "Push-ups"). One line, it does not shrink.
  ///
  /// In en, this message translates to:
  /// **'{mode} · pick where it flies. You can change this later.'**
  String builderPickRegionSubtitle(String mode);

  /// Level Builder, new level sheet: the Tap & Fly card's line under its name: what a Tap & Fly level can hold. At most two short lines in a narrow card.
  ///
  /// In en, this message translates to:
  /// **'Tap to flap. Gates, stars, enemies and a boss.'**
  String get builderPickTouchLine;

  /// Level Builder, new level sheet: the Push-Up Flight card's line: a push-up level has two lanes (glossary ui.lane) and every dip into the low lane is one push-up. At most two short lines.
  ///
  /// In en, this message translates to:
  /// **'A high lane and a low one: every dip is a push-up.'**
  String get builderPickPushUpLine;

  /// Level Builder, new level sheet: the Squat & Fly card's line: two lanes, every dip is one squat. At most two short lines.
  ///
  /// In en, this message translates to:
  /// **'A high lane and a low one: every dip is a squat.'**
  String get builderPickSquatLine;

  /// Level Builder, new level sheet: the Jump & Fly card's line: each jump lifts the bird; gates can sit at any height. At most two short lines.
  ///
  /// In en, this message translates to:
  /// **'Jump for lift. Gates anywhere in the sky.'**
  String get builderPickJumpLine;

  /// Level Builder, new level sheet: screen-reader label of a mode card: the mode's name, then its line.
  ///
  /// In en, this message translates to:
  /// **'{mode}. {line}'**
  String builderPickModeSemantics(String mode, String line);

  /// Level Builder, new level sheet: tiny tag with a camera icon on the cards of the modes played with the phone's camera (push-ups, squats, jumps).
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get builderPickCamera;

  /// Level Builder, new level sheet, step 2: tiny sticker on the region card the game suggests for the chosen mode. One word if possible: the badge is small.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get builderPickSuggested;

  /// Level Builder, new level sheet: screen-reader label of the suggested region's card. {region} is the region's name.
  ///
  /// In en, this message translates to:
  /// **'{region}, suggested'**
  String builderPickSuggestedSemantics(String region);

  /// Level Builder: screen-reader label of the close key on a level's More sheet (Share code, Duplicate, Delete).
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get builderPickClose;

  /// Level Builder, a level's More sheet: the Share code card's line while the level cannot be flown yet (it replaces builderPickShareLine; at most two short lines).
  ///
  /// In en, this message translates to:
  /// **'Not yet: fix what’s marked in red first.'**
  String get builderPickNotYet;

  /// Level Builder, a level's More sheet: title of the card that copies the level's share code (glossary ui.share-code). One line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get builderPickShare;

  /// Level Builder, a level's More sheet: the Share code card's line (at most two short lines). Keep "Beakbound" in Latin letters.
  ///
  /// In en, this message translates to:
  /// **'Copy a code a friend can paste into their Beakbound.'**
  String get builderPickShareLine;

  /// Level Builder, a level's More sheet: title of the card that copies the level under a new name. One line, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get builderPickDuplicate;

  /// Level Builder, a level's More sheet: the Duplicate card's line (at most two short lines).
  ///
  /// In en, this message translates to:
  /// **'Make a copy to try another idea.'**
  String get builderPickDuplicateLine;

  /// Level Builder, a level's More sheet: the Delete card's line (at most two short lines); a question comes before anything is deleted.
  ///
  /// In en, this message translates to:
  /// **'Throw the level away. You’ll be asked first.'**
  String get builderPickDeleteLine;

  /// Level Builder: a level's mode and region, under its name on the More sheet and in a pasted level's preview. Keep the middle dot or use your language's separator.
  ///
  /// In en, this message translates to:
  /// **'{mode} · {region}'**
  String builderPickLevelSubtitle(String mode, String region);

  /// Level Builder, a pasted level's preview: screen-reader label of its close key (and of the dimmed sky around it).
  ///
  /// In en, this message translates to:
  /// **'Cancel import'**
  String get builderPickCancelImport;

  /// Level Builder, a pasted level's preview: big title of the sheet showing a level from a friend's code. One line, it does not shrink.
  ///
  /// In en, this message translates to:
  /// **'A level to fly!'**
  String get builderPickImportTitle;

  /// Level Builder, a pasted level's preview: one line under the title. One line, it does not shrink.
  ///
  /// In en, this message translates to:
  /// **'Someone shared this level with you.'**
  String get builderPickImportSubtitle;

  /// Level Builder, a pasted level's preview: sticker on its picture: the friend who made it flew it to the finish (glossary ui.cleared-by-you). Tiny badge.
  ///
  /// In en, this message translates to:
  /// **'Cleared by its maker'**
  String get builderPickClearedByMaker;

  /// Level Builder, a pasted level's preview: one fact line: how many stars the level holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} stars to collect}}'**
  String builderPickStarsToCollect(int count);

  /// Level Builder, a pasted level's preview: one fact line: the boss the level ends with. {boss} is the boss's name ("Baron Bat"). {bossId} is the boss's id (baronBat, spitterBeetle, duskMoth, pirate, dragon, kingCoo, searchlightGargoyle, neferhoo): select on it for the article or case the name takes in your language, e.g. "{bossId, select, duskMoth{die {boss}} dragon{den Glutdrachen} other{den {boss}}}"; keep {boss} wherever the name is written as is, and always end with other{…} for a boss added later.
  ///
  /// In en, this message translates to:
  /// **'{bossId, select, other{Ends with {boss}}}'**
  String builderPickEndsWith(String boss, String bossId);

  /// Level Builder, a pasted level's preview: one fact line when the friend who made it has not flown it to the finish (so it may be impossible).
  ///
  /// In en, this message translates to:
  /// **'Its maker hasn’t flown it to the end yet.'**
  String get builderPickNotFlown;

  /// Level Builder, a pasted level's preview: small caption over the strip that pictures the level's route.
  ///
  /// In en, this message translates to:
  /// **'The route'**
  String get builderPickRoute;

  /// Level Builder, a pasted level's preview: warning line when the player already keeps a level with the same route. {name} is that level's name as the player saved it.
  ///
  /// In en, this message translates to:
  /// **'You already have this level: “{name}”.'**
  String builderPickAlreadyHave(String name);

  /// Level Builder, a pasted level's preview: key that imports the level anyway, as a second copy (when the player already has it). Shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Import a copy'**
  String get builderPickImportCopy;

  /// Level Builder, a pasted level's preview: key that opens the player's own copy of the level in the editor instead. Shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Open yours'**
  String get builderPickOpenYours;

  /// Level Builder, a pasted level's preview: key that keeps the friend's level on the player's shelf. Shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get builderPickImport;

  /// Level Builder, rename card: screen-reader label of the dimmed screen around the card (tapping it cancels).
  ///
  /// In en, this message translates to:
  /// **'Cancel rename'**
  String get builderShelfRenameCancelSemantics;

  /// Level Builder, rename card: its title, at the top of the small card over the keyboard.
  ///
  /// In en, this message translates to:
  /// **'Name your level'**
  String get builderShelfRenameTitle;

  /// Level Builder, rename card: small red note beside the title while the name field is empty.
  ///
  /// In en, this message translates to:
  /// **'A name needs a letter or two'**
  String get builderShelfRenameEmpty;

  /// Level Builder, rename card: screen-reader label of the Save key.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get builderShelfRenameSaveSemantics;

  /// Level Builder, rename card: the key that saves the new name. One short verb.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get builderShelfRenameSave;

  /// Fly Together (two players on one phone): the mode where the two birds share one rope (glossary mode.roped). On the mode switch under a little picture (shrinks), in tags and on the results.
  ///
  /// In en, this message translates to:
  /// **'Roped'**
  String get coopMode_roped;

  /// Fly Together (two players on one phone): the mode where each bird flies on its own (glossary mode.no-rope). Short label, the opposite of Roped.
  ///
  /// In en, this message translates to:
  /// **'No rope'**
  String get coopMode_free;

  /// Fly Together (two players on one phone): the duel mode, one player against the other (glossary mode.duel). Keep the numeric "1 v 1" form if your language uses one. Right-to-left languages: put a word of your own between the digits (a Latin "v" between two digits is reordered to "v 1 1" in an RTL line).
  ///
  /// In en, this message translates to:
  /// **'1 v 1'**
  String get coopMode_duel;

  /// Fly Together (two players on one phone): the setup screen's title (glossary mode.fly-together). Heading, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Fly Together'**
  String get coopTitle;

  /// Fly Together (two players on one phone): small capital tag beside the title: the mode is for two players sharing one phone. Capitals where your script has them.
  ///
  /// In en, this message translates to:
  /// **'TWO PLAYERS · ONE PHONE'**
  String get coopPlayersTag;

  /// Fly Together (two players on one phone): capital tag at the top right: the team's best score in the chosen mode. {mode} is the mode's name in capitals ("ROPED", "NO ROPE"), {best} the score.
  ///
  /// In en, this message translates to:
  /// **'{mode} BEST {best}'**
  String coopBestTag(String mode, int best);

  /// Fly Together (two players on one phone): capital tag at the top right before the team has a best score in the chosen mode. {mode} is the mode's name in capitals.
  ///
  /// In en, this message translates to:
  /// **'{mode}: NO BEST YET'**
  String coopNoBestTag(String mode);

  /// Fly Together (two players on one phone), 1 v 1 chosen: capital tag at the top right: how many duels these players have fought. {mode} is "1 V 1" (coopMode_duel in capitals).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{mode} · {count} DUELS}}'**
  String duelCountTag(String mode, int count);

  /// Fly Together (two players on one phone), 1 v 1 chosen: capital tag at the top right before the first duel. {mode} is "1 V 1" (coopMode_duel in capitals).
  ///
  /// In en, this message translates to:
  /// **'{mode}: FIRST DUEL'**
  String duelFirstTag(String mode);

  /// Fly Together (two players on one phone), Roped chosen: the bold first sentence of the speech bubble that explains the mode; coopRopedBody follows on the same lines.
  ///
  /// In en, this message translates to:
  /// **'Your birds share one rope.'**
  String get coopRopedLead;

  /// Fly Together (two players on one phone), Roped chosen: the rest of the explaining bubble, after coopRopedLead (two or three lines; the bubble shrinks its text to fit). "Sprint" is the Sprint key (glossary weapon.sprint).
  ///
  /// In en, this message translates to:
  /// **'Flap together to climb high: a bird flapping alone lifts both, but only a little. Sprint to drag your partner along.'**
  String get coopRopedBody;

  /// Fly Together (two players on one phone), No rope chosen: the bold start of the explaining bubble, the mode's name followed by a colon; coopFreeBody continues the sentence.
  ///
  /// In en, this message translates to:
  /// **'No rope:'**
  String get coopFreeLead;

  /// Fly Together (two players on one phone), No rope chosen: the rest of the explaining bubble, continuing after coopFreeLead ("No rope:"), so it starts in lower case in English.
  ///
  /// In en, this message translates to:
  /// **'each bird flies on its own and only bumps into the other. Hearts, shield and score are still shared.'**
  String get coopFreeBody;

  /// Fly Together (two players on one phone), 1 v 1 chosen: the bold first word of the bubble that explains the duel; duelBody follows.
  ///
  /// In en, this message translates to:
  /// **'Fight!'**
  String get duelLead;

  /// Fly Together (two players on one phone), 1 v 1 chosen: the rest of the explaining bubble (the bubble shrinks its text to fit). Glossary: pickup.mystery-box, enemy.spitter-beetle, pickup.star-power.
  ///
  /// In en, this message translates to:
  /// **'Each bird has its own hearts. Grab mystery boxes: some send bats, a spitter or meteors at your rival, others bring a heart, a shield or star power. Last bird flying wins.'**
  String get duelBody;

  /// Fly Together (two players on one phone): the big key that starts a Roped or No rope flight. Short; shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Fly together'**
  String get coopStart;

  /// Fly Together (two players on one phone): the big key that starts a 1 v 1 duel. Short; shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Fight!'**
  String get duelStart;

  /// Fly Together (two players on one phone): screen-reader label of the flight: who taps where.
  ///
  /// In en, this message translates to:
  /// **'Player 1 taps the left half to flap, player 2 the right half'**
  String get coopFlightSemantics;

  /// Fly Together (two players on one phone): screen-reader label of the pause key during the flight.
  ///
  /// In en, this message translates to:
  /// **'Pause flight'**
  String get coopPauseSemantics;

  /// Fly Together (two players on one phone): screen-reader label of a player's Shoot key (glossary weapon.shoot). {player} is 1 or 2.
  ///
  /// In en, this message translates to:
  /// **'Player {player} shoot'**
  String coopShootSemantics(int player);

  /// Fly Together (two players on one phone): screen-reader label of a player's Sprint key (glossary weapon.sprint). {player} is 1 or 2.
  ///
  /// In en, this message translates to:
  /// **'Player {player} sprint'**
  String coopSprintSemantics(int player);

  /// The very short player tag ("P1", "P2": player 1 / player 2), the one wording for every two-player place: Fly Together's flight corners, the results' coins and the birds' flags (glossary ui.player), the tiny tag painted on each bird during a co-op or 1 v 1 flight, and the tags over the two birds in the mini games picker art. {player} is 1 or 2. Keep it as short as "P1" (2 to 3 characters).
  ///
  /// In en, this message translates to:
  /// **'P{player}'**
  String coopPlayerShort(int player);

  /// Fly Together (two players on one phone): a player's capital tag: on the setup card's ribbon, over a duel player's hearts and on the duel scoreboard. {player} is 1 or 2.
  ///
  /// In en, this message translates to:
  /// **'PLAYER {player}'**
  String coopPlayerCaps(int player);

  /// Fly Together (two players on one phone): screen-reader label of the star magnet meter while it pulls stars (glossary pickup.star-magnet).
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, other{Star magnet: {seconds} seconds remaining}}'**
  String coopMagnetSemantics(int seconds);

  /// Fly Together (two players on one phone): screen-reader label of the star magnet meter while it charges: perfect gates passed so far of the gates it needs (glossary ui.perfect-pass).
  ///
  /// In en, this message translates to:
  /// **'{gates, plural, other{Magnet charging: {charge} of {gates} perfect gates}}'**
  String coopMagnetChargingSemantics(int charge, int gates);

  /// Fly Together (two players on one phone): seconds left on a small meter (star magnet, duel star power): the number and your short unit for seconds ("5s"). Tiny.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, other{{seconds}s}}'**
  String coopSecondsShort(int seconds);

  /// Fly Together (two players on one phone), Roped: the countdown card's title before the flight starts (heading). "Ready, steady…" is the usual "on your marks" phrase.
  ///
  /// In en, this message translates to:
  /// **'Rope on. Ready, steady…'**
  String get coopCountdownRoped;

  /// Fly Together (two players on one phone), No rope: the countdown card's title (heading); the usual "on your marks" phrase.
  ///
  /// In en, this message translates to:
  /// **'Ready, steady…'**
  String get coopCountdownFree;

  /// Fly Together (two players on one phone), 1 v 1: the countdown card's title before the duel starts (heading).
  ///
  /// In en, this message translates to:
  /// **'Ready to duel…'**
  String get duelCountdown;

  /// Fly Together (two players on one phone), Roped: two lines under the countdown (keep the line break).
  ///
  /// In en, this message translates to:
  /// **'Flap together to climb high.\nSprint to drag your partner along!'**
  String get coopCountdownRopedHint;

  /// Fly Together (two players on one phone), No rope: two lines under the countdown (keep the line break).
  ///
  /// In en, this message translates to:
  /// **'Each bird flies on its own.\nShare the hearts, beat the gates!'**
  String get coopCountdownFreeHint;

  /// Fly Together (two players on one phone), 1 v 1: two lines under the countdown (keep the line break).
  ///
  /// In en, this message translates to:
  /// **'Grab the mystery boxes!\nLast bird flying wins.'**
  String get duelCountdownHint;

  /// Fly Together (two players on one phone), 1 v 1: screen-reader label of a player's star power meter (glossary pickup.star-power). {player} is 1 or 2.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, other{Player {player} star power: {seconds} seconds left}}'**
  String duelStarPowerSemantics(int player, int seconds);

  /// Fly Together (two players on one phone): results key back to the home screen. Narrow key, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get coopHome;

  /// Fly Together (two players on one phone): results key back to the bird pickers. Narrow key, shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Change birds'**
  String get coopChangeBirds;

  /// Fly Together (two players on one phone): results key once the session is saved (glossary ui.saved-session). Shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get coopSaved;

  /// Fly Together (two players on one phone): results key while the session saves. Shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get coopSaving;

  /// Fly Together (two players on one phone): results key that saves the flight's session (video, glossary ui.saved-session) to watch in Records. Shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Save session'**
  String get coopSaveSession;

  /// Fly Together (two players on one phone): the big results key that starts another duel with the same birds (glossary ui.rematch).
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get duelRematch;

  /// Fly Together (two players on one phone): the big results key that starts another team flight (glossary ui.fly).
  ///
  /// In en, this message translates to:
  /// **'Fly again'**
  String get coopFlyAgain;

  /// Fly Together (two players on one phone), 1 v 1 results: the big title (lettering, shrinks to fit). {player} is 1 or 2.
  ///
  /// In en, this message translates to:
  /// **'Player {player} wins!'**
  String duelWinner(int player);

  /// Fly Together (two players on one phone), 1 v 1 results: the big title when both birds fell together (glossary ui.rematch notes "A draw!").
  ///
  /// In en, this message translates to:
  /// **'A draw!'**
  String get duelDraw;

  /// Fly Together (two players on one phone), 1 v 1 results: the big title when the players ended the duel from the pause card before anyone won.
  ///
  /// In en, this message translates to:
  /// **'Duel stopped'**
  String get duelStopped;

  /// Fly Together (two players on one phone), 1 v 1 results: the plate under the title when nobody won: the two birds' names ("Pip vs Minty").
  ///
  /// In en, this message translates to:
  /// **'{first} vs {second}'**
  String duelVersusCaption(String first, String second);

  /// Fly Together (two players on one phone), 1 v 1 results: the plate under the title: the winning bird's name and the beaten bird's ("Pip beat Minty"; past tense). Grammatical gender: Pip and Minty masculine, Peaches and Orbit feminine (glossary).
  ///
  /// In en, this message translates to:
  /// **'{winner} beat {loser}'**
  String duelBeatCaption(String winner, String loser);

  /// Fly Together (two players on one phone), 1 v 1: banner under a player's hearts when their mystery box sent an attack after the rival. {prize} is the prize's name ("Bat swarm"), {rival} the other player's number. Short shout.
  ///
  /// In en, this message translates to:
  /// **'{prize} at P{rival}!'**
  String duelPrizeAttack(String prize, int rival);

  /// Fly Together (two players on one phone), 1 v 1: banner under a player's hearts when their mystery box gave them a help. {prize} is the prize's name ("Heart"). Short shout.
  ///
  /// In en, this message translates to:
  /// **'{prize}!'**
  String duelPrizeHelp(String prize);

  /// Fly Together (two players on one phone), 1 v 1: a mystery box prize, a line of swarm bats sent at the rival (glossary pickup.bat-swarm). Short name with a capital first letter, shown in the box's banner.
  ///
  /// In en, this message translates to:
  /// **'Bat swarm'**
  String get duelPrize_batSwarm;

  /// Fly Together (two players on one phone), 1 v 1: a mystery box prize, a spitter beetle sent ahead of the rival (glossary enemy.spitter-beetle). Short name with a capital first letter, shown in the box's banner.
  ///
  /// In en, this message translates to:
  /// **'Spitter beetle'**
  String get duelPrize_spitter;

  /// Fly Together (two players on one phone), 1 v 1: a mystery box prize, meteors dropped where the rival flies (glossary pickup.meteor-shower). Short name with a capital first letter, shown in the box's banner.
  ///
  /// In en, this message translates to:
  /// **'Meteor shower'**
  String get duelPrize_meteorShower;

  /// Fly Together (two players on one phone), 1 v 1: a mystery box prize, one more heart (glossary pickup.heart). Short name with a capital first letter, shown in the box's banner.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get duelPrize_heart;

  /// Fly Together (two players on one phone), 1 v 1: a mystery box prize, a shield that takes the next hit (glossary pickup.shield). Short name with a capital first letter, shown in the box's banner.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get duelPrize_shield;

  /// Fly Together (two players on one phone), 1 v 1: a mystery box prize, a few seconds of star power: nothing hurts the bird (glossary pickup.star-power). Short name with a capital first letter, shown in the box's banner.
  ///
  /// In en, this message translates to:
  /// **'Star power'**
  String get duelPrize_starPower;

  /// Fly Together (two players on one phone): small note on player 1's card: they tap the left half of the screen to flap.
  ///
  /// In en, this message translates to:
  /// **'Tap the left half'**
  String get coopTapLeftHalf;

  /// Fly Together (two players on one phone): small note on player 2's card: they tap the right half of the screen to flap.
  ///
  /// In en, this message translates to:
  /// **'Tap the right half'**
  String get coopTapRightHalf;

  /// Fly Together (two players on one phone): screen-reader label of a bird coin in a player's tray. {player} is 1 or 2, {bird} the bird's name.
  ///
  /// In en, this message translates to:
  /// **'Player {player}: {bird}'**
  String coopPickSemantics(int player, String bird);

  /// Fly Together (two players on one phone): big line on each half of the screen during the countdown: whose half it is. {player} is 1 or 2 ("P1", glossary ui.player). One line.
  ///
  /// In en, this message translates to:
  /// **'P{player} · tap this side'**
  String coopSideHint(int player);

  /// Fly Together (two players on one phone): the countdown line on player 1's half when a keyboard is in use: the letters W, D and A are keyboard keys (keep them); flap, shoot (glossary weapon.shoot) and sprint (weapon.sprint) are what they do. One line.
  ///
  /// In en, this message translates to:
  /// **'P1 · W flap · D shoot · A sprint'**
  String get coopKeysP1;

  /// Fly Together (two players on one phone): the countdown line on player 2's half with a keyboard: Up, Right and Left are the arrow keys (use your keyboard's names, or draw the keys as ↑ → ←: this line has a font for the arrows); flap, shoot and sprint what they do. One line.
  ///
  /// In en, this message translates to:
  /// **'P2 · Up flap · Right shoot · Left sprint'**
  String get coopKeysP2;

  /// Fly Together (two players on one phone): screen-reader label of the Roped choice on the mode switch.
  ///
  /// In en, this message translates to:
  /// **'Roped: the birds share a rope'**
  String get coopRopedSemantics;

  /// Fly Together (two players on one phone): screen-reader label of the No rope choice on the mode switch.
  ///
  /// In en, this message translates to:
  /// **'No rope: each bird flies on its own'**
  String get coopFreeSemantics;

  /// Fly Together (two players on one phone): screen-reader label of the 1 v 1 choice on the mode switch.
  ///
  /// In en, this message translates to:
  /// **'1 v 1: the birds fight each other'**
  String get duelModeSemantics;

  /// Fly Together (two players on one phone), 1 v 1: the "versus" badge between the two players' cards (a jagged sticker, shrinks to fit). Very short.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get duelVersus;

  /// Fly Together (two players on one phone): small status line under the results' scoreboard after the session was saved; Records is the screen (glossary ui.records-screen). One line.
  ///
  /// In en, this message translates to:
  /// **'Session saved · Watch in Records'**
  String get coopSessionSaved;

  /// Fly Together (two players on one phone), team results: the big title when the team beat its best score (lettering, shrinks to fit).
  ///
  /// In en, this message translates to:
  /// **'New team best!'**
  String get coopNewTeamBest;

  /// Fly Together (two players on one phone), team results: the big title after a flight that did not beat the best (warm praise; lettering, shrinks to fit).
  ///
  /// In en, this message translates to:
  /// **'What a team.'**
  String get coopWhatATeam;

  /// Fly Together (two players on one phone), team results: the two birds' names on the plate under the title ("Pip & Minty").
  ///
  /// In en, this message translates to:
  /// **'{first} & {second}'**
  String coopPairCaption(String first, String second);

  /// Fly Together (two players on one phone), team results: small capital label over the team's score (glossary ui.team-score).
  ///
  /// In en, this message translates to:
  /// **'TEAM SCORE'**
  String get coopTeamScore;

  /// Fly Together (two players on one phone), team results: small capital label over the team's best score (shrinks to fit).
  ///
  /// In en, this message translates to:
  /// **'TEAM BEST'**
  String get coopTeamBest;

  /// Fly Together (two players on one phone), team results: capital words on the yellow ribbon that lands on the best plaque when the team beat it.
  ///
  /// In en, this message translates to:
  /// **'NEW TEAM BEST!'**
  String get coopNewTeamBestRibbon;

  /// Fly Together (two players on one phone), team results: small label under the flight's duration ("1:42"). One line.
  ///
  /// In en, this message translates to:
  /// **'flight time'**
  String get coopStatFlightTime;

  /// Fly Together (two players on one phone), team results: small label under the number of stars collected; the number is shown above it (not in the text), {count} only picks the right form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{stars}}'**
  String coopStatStars(int count);

  /// Fly Together (two players on one phone), team results: small label under the number of gates passed; the number is shown above it, {count} only picks the form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{gates}}'**
  String coopStatGates(int count);

  /// Fly Together (two players on one phone), team results: small capital label over the bar that splits the flaps between player 1 and player 2 (glossary ui.team-score).
  ///
  /// In en, this message translates to:
  /// **'FLAP SHARE'**
  String get coopFlapShare;

  /// Fly Together (two players on one phone), team results: a player's share of the flaps, in percent (0-100). Put the sign where your language does ("%50", "50 %").
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String coopPercent(int percent);

  /// Fly Together (two players on one phone), team results: label under a player's number of flaps (wing beats, glossary ui.flap); the number is shown above it, {count} only picks the form. {player} is 1 or 2 ("P1").
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{P{player} flaps}}'**
  String coopPlayerFlaps(int count, int player);

  /// Fly Together (two players on one phone), 1 v 1 results: small line with how long the duel lasted. {time} is minutes:seconds ("1:42").
  ///
  /// In en, this message translates to:
  /// **'Duel time {time}'**
  String duelTime(String time);

  /// Fly Together (two players on one phone), 1 v 1 results: small capital word before the series score (duels won by player 1 – player 2 since they sat down, "SERIES 2–1"; glossary ui.rematch).
  ///
  /// In en, this message translates to:
  /// **'SERIES'**
  String get duelSeries;

  /// Fly Together (two players on one phone), 1 v 1 results: label of a row between the two players' numbers: how many hearts each bird kept.
  ///
  /// In en, this message translates to:
  /// **'hearts left'**
  String get duelHeartsLeft;

  /// Fly Together (two players on one phone), 1 v 1 results: label of a row between the players' numbers: mystery boxes each bird opened.
  ///
  /// In en, this message translates to:
  /// **'boxes opened'**
  String get duelBoxesOpened;

  /// Fly Together (two players on one phone), 1 v 1 results: label of a row between the players' numbers: times each bird hurt its rival.
  ///
  /// In en, this message translates to:
  /// **'hits landed'**
  String get duelHitsLanded;

  /// Fly Together (two players on one phone): the pause card's line under its title; the two birds sit on the card. "Count you in" = the countdown before the flight goes on.
  ///
  /// In en, this message translates to:
  /// **'You’re both perched and waiting. We’ll count you both in.'**
  String get coopPauseSubtitle;

  /// Fly Together (two players on one phone): the pause card key that ends the flight and shows the results.
  ///
  /// In en, this message translates to:
  /// **'Finish flight'**
  String get coopFinishFlight;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: the coaching line before the camera starts.
  ///
  /// In en, this message translates to:
  /// **'Prop your phone low in landscape, facing you or beside you.'**
  String get cameraLabIntro;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: coaching line when some body parts are hard to see. {parts} lists them (cameraLabJoint* words joined with cameraLabJointList: "shoulder, wrist"); reword so it works for one to four parts ("need a clearer view of: …" is fine).
  ///
  /// In en, this message translates to:
  /// **'Almost there · need a clearer {parts}'**
  String cameraLabAlmostThere(String parts);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: a body part in cameraLabAlmostThere's list. Lower case unless your language capitalizes nouns.
  ///
  /// In en, this message translates to:
  /// **'shoulder'**
  String get cameraLabJointShoulder;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: a body part in cameraLabAlmostThere's list.
  ///
  /// In en, this message translates to:
  /// **'elbow'**
  String get cameraLabJointElbow;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: a body part in cameraLabAlmostThere's list.
  ///
  /// In en, this message translates to:
  /// **'wrist'**
  String get cameraLabJointWrist;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: a body part in cameraLabAlmostThere's list.
  ///
  /// In en, this message translates to:
  /// **'hip'**
  String get cameraLabJointHip;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: joins two body parts of cameraLabAlmostThere's list ("shoulder, wrist"); longer lists repeat it. Use your language's list comma.
  ///
  /// In en, this message translates to:
  /// **'{first}, {rest}'**
  String cameraLabJointList(String first, String rest);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: coaching line while the camera starts.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get cameraLabStarting;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: coaching line when the player has not allowed the camera.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Allow it in app settings, then try again.'**
  String get cameraLabDenied;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: coaching line when the camera failed. {error} is the system's technical message (often English).
  ///
  /// In en, this message translates to:
  /// **'Camera could not start: {error}'**
  String cameraLabFailed(String error);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: coaching line after the app went to the background. "Start" names the key cameraLabStartCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera stopped. Tap Start to recalibrate.'**
  String get cameraLabStopped;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: the tappable capital line over the camera picture that leads back to the home screen. One line.
  ///
  /// In en, this message translates to:
  /// **'CAMERA LAB · Back to home'**
  String get cameraLabBack;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, push-ups: big step title 1 of 3 (keep the number). One line.
  ///
  /// In en, this message translates to:
  /// **'1. Show your arms & hip'**
  String get cameraLabStepShow;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, push-ups: step title 2 of 3 (keep the number): two push-ups calibrate the tracking.
  ///
  /// In en, this message translates to:
  /// **'2. Do two push-ups'**
  String get cameraLabStepPushUps;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: step title 3 of 3 (keep the number): calibration is done, the player moves a test bird.
  ///
  /// In en, this message translates to:
  /// **'3. Move your bird!'**
  String get cameraLabStepMove;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, squats: the step title while calibrating squats.
  ///
  /// In en, this message translates to:
  /// **'Find your squat range'**
  String get cameraLabStepSquat;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, jumps: the step title while calibrating jumps.
  ///
  /// In en, this message translates to:
  /// **'Find your standing position'**
  String get cameraLabStepJump;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, push-ups: three short lines of help under the step title (keep the line breaks).
  ///
  /// In en, this message translates to:
  /// **'Phone low, facing you or beside you.\nFacing it? Show both shoulders, an arm and hip.\nMove down and up twice at your own pace.'**
  String get cameraLabPushUpHelp;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, squats: help under the step title (wraps).
  ///
  /// In en, this message translates to:
  /// **'Stand still, squat comfortably and hold briefly, then stand back up. Squat to descend; stand to rise.'**
  String get cameraLabSquatHelp;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, jumps: help under the step title (wraps).
  ///
  /// In en, this message translates to:
  /// **'Stand facing the phone with your whole body and feet visible. Hold still, then make small jumps. One jump = one big boost.'**
  String get cameraLabJumpHelp;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, push-ups: two lines at the corner of the test sky: a capital title, then calibrated push-ups so far of the {total} needed (keep the line break).
  ///
  /// In en, this message translates to:
  /// **'{done, plural, other{CALIBRATION\n{done} / {total} calibrated}}'**
  String cameraLabCalibrationCount(int done, int total);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, squats and jumps: two lines at the corner of the test sky: a capital title, then how far calibration is, in percent (keep the line break).
  ///
  /// In en, this message translates to:
  /// **'CALIBRATION\n{percent}% calibrated'**
  String cameraLabCalibrationPercent(int percent);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, push-ups: two lines at the corner of the test sky after calibration: a capital title, then push-ups counted so far (keep the line break).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{CONTROL TEST\n{count} push-ups}}'**
  String cameraLabTestPushUps(int count);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, squats: like cameraLabTestPushUps, counting squats.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{CONTROL TEST\n{count} squats}}'**
  String cameraLabTestSquats(int count);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking, jumps: like cameraLabTestPushUps, counting jumps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{CONTROL TEST\n{count} jumps}}'**
  String cameraLabTestJumps(int count);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: tiny technical readout of the tracking speed: frames per second (Hz) and the 95th-percentile delay in milliseconds. Keep the units' usual symbols.
  ///
  /// In en, this message translates to:
  /// **'{hz} Hz · {ms} ms p95'**
  String cameraLabRate(String hz, String ms);

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: the main key's label while the camera starts.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get cameraLabStartingButton;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: the main key once the camera runs: start calibrating again.
  ///
  /// In en, this message translates to:
  /// **'Recalibrate'**
  String get cameraLabRecalibrate;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: the main key that starts the camera.
  ///
  /// In en, this message translates to:
  /// **'Start camera'**
  String get cameraLabStartCamera;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: coaching line after switching mode. "Start camera" is the key cameraLabStartCamera: same words.
  ///
  /// In en, this message translates to:
  /// **'Tap Start camera'**
  String get cameraLabTapStart;

  /// Camera lab (Settings › Camera & tracking lab): a test screen for the camera tracking: text key that switches the lab to another camera mode. {mode} is its name ("Jump & Fly").
  ///
  /// In en, this message translates to:
  /// **'Try {mode}'**
  String cameraLabTry(String mode);

  /// Camera mini game setup: tiny capital badge on the camera picture with a status lamp: the camera is starting up (waking up).
  ///
  /// In en, this message translates to:
  /// **'WAKING'**
  String get cameraBadgeWaking;

  /// Camera mini game setup: tiny capital badge on the camera picture with a status lamp: the camera is on and looking for the player.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get cameraBadgeLive;

  /// Camera mini game setup: tiny capital badge on the camera picture with a status lamp: the player is found and calibrated.
  ///
  /// In en, this message translates to:
  /// **'LOCKED ON'**
  String get cameraBadgeLockedOn;

  /// Camera mini game setup: tiny capital badge on the camera picture with a status lamp: the camera is off or failed.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get cameraBadgeOffline;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. The camera's picture is late; wait a moment.
  ///
  /// In en, this message translates to:
  /// **'Camera is catching up'**
  String get trackingCatchingUp;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups: no body found; step into the drawn outline.
  ///
  /// In en, this message translates to:
  /// **'Step into the body outline'**
  String get trackingStepIntoOutline;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups seen from the front.
  ///
  /// In en, this message translates to:
  /// **'Keep both shoulders in view'**
  String get trackingKeepShoulders;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups seen from the side: these body parts must be visible.
  ///
  /// In en, this message translates to:
  /// **'Show one shoulder, elbow, wrist and hip from the side'**
  String get trackingShowSide;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English.
  ///
  /// In en, this message translates to:
  /// **'Move a little closer'**
  String get trackingMoveCloser;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. The player is standing; they should get into the push-up (plank) position.
  ///
  /// In en, this message translates to:
  /// **'Get down into your push-up position'**
  String get trackingGetDown;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups, side view.
  ///
  /// In en, this message translates to:
  /// **'Put your hands on the floor and extend your body behind you'**
  String get trackingHandsOnFloor;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups: the body is folded.
  ///
  /// In en, this message translates to:
  /// **'Extend your body a little farther behind your hands'**
  String get trackingExtendBody;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups: the arm bends too far.
  ///
  /// In en, this message translates to:
  /// **'Stay within a comfortable push-up range'**
  String get trackingComfortableRange;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups, front view.
  ///
  /// In en, this message translates to:
  /// **'Place your hands on the floor with your body behind them'**
  String get trackingPlaceHands;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups: tracking works from the front.
  ///
  /// In en, this message translates to:
  /// **'Front view tracked · keep your hands in view'**
  String get trackingFrontTracked;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups: tracking works; the player may look at the floor.
  ///
  /// In en, this message translates to:
  /// **'Body in view · face can look down'**
  String get trackingBodyInView;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups: arms tracked, legs not fully visible.
  ///
  /// In en, this message translates to:
  /// **'Arms tracked · leg check limited'**
  String get trackingArmsTracked;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-up calibration: hold still at the top of a push-up.
  ///
  /// In en, this message translates to:
  /// **'Find a comfortable top position'**
  String get trackingFindTop;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-up calibration finished.
  ///
  /// In en, this message translates to:
  /// **'Calibrated! Try moving your bird.'**
  String get trackingCalibrated;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. The camera has not sent a new picture yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a fresh frame'**
  String get trackingFreshFrame;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups: the player moved nearer or farther; calibrate again.
  ///
  /// In en, this message translates to:
  /// **'Camera distance changed · recalibrate'**
  String get trackingDistanceChanged;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Push-ups: no arm visible.
  ///
  /// In en, this message translates to:
  /// **'Keep an arm in view'**
  String get trackingKeepArm;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squats.
  ///
  /// In en, this message translates to:
  /// **'Step back so your shoulders, hips, knees and feet are in view'**
  String get trackingSquatStepBack;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squats.
  ///
  /// In en, this message translates to:
  /// **'Face the camera with both feet on the floor'**
  String get trackingSquatFaceCamera;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squats: how the bird is steered (down and up).
  ///
  /// In en, this message translates to:
  /// **'Squat to descend · stand to rise'**
  String get trackingSquatControls;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squats and jumps: the player moved since calibrating.
  ///
  /// In en, this message translates to:
  /// **'Face the camera at your starting distance · recalibrate if you moved'**
  String get trackingStartingDistance;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squats.
  ///
  /// In en, this message translates to:
  /// **'Keep both feet planted in your starting spot'**
  String get trackingFeetPlanted;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squat calibration, first step.
  ///
  /// In en, this message translates to:
  /// **'Stand tall and still with both feet in view'**
  String get trackingSquatStandTall;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squat and jump calibration.
  ///
  /// In en, this message translates to:
  /// **'Stand tall and still for a moment'**
  String get trackingStandStill;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squat calibration.
  ///
  /// In en, this message translates to:
  /// **'Squat to a comfortable depth and hold briefly'**
  String get trackingSquatDepth;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squat calibration.
  ///
  /// In en, this message translates to:
  /// **'Squat comfortably, then hold for a moment'**
  String get trackingSquatHold;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squat calibration.
  ///
  /// In en, this message translates to:
  /// **'Hold this comfortable squat briefly'**
  String get trackingSquatHoldBriefly;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squat calibration, last step.
  ///
  /// In en, this message translates to:
  /// **'Stand back up to finish calibration'**
  String get trackingSquatStandUp;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Squat calibration finished.
  ///
  /// In en, this message translates to:
  /// **'Ready! Squat to descend · stand to rise'**
  String get trackingSquatReady;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Jumps.
  ///
  /// In en, this message translates to:
  /// **'Step back so your shoulders, hips and both feet are in view'**
  String get trackingJumpStepBack;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Jumps.
  ///
  /// In en, this message translates to:
  /// **'Stand facing the camera with room above you to jump'**
  String get trackingJumpFaceCamera;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Jumps.
  ///
  /// In en, this message translates to:
  /// **'Small jumps are enough · land before jumping again'**
  String get trackingJumpSmall;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Jump calibration, first step.
  ///
  /// In en, this message translates to:
  /// **'Stand still with your whole body and both feet in view'**
  String get trackingJumpStandStill;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Jump calibration finished.
  ///
  /// In en, this message translates to:
  /// **'Ready! One small jump gives one big boost.'**
  String get trackingJumpReady;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Before the camera flight starts, while the player gets into place.
  ///
  /// In en, this message translates to:
  /// **'Find your position'**
  String get trackingFindPosition;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. The camera tracking stopped with an error.
  ///
  /// In en, this message translates to:
  /// **'Tracking interrupted'**
  String get trackingInterrupted;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. The camera stopped; maybe its permission was taken away.
  ///
  /// In en, this message translates to:
  /// **'Camera interrupted. Check camera permission and try again.'**
  String get trackingCameraInterrupted;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. The camera stopped while the game was in the background.
  ///
  /// In en, this message translates to:
  /// **'Camera stopped while the app was away'**
  String get trackingCameraAway;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Jump flight: the bird is ready for the next jump. Also on a one-line caption under the jump preview: keep it short.
  ///
  /// In en, this message translates to:
  /// **'Jump for a big boost'**
  String get trackingJumpBoost;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. Jump flight: the player is in the air. Also on a one-line caption under the jump preview: keep it short.
  ///
  /// In en, this message translates to:
  /// **'Land to prepare your next jump'**
  String get trackingJumpLand;

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. {step} of {total} counts the calibration movements ("1 of 2", "2 of 2"): keep both numbers. Push-up calibration: the push-up was too shallow.
  ///
  /// In en, this message translates to:
  /// **'Lower a little more · {step} of {total}'**
  String trackingLowerMore(int step, int total);

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. {step} of {total} counts the calibration movements ("1 of 2", "2 of 2"): keep both numbers. Push-up calibration: go down into a push-up.
  ///
  /// In en, this message translates to:
  /// **'Lower comfortably · {step} of {total}'**
  String trackingLowerComfortably(int step, int total);

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. {step} of {total} counts the calibration movements ("1 of 2", "2 of 2"): keep both numbers. Push-up calibration: come back up.
  ///
  /// In en, this message translates to:
  /// **'Push back up · {step} of {total}'**
  String trackingPushBackUp(int step, int total);

  /// Camera coaching line: shown under the camera picture while a camera mini game (push-ups, squats or jumps) finds the player and calibrates, and during that flight; also in the Camera lab. Friendly, short instruction to the player; keep it about as long as the English. {step} of {total} counts the calibration movements ("1 of 2", "2 of 2"): keep both numbers. Push-up calibration: the second push-up should go as deep as the first.
  ///
  /// In en, this message translates to:
  /// **'Match your first comfortable range · {step} of {total}'**
  String trackingMatchRange(int step, int total);

  /// Snack bar when buying an upgrade, unlocking or choosing a bird could not be saved. {error} is a technical error text, kept as is.
  ///
  /// In en, this message translates to:
  /// **'Could not save this change. Please try again. ({error})'**
  String commonSaveFailed(String error);

  /// Common: dialog button that deletes something (destructive).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Birds and Upgrades screens: how many more stars the player needs before they can buy it (a short chip). {count} is a number of stars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} more to go}}'**
  String commonMoreToGo(int count);

  /// Title screen: heading shown when the save could not be loaded, above a Try again button. "Nest" = the player's home base.
  ///
  /// In en, this message translates to:
  /// **'Your nest needs a moment.'**
  String get homeUnavailable;

  /// Title screen: screen reader label and tooltip of the gear key at the top right that opens Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// Title screen: the bird's speech bubble before the very first flight. The bird speaks to the player; {bird} is its name (Pip, Peaches, Minty, Orbit). "Ready to fly?" asks the player.
  ///
  /// In en, this message translates to:
  /// **'Hi, I’m {bird}! Ready to fly?'**
  String homeGreetingFirst(String bird);

  /// Title screen: speech bubble once today's Adventure (the daily goals) is complete. {bird} is the bird's name. {gender} is the bird's grammatical gender for agreement (male: Pip, Minty; female: Peaches, Orbit; see glossary CHARACTERS.md): English words all three cases the same; gendered languages word each case.
  ///
  /// In en, this message translates to:
  /// **'{gender, select, male{Adventure done! {bird} is proud.} female{Adventure done! {bird} is proud.} other{Adventure done! {bird} is proud.}}'**
  String homeGreetingDone(String gender, String bird);

  /// Title screen: the usual speech bubble. "Are you?" asks the player. {bird} is the bird's name. {gender} is the bird's grammatical gender for agreement (male: Pip, Minty; female: Peaches, Orbit; see glossary CHARACTERS.md): English words all three cases the same; gendered languages word each case.
  ///
  /// In en, this message translates to:
  /// **'{gender, select, male{{bird} is ready. Are you?} female{{bird} is ready. Are you?} other{{bird} is ready. Are you?}}'**
  String homeGreetingReady(String gender, String bird);

  /// Title screen: big capital title on the yellow key that starts an endless flight (game mode "Endless"). Shrinks to fit; capitals.
  ///
  /// In en, this message translates to:
  /// **'ENDLESS'**
  String get homeEndlessTitle;

  /// Title screen: small line under ENDLESS.
  ///
  /// In en, this message translates to:
  /// **'Fly as far as you can'**
  String get homeEndlessDetail;

  /// Screen reader label of the Endless key before the first endless flight.
  ///
  /// In en, this message translates to:
  /// **'Endless. Fly as far as you can.'**
  String get homeEndlessSemantics;

  /// Screen reader label of the Endless key; {best} is the best endless flight's star points.
  ///
  /// In en, this message translates to:
  /// **'{best, plural, other{Endless. Fly as far as you can. Best: {best} stars.}}'**
  String homeEndlessBestSemantics(int best);

  /// Title screen: small tag on the Endless key, followed by the best score as a number ("Best 240").
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get homeBest;

  /// Title screen: small tag on the Endless key before the first endless flight (an invitation to set a best score).
  ///
  /// In en, this message translates to:
  /// **'Set your first best'**
  String get homeBestNone;

  /// Title screen: big capital title on the green key that opens the campaign map (story mode). Shrinks to fit; capitals.
  ///
  /// In en, this message translates to:
  /// **'CAMPAIGN'**
  String get homeCampaignTitle;

  /// Title screen: small line on the Campaign key once every level is cleared. Echoes the motto "Every letter lands." (deliver/land).
  ///
  /// In en, this message translates to:
  /// **'Every letter delivered'**
  String get homeCampaignDone;

  /// Screen reader label of the Campaign key. {level} is the next level, such as "1-3 · Canopy Run"; {stars} level stars earned of {total}.
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, other{Campaign. Next: {level}. {stars} of {total} stars.}}'**
  String homeCampaignNextSemantics(int stars, int total, String level);

  /// Screen reader label of the Campaign key once every level is cleared.
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, other{Campaign. Every letter delivered. {stars} of {total} stars.}}'**
  String homeCampaignDoneSemantics(int stars, int total);

  /// A campaign level as a short label: its number and its name, such as "1-3 · Canopy Run" (Campaign key, saved sessions). Usually left as is.
  ///
  /// In en, this message translates to:
  /// **'{id} · {name}'**
  String homeLevelLabel(String id, String name);

  /// Title screen: capital title of the key that opens the mini games (push-ups, squats, jumps with the camera, and two players). Side games, not a fitness app.
  ///
  /// In en, this message translates to:
  /// **'MINI GAMES'**
  String get homeMiniGamesTitle;

  /// Title screen: small line under MINI GAMES. Keep the "·".
  ///
  /// In en, this message translates to:
  /// **'Workouts · 2 players'**
  String get homeMiniGamesDetail;

  /// Screen reader label of the Mini games key.
  ///
  /// In en, this message translates to:
  /// **'Mini games. Push-ups, squats, jumps, or two players.'**
  String get homeMiniGamesSemantics;

  /// Title screen: capital title of the key that opens the Level Builder (make your own levels).
  ///
  /// In en, this message translates to:
  /// **'LEVEL BUILDER'**
  String get homeBuilderTitle;

  /// Title screen: small line under LEVEL BUILDER: three short verbs.
  ///
  /// In en, this message translates to:
  /// **'Make · fly · share'**
  String get homeBuilderDetail;

  /// Screen reader label of the Level Builder key.
  ///
  /// In en, this message translates to:
  /// **'Level Builder. Make your own levels, fly them and share them.'**
  String get homeBuilderSemantics;

  /// Title screen: small line on the locked Level Builder key: how many more flights until it opens.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Unlocks in 1 flight} other{Unlocks in {count} flights}}'**
  String homeBuilderLocked(int count);

  /// Screen reader label of the locked Level Builder key.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Level Builder. Locked. Unlocks in 1 flight.} other{Level Builder. Locked. Unlocks in {count} flights.}}'**
  String homeBuilderLockedSemantics(int count);

  /// Title screen shelf: label under the daily Adventure icon (today's three small goals). One short word.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get homeDockAdventure;

  /// Screen reader label of the Adventure shelf item.
  ///
  /// In en, this message translates to:
  /// **'{done, plural, other{Today’s adventure. {done} of 3 goals complete.}}'**
  String homeDockAdventureSemantics(int done);

  /// Title screen shelf: label under the birds icon (the four birds to fly with). One short word.
  ///
  /// In en, this message translates to:
  /// **'Birds'**
  String get homeDockBirds;

  /// Screen reader label of the Birds shelf item; {bird} is the chosen bird's name.
  ///
  /// In en, this message translates to:
  /// **'Birds. Flying with {bird}.'**
  String homeDockBirdsSemantics(String bird);

  /// Title screen shelf: label under the upgrades icon (power-ups bought with stars). One short word.
  ///
  /// In en, this message translates to:
  /// **'Upgrades'**
  String get homeDockUpgrades;

  /// Screen reader label of the Upgrades shelf item.
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, other{Upgrades. {stars} stars to spend.}}'**
  String homeDockUpgradesSemantics(int stars);

  /// Title screen shelf: label under the passport icon (stamps and medals). One short word.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get homeDockPassport;

  /// Screen reader label of the Passport shelf item.
  ///
  /// In en, this message translates to:
  /// **'{earned, plural, other{Passport. {earned} of {total} medals.}}'**
  String homeDockPassportSemantics(int earned, int total);

  /// Title screen shelf: label under the records icon (best scores and recent flights). One short word.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get homeDockRecords;

  /// Mini games picker (a dialog over the title screen): its title.
  ///
  /// In en, this message translates to:
  /// **'Mini games'**
  String get homeMiniGamesPickerTitle;

  /// Mini games picker: one line under the title.
  ///
  /// In en, this message translates to:
  /// **'Move to fly, or share the phone with a friend.'**
  String get homeMiniGamesPickerIntro;

  /// Mini games picker: screen reader label of the close key.
  ///
  /// In en, this message translates to:
  /// **'Close mini games'**
  String get homeMiniGamesCloseSemantics;

  /// Mini games picker: two short lines on the push-up card (\n starts the second line): go down and the bird dips, push up and it soars.
  ///
  /// In en, this message translates to:
  /// **'Lower to dip.\nPush up to soar.'**
  String get homeMiniGamesPushUpCard;

  /// Mini games picker: two short lines on the squat card (\n starts the second line).
  ///
  /// In en, this message translates to:
  /// **'Squat low.\nStand to soar.'**
  String get homeMiniGamesSquatCard;

  /// Mini games picker: two short lines on the jump card (\n starts the second line).
  ///
  /// In en, this message translates to:
  /// **'Jump for lift.\nGlide for stars.'**
  String get homeMiniGamesJumpCard;

  /// Mini games picker: two short lines on the two-player card (\n starts the second line). "Duel" = the 1 v 1 mode.
  ///
  /// In en, this message translates to:
  /// **'Two players, one phone.\nTeam up or duel.'**
  String get homeMiniGamesCoopCard;

  /// Mini games picker: tiny tag on a card: this game uses the camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get homeMiniGamesCamera;

  /// Mini games picker: tiny tag on the two-player card.
  ///
  /// In en, this message translates to:
  /// **'2 players'**
  String get homeMiniGamesPlayers;

  /// Mini games picker: title of the two-player card (mode name "Fly Together": two birds on one phone).
  ///
  /// In en, this message translates to:
  /// **'Fly Together'**
  String get homeMiniGamesCoop;

  /// Birds screen title (the four birds the player can fly with; "flight crew" is a friendly word for them).
  ///
  /// In en, this message translates to:
  /// **'Meet your flight crew.'**
  String get birdsTitle;

  /// Birds screen: capital tag in the header: how many of the birds the player has flown with.
  ///
  /// In en, this message translates to:
  /// **'{flown} OF {total} FLOWN'**
  String birdsFlownTag(int flown, int total);

  /// Birds screen: capital pill over the bird the player flies with now.
  ///
  /// In en, this message translates to:
  /// **'YOUR CO-PILOT'**
  String get birdsStatusCopilot;

  /// Birds screen: capital pill over an unlocked bird the player could choose.
  ///
  /// In en, this message translates to:
  /// **'READY TO FLY'**
  String get birdsStatusReady;

  /// Birds screen: capital pill over a bird still to unlock with stars.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get birdsStatusLocked;

  /// Birds screen: chip saying the player has not flown with this bird.
  ///
  /// In en, this message translates to:
  /// **'Not flown yet'**
  String get birdsNotFlown;

  /// Birds screen: chip with how many flights the player flew with this bird.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 flight} other{{count} flights}}'**
  String birdsFlights(int count);

  /// Birds screen: big button that picks this bird for the next flights. Shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Fly with {bird}'**
  String birdsFlyWith(String bird);

  /// Screen reader label of the Fly with button; {current} is the bird chosen now.
  ///
  /// In en, this message translates to:
  /// **'Fly with {bird} instead of {current}'**
  String birdsFlyWithSemantics(String bird, String current);

  /// Birds screen: big button that buys this bird with stars (its price is shown beside it). Shrinks to fit.
  ///
  /// In en, this message translates to:
  /// **'Unlock {bird}'**
  String birdsUnlock(String bird);

  /// Screen reader label of the Unlock button.
  ///
  /// In en, this message translates to:
  /// **'{price, plural, other{Unlock {bird} for {price} stars}}'**
  String birdsUnlockSemantics(int price, String bird);

  /// Screen reader label of the greyed Unlock button.
  ///
  /// In en, this message translates to:
  /// **'{price, plural, other{Unlock {bird} for {price} stars, not enough stars yet}}'**
  String birdsUnlockShortSemantics(int price, String bird);

  /// Birds screen: plate where the button would be, for the bird the player already flies with.
  ///
  /// In en, this message translates to:
  /// **'Flying with you'**
  String get birdsFlyingWithYou;

  /// Birds screen, bird list: screen reader label of the chosen bird.
  ///
  /// In en, this message translates to:
  /// **'{bird}, flying with you'**
  String birdsCardFlyingSemantics(String bird);

  /// Birds screen, bird list: screen reader label of the chosen bird before its first flight.
  ///
  /// In en, this message translates to:
  /// **'{bird}, flying with you, new'**
  String birdsCardFlyingNewSemantics(String bird);

  /// Birds screen, bird list: screen reader label of a locked bird and its price.
  ///
  /// In en, this message translates to:
  /// **'{price, plural, other{{bird}, locked, {price} stars}}'**
  String birdsCardLockedSemantics(int price, String bird);

  /// Birds screen, bird list: screen reader label of an unlocked bird not flown yet.
  ///
  /// In en, this message translates to:
  /// **'{bird}, new'**
  String birdsCardNewSemantics(String bird);

  /// Birds screen, bird list: tiny capital ribbon on the chosen bird's portrait.
  ///
  /// In en, this message translates to:
  /// **'FLYING'**
  String get birdsTagFlying;

  /// Birds screen, bird list: tiny capital ribbon on a bird not flown yet.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get birdsTagNew;

  /// Birds screen and Fly Together bird picker: Pip's tagline, in a speech-bubble card beside the bird. See the glossary's catchphrase entry for its wordplay.
  ///
  /// In en, this message translates to:
  /// **'Small bird. Big sky.'**
  String get bird_0_description;

  /// Birds screen: the name of the sparkly trail Pip leaves behind in flight (a cosmetic), on a chip.
  ///
  /// In en, this message translates to:
  /// **'Sunshine bubbles'**
  String get bird_0_trail;

  /// Birds screen and Fly Together bird picker: Peaches's tagline, in a speech-bubble card beside the bird. See the glossary's catchphrase entry for its wordplay.
  ///
  /// In en, this message translates to:
  /// **'Rosy cheeks, curly crest, all heart.'**
  String get bird_1_description;

  /// Birds screen: the name of the sparkly trail Peaches leaves behind in flight (a cosmetic), on a chip.
  ///
  /// In en, this message translates to:
  /// **'Peach hearts'**
  String get bird_1_trail;

  /// Birds screen and Fly Together bird picker: Minty's tagline, in a speech-bubble card beside the bird. See the glossary's catchphrase entry for its wordplay.
  ///
  /// In en, this message translates to:
  /// **'Tiny hummer. Fresh sprig. Full speed.'**
  String get bird_2_description;

  /// Birds screen: the name of the sparkly trail Minty leaves behind in flight (a cosmetic), on a chip.
  ///
  /// In en, this message translates to:
  /// **'Mint leaves'**
  String get bird_2_trail;

  /// Birds screen and Fly Together bird picker: Orbit's tagline, in a speech-bubble card beside the bird. See the glossary's catchphrase entry for its wordplay.
  ///
  /// In en, this message translates to:
  /// **'A dreamy owl who flies by starlight.'**
  String get bird_3_description;

  /// Birds screen: the name of the sparkly trail Orbit leaves behind in flight (a cosmetic), on a chip.
  ///
  /// In en, this message translates to:
  /// **'Stardust sparkles'**
  String get bird_3_trail;

  /// Gold star-wallet pill (Birds and Upgrades screens): two tiny capital lines (\n) beside the number of stars the player can spend.
  ///
  /// In en, this message translates to:
  /// **'YOUR\nSTARS'**
  String get upgradesWalletLabel;

  /// Screen reader label of the star wallet.
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, other{{stars} stars to spend}}'**
  String upgradesWalletSemantics(int stars);

  /// Upgrades screen title (the four power-ups bought with collected stars).
  ///
  /// In en, this message translates to:
  /// **'Power up your bird.'**
  String get upgradesTitle;

  /// Upgrades screen: one line under the title. The upgrades are drawn as gear sockets.
  ///
  /// In en, this message translates to:
  /// **'Tap a gear to see what it does. Every star you pick up in flight is one to spend.'**
  String get upgradesIntro;

  /// Upgrades screen: screen reader label of an upgrade the player can afford.
  ///
  /// In en, this message translates to:
  /// **'{cost, plural, other{{power}, level {level} of {max}. Next level {cost} stars}}'**
  String upgradesSocketSemantics(int cost, String power, int level, int max);

  /// Upgrades screen: screen reader label of an upgrade the player cannot afford yet.
  ///
  /// In en, this message translates to:
  /// **'{cost, plural, other{{power}, level {level} of {max}. Next level {cost} stars, not enough yet}}'**
  String upgradesSocketLockedSemantics(
    int cost,
    String power,
    int level,
    int max,
  );

  /// Upgrades screen: screen reader label of an upgrade at its top level.
  ///
  /// In en, this message translates to:
  /// **'{power}, level {level} of {max}. Maxed'**
  String upgradesSocketMaxedSemantics(String power, int level, int max);

  /// Upgrades screen: tiny capital price tag of an upgrade at its top level.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get upgradesMax;

  /// Upgrades screen callout: the upgrade's current level, followed by an arrow and the next level number.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String upgradesLevel(int level);

  /// Upgrades screen callout: the upgrade is at its highest level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}, the top'**
  String upgradesLevelTop(int level);

  /// Upgrades screen: screen reader label of a stat row at its top level, e.g. "Cooldown 15 s".
  ///
  /// In en, this message translates to:
  /// **'{label} {now}'**
  String upgradesStatSemantics(String label, String now);

  /// Upgrades screen: screen reader label of a stat row with the next level's value.
  ///
  /// In en, this message translates to:
  /// **'{label} {now}, next level {next}'**
  String upgradesStatUpgradeSemantics(String label, String now, String next);

  /// Upgrades screen: a stat value in percent ({value} is a number such as 85). Write it the way your language writes percentages.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String upgradesStatPercent(String value);

  /// Upgrades screen: a stat value in seconds ({value} is a number such as 1.2 or 15). Use your short unit for seconds.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String upgradesStatSeconds(String value);

  /// Upgrades screen: a stat value as a multiple of the normal reach ({value} such as 2.4). Keep the × sign.
  ///
  /// In en, this message translates to:
  /// **'{value}×'**
  String upgradesStatTimes(String value);

  /// Upgrades screen callout: the wallet after buying the next level.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{You will have {count} stars left.}}'**
  String upgradesStarsLeft(int count);

  /// Upgrades screen: the big buy button (the price sits beside it). One short verb.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradesButton;

  /// Screen reader label of the Upgrade button.
  ///
  /// In en, this message translates to:
  /// **'{cost, plural, other{Upgrade for {cost} stars}}'**
  String upgradesBuySemantics(int cost);

  /// Screen reader label of the greyed Upgrade button.
  ///
  /// In en, this message translates to:
  /// **'{cost, plural, other{Upgrade for {cost} stars, not enough stars yet}}'**
  String upgradesBuyLockedSemantics(int cost);

  /// Upgrades screen: plate where the Upgrade button would be once the upgrade is at its top level.
  ///
  /// In en, this message translates to:
  /// **'Maxed out'**
  String get upgradesMaxedOut;

  /// Upgrades screen: the name of the "Shot power" upgrade, a big title in its callout and screen reader labels. Same word as in flight (glossary "power-up").
  ///
  /// In en, this message translates to:
  /// **'Shot power'**
  String get power_shot_name;

  /// Upgrades screen callout: what the "Shot power" upgrade does, one or two short lines. "Shoot" is the fire button's label.
  ///
  /// In en, this message translates to:
  /// **'Hold Shoot to charge a bigger, harder rock.'**
  String get power_shot_blurb;

  /// Upgrades screen: the name of the "Sprint" upgrade, a big title in its callout and screen reader labels. Same word as in flight (glossary "power-up").
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get power_sprint_name;

  /// Upgrades screen callout: what the "Sprint" upgrade does, one or two short lines. "Shoot" is the fire button's label.
  ///
  /// In en, this message translates to:
  /// **'A speed burst that smashes enemies in your way.'**
  String get power_sprint_blurb;

  /// Upgrades screen: the name of the "Shield" upgrade, a big title in its callout and screen reader labels. Same word as in flight (glossary "power-up").
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get power_shield_name;

  /// Upgrades screen callout: what the "Shield" upgrade does, one or two short lines. "Shoot" is the fire button's label.
  ///
  /// In en, this message translates to:
  /// **'Blocks one hit for you. Collect stars in flight to refill it.'**
  String get power_shield_blurb;

  /// Upgrades screen: the name of the "Magnet" upgrade, a big title in its callout and screen reader labels. Same word as in flight (glossary "power-up").
  ///
  /// In en, this message translates to:
  /// **'Magnet'**
  String get power_magnet_name;

  /// Upgrades screen callout: what the "Magnet" upgrade does, one or two short lines. "Shoot" is the fire button's label.
  ///
  /// In en, this message translates to:
  /// **'Fly perfectly through gates to earn it. It pulls stars to you.'**
  String get power_magnet_blurb;

  /// Upgrades screen callout: label of one stat row (its value is on the right): how far a held shot charges (shot power).
  ///
  /// In en, this message translates to:
  /// **'Max charge'**
  String get power_stat_maxCharge;

  /// Upgrades screen callout: label of one stat row (its value is on the right): how long one sprint lasts.
  ///
  /// In en, this message translates to:
  /// **'Burst length'**
  String get power_stat_burstLength;

  /// Upgrades screen callout: label of one stat row (its value is on the right): the wait before the next sprint.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get power_stat_cooldown;

  /// Upgrades screen callout: label of one stat row (its value is on the right): stars to collect to get the shield back.
  ///
  /// In en, this message translates to:
  /// **'Stars to refill'**
  String get power_stat_starsToRefill;

  /// Upgrades screen callout: label of one stat row (its value is on the right): how long the bird cannot be hit after its shield breaks.
  ///
  /// In en, this message translates to:
  /// **'Safe time after it breaks'**
  String get power_stat_safeTime;

  /// Upgrades screen callout: label of one stat row (its value is on the right): perfect passes through gates needed to earn the star magnet.
  ///
  /// In en, this message translates to:
  /// **'Perfect gates needed'**
  String get power_stat_perfectGates;

  /// Upgrades screen callout: label of one stat row (its value is on the right): how long the star magnet pulls.
  ///
  /// In en, this message translates to:
  /// **'Lasts'**
  String get power_stat_lasts;

  /// Upgrades screen callout: label of one stat row (its value is on the right): how far the star magnet reaches.
  ///
  /// In en, this message translates to:
  /// **'Reach'**
  String get power_stat_reach;

  /// Passport screen title (a travel passport collecting stamps and medals).
  ///
  /// In en, this message translates to:
  /// **'Your sky passport.'**
  String get passportTitle;

  /// Passport screen: small key in the header that opens today's Adventure postcard.
  ///
  /// In en, this message translates to:
  /// **'Daily card'**
  String get passportDailyCard;

  /// Passport screen: capital tag in the header: medals earned of all.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} MEDALS'**
  String passportMedalsTag(int earned, int total);

  /// Passport screen: one line under the title. "Stamp" is an ink stamp in a passport (see glossary "stamp (passport)").
  ///
  /// In en, this message translates to:
  /// **'Small adventures. Lasting souvenirs. Bronze, silver and gold for every stamp.'**
  String get passportIntro;

  /// Passport: part of a stamp's screen reader label before its first medal.
  ///
  /// In en, this message translates to:
  /// **'No medal yet'**
  String get passportNoMedal;

  /// Passport: part of a stamp's screen reader label: the best medal held.
  ///
  /// In en, this message translates to:
  /// **'{medal, select, bronze{Bronze medal} silver{Silver medal} other{Gold medal}}'**
  String passportMedalHeld(String medal);

  /// Passport: screen reader label of a stamp. {held} is "No medal yet" or "Silver medal"; {next} is the next medal ("Gold"); {goal} its goal sentence.
  ///
  /// In en, this message translates to:
  /// **'{stamp}. {held}. Next, {next}: {goal} {current} of {target}.'**
  String passportStampSemantics(
    String stamp,
    String held,
    String next,
    String goal,
    int current,
    int target,
  );

  /// Passport: screen reader label of a stamp with all three medals.
  ///
  /// In en, this message translates to:
  /// **'{stamp}. Gold medal. {goal}'**
  String passportStampDoneSemantics(String stamp, String goal);

  /// Passport stamp: tiny capital label beside the progress: the medal the bar leads to.
  ///
  /// In en, this message translates to:
  /// **'{medal, select, bronze{TO BRONZE} silver{TO SILVER} other{TO GOLD}}'**
  String passportToMedal(String medal);

  /// Passport: tiny capital word in the teal postmark on a stamp with all three medals.
  ///
  /// In en, this message translates to:
  /// **'STAMPED'**
  String get passportStamped;

  /// Results after a flight: a stamp and the medal just won, such as "Star chaser: Silver". Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'{stamp}: {medal}'**
  String passportMedalTitle(String stamp, String medal);

  /// Results: a stamp with no medal yet (rarely shown).
  ///
  /// In en, this message translates to:
  /// **'{stamp}: none yet'**
  String passportMedalTitleNone(String stamp);

  /// Results: the next medal to earn, such as "Star chaser · Silver". This is the pattern of the Play achievement names: Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'{stamp} · {medal}'**
  String passportNextTitle(String stamp, String medal);

  /// The bronze medal of a passport stamp (sports medal metal), in results and screen reader labels. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get passportMedal_bronze;

  /// The silver medal of a passport stamp (sports medal metal), in results and screen reader labels. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get passportMedal_silver;

  /// The gold medal of a passport stamp (sports medal metal), in results and screen reader labels. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get passportMedal_gold;

  /// Passport stamp title "Frequent flyer" (see the glossary's achievement entry for the idiom), on the stamp and in results; sentence case. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Frequent flyer'**
  String get stamp_frequentFlyer_name;

  /// Passport stamp "Frequent flyer": the goal of its next medal, on the stamp (two small lines) and in results. {count} picks the plural form; {n} is the same number as the player sees it, thousands grouped (5,000). Must match the Play achievement descriptions in l10n/store/<lang>.json.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Finish {n} scored flights.}}'**
  String stamp_frequentFlyer_goal(int count, String n);

  /// Passport stamp title "On the dot" (see the glossary's achievement entry for the idiom), on the stamp and in results; sentence case. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'On the dot'**
  String get stamp_onTheDot_name;

  /// Passport stamp "On the dot": the goal of its next medal, on the stamp (two small lines) and in results. {count} picks the plural form; {n} is the same number as the player sees it, thousands grouped (5,000). Must match the Play achievement descriptions in l10n/store/<lang>.json.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Fly {n} perfect passes along the aiming marks.}}'**
  String stamp_onTheDot_goal(int count, String n);

  /// Passport stamp title "Star chaser" (see the glossary's achievement entry for the idiom), on the stamp and in results; sentence case. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Star chaser'**
  String get stamp_starChaser_name;

  /// Passport stamp "Star chaser": the goal of its next medal, on the stamp (two small lines) and in results. {count} picks the plural form; {n} is the same number as the player sees it, thousands grouped (5,000). Must match the Play achievement descriptions in l10n/store/<lang>.json.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Collect {n} stars.}}'**
  String stamp_starChaser_goal(int count, String n);

  /// Passport stamp title "Constellation" (see the glossary's achievement entry for the idiom), on the stamp and in results; sentence case. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Constellation'**
  String get stamp_constellation_name;

  /// Passport stamp "Constellation": the goal of its next medal, on the stamp (two small lines) and in results. {count} picks the plural form; {n} is the same number as the player sees it, thousands grouped (5,000). Must match the Play achievement descriptions in l10n/store/<lang>.json.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Collect {n} stars in one unbroken streak.}}'**
  String stamp_constellation_goal(int count, String n);

  /// Passport stamp title "Sky captain" (see the glossary's achievement entry for the idiom), on the stamp and in results; sentence case. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Sky captain'**
  String get stamp_skyCaptain_name;

  /// Passport stamp "Sky captain": the goal of its next medal, on the stamp (two small lines) and in results. {count} picks the plural form; {n} is the same number as the player sees it, thousands grouped (5,000). Must match the Play achievement descriptions in l10n/store/<lang>.json.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Score {n} points in one endless flight.}}'**
  String stamp_skyCaptain_goal(int count, String n);

  /// Passport stamp title "Trailblazer" (see the glossary's achievement entry for the idiom), on the stamp and in results; sentence case. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Trailblazer'**
  String get stamp_trailblazer_name;

  /// Passport stamp "Trailblazer": the goal of its next medal, on the stamp (two small lines) and in results. {count} picks the plural form; {n} is the same number as the player sees it, thousands grouped (5,000). Must match the Play achievement descriptions in l10n/store/<lang>.json.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Fly at least 60 seconds in {n} endless flights.}}'**
  String stamp_trailblazer_goal(int count, String n);

  /// Passport stamp title "Flock together" (see the glossary's achievement entry for the idiom), on the stamp and in results; sentence case. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'Flock together'**
  String get stamp_flockTogether_name;

  /// Passport stamp title "All-rounder" (see the glossary's achievement entry for the idiom), on the stamp and in results; sentence case. Must use the SAME words as this stamp's Google Play achievement names in l10n/store/<lang>.json ("{stamp} · {medal}", e.g. "Frequent Flyer · Bronze"), so the game and Play Console agree.
  ///
  /// In en, this message translates to:
  /// **'All-rounder'**
  String get stamp_allRounder_name;

  /// Passport stamp "Flock together", bronze goal. Must match the Play achievement description.
  ///
  /// In en, this message translates to:
  /// **'Take two different birds on scored flights.'**
  String get stamp_flockTogether_goalBronze;

  /// Passport stamp "Flock together", silver goal. Must match the Play achievement description.
  ///
  /// In en, this message translates to:
  /// **'Take all four birds on scored flights.'**
  String get stamp_flockTogether_goalSilver;

  /// Passport stamp "Flock together", gold goal. {count} picks the plural form; {n} is the same number as the player sees it, thousands grouped (5,000). Must match the Play achievement description.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Fly {n} scored flights with every bird.}}'**
  String stamp_flockTogether_goalGold(int count, String n);

  /// Passport stamp "All-rounder", bronze goal (the camera mini games). Must match the Play achievement description.
  ///
  /// In en, this message translates to:
  /// **'Fly a push-up, squat or jump mini game.'**
  String get stamp_allRounder_goalBronze;

  /// Passport stamp "All-rounder", silver goal. Must match the Play achievement description.
  ///
  /// In en, this message translates to:
  /// **'Fly all three mini games: push-up, squat, jump.'**
  String get stamp_allRounder_goalSilver;

  /// Passport stamp "All-rounder", gold goal. {count} picks the plural form; {n} is the same number as the player sees it, thousands grouped (5,000). Must match the Play achievement description.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Fly {n} scored flights in each mini game.}}'**
  String stamp_allRounder_goalGold(int count, String n);

  /// Google Play Games cloud save: the one-line description of the saved game in Google's list: campaign stars, medals, and the level the campaign is at ("38★ · 12 medals · at 3-2"). Keep the ★.
  ///
  /// In en, this message translates to:
  /// **'{medals, plural, other{{stars}★ · {medals} medals · at {level}}}'**
  String playGamesSaveDescription(int medals, int stars, String level);

  /// Daily Adventure screen: heading when the save could not be loaded, above a Try again button.
  ///
  /// In en, this message translates to:
  /// **'Your adventure needs a moment.'**
  String get dailyUnavailable;

  /// Daily Adventure screen title (three small goals for today).
  ///
  /// In en, this message translates to:
  /// **'Today’s little adventure.'**
  String get dailyTitle;

  /// Daily Adventure screen: capital tag in the header: today's date ({date}, short, in capitals, e.g. "7 OCT", written by the app in your language's order) and goals done of three.
  ///
  /// In en, this message translates to:
  /// **'{date} · {done}/3 GOALS'**
  String dailyDateTag(String date, int done);

  /// Daily Adventure screen: one line under the title. "Control" = tap, push-up, squat or jump.
  ///
  /// In en, this message translates to:
  /// **'Three goals. Any control. One endless flight works on all three.'**
  String get dailyIntro;

  /// Daily Adventure screen: key that starts an endless flight (game mode "Endless"), beside keys named after the mini games.
  ///
  /// In en, this message translates to:
  /// **'Endless'**
  String get dailyLaunchEndless;

  /// Daily Adventure postcard: tiny capital kicker at its top left. "Sky Club" is the birds' postal club (glossary).
  ///
  /// In en, this message translates to:
  /// **'SKY CLUB POSTCARD'**
  String get dailyPostcardKicker;

  /// Daily Adventure postcard: capital pill once all three goals are done.
  ///
  /// In en, this message translates to:
  /// **'POSTCARD STAMPED!'**
  String get dailyStamped;

  /// Daily Adventure postcard: capital pill: goals done of three.
  ///
  /// In en, this message translates to:
  /// **'{done} / 3 GOALS COMPLETE'**
  String dailyGoalsComplete(int done);

  /// Daily Adventure postcard: small line once the card is stamped.
  ///
  /// In en, this message translates to:
  /// **'A small adventure, all yours.'**
  String get dailyDoneNote;

  /// Daily Adventure postcard: small line while goals are open.
  ///
  /// In en, this message translates to:
  /// **'Finish all three to stamp this card.'**
  String get dailyOpenNote;

  /// Daily Adventure: screen reader label of a finished goal; {goal} is its sentence.
  ///
  /// In en, this message translates to:
  /// **'{goal} Complete'**
  String dailyGoalCompleteSemantics(String goal);

  /// Daily Adventure: screen reader label of an open goal.
  ///
  /// In en, this message translates to:
  /// **'{goal} {current} of {target}'**
  String dailyGoalProgressSemantics(String goal, int current, int target);

  /// Daily Adventure: tooltip of a day's coin in the week row; {date} is the day's date.
  ///
  /// In en, this message translates to:
  /// **'{date}: Postcard stamped'**
  String dailyWeekStampedSemantics(String date);

  /// Daily Adventure: tooltip of a day's coin in the week row.
  ///
  /// In en, this message translates to:
  /// **'{date}: {done}/3 goals'**
  String dailyWeekProgressSemantics(String date, int done);

  /// Daily Adventure: small line under the week row: new goals every day, and missing a day costs nothing.
  ///
  /// In en, this message translates to:
  /// **'Fresh goals. No streak to lose.'**
  String get dailyNoStreak;

  /// Daily Adventure postcard: the day's whimsical title (one of six that rotate). Short; alliteration welcome.
  ///
  /// In en, this message translates to:
  /// **'Sunrise delivery'**
  String get dailyTheme_0;

  /// Daily Adventure postcard: the day's whimsical title (one of six that rotate). Short; alliteration welcome.
  ///
  /// In en, this message translates to:
  /// **'Peach picnic'**
  String get dailyTheme_1;

  /// Daily Adventure postcard: the day's whimsical title (one of six that rotate). Short; alliteration welcome.
  ///
  /// In en, this message translates to:
  /// **'Moonlit mail'**
  String get dailyTheme_2;

  /// Daily Adventure postcard: the day's whimsical title (one of six that rotate). Short; alliteration welcome.
  ///
  /// In en, this message translates to:
  /// **'Cloud parade'**
  String get dailyTheme_3;

  /// Daily Adventure postcard: the day's whimsical title (one of six that rotate). Short; alliteration welcome.
  ///
  /// In en, this message translates to:
  /// **'Twilight treasure'**
  String get dailyTheme_4;

  /// Daily Adventure postcard: the day's whimsical title (one of six that rotate). Short; alliteration welcome.
  ///
  /// In en, this message translates to:
  /// **'Garden party'**
  String get dailyTheme_5;

  /// Daily Adventure: a goal's cheerful title, beside its count. Short; idioms welcome.
  ///
  /// In en, this message translates to:
  /// **'Spread your wings'**
  String get task_flights_title;

  /// Daily Adventure: the goal's sentence, one small line under its title. {count} is the target.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Finish {count} scored flights today.}}'**
  String task_flights_goal(int count);

  /// Daily Adventure: a goal's cheerful title, beside its count. Short; idioms welcome.
  ///
  /// In en, this message translates to:
  /// **'Open horizons'**
  String get task_gates_title;

  /// Daily Adventure: the goal's sentence, one small line under its title. {count} is the target.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Clear {count} gates across today’s scored flights.}}'**
  String task_gates_goal(int count);

  /// Daily Adventure: a goal's cheerful title, beside its count. Short; idioms welcome.
  ///
  /// In en, this message translates to:
  /// **'Pocketful of stars'**
  String get task_stars_title;

  /// Daily Adventure: the goal's sentence, one small line under its title. {count} is the target.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Collect {count} stars across today’s flights.}}'**
  String task_stars_goal(int count);

  /// Daily Adventure: a goal's cheerful title, beside its count. Short; idioms welcome.
  ///
  /// In en, this message translates to:
  /// **'Keep the sparkle'**
  String get task_streak_title;

  /// Daily Adventure: the goal's sentence, one small line under its title. {count} is the target.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Collect {count} stars in one unbroken streak.}}'**
  String task_streak_goal(int count);

  /// Daily Adventure: a goal's cheerful title, beside its count. Short; idioms welcome.
  ///
  /// In en, this message translates to:
  /// **'Right on the mark'**
  String get task_perfects_title;

  /// Daily Adventure: the goal's sentence, one small line under its title. {count} is the target.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Fly {count} perfect passes today.}}'**
  String task_perfects_goal(int count);

  /// Daily Adventure: a goal's cheerful title, beside its count. Short; idioms welcome.
  ///
  /// In en, this message translates to:
  /// **'The whole journey'**
  String get task_finishTrail_title;

  /// Daily Adventure: the goal's sentence, one small line under its title.
  ///
  /// In en, this message translates to:
  /// **'Fly for at least 60 seconds in one endless flight.'**
  String get task_finishTrail_goal;

  /// Records screen title (best scores and recent flights).
  ///
  /// In en, this message translates to:
  /// **'Your little victories.'**
  String get recordsTitle;

  /// Records screen: title of the card with the best scores.
  ///
  /// In en, this message translates to:
  /// **'Your star points to beat'**
  String get recordsBestsTitle;

  /// Records screen: tiny capital heading over the main game's bests (Endless and Campaign).
  ///
  /// In en, this message translates to:
  /// **'MAIN GAME'**
  String get recordsSectionMain;

  /// Records screen: tiny capital heading over the mini games' bests.
  ///
  /// In en, this message translates to:
  /// **'MINI GAMES'**
  String get recordsSectionMini;

  /// Records screen: label of the best endless flight ("Endless" mode flown with "Tap & Fly" controls).
  ///
  /// In en, this message translates to:
  /// **'Endless · Tap & Fly'**
  String get recordsEndless;

  /// Records screen: label of the campaign's level stars earned of all.
  ///
  /// In en, this message translates to:
  /// **'Campaign stars'**
  String get recordsCampaignStars;

  /// Records and saved sessions: a two-player mode: "Fly Together" and {mode}, the mode's own name (coopMode_*: "Roped", "No rope" or "1 v 1").
  ///
  /// In en, this message translates to:
  /// **'Fly Together · {mode}'**
  String recordsCoopName(String mode);

  /// Records screen: a lifetime total on a small plate, after the number in bold ("120 scored flights").
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{scored flights}}'**
  String recordsTotalFlights(int count);

  /// Records screen: lifetime total of gates flown through, after the number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{gates}}'**
  String recordsTotalGates(int count);

  /// Records screen: lifetime total of two-player team flights (Fly Together), after the number ("6 together").
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{together}}'**
  String recordsTotalTogether(int count);

  /// Records screen: lifetime total of 1 v 1 duels, after the number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{duels}}'**
  String recordsTotalDuels(int count);

  /// Records screen: lifetime total of push-ups (mini game), after the number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{push-ups}}'**
  String recordsTotalPushUps(int count);

  /// Records screen: lifetime total of squats (mini game), after the number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{squats}}'**
  String recordsTotalSquats(int count);

  /// Records screen: title of the list of the latest flights.
  ///
  /// In en, this message translates to:
  /// **'Recent flights'**
  String get recordsRecentTitle;

  /// Records screen: heading of the empty recent-flights list.
  ///
  /// In en, this message translates to:
  /// **'A big sky. A clean slate.'**
  String get recordsEmptyTitle;

  /// Records screen: line under the empty list heading.
  ///
  /// In en, this message translates to:
  /// **'Your first scored flight starts the story.'**
  String get recordsEmptyBody;

  /// Records screen: a recent flight's small line: the day ({date}, short, written by the app in your language's order) and how long it lasted.
  ///
  /// In en, this message translates to:
  /// **'{date} · {seconds} sec'**
  String recordsSlipDetail(String date, int seconds);

  /// Records screen: the same for an old "Classic" flight.
  ///
  /// In en, this message translates to:
  /// **'Classic · {date} · {seconds} sec'**
  String recordsSlipDetailClassic(String date, int seconds);

  /// Records screen key and the saved sessions screen title: flights the player saved to watch again (replay and camera video).
  ///
  /// In en, this message translates to:
  /// **'Saved sessions'**
  String get replaySavedSessions;

  /// Saved sessions screen: tooltip of the back arrow.
  ///
  /// In en, this message translates to:
  /// **'Back to Records'**
  String get replayBackToRecordsSemantics;

  /// Saved sessions screen: a button shown when the list could not load; tapping retries.
  ///
  /// In en, this message translates to:
  /// **'Could not load sessions. Retry'**
  String get replaySessionsLoadFailed;

  /// Saved sessions screen: heading when no session is saved.
  ///
  /// In en, this message translates to:
  /// **'Your flights belong here'**
  String get replayEmptyTitle;

  /// Saved sessions screen: line under the empty heading.
  ///
  /// In en, this message translates to:
  /// **'Save a session after a flight to watch it here.'**
  String get replayEmptyBody;

  /// Saved sessions screen: button back to the title screen.
  ///
  /// In en, this message translates to:
  /// **'Choose a flight'**
  String get replayEmptyButton;

  /// Saved sessions list: a session's small line: when it was flown ({date}, date and time written by the app), how long, and its score.
  ///
  /// In en, this message translates to:
  /// **'{score, plural, other{{date} · {seconds} sec · {score} star points}}'**
  String replaySessionStars(int score, String date, int seconds);

  /// Saved sessions list: the same for an old flight scored in gates.
  ///
  /// In en, this message translates to:
  /// **'{score, plural, other{{date} · {seconds} sec · {score} gates}}'**
  String replaySessionGates(int score, String date, int seconds);

  /// Saved sessions list: tooltip of the bin button.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get replayDeleteSemantics;

  /// Delete dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete this session?'**
  String get replayDeleteTitle;

  /// Delete dialog text.
  ///
  /// In en, this message translates to:
  /// **'The camera video and replay will be removed. Your scores stay in Records.'**
  String get replayDeleteBody;

  /// Snack bar when deleting a session failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete session. Try again.'**
  String get replayDeleteFailed;

  /// Saved session title for a Level Builder level: the player's own level name and the controls it was flown with ("Tap & Fly").
  ///
  /// In en, this message translates to:
  /// **'{name} · {mode}'**
  String replaySessionBuilt(String name, String mode);

  /// Saved session title for a campaign level this version no longer has.
  ///
  /// In en, this message translates to:
  /// **'Level {id}'**
  String replaySessionUnknownLevel(String id);

  /// Saved session title: the controls ("Tap & Fly", "Squat & Fly"…) and the mode "Endless".
  ///
  /// In en, this message translates to:
  /// **'{mode} · Endless'**
  String replaySessionEndless(String mode);

  /// Saved session title of an old practice flight.
  ///
  /// In en, this message translates to:
  /// **'{mode} · Practice'**
  String replaySessionPractice(String mode);

  /// Saved session title of a practice endless flight.
  ///
  /// In en, this message translates to:
  /// **'{mode} · Endless · Practice'**
  String replaySessionEndlessPractice(String mode);

  /// Replay screen: message when a saved session cannot be played.
  ///
  /// In en, this message translates to:
  /// **'This session could not be opened.'**
  String get replayOpenFailed;

  /// Replay screen: button under the error message.
  ///
  /// In en, this message translates to:
  /// **'Back to sessions'**
  String get replayBackToSessions;

  /// Replay screen: small text in the camera window when no video was recorded for this moment.
  ///
  /// In en, this message translates to:
  /// **'Camera was paused during this part of the session'**
  String get replayCameraPaused;

  /// Replay screen: small text in the camera window when the video cannot play.
  ///
  /// In en, this message translates to:
  /// **'Camera clip unavailable · Gameplay still plays'**
  String get replayCameraUnavailable;

  /// Replay screen: small text in the camera window while the video loads.
  ///
  /// In en, this message translates to:
  /// **'Loading camera…'**
  String get replayCameraLoading;

  /// Replay screen: card over the replay where the player had paused the flight. Friendly, like the in-flight pause title.
  ///
  /// In en, this message translates to:
  /// **'Taking a breather'**
  String get replayPaused;

  /// Replay screen: screen reader label of the tap surface.
  ///
  /// In en, this message translates to:
  /// **'Hide replay controls'**
  String get replayHideControlsSemantics;

  /// Replay screen: screen reader label of the tap surface.
  ///
  /// In en, this message translates to:
  /// **'Show replay controls'**
  String get replayShowControlsSemantics;

  /// Replay screen: screen reader label of the back key.
  ///
  /// In en, this message translates to:
  /// **'Back to saved sessions'**
  String get replayBackToSavedSemantics;

  /// Replay screen: capital title at the top.
  ///
  /// In en, this message translates to:
  /// **'REPLAY'**
  String get replayTitle;

  /// Replay screen: capital title with the session's name, such as "1-3 · Canopy Run".
  ///
  /// In en, this message translates to:
  /// **'REPLAY · {session}'**
  String replayTitleSession(String session);

  /// Replay screen: screen reader label of the score box.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String replayScoreSemantics(int score);

  /// Replay screen: small line under the score: hearts left and the flight clock ({clock} like "1:05" or "12s").
  ///
  /// In en, this message translates to:
  /// **'{hearts, plural, other{{hearts} hearts}} · {clock}'**
  String replayHearts(int hearts, String clock);

  /// Replay screen, a 1 v 1 duel: each player's hearts and the clock. "P1"/"P2" = player 1/2 (keep your usual short form).
  ///
  /// In en, this message translates to:
  /// **'P1 {p1} · P2 {p2} hearts · {clock}'**
  String replayDuelHearts(int p1, int p2, String clock);

  /// Replay screen: seconds left on an old timed flight's clock (a number and a short unit).
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String replayClockSeconds(int seconds);

  /// Replay screen: the star magnet is on, seconds left.
  ///
  /// In en, this message translates to:
  /// **'Magnet · {seconds}s'**
  String replayMagnet(int seconds);

  /// Replay controls: tooltip of the pause button.
  ///
  /// In en, this message translates to:
  /// **'Pause replay'**
  String get replayPauseSemantics;

  /// Replay controls: tooltip of the play button.
  ///
  /// In en, this message translates to:
  /// **'Play replay'**
  String get replayPlaySemantics;

  /// Replay controls: tooltip of the restart button.
  ///
  /// In en, this message translates to:
  /// **'Restart replay'**
  String get replayRestartSemantics;

  /// Replay controls: tooltip of the rewind button.
  ///
  /// In en, this message translates to:
  /// **'Back 5 seconds'**
  String get replayBack5Semantics;

  /// Replay controls: tooltip of the fast-forward button.
  ///
  /// In en, this message translates to:
  /// **'Forward 5 seconds'**
  String get replayForward5Semantics;

  /// Replay controls: tooltip of the highlights button while they are being found.
  ///
  /// In en, this message translates to:
  /// **'Finding flight highlights'**
  String get replayHighlightsFinding;

  /// Replay controls: tooltip of the greyed highlights button.
  ///
  /// In en, this message translates to:
  /// **'No flight highlights available'**
  String get replayHighlightsNone;

  /// Replay: the highlights button's tooltip and the title of the highlights sheet (sports-style best moments of the flight).
  ///
  /// In en, this message translates to:
  /// **'Flight highlights'**
  String get replayHighlights;

  /// Highlights sheet: screen reader label of the close key.
  ///
  /// In en, this message translates to:
  /// **'Close highlights'**
  String get replayHighlightsCloseSemantics;

  /// Highlights sheet: one line under the title.
  ///
  /// In en, this message translates to:
  /// **'Pick a moment. Watch from just before it happened.'**
  String get replayHighlightsHint;

  /// Replay controls: dropdown choice: camera video in a small corner window.
  ///
  /// In en, this message translates to:
  /// **'Corner camera'**
  String get replayViewCorner;

  /// Replay controls: dropdown choice: camera video behind the game.
  ///
  /// In en, this message translates to:
  /// **'Camera background'**
  String get replayViewBackground;

  /// Replay controls: dropdown choice: no camera video.
  ///
  /// In en, this message translates to:
  /// **'Gameplay only'**
  String get replayViewGameplay;

  /// Replay controls: tooltip of the button that moves the camera window to the next corner.
  ///
  /// In en, this message translates to:
  /// **'Move camera corner'**
  String get replayMoveCornerSemantics;

  /// Replay controls: tooltip: mute the microphone sound recorded with the video.
  ///
  /// In en, this message translates to:
  /// **'Mute recorded audio'**
  String get replayMuteRecordedSemantics;

  /// Replay controls: tooltip: play the recorded microphone sound.
  ///
  /// In en, this message translates to:
  /// **'Enable recorded audio'**
  String get replayUnmuteRecordedSemantics;

  /// Replay controls: tooltip: mute the game's music and effects.
  ///
  /// In en, this message translates to:
  /// **'Mute game sound'**
  String get replayMuteGameSemantics;

  /// Replay controls: tooltip: play the game's music and effects.
  ///
  /// In en, this message translates to:
  /// **'Enable game sound'**
  String get replayUnmuteGameSemantics;

  /// Replay controls: tooltip of the full screen button.
  ///
  /// In en, this message translates to:
  /// **'Hide controls / full screen'**
  String get replayFullScreenSemantics;

  /// Flight highlights sheet (replay): title of the moment the flight starts.
  ///
  /// In en, this message translates to:
  /// **'Takeoff'**
  String get replayMomentTakeoff;

  /// Flight highlights sheet (replay): line under "Takeoff".
  ///
  /// In en, this message translates to:
  /// **'The sky is yours.'**
  String get replayMomentTakeoffDetail;

  /// Flight highlights sheet (replay): title: the star magnet switched on (same words as the flight callout).
  ///
  /// In en, this message translates to:
  /// **'Star magnet'**
  String get replayMomentMagnet;

  /// Flight highlights sheet (replay): line under "Star magnet".
  ///
  /// In en, this message translates to:
  /// **'Three perfect passes bring the stars closer.'**
  String get replayMomentMagnetDetail;

  /// Flight highlights sheet (replay): title: the first group of three stars collected.
  ///
  /// In en, this message translates to:
  /// **'First star trio'**
  String get replayMomentStarTrio;

  /// Flight highlights sheet (replay): line under "First star trio".
  ///
  /// In en, this message translates to:
  /// **'Three stars become a constellation. +5 points!'**
  String get replayMomentStarTrioDetail;

  /// Flight highlights sheet (replay): line under "First star trio" when the game's calmer star effects are on.
  ///
  /// In en, this message translates to:
  /// **'Every star in the group collected. +5 points!'**
  String get replayMomentStarTrioSubtleDetail;

  /// Flight highlights sheet (replay): title: the star streak multiplier reached {multiplier} (2 or 3). Keep the ×.
  ///
  /// In en, this message translates to:
  /// **'{multiplier}× star power'**
  String replayMomentStreak(int multiplier);

  /// Flight highlights sheet (replay): line under the star power title.
  ///
  /// In en, this message translates to:
  /// **'A sparkling streak of stars.'**
  String get replayMomentStreakDetail;

  /// Flight highlights sheet (replay): title: the shield blocked a hit.
  ///
  /// In en, this message translates to:
  /// **'Shield save'**
  String get replayMomentShield;

  /// Flight highlights sheet (replay): line under "Shield save".
  ///
  /// In en, this message translates to:
  /// **'A close call, and another chance.'**
  String get replayMomentShieldDetail;

  /// Flight highlights sheet (replay): title: the first perfect pass through a gate.
  ///
  /// In en, this message translates to:
  /// **'First perfect pass'**
  String get replayMomentPerfect;

  /// Flight highlights sheet (replay): line under "First perfect pass".
  ///
  /// In en, this message translates to:
  /// **'Right through the aiming mark.'**
  String get replayMomentPerfectDetail;

  /// Flight highlights sheet (replay): title: a number of gates flown through.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} gates cleared}}'**
  String replayMomentGates(int count);

  /// Flight highlights sheet (replay): line under the gates title.
  ///
  /// In en, this message translates to:
  /// **'A little farther into the sky.'**
  String get replayMomentGatesDetail;

  /// Flight highlights sheet (replay): line under a rush or gale escape without a hit.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, other{Not a scratch. +{points} points!}}'**
  String replayMomentFlawlessDetail(int points);

  /// Flight highlights sheet (replay): line under a rush escape (sprint rings carried the bird out).
  ///
  /// In en, this message translates to:
  /// **'{points, plural, other{Sprint rings to safety. +{points} points!}}'**
  String replayMomentRushDetail(int points);

  /// Flight highlights sheet (replay): title: the bird flew through a storm wind (gale) to its end.
  ///
  /// In en, this message translates to:
  /// **'Weathered the gale'**
  String get replayMomentGale;

  /// Flight highlights sheet (replay): line under "Weathered the gale".
  ///
  /// In en, this message translates to:
  /// **'{points, plural, other{Dodged the flying debris. +{points} points!}}'**
  String replayMomentGaleDetail(int points);

  /// Flight highlights sheet (replay): title: the level was finished.
  ///
  /// In en, this message translates to:
  /// **'Route complete'**
  String get replayMomentRouteComplete;

  /// Flight highlights sheet (replay): title: the end of the flight.
  ///
  /// In en, this message translates to:
  /// **'Final moment'**
  String get replayMomentFinal;

  /// Flight highlights sheet (replay): line under "Route complete".
  ///
  /// In en, this message translates to:
  /// **'You reached the end of the route.'**
  String get replayMomentCompleteDetail;

  /// Flight highlights sheet (replay): line under "Final moment" when the flight ended in a crash.
  ///
  /// In en, this message translates to:
  /// **'Watch the final approach.'**
  String get replayMomentCollisionDetail;

  /// Flight highlights sheet (replay): line under "Final moment" otherwise.
  ///
  /// In en, this message translates to:
  /// **'The end of this flight.'**
  String get replayMomentEndDetail;

  /// First launch, the very first screen: title over the list of languages. It cycles through every language, each in its own words, so keep it short and plain.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get welcomeTitle;

  /// First launch, language screen: the big button that confirms the chosen language and starts flight school (the first lesson). Playful.
  ///
  /// In en, this message translates to:
  /// **'Let’s fly!'**
  String get welcomeContinue;

  /// First launch, language screen: small line under the languages.
  ///
  /// In en, this message translates to:
  /// **'You can change it any time in Settings.'**
  String get welcomeHint;

  /// First launch, language screen: small badge on the language that matches the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Your phone’s language'**
  String get welcomeDevice;

  /// Name of the first-time lesson (tutorial) flown before the campaign: on the pause card, in Settings and on the courier licence. Postmaster Bill teaches it.
  ///
  /// In en, this message translates to:
  /// **'Flight school'**
  String get tutorialTitle;

  /// Flight school: key that skips the first-time lesson and goes straight to the campaign map. On the intro and the pause card.
  ///
  /// In en, this message translates to:
  /// **'Skip lesson'**
  String get tutorialSkip;

  /// Flight school: title of the box that asks whether to skip the lesson.
  ///
  /// In en, this message translates to:
  /// **'Skip flight school?'**
  String get tutorialSkipTitle;

  /// Flight school: text of the box that asks whether to skip the lesson.
  ///
  /// In en, this message translates to:
  /// **'You can take the lesson again any time from Settings.'**
  String get tutorialSkipBody;

  /// Flight school: confirms skipping the lesson.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkipConfirm;

  /// Flight school: keeps flying the lesson instead of skipping it.
  ///
  /// In en, this message translates to:
  /// **'Keep learning'**
  String get tutorialSkipCancel;

  /// Flight school pause card: flies the lesson again from the beginning.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get tutorialRestart;

  /// Flight school goal chip: tap to flap a few times. Followed by a count such as 2/3.
  ///
  /// In en, this message translates to:
  /// **'Flap'**
  String get tutorialGoalFlaps;

  /// Flight school goal chip: fly through stars. Followed by a count. Also a ticked skill on the courier licence.
  ///
  /// In en, this message translates to:
  /// **'Collect stars'**
  String get tutorialGoalStars;

  /// Flight school goal chip: fly through the gaps in the gates. Followed by a count. Also a ticked skill on the courier licence.
  ///
  /// In en, this message translates to:
  /// **'Fly through gates'**
  String get tutorialGoalGates;

  /// Flight school goal chip: shoot pebbles at bats. Followed by a count. Also a ticked skill on the courier licence.
  ///
  /// In en, this message translates to:
  /// **'Knock out bats'**
  String get tutorialGoalBats;

  /// Flight school goal chip: break a stone door with a charged shot. Also a ticked skill on the courier licence.
  ///
  /// In en, this message translates to:
  /// **'Smash the door'**
  String get tutorialGoalDoor;

  /// Flight school goal chip: press Sprint once. Also a ticked skill on the courier licence. Same game term as the Sprint button.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get tutorialGoalSprint;

  /// Flight school goal chip in the boss fight: defeat the Pirate Captain. Also a ticked skill on the courier licence.
  ///
  /// In en, this message translates to:
  /// **'Beat the Captain'**
  String get tutorialGoalBoss;

  /// Flight school: big shout while the lesson waits for a tap anywhere on the screen to flap.
  ///
  /// In en, this message translates to:
  /// **'Tap!'**
  String get tutorialPromptTap;

  /// Flight school: big shout next to the Shoot button while the lesson waits for it to be pressed. Shoot is the button's name.
  ///
  /// In en, this message translates to:
  /// **'Tap Shoot'**
  String get tutorialPromptShoot;

  /// Flight school: big shout next to the Shoot button: press and keep holding it to charge a power shot, then let go.
  ///
  /// In en, this message translates to:
  /// **'Hold Shoot'**
  String get tutorialPromptHoldShoot;

  /// Flight school: big shout next to the Sprint button while the lesson waits for it to be pressed. Sprint is the button's name.
  ///
  /// In en, this message translates to:
  /// **'Tap Sprint'**
  String get tutorialPromptSprint;

  /// Flight school: pop-up praise when a lesson's goal is met.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get tutorialPraiseNice;

  /// Flight school: pop-up praise when a lesson's goal is met (another wording).
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get tutorialPraiseGreat;

  /// Flight school: pop-up praise when a lesson's goal is met (another wording).
  ///
  /// In en, this message translates to:
  /// **'Brilliant!'**
  String get tutorialPraiseSuper;

  /// Screen reader: flight school has frozen the flight until the player does what it asks. {prompt} is one of the shouts, such as "Tap Shoot".
  ///
  /// In en, this message translates to:
  /// **'The lesson is waiting: {prompt}'**
  String tutorialWaitingSemantics(String prompt);

  /// End of flight school: title of the card the new courier earns, like a driving licence for mail birds.
  ///
  /// In en, this message translates to:
  /// **'Courier licence'**
  String get licenceTitle;

  /// Courier licence: who issues it, the club's post office. Same name as in the story.
  ///
  /// In en, this message translates to:
  /// **'Sky Club post'**
  String get licenceIssuer;

  /// Courier licence: label over the bird's name (the holder).
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get licenceHolder;

  /// Courier licence: label over the holder's rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get licenceRank;

  /// Courier licence: the rank of a brand-new courier.
  ///
  /// In en, this message translates to:
  /// **'Rookie courier'**
  String get licenceRankRookie;

  /// Courier licence: label over the list of ticked skills learned in flight school.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get licenceSkills;

  /// Courier licence: word on the round rubber stamp slammed onto the card. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Certified'**
  String get licenceStamp;

  /// Courier licence: the signature line. {name} is Postmaster Bill's name.
  ///
  /// In en, this message translates to:
  /// **'Signed: {name}'**
  String licenceSignedBy(String name);

  /// Courier licence: how many stars were collected in the lesson.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String licenceStars(int count);

  /// Courier licence: the main button, which opens the campaign map. Excited.
  ///
  /// In en, this message translates to:
  /// **'Start my first route'**
  String get licenceStart;

  /// Courier licence: smaller button that flies flight school again.
  ///
  /// In en, this message translates to:
  /// **'Fly it again'**
  String get licenceAgain;

  /// Settings: key that flies the first-time lesson again. Same name as tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Flight school'**
  String get settingsTutorial;

  /// Settings: small line on the flight school key.
  ///
  /// In en, this message translates to:
  /// **'Take the first lesson again'**
  String get settingsTutorialDetail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'id',
    'ja',
    'ko',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return AppLocalizationsEnXa();
        }
        break;
      }
    case 'es':
      {
        switch (locale.countryCode) {
          case '419':
            return AppLocalizationsEs419();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
