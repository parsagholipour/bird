// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonTryAgain => 'Erneut versuchen';

  @override
  String get languageKeyLabel => 'Sprache';

  @override
  String languageKeySemantics(String language) {
    return 'Sprache: $language. Ändere die Sprache des Spiels.';
  }

  @override
  String get languageSystemDefault => 'Systemsprache';

  @override
  String languageSystemDetail(String language) {
    return 'Wie dein Handy: $language';
  }

  @override
  String get languageCurrent => 'Aktuelle Sprache';

  @override
  String get languageName_en => 'Englisch';

  @override
  String get languageName_es_419 => 'Spanisch (Lateinamerika)';

  @override
  String get languageName_pt_br => 'Portugiesisch (BR)';

  @override
  String get languageName_id => 'Indonesisch';

  @override
  String get languageName_fr => 'Französisch';

  @override
  String get languageName_de => 'Deutsch';

  @override
  String get languageName_ja => 'Japanisch';

  @override
  String get languageName_ko => 'Koreanisch';

  @override
  String get languageName_tr => 'Türkisch';

  @override
  String get languageName_zh_hant => 'Chinesisch (Langzeichen)';

  @override
  String get languageName_ru => 'Russisch';

  @override
  String get languageName_ar => 'Arabisch';

  @override
  String get voicePackReady => 'Stimmen bereit';

  @override
  String get voicePackDownload => 'Stimmen laden';

  @override
  String voicePackDownloading(int percent) {
    return 'Stimmen $percent %';
  }

  @override
  String get voicePackStarting => 'Lade Stimmen…';

  @override
  String get voicePackEnglish => 'Englische Stimmen';

  @override
  String get voicePackFailed => 'Laden misslungen';

  @override
  String get settingsTitle => 'Fühl dich wie zu Hause.';

  @override
  String get settingsSectionSound => 'Ton';

  @override
  String get settingsSectionComfort => 'Komfort';

  @override
  String get settingsMusicTitle => 'Himmelsclub-Soundtrack';

  @override
  String get settingsMusicDetail => 'Musik für Menü, Abenteuer und Bosse.';

  @override
  String get settingsEffectsTitle => 'Soundeffekte';

  @override
  String get settingsEffectsDetail => 'Flug, Kampf, Extras und Menüklänge.';

  @override
  String get settingsVoicesTitle => 'Figurenstimmen';

  @override
  String get settingsVoicesDetail =>
      'Geschichte, Dankeskarten und Sprint-Rufe.';

  @override
  String get settingsReducedMotionTitle => 'Bewegung reduzieren';

  @override
  String get settingsReducedMotionDetail =>
      'Ruhigere Menüs, weniger Deko-Effekte.';

  @override
  String get settingsSwitchOn => 'AN';

  @override
  String get settingsSwitchOff => 'AUS';

  @override
  String get settingsUnavailable => 'Einstellungen brauchen noch kurz.';

  @override
  String get settingsPrivacyKicker => 'AUF DEM GERÄT. IMMER.';

  @override
  String get settingsPrivacyTitle => 'Deine Kamera bleibt deine.';

  @override
  String get settingsPrivacyBody =>
      'Video und optionaler Mikrofonton bleiben auf dem Handy. Nicht Gespeichertes wird gelöscht. Kein Upload.';

  @override
  String get settingsCameraLab => 'Kamera- & Tracking-Labor';

  @override
  String get settingsAbout => 'Info & Lizenzen';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'Info & Lizenzen, Version $version';
  }

  @override
  String get settingsReset => 'Fortschritt zurücksetzen';

  @override
  String settingsResetDone(String bird) {
    return 'Alles auf Anfang. $bird wartet schon auf dich.';
  }

  @override
  String get settingsResetTitle => 'Neues Abenteuer beginnen?';

  @override
  String get settingsResetBody =>
      'Das löscht gespeicherte Videos, Wiederholungen, Punkte, Flüge, gebaute Level und Einstellungen auf diesem Handy. Das geht nicht rückgängig.';

  @override
  String get settingsResetBodyCloud =>
      'Das löscht gespeicherte Videos, Wiederholungen, Punkte, Flüge, gebaute Level und Einstellungen auf diesem Handy und deinen Play-Spiele-Cloud-Speicher. Das geht nicht rückgängig.';

  @override
  String get settingsResetConfirm => 'Alles löschen';

  @override
  String get settingsResetKeep => 'Fortschritt behalten';

  @override
  String get playGamesName => 'Play Spiele';

  @override
  String get playGamesConnected => 'Verbunden';

  @override
  String get playGamesNotConnected => 'Abgemeldet';

  @override
  String get playGamesConnecting => 'Verbinde…';

  @override
  String get playGamesConnectFailed => 'Verbindung fehlgeschlagen';

  @override
  String get playGamesIdle => 'Cloud-Speicher & Erfolge';

  @override
  String get playGamesSaving => 'Speichere in der Cloud…';

  @override
  String get playGamesOfflineUnsaved => 'Offline · noch nicht gesichert';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'Offline · gesichert $ago';
  }

  @override
  String get playGamesUpdateNeeded => 'Zum Sync Beakbound updaten';

  @override
  String get playGamesUnreadable => 'Cloud-Speicher nicht lesbar';

  @override
  String get playGamesOn => 'Cloud-Speicher ist an';

  @override
  String get playGamesResetElsewhere => 'Auf anderem Handy gelöscht';

  @override
  String playGamesRestored(String ago) {
    return 'Aus Cloud geladen · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'In Cloud gesichert · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Play-Spiele-Erfolge';

  @override
  String get playGamesConnectSemantics => 'Play Spiele verbinden';

  @override
  String get playGamesAchievements => 'Erfolge';

  @override
  String get playGamesConnect => 'Verbinden';

  @override
  String get timeAgoJustNow => 'gerade eben';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'vor $minutes min',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'vor $hours h',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'vor $days Tg.',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '+1 LEBEN!';

  @override
  String calloutStarTrio(int points) {
    return 'STERNTRIO +$points!';
  }

  @override
  String get calloutNiceShot => 'VOLLTREFFER!';

  @override
  String calloutNiceShotPoints(int points) {
    return 'VOLLTREFFER +$points!';
  }

  @override
  String get calloutSmash => 'KRACH!';

  @override
  String calloutSmashPoints(int points) {
    return 'KRACH +$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return 'KRACH ×$count!';
  }

  @override
  String get calloutBossDown => 'BOSS BESIEGT!';

  @override
  String calloutBossDownPoints(int points) {
    return 'BOSS K.O. +$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier× STERNENKRAFT!';
  }

  @override
  String get calloutPerfect => 'PERFEKT!';

  @override
  String calloutPerfectChain(int count) {
    return 'PERFEKT ×$count';
  }

  @override
  String get calloutShieldReady => 'SCHILD BEREIT';

  @override
  String get calloutShieldSave => 'SCHILD HÄLT!';

  @override
  String get calloutKeepFlying => 'FLIEG WEITER!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count TORE!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'NOCH $seconds SEKUNDEN',
      one: 'NOCH $seconds SEKUNDE',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => 'STERNMAGNET!';

  @override
  String get calloutSprintRing => 'SPRINTRING!';

  @override
  String calloutRushChain(int count) {
    return 'ANSTURM ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'METEOR +$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return 'KLONK +$points!';
  }

  @override
  String get calloutScorched => 'ANGESENGT!';

  @override
  String get region_jungle => 'Dschungel';

  @override
  String get region_antarctica => 'Antarktis';

  @override
  String get region_aztec => 'Aztekenreich';

  @override
  String get region_paris => 'Paris';

  @override
  String get region_egypt => 'Ägypten';

  @override
  String get region_cyberpunk => 'Cyberpunk-Stadt';

  @override
  String get region_china => 'China';

  @override
  String get region_brazil => 'Brasilien';

  @override
  String get region_newYork => 'New York';

  @override
  String get region_arabia => 'Antikes Arabien';

  @override
  String get region_rome => 'Antikes Rom';

  @override
  String get region_mexico => 'Mexiko';

  @override
  String get region_sea => 'Hohe See';

  @override
  String get boss_baronBat_name => 'Baron Fledermaus';

  @override
  String get boss_spitterBeetle_name => 'Spuckkönig';

  @override
  String get boss_duskMoth_name => 'Dämmerkaiserin';

  @override
  String get boss_pirate_name => 'Piratenkapitän';

  @override
  String get boss_dragon_name => 'Glutdrache';

  @override
  String get boss_kingCoo_name => 'König Gurr';

  @override
  String get boss_searchlightGargoyle_name => 'Scheinwerfer-Wasserspeier';

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
  String get playMode_pushUp => 'Liegestütz-Flug';

  @override
  String get playMode_jump => 'Hüpf & Flieg';

  @override
  String get playMode_touch => 'Tipp & Flieg';

  @override
  String get playMode_squat => 'Hock & Flieg';

  @override
  String get chapter_1_route => 'Die Blätterdach-Route';

  @override
  String get chapter_1_postmark => 'BLÄTTERDACH-ROUTE';

  @override
  String get chapter_1_postcard =>
      'In den Baumkronen landen wieder Briefe! Die Tukane sagen Danke (sehr laut). Die Krone von Baron Fledermaus steht bei uns auf dem Kaminsims.';

  @override
  String get chapter_1_postscript =>
      'Auf der Alten Straße riecht es, als würde etwas brodeln.';

  @override
  String get chapter_2_route => 'Die Alte Straße';

  @override
  String get chapter_2_postmark => 'ALTE STRASSE';

  @override
  String get chapter_2_postcard =>
      'Die Karawanen rollen, und gebraut wird nur noch Minztee. Die Kolbenkrone des Königs ist jetzt unsere Blumenvase.';

  @override
  String get chapter_2_postscript =>
      'Gestern gingen in der Stadt die Laternen aus. Bring Licht mit.';

  @override
  String get chapter_3_route => 'Die Laternenlinie';

  @override
  String get chapter_3_postmark => 'LATERNENLINIE';

  @override
  String get chapter_3_postcard =>
      'Die Laternen leuchten, und die Nachtpost ist hellwach! Paris schickt ein Croissant. New York schickt eine Brezel.';

  @override
  String get chapter_3_postscript => 'Die Hafenglocken läuten nicht mehr.';

  @override
  String get chapter_4_route => 'Die Gezeitenroute';

  @override
  String get chapter_4_postmark => 'GEZEITENROUTE';

  @override
  String get chapter_4_postcard =>
      'Die Hafenglocken läuten wieder für Briefe, nicht für Kanonen. Der Papagei ist geblieben. Er lässt grüßen.';

  @override
  String get chapter_4_postscript =>
      'Es heißt, am Rand der Karte brennt der Himmel.';

  @override
  String get chapter_5_route => 'Der Rand der Karte';

  @override
  String get chapter_5_postmark => 'RAND DER KARTE';

  @override
  String get chapter_5_postcard =>
      'Der Himmel ist klar von Pol zu Pol, und jede Route läuft. Der ganze Himmelsclub ist stolz auf dich.';

  @override
  String get chapter_5_postscript =>
      'Der endlose Himmel wartet, wann immer du bereit bist.';

  @override
  String get level_1_1_name => 'Erste Zustellung';

  @override
  String get level_1_1_cargo => 'Geburtstagskarte für die Tukan-Zwillinge';

  @override
  String get level_1_1_sender => 'Die Tukan-Zwillinge';

  @override
  String get level_1_1_hint => 'Tipp zum Flattern. Flieg durch die Sterne.';

  @override
  String get level_1_2_name => 'Sternenserie';

  @override
  String get level_1_2_cargo => 'Sternkarten fürs Sternengucker-Faultier';

  @override
  String get level_1_2_sender => 'Das Sternengucker-Faultier';

  @override
  String get level_1_2_hint =>
      'Sterne am Stück geben 3×; drei perfekte Tore bringen einen Magneten.';

  @override
  String get level_1_3_name => 'Fledermaus-Patrouille';

  @override
  String get level_1_3_cargo => 'Nachtlichter für die Glühwürmchen-Kita';

  @override
  String get level_1_3_sender => 'Die Glühwürmchen-Kita';

  @override
  String get level_1_3_hint =>
      'Schießen: Tipp auf Schießen, um Fledermäuse k.o. zu schießen.';

  @override
  String get level_1_4_name => 'Karnevalshimmel';

  @override
  String get level_1_4_cargo => 'Federboas für die Karnevalsparade';

  @override
  String get level_1_4_sender => 'Die Samba-Aras';

  @override
  String get level_1_4_hint =>
      'Sturm! Achte auf das ! und weich den Fußbällen aus.';

  @override
  String get level_1_5_name => 'Eilpost';

  @override
  String get level_1_5_cargo => 'Eil-Einladung für den Trommelchef';

  @override
  String get level_1_5_sender => 'Der Trommelchef';

  @override
  String get level_1_5_hint =>
      'Sprint fegt Fledermäuse weg und prescht nach vorn.';

  @override
  String get level_1_6_name => 'Tempeltreppe';

  @override
  String get level_1_6_cargo => 'Kakaobohnen für die Tempelköche';

  @override
  String get level_1_6_sender => 'Die Tempelköche';

  @override
  String get level_1_7_name => 'Morgenrot-Quartier';

  @override
  String get level_1_7_cargo => 'Sonnenuhr für den Hüter der Morgenröte';

  @override
  String get level_1_7_sender => 'Der Hüter der Morgenröte';

  @override
  String get level_1_8_name => 'Baron Fledermaus';

  @override
  String get level_1_8_cargo => 'Letzte Mahnung für Baron Fledermaus';

  @override
  String get level_1_8_sender => 'Baron Fledermaus';

  @override
  String get level_2_1_name => 'Käferstraße';

  @override
  String get level_2_1_cargo => 'Lorbeerkränze für die Wagenlenker';

  @override
  String get level_2_1_sender => 'Die Wagenlenker';

  @override
  String get level_2_1_hint => 'Käfer spucken Kerne. Schieß die Kerne ab.';

  @override
  String get level_2_2_name => 'Versiegelte Tore';

  @override
  String get level_2_2_cargo => 'Neuer Meißel für den Bildhauer';

  @override
  String get level_2_2_sender => 'Der Bildhauer';

  @override
  String get level_2_2_hint =>
      'Halte Schießen gedrückt: Der große Stein bricht Steinplatten.';

  @override
  String get level_2_3_name => 'Lauffeuer-Rennen';

  @override
  String get level_2_3_cargo => 'Wassereimer für die Feuerwehr';

  @override
  String get level_2_3_sender => 'Die Feuerwehr';

  @override
  String get level_2_3_hint =>
      'Flieg durch die goldenen Ringe, um dem Feuer zu entkommen!';

  @override
  String get level_2_4_name => 'Nil-Serpentinen';

  @override
  String get level_2_4_cargo => 'Ein Buch neuer Rätsel für die Sphinx';

  @override
  String get level_2_4_sender => 'Die Sphinx';

  @override
  String get level_2_5_name => 'Himmelssturz';

  @override
  String get level_2_5_cargo => 'Teleskop für den Pyramiden-Astronomen';

  @override
  String get level_2_5_sender => 'Der Pyramiden-Astronom';

  @override
  String get level_2_5_hint => 'Ringsprints zertrümmern Meteore.';

  @override
  String get level_2_6_name => 'Zurück an den Absender';

  @override
  String get level_2_6_cargo => 'Staubwedel für die Hausmeisterin';

  @override
  String get level_2_6_sender => 'Die Pyramiden-Hausmeisterin';

  @override
  String get level_2_6_hint =>
      'Schieß seine Briefe ab, um sie zurückzuschicken. Zurück an den Absender!';

  @override
  String get level_2_7_name => 'Laternenbasar';

  @override
  String get level_2_7_cargo => 'Lampenöl für die Laternenhändler';

  @override
  String get level_2_7_sender => 'Die Laternenhändler';

  @override
  String get level_2_8_name => 'Die lange Karawane';

  @override
  String get level_2_8_cargo => 'Wasserflaschen für die lange Karawane';

  @override
  String get level_2_8_sender => 'Der Karawanenführer';

  @override
  String get level_2_9_name => 'Spuckkönig';

  @override
  String get level_2_9_cargo => 'Brau-Verbot für den Spuckkönig';

  @override
  String get level_2_9_sender => 'Spuckkönig';

  @override
  String get level_3_1_name => 'Mottenlicht';

  @override
  String get level_3_1_cargo => 'Glühbirnen fürs Theatervordach';

  @override
  String get level_3_1_sender => 'Der Bühnenmeister';

  @override
  String get level_3_1_hint =>
      'Falter schießen Dreierfächer. Schlüpf dazwischen durch.';

  @override
  String get level_3_2_name => 'Räder im Regen';

  @override
  String get level_3_2_cargo => 'Schirme für die Kiosktauben';

  @override
  String get level_3_2_sender => 'Die Kiosktauben';

  @override
  String get level_3_2_hint =>
      'Gassentauben stoßen herab und klauen Sterne. Schieß sie zuerst ab!';

  @override
  String get level_3_3_name => 'Dampfgasse';

  @override
  String get level_3_3_cargo => 'Heiße Brezeln für die Nachttaxifahrer';

  @override
  String get level_3_3_sender => 'Die Nachttaxifahrer';

  @override
  String get level_3_3_hint =>
      'Geysire zischen, dann pusten sie. Hüpf über heiße, lass dich von sanften tragen.';

  @override
  String get level_3_4_name => 'Sturmwarnung';

  @override
  String get level_3_4_cargo => 'Wetterhahn für den höchsten Turm';

  @override
  String get level_3_4_sender => 'Der Turmwärter';

  @override
  String get level_3_4_hint =>
      'Bleib aus dem Licht. Schieß auf die Lampe, wenn sie aufgeht! Kein Sprint hier.';

  @override
  String get level_3_5_name => 'Kristalldächer';

  @override
  String get level_3_5_cargo => 'Croissants für die Dachmaler';

  @override
  String get level_3_5_sender => 'Die Dachmaler';

  @override
  String get level_3_6_name => 'Nach dem Sturm';

  @override
  String get level_3_6_cargo => 'Noten für den Akkordeonspieler';

  @override
  String get level_3_6_sender => 'Der Akkordeonspieler';

  @override
  String get level_3_6_hint =>
      'Sturm! Achte auf das ! und nimm die freie Seite.';

  @override
  String get level_3_7_name => 'Mitternachtsexpress';

  @override
  String get level_3_7_cargo => 'Mitternachtsliebesbrief für die Bäckerin';

  @override
  String get level_3_7_sender => 'Die Bäckerin';

  @override
  String get level_3_7_hint => 'Sprinte durch die Schwärme.';

  @override
  String get level_3_8_name => 'Dämmerkaiserin';

  @override
  String get level_3_8_cargo => 'Weckruf für die Dämmerkaiserin';

  @override
  String get level_3_8_sender => 'Dämmerkaiserin';

  @override
  String get level_4_1_name => 'Hafenlichter';

  @override
  String get level_4_1_cargo => 'Neue Linse für die Leuchtturmwärterin';

  @override
  String get level_4_1_sender => 'Die Leuchtturmwärterin';

  @override
  String get level_4_2_name => 'Vulkanpass';

  @override
  String get level_4_2_cargo => 'Ofenhandschuhe für die Vulkanbäckerin';

  @override
  String get level_4_2_sender => 'Die Vulkanbäckerin';

  @override
  String get level_4_2_hint => 'Hüpf über die Lavafontänen.';

  @override
  String get level_4_3_name => 'Die Küste entlang';

  @override
  String get level_4_3_cargo => 'Drachenschnur fürs Strandfest';

  @override
  String get level_4_3_sender => 'Die Drachenflieger';

  @override
  String get level_4_4_name => 'Niedrigwasser';

  @override
  String get level_4_4_cargo => 'Eine Antwort für den Inseleinsiedler';

  @override
  String get level_4_4_sender => 'Der Inseleinsiedler';

  @override
  String get level_4_4_hint => 'Berühr das Wasser nicht.';

  @override
  String get level_4_5_name => 'Springflut';

  @override
  String get level_4_5_cargo => 'Gezeitentafel für die Fährcrew';

  @override
  String get level_4_5_sender => 'Die Fährcrew';

  @override
  String get level_4_5_hint => 'Wenn die Glocke läutet, flieg hoch.';

  @override
  String get level_4_6_name => 'Breitseiten-Bucht';

  @override
  String get level_4_6_cargo => 'Fischkekse für die Möwenkolonie';

  @override
  String get level_4_6_sender => 'Die Möwenkolonie';

  @override
  String get level_4_7_name => 'Stürmische Überfahrt';

  @override
  String get level_4_7_cargo => 'Trockene Socken für die Sturmwache';

  @override
  String get level_4_7_sender => 'Die Sturmwache';

  @override
  String get level_4_8_name => 'Piratenkapitän';

  @override
  String get level_4_8_cargo => 'Rückgabe-Befehl für den Käpt’n';

  @override
  String get level_4_8_sender => 'Piratenkapitän';

  @override
  String get level_5_1_name => 'Polarlicht-Post';

  @override
  String get level_5_1_cargo => 'Wollmützen für den Pinguinchor';

  @override
  String get level_5_1_sender => 'Der Pinguinchor';

  @override
  String get level_5_1_hint =>
      'Jetzt kann jeder Ansturm kommen. Lies das Banner!';

  @override
  String get level_5_2_name => 'Polarnacht';

  @override
  String get level_5_2_cargo => 'Heißer Kakao für die Polarstation';

  @override
  String get level_5_2_sender => 'Die Polarstation';

  @override
  String get level_5_3_name => 'Neon-Express';

  @override
  String get level_5_3_cargo => 'Ersatzsicherungen fürs Nudelbar-Schild';

  @override
  String get level_5_3_sender => 'Der Nudelkoch';

  @override
  String get level_5_4_name => 'Datensturm';

  @override
  String get level_5_4_cargo => 'Papierbrief für einen neugierigen Roboter';

  @override
  String get level_5_4_sender => 'Einheit 7';

  @override
  String get level_5_5_name => 'Skyline-Sprint';

  @override
  String get level_5_5_cargo => 'Renntickets für die Dachläufer';

  @override
  String get level_5_5_sender => 'Die Dachläufer';

  @override
  String get level_5_6_name => 'Laternenfest';

  @override
  String get level_5_6_cargo => 'Papierlaternen für das Fest';

  @override
  String get level_5_6_sender => 'Die Laternenmacher';

  @override
  String get level_5_7_name => 'Die letzte Etappe';

  @override
  String get level_5_7_cargo => 'Bergtee für das Kloster';

  @override
  String get level_5_7_sender => 'Die Bergmönche';

  @override
  String get level_5_8_name => 'Glutdrache';

  @override
  String get level_5_8_cargo => 'Der allererste Brief an den Drachen';

  @override
  String get level_5_8_sender => 'Glutdrache';

  @override
  String get storyPostmasterName => 'Postmeister Bill';

  @override
  String get storySkip => 'Überspringen';

  @override
  String get storyNextLineSemantics => 'Nächste Zeile';

  @override
  String get storyFinishSemantics => 'Beenden';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => 'Jeder Brief kommt an.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => 'Flieg!';

  @override
  String levelIntroRunUp(int seconds) {
    return 'Erst $seconds s Anflug';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'Etwa $seconds s bis ins Ziel';
  }

  @override
  String get campaignGuardian => 'WÄCHTER';

  @override
  String get levelIntroBossFight => 'BOSSKAMPF';

  @override
  String get levelIntroNew => 'NEU';

  @override
  String get levelIntroTip => 'TIPP';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Besiege den $boss',
      'spitterBeetle': 'Besiege den $boss',
      'duskMoth': 'Besiege die $boss',
      'pirate': 'Besiege den $boss',
      'dragon': 'Besiege den Glutdrachen',
      'searchlightGargoyle': 'Besiege den $boss',
      'other': 'Besiege $boss',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroGoalFinish => 'Erreiche das Ziel';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sammle $count Sterne',
      one: 'Sammle 1 Stern',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Ein Stern: $goal.',
      'two': 'Zwei Sterne: $goal.',
      'other': 'Drei Sterne: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Ein Stern: $goal. Erreicht.',
      'two': 'Zwei Sterne: $goal. Erreicht.',
      'other': 'Drei Sterne: $goal. Erreicht.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bestwert: $count Sterne',
      one: 'Bestwert: 1 Stern',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'Noch nicht zugestellt';

  @override
  String get levelIntroFirstFlight => 'Erster Flug';

  @override
  String get levelIntroControlFlap => 'Flattern';

  @override
  String get levelIntroControlShoot => 'Schießen';

  @override
  String get levelIntroControlSprint => 'Sprint';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Steuerung: Flattern.',
      'shoot': 'Steuerung: Flattern, Schießen.',
      'sprint': 'Steuerung: Flattern, Sprint.',
      'other': 'Steuerung: Flattern, Schießen, Sprint.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => 'SONDERZUSTELLUNG';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return 'Sonderzustellung: $cargo.';
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
    return 'Level $level, $name. $region. Wächter-Level: $boss.';
  }

  @override
  String get levelIntroStory => 'Geschichte';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonHome => 'Hauptmenü';

  @override
  String get commonBackHome => 'Zum Hauptmenü';

  @override
  String get campaignComingSoon => 'Demnächst';

  @override
  String campaignStopComingSoon(String region) {
    return '$region – demnächst';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Besiege den $boss zum Freischalten',
      'spitterBeetle': 'Besiege den $boss zum Freischalten',
      'duskMoth': 'Besiege die $boss zum Freischalten',
      'pirate': 'Besiege den $boss zum Freischalten',
      'dragon': 'Besiege den Glutdrachen zum Freischalten',
      'searchlightGargoyle': 'Besiege den $boss zum Freischalten',
      'other': 'Besiege $boss zum Freischalten',
    });
    return '$_temp0';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'Schaffe $level zum Freischalten';
  }

  @override
  String get campaignMapUnavailable => 'Die Karte braucht noch kurz.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return '$name schließen';
  }

  @override
  String get campaignMapPreviousStop => 'Vorheriger Halt';

  @override
  String get campaignMapNextStop => 'Nächster Halt';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. Kapitel $chapter, $route. Demnächst.',
      'locked': '$region. Kapitel $chapter, $route. Gesperrt.',
      'other': '$region. Kapitel $chapter, $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return 'KAPITEL $chapter · $route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level, $name, Boss',
      'guardian': 'Level $level, $name, Wächter $boss',
      'other': 'Level $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. Gesperrt.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. Gesperrt. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars von 3 Sternen',
    );
    return '$node. Als Nächstes. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars von 3 Sternen',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'Wasserspeier',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return 'Postkarte von Kapitel $chapter';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars von $total Kampagnensternen',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'Hallo, Kurier,';

  @override
  String get campaignPostcardPs => 'P.S.';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'Postkarte: $route. Hallo, Kurier, $body P.S. $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'Herzliche Grüße';

  @override
  String get campaignPostcardHeader => 'HIMMELSCLUB-POSTKARTE';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'An den Kurier';

  @override
  String get campaignPostcardAddressStreet => 'Himmelsclub-Post';

  @override
  String get campaignPostcardAddressCity => 'Hoch am Himmel';

  @override
  String get campaignPostmarkDelivered => 'ZUGESTELLT';

  @override
  String get campaignPostmarkClub => 'HIMMELSCLUB-POST';

  @override
  String get campaignStampSkyClub => 'HIMMELSCLUB';

  @override
  String campaignThanksQuoted(String thanks) {
    return '„$thanks“';
  }

  @override
  String campaignThanksSignature(String sender) {
    return '— $sender';
  }

  @override
  String campaignThanksSemantics(String sender, String thanks) {
    return 'Dankeskarte – $sender: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'Kurz einrichten. Viel Himmel.';

  @override
  String get flightSetupTitleSquat => 'Füße fest. Flügel auf.';

  @override
  String get flightSetupTitleJump => 'Kleine Sprünge. Große Flügel.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'LEVEL · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · GEWERTET';
  }

  @override
  String get flightSetupRoomPushUp => 'Mach ein wenig Platz zum Bewegen.';

  @override
  String get flightSetupRoomBody => 'Zeig deinen ganzen Körper.';

  @override
  String get flightSetupTipsPushUp =>
      'Handy tief. Zeig einen Arm und die Hüfte.\nFrontal? Halte beide Schultern im Bild.';

  @override
  String get flightSetupTipsSquat =>
      'Hock dich hin zum Sinken. Steh auf zum Steigen.\nBeide Füße bleiben am Boden.';

  @override
  String get flightSetupTipsJump =>
      'Spring für Schub + 3 s Gleiten.\nLande, bevor du wieder springst.';

  @override
  String get flightSetupHowToFly => 'SO FLIEGST DU';

  @override
  String get flightSetupStep1PushUp => 'Zeig Arm und Hüfte';

  @override
  String get flightSetupStep1Squat => 'Platz für Kniebeugen';

  @override
  String get flightSetupStep1Jump => 'Platz zum Springen';

  @override
  String get flightSetupStep1DetailPushUp =>
      'Frontal zum Handy? Zeig beide Schultern, einen Arm und eine Hüfte.';

  @override
  String get flightSetupStep1DetailBody =>
      'Handy quer. Zeig deinen Körper und beide Füße.';

  @override
  String get flightSetupStep2PushUp => 'Finde deinen Bewegungsbereich';

  @override
  String get flightSetupStep2Squat => 'Finde deine bequeme Hocke';

  @override
  String get flightSetupStep2Jump => 'Steh gerade und still';

  @override
  String get flightSetupStep2DetailPushUp =>
      'Geh bequem in den Stütz, dann zweimal runter und hoch.';

  @override
  String get flightSetupStep2DetailSquat =>
      'Steh still, geh in die Hocke, halte kurz und steh wieder auf.';

  @override
  String get flightSetupStep2DetailJump =>
      'Halte kurz still. Dann spring für viel Schub.';

  @override
  String get flightSetupStep3Stars => 'Sammle Sterne';

  @override
  String get flightSetupStep3DetailJump =>
      'Sterne geben 0,75 s Gleiten, bis 5 s. Sammle Sterntrios für +5 Punkte.';

  @override
  String get flightSetupLivesEndless =>
      'Drei Herzen + ein Schild. Du kannst jederzeit pausieren.';

  @override
  String get flightSetupLivesClassic =>
      'Ein Zusammenstoß oder eine verlorene Position beendet einen gewerteten Flug. Du kannst jederzeit pausieren.';

  @override
  String get flightSetupCameraButton => 'Kamera einrichten';

  @override
  String get flightMicTitle => 'Mikrofon aufnehmen';

  @override
  String get flightMicOn => 'An';

  @override
  String get flightMicOptional => 'Optional';

  @override
  String get flightMicDetail =>
      'Deine Stimme und der Raumklang kommen in die Wiederholungen. Das Mikrofon läuft nur im Flug. Alles bleibt auf diesem Handy.';

  @override
  String get flightMicSemantics => 'Mikrofon für Wiederholungen aufnehmen';

  @override
  String get flightMicSettings => 'Mikrofon-Einstellungen';

  @override
  String get flightCalibrationTitleReady => 'Du hast deine Flügel gefunden!';

  @override
  String get flightCalibrationTitleWaking => 'Deine Kamera wacht auf…';

  @override
  String get flightCalibrationTitleError => 'Verbinden wir deine Kamera neu.';

  @override
  String get flightCalibrationTitleRange => 'Finde deinen Bewegungsbereich.';

  @override
  String get flightCalibrationTitleStill => 'Steh gerade und still.';

  @override
  String get flightCalibrationStepTry => 'Beweg mal deinen Vogel.';

  @override
  String get flightCalibrationStepTop => 'Geh bequem in den Stütz.';

  @override
  String get flightCalibrationStepLower => 'Lass dich langsam runter.';

  @override
  String get flightCalibrationStepPushBack => 'Drück dich wieder hoch.';

  @override
  String get flightCalibrationStepStill => 'Steh gerade und still.';

  @override
  String get flightCalibrationStepSquat => 'Geh bequem in die Hocke.';

  @override
  String get flightCalibrationStepStandUp => 'Steh wieder auf.';

  @override
  String get flightCalibrationStepDone => 'Du hast deine Flügel gefunden!';

  @override
  String get flightCalibrationReadyPushUp =>
      'Drück dich hoch zum Steigen. Runter zum Gleiten.';

  @override
  String get flightCalibrationReadySquat =>
      'Hock dich hin zum Sinken. Steh auf zum Steigen.';

  @override
  String get flightCalibrationReadyJump =>
      'Spring, dann ruh dich aus, während dein Vogel gleitet.';

  @override
  String get flightCalibrationKeepPushUp =>
      'Halte Schultern, einen Arm und eine Hüfte im Bild. Beweg dich bequem.';

  @override
  String get flightCalibrationKeepBody =>
      'Halte Schultern, Hüften und beide Füße im Bild.';

  @override
  String get flightCalibrationLearning => 'Lerne deinen Bereich beim Bewegen.';

  @override
  String get flightCalibrationAfter =>
      'Nach dem Kalibrieren fliegt dein Vogel.';

  @override
  String get flightCalibrationJump => 'Spring!';

  @override
  String get flightCalibrationTagCheck => 'STEUERUNGSTEST';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '$count/2 LIEGESTÜTZE';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '$percent % KALIBRIERT';
  }

  @override
  String get flightCalibrationTakeoff => 'Bereit zum Abheben';

  @override
  String get flightCalibrationStarting => 'Startet…';

  @override
  String get flightCalibrationRestart => 'Neu kalibrieren';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate Updates/s · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate Updates/s · $p95 ms p95 (nur Verarbeitung)';
  }

  @override
  String get flightCalibrationStatusReady => 'BEREIT';

  @override
  String get flightCalibrationStatusStarting => 'STARTET';

  @override
  String get flightCalibrationStatusCameraOff => 'KAMERA AUS';

  @override
  String get flightCalibrationStatusCalibrating => 'KALIBRIERUNG';

  @override
  String get flightSwitchCameraSemantics => 'Kamera wechseln';

  @override
  String get flightCalibrationStepIntoView => 'Stell dich ins Bild';

  @override
  String get flightCameraTroubleTitle => 'Ein Neustart hilft meistens.';

  @override
  String get flightCameraTroubleAllow =>
      'Erlaube den Kamerazugriff in den Einstellungen.';

  @override
  String get flightCameraTroubleClose =>
      'Schließ andere Kamera-Apps und versuch es noch mal.';

  @override
  String get flightCameraPermissionSemantics =>
      'Einstellungen für die Kamera-Berechtigung';

  @override
  String get flightNoteRememberFailed =>
      'Für diesen Flug geändert. Deine Wahl konnte nicht gespeichert werden.';

  @override
  String get flightNoteMicUnavailable =>
      'Mikrofon nicht verfügbar. Video und Spiel laufen trotzdem.';

  @override
  String get flightNoteMicBlocked =>
      'Mikrofon blockiert. Du kannst es in den Einstellungen erlauben; Video geht trotzdem.';

  @override
  String get flightNoteMicOff =>
      'Mikrofon aus. Du kannst trotzdem spielen und Videos speichern.';

  @override
  String get flightNoteVideoUnavailable =>
      'Kameravideo nicht verfügbar. Der Spielverlauf kann trotzdem gespeichert werden.';

  @override
  String get flightNoteMicAudioLost =>
      'Der Mikrofonton war nicht verfügbar. Video und Spielverlauf können trotzdem gespeichert werden.';

  @override
  String get flightNoteVideoInterrupted =>
      'Kameravideo unterbrochen. Vorhandene Aufnahmen und Spielverlauf können trotzdem gespeichert werden.';

  @override
  String get flightNoteSessionSaveFailed =>
      'Flug nicht gespeichert. Tipp auf „Flug speichern“ für einen neuen Versuch.';

  @override
  String get flightNoteWakingCamera => 'Deine Kamera wacht auf…';

  @override
  String get flightNoteCameraOff =>
      'Kamerazugriff ist aus. Erlaube ihn in den Android-Einstellungen, komm zurück und versuch es noch mal.';

  @override
  String get flightNoteCameraFailed =>
      'Die Kamera konnte nicht starten. Versuch es noch mal oder wechsle die Kamera.';

  @override
  String get flightNotePreparing => 'Dein Flug wird vorbereitet…';

  @override
  String get flightNoteSaveFailed =>
      'Dein Flug wurde nicht gespeichert. Tipp für einen neuen Versuch.';

  @override
  String get flightNoteWelcomeBack =>
      'Willkommen zurück. Prüfen wir noch mal deine Position.';

  @override
  String get flightNoteCameraInterrupted =>
      'Kamera unterbrochen. Prüf die Kamera-Berechtigung und versuch es noch mal.';

  @override
  String get flightNoteTrackingInterrupted => 'Tracking unterbrochen';

  @override
  String get flightFindPosition => 'Finde deine Position';

  @override
  String get flightTapSemantics => 'Tipp zum Flattern';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'Tipp zum Flattern. Vorhut des Bosses im Anflug: $group';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'Tipp zum Flattern. $boss: $hp von $maxHp Lebenspunkten';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'Tipp zum Flattern. $boss: $hp von $maxHp Lebenspunkten. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'Zu den Ergebnissen';

  @override
  String get hudPauseSemantics => 'Flug pausieren';

  @override
  String get flightHintTestSteerKeys =>
      'Testflug: Steuern mit Pfeil hoch und runter.';

  @override
  String get flightHintTestSteerDrag =>
      'Testflug: Zum Steuern hoch und runter ziehen.';

  @override
  String get flightHintTestJumpKeys => 'Testflug: Leertaste zum Springen.';

  @override
  String get flightHintTestJumpTap => 'Testflug: Tippen zum Springen.';

  @override
  String get flightHintKeysStars =>
      'Leertaste zum Flattern. Flieg durch die Sterne.';

  @override
  String get flightHintKeysShoot =>
      'Leertaste zum Flattern. Halte D, um einen Schuss aufzuladen.';

  @override
  String get flightHintKeysCombat =>
      'Leertaste zum Flattern. Halte D zum Aufladen. A zum Sprinten!';

  @override
  String get flightHintKeysPause => 'Leertaste zum Flattern. Esc pausiert.';

  @override
  String get flightHintTapStars =>
      'Tipp in den Himmel zum Flattern. Flieg durch die Sterne.';

  @override
  String get flightHintTapShoot =>
      'Tipp in den Himmel zum Flattern. Halte Schießen zum Aufladen.';

  @override
  String get flightHintTapCombat =>
      'Tipp in den Himmel zum Flattern. Halte Schießen zum Aufladen. Sprint zum Rammen!';

  @override
  String get flightHintTapRelease =>
      'Tippen zum Flattern. Zwischen den Tipps loslassen.';

  @override
  String get flightHintTrail => 'Folge den Sternen. Dein Schild ist bereit.';

  @override
  String get flightHintSky => 'Der Himmel gehört dir.';

  @override
  String hudClockSemantics(String time) {
    return 'Noch $time';
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
      other: 'Sternmagnet: noch $seconds Sekunden',
      one: 'Sternmagnet: noch $seconds Sekunde',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Magnet lädt: $charge von $gates perfekten Toren',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'Suche dich…';

  @override
  String get hudShoot => 'Schießen';

  @override
  String get hudSprint => 'Sprint';

  @override
  String get flightTestNothingSaved => 'ohne Speichern';

  @override
  String get flightCountdownReady => 'Achtung, fertig…';

  @override
  String get flightPauseTitle => 'Kurz verschnaufen.';

  @override
  String get flightPauseKeepFlying => 'Weiterfliegen';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. Dein Vogel sitzt und wartet.';
  }

  @override
  String flightPausedTest(String name) {
    return 'Testflug von $name. Nichts wird gespeichert.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. Dein Vogel sitzt und wartet.';
  }

  @override
  String get flightPausedTouch =>
      'Dein Vogel sitzt und wartet. Wir zählen dich wieder rein.';

  @override
  String get flightPausedCamera =>
      'Schüttel dich kurz aus und geh zurück in Position. Wir zählen dich rein.';

  @override
  String get flightPauseEdit => 'Bearbeiten';

  @override
  String get flightPauseBuilder => 'Baukasten';

  @override
  String get flightPauseFinish => 'Flug beenden';

  @override
  String get hudShieldRecovering => 'Erholt sich';

  @override
  String get hudShieldReady => 'Schild bereit';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Schild lädt: $charge von $stars Sternen',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Herzen',
      one: 'Noch $count Herz',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'Sprintet';

  @override
  String get hudSprintReady => 'Bereit';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Lädt auf, $seconds Sekunden',
      one: 'Lädt auf, $seconds Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint =>
      'Prescht voran und rammt Fledermäuse und Steinplatten weg';

  @override
  String get hudShotReloading => 'Lädt nach…';

  @override
  String hudShotFullCharge(int ms) {
    return 'Voll aufgeladen, noch $ms ms';
  }

  @override
  String hudShotCharging(int percent) {
    return 'Lädt $percent %';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'Munition $percent %';
  }

  @override
  String get hudShotHint => 'Halten, um einen größeren Stein aufzuladen';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne erreicht',
      one: '$count Stern erreicht',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne bei $at',
      one: '$count Stern bei $at',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars Sterne gesammelt',
      one: '$stars Stern gesammelt',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'MAX';

  @override
  String hudRouteSemantics(int percent) {
    return 'Route zu $percent % geflogen';
  }

  @override
  String hudGlideCompact(String time) {
    return 'Gleiten · $time';
  }

  @override
  String get hudJumpToGlide => 'Spring & gleite';

  @override
  String get hudJump => 'Spring';

  @override
  String hudGlideSemantics(String time) {
    return 'Gleiten, noch $time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'Gleiten endet, noch $time';
  }

  @override
  String get hudJumpChargeSemantics =>
      'Spring, um 3 Sekunden Gleiten aufzuladen';

  @override
  String get hudRecordNewBest => 'Neuer Rekord!';

  @override
  String get hudRecordMatched => 'Gleichstand!';

  @override
  String hudRecordBest(int best) {
    return 'Bestwert $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '+$points über dem Bestwert';
  }

  @override
  String get hudRecordOneMore => 'Noch 1 bis zum Rekord';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count bis zum Rekord',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'Punkte: $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'Punkte: $score, $multiplier-facher Multiplikator';
  }

  @override
  String get commonBusySemantics => 'Beschäftigt';

  @override
  String get flightResultBumpClouds => 'Ein kleiner Rempler in den Wolken.';

  @override
  String get flightResultPersonalBest => 'DEIN BESTWERT';

  @override
  String get flightResultNewPersonalBest => 'NEUER BESTWERT!';

  @override
  String get flightResultStarsCollected => 'GESAMMELTE STERNE';

  @override
  String get flightResultDailyStamped => 'Heutige Postkarte gestempelt!';

  @override
  String flightResultNextStamp(String stamp) {
    return 'Als Nächstes: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'Auf diesem Handy gespeichert';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Gespeichert · $total Tore insgesamt',
      one: 'Gespeichert · $total Tor insgesamt',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'Dein Flug wird gespeichert…';

  @override
  String get flightResultSessionSaved => 'Flug gespeichert · Siehe Rekorde';

  @override
  String get flightResultWatchReplay => 'Nochmal ansehen';

  @override
  String get flightResultPreparing => 'Vorbereiten…';

  @override
  String get flightResultSavingShort => 'Speichert…';

  @override
  String get flightResultSaveSession => 'Flug speichern';

  @override
  String get flightResultFlyAgain => 'Nochmal fliegen';

  @override
  String get commonRetry => 'Nochmal';

  @override
  String get commonMap => 'Karte';

  @override
  String get commonNext => 'Weiter';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liegestütze',
      one: 'Liegestütz',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kniebeugen',
      one: 'Kniebeuge',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprünge',
      one: 'Sprung',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flügelschläge',
      one: 'Flügelschlag',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'Flugzeit';

  @override
  String get flightStatPerfect => 'perfekt';

  @override
  String get flightStatBestStreak => 'beste Serie';

  @override
  String get flightStatRank => 'Rang';

  @override
  String get flightRankSkyCaptain => 'Himmelskapitän';

  @override
  String get flightRankCloudExplorer => 'Wolkenforscher';

  @override
  String get flightRankFirstWings => 'Erste Flügel';

  @override
  String flightPercent(int percent) {
    return '$percent %';
  }

  @override
  String get gameOverCaptionBest => 'Rausgerempelt, aber mit neuem Rekord!';

  @override
  String get gameOverCaptionSea => 'Ein kleiner Platscher ins Meer.';

  @override
  String get gameOverSplash => 'Platsch!';

  @override
  String get gameOverBonk => 'Klonk!';

  @override
  String get gameOverEveryMarkSemantics => 'Alle Sternmarken erreicht';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Sterne für $mark Sterne',
      one: 'Noch $count Stern für $mark Sterne',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: noch $hp von $maxHp Lebenspunkten';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '$percent Prozent der Route geflogen';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: NOCH $hp LP';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$boss: LEBEN ÜBRIG';
  }

  @override
  String get gameOverRouteFlown => 'ROUTE GEFLOGEN';

  @override
  String gameOverHp(int hp) {
    return '$hp LP';
  }

  @override
  String gameOverMoreFor(int count) {
    return 'Noch $count für';
  }

  @override
  String get gameOverBothMarks => 'Beide Marken erreicht';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'searchlightGargoyle': 'Marken erreicht. Besiege den $boss!',
      'other': 'Marken erreicht. Besiege $boss!',
    });
    return '$_temp0';
  }

  @override
  String get miniResultTitle => 'Jeder Flug zählt.';

  @override
  String get miniResultComplete => 'FLUG GESCHAFFT';

  @override
  String get miniResultCheerBest => 'Was für ein Flug!';

  @override
  String get miniResultCheerComplete => 'Flug geschafft!';

  @override
  String get miniResultCheerNice => 'Schön geflogen.';

  @override
  String get miniResultNew => 'NEU';

  @override
  String get flightEndTrackingLost =>
      'Wir haben dich kurz aus den Augen verloren.';

  @override
  String get flightEndPostureLost => 'Deine Position war außer Reichweite.';

  @override
  String get flightEndBackgrounded => 'Du hast den Himmel kurz verlassen.';

  @override
  String get flightEndBreak => 'Eine wohlverdiente Verschnaufpause.';

  @override
  String get flightEndQuit => 'Bis zum nächsten Abenteuer.';

  @override
  String get flightEndStalled => 'Das Spiel wurde unterbrochen.';

  @override
  String get flightEndCompleted =>
      'Ein ganzer Himmel voller Sterne. Alles deins.';

  @override
  String get levelResultTryAgain => 'Nochmal!';

  @override
  String get levelResultVictory => 'Sieg!';

  @override
  String get levelResultGuardianDown => 'Wächter besiegt!';

  @override
  String get levelResultDelivered => 'Zugestellt!';

  @override
  String levelResultComingSoon(String region) {
    return '$region kommt bald!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned von 3 Sternen';
  }

  @override
  String levelResultBest(int best) {
    return 'Bestwert $best';
  }

  @override
  String get levelResultNoBest => 'Kein Bestwert';

  @override
  String get levelResultFirstClear => 'Premiere!';

  @override
  String get levelResultNewBest => 'NEUER REKORD!';

  @override
  String get levelResultScore => 'PUNKTE';

  @override
  String get levelResultGoalBoss => 'Boss';

  @override
  String get levelResultGoalGuardian => 'Wächter';

  @override
  String get levelResultGoalFinish => 'Ziel';

  @override
  String get levelResultGoalDone => 'Geschafft';

  @override
  String get levelResultGoalNotYet => 'Noch nicht';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'Erst ins Ziel';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. Geschafft.';
  }

  @override
  String get levelResultPostcardWaiting =>
      'Auf der Karte wartet eine Postkarte!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '$id $name ist offen!';
  }

  @override
  String get levelResultReachFinish => 'Erreiche das Ziel für Sterne.';

  @override
  String get course_classic_title => 'Klassisch';

  @override
  String get course_starTrail_title => 'Endlos';

  @override
  String get course_classic_instructions =>
      'Finde die Lücken. Folge den Zielmarken für einen perfekten Durchflug.';

  @override
  String get course_starTrail_instructions =>
      'Sammle alle 3 Sterne einer Gruppe für +5. Sterne am Stück geben bis zu 3×. Sterne laden dein Schild auf; perfekte Tore bringen einen Sternmagneten. Verbessere beides mit Sternen!';

  @override
  String get course_classic_scoreLabel => 'HINDERNISSE';

  @override
  String get course_starTrail_scoreLabel => 'STERNPUNKTE';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tore',
      one: 'Tor',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sternpunkte',
      one: 'Sternpunkt',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics =>
      'Klassisch: Flieg durch die Lücken.';

  @override
  String get course_starTrail_previewSemantics =>
      'Endlos: Sammle Sterne mit drei Herzen und einem Schild.';

  @override
  String get obstacle_garden_name => 'Gartentor';

  @override
  String get obstacle_windLift_name => 'Aufwindtor';

  @override
  String get obstacle_petalGate_name => 'Blütenklappen';

  @override
  String get obstacle_switchback_name => 'Serpentine';

  @override
  String get obstacle_lanternDrift_name => 'Laternentreiben';

  @override
  String get obstacle_sunWheels_name => 'Sonnenräder';

  @override
  String get obstacle_crystalSteps_name => 'Kristallstufen';

  @override
  String get rush_wildfire_name => 'Lauffeuer';

  @override
  String get rush_wildfire_escape => 'Dem Lauffeuer entkommen';

  @override
  String get rush_skyfall_name => 'Himmelssturz';

  @override
  String get rush_skyfall_escape => 'Himmelssturz überlebt';

  @override
  String get rush_eruption_name => 'Ausbruch';

  @override
  String get rush_eruption_escape => 'Ausbruch überstanden';

  @override
  String get rush_swarm_name => 'Schwarm';

  @override
  String get rush_swarm_escape => 'Durch den Schwarm gepflügt';

  @override
  String get boss_baronBat_title => 'HERR DES STURMS';

  @override
  String get boss_spitterBeetle_title => 'BRAUMEISTER DES SCHWARMS';

  @override
  String get boss_duskMoth_title => 'HÜTERIN DES DÄMMERSCHLEIERS';

  @override
  String get boss_pirate_title => 'SCHRECKEN DER FLUT';

  @override
  String get boss_dragon_title => 'HERRSCHER DES BRENNENDEN HIMMELS';

  @override
  String get boss_kingCoo_title => 'KOMMISSAR VOM KANTSTEIN';

  @override
  String get boss_searchlightGargoyle_title => 'WÄCHTER DES HÖCHSTEN TURMS';

  @override
  String get boss_neferhoo_title => 'HÜTER DES VERLORENEN BRIEFS';

  @override
  String get boss_baronBat_returnTitle => 'DER STURM KEHRT ZURÜCK';

  @override
  String get boss_baronBat_barName => 'BARON FLEDERMAUS';

  @override
  String get boss_spitterBeetle_barName => 'SPUCKKÖNIG';

  @override
  String get boss_duskMoth_barName => 'DÄMMERKAISERIN';

  @override
  String get boss_pirate_barName => 'PIRATENKAPITÄN';

  @override
  String get boss_dragon_barName => 'GLUTDRACHE';

  @override
  String get boss_kingCoo_barName => 'KÖNIG GURR';

  @override
  String get boss_searchlightGargoyle_barName => 'WASSERSPEIER';

  @override
  String get boss_neferhoo_barName => 'NEFERHOO';

  @override
  String get vanguard_baronBat_title => 'DIE FLEDERMÄUSE DES BARONS';

  @override
  String get vanguard_baronBat_call =>
      'Da kommen sie! Der Baron ist direkt dahinter.';

  @override
  String get vanguard_spitterBeetle_title => 'DIE BRUT DES SPUCKKÖNIGS';

  @override
  String get vanguard_spitterBeetle_call =>
      'Da kommen sie! Der Spuckkönig ist direkt dahinter.';

  @override
  String get vanguard_duskMoth_title => 'DIE FALTER DER DÄMMERKAISERIN';

  @override
  String get vanguard_duskMoth_call =>
      'Da kommen sie! Die Kaiserin ist direkt dahinter.';

  @override
  String get vanguard_kingCoo_title => 'KÖNIG GURRS STAFFEL';

  @override
  String get vanguard_kingCoo_call =>
      'Da kommen sie! König Gurr ist direkt dahinter.';

  @override
  String get vanguard_kingCoo_callCrusts =>
      'Da kommen sie! Weich den Brotkrusten aus!';

  @override
  String get vanguard_kingCoo_callReturns =>
      'Weich den Krusten aus! Wer entwischt, kommt zurück!';

  @override
  String get bossVanguardClear => 'FREI!';

  @override
  String get bossVanguardLeft => 'ÜBRIG';

  @override
  String get bossStragglersCaught => 'ALLE ERWISCHT!';

  @override
  String get bossHint_strongerBaronBat =>
      'STÄRKER · Dreifachschüsse, und seine Fledermäuse mischen mit!';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'STÄRKER · Volle Fächer, und seine Käfer mischen mit!';

  @override
  String get bossHint_strongerDuskMoth =>
      'STÄRKER · Siebenerfächer, und ihre Falter mischen mit!';

  @override
  String get bossHint_strongerPirate => 'STÄRKER · Die Flut steigt!';

  @override
  String get bossHint_strongerDragon =>
      'STÄRKER · Achte auf Drachenatem und Schwärme!';

  @override
  String get bossHint_strongerKingCoo =>
      'STÄRKER · Er pfeift seine Staffel herbei!';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'STÄRKER · Federn fallen bei offener Lampe!';

  @override
  String get bossHint_strongerGargoyle => 'STÄRKER · Steinfedern fallen!';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'STÄRKER · Das Anch – und seine Mumienfledermäuse!';

  @override
  String get bossHint_strongerNeferhoo =>
      'STÄRKER · Das goldene Anch kommt zurück!';

  @override
  String get bossHint_tideRising => 'FLUT STEIGT · Flieg hoch!';

  @override
  String get bossHint_highTide => 'HOCHWASSER · Bleib über dem Wasser';

  @override
  String get bossHint_tideFury => 'ZORN · Breitseiten zwischen den Flutwellen';

  @override
  String get bossHint_tideCalm =>
      'Weich den Kanonenkugeln aus · Bleib aus dem Wasser';

  @override
  String get bossHint_dragonSwarm =>
      'SCHWARM · Weich den Fledermäusen aus oder sprinte durch';

  @override
  String get bossHint_dragonFuryDebut => 'ZORN · Schnellere Feuerbälle';

  @override
  String get bossHint_dragonFury => 'ZORN · Feuerbälle zerplatzen zu Glut';

  @override
  String get bossHint_dragonCalm =>
      'Weich den Feuerbällen aus · Achte auf den Drachenatem';

  @override
  String get bossHint_screechFury =>
      'ZORN · Schnellere Feuerbälle, mehr Fledermäuse';

  @override
  String get bossHint_screechCalm =>
      'Weich Feuerbällen und Fledermäusen aus · Achte auf das Kreischen';

  @override
  String get bossHint_cooPopped => 'PLOPP! · Keine Staffel';

  @override
  String get bossHint_cooSquadron => 'STAFFEL · Folge der freien Bahn!';

  @override
  String get bossHint_cooPuffed =>
      'AUFGEPLUSTERT · Schieß auf seine Brust (x2)!';

  @override
  String get bossHint_cooCrumbBomb => 'KRÜMELBOMBE · Raus aus dem Ring!';

  @override
  String get bossHint_cooFury => 'ZORN · Bleib zwischen den Ringen';

  @override
  String get bossHint_cooCalm =>
      'Weich den Krümelbomben aus · Schieß auf seine Brust, wenn er sich aufplustert';

  @override
  String get bossHint_beamOn => 'LICHTSTRAHL · Bleib im Dunkeln';

  @override
  String get bossHint_beamFury => 'ZORN · Schlüpf zwischen den Strahlen durch';

  @override
  String get bossHint_beamIncomingHigh => 'LICHTSTRAHL KOMMT · Flieg tief!';

  @override
  String get bossHint_beamIncomingLow => 'LICHTSTRAHL KOMMT · Flieg hoch!';

  @override
  String get bossHint_lampOpen => 'LAMPE OFFEN · Schieß auf die Lampe!';

  @override
  String get bossHint_shuttersClosed => 'KLAPPEN ZU · Spar dir die Schüsse';

  @override
  String get bossHint_mothFuryNoVeil =>
      'ZORN · Siebenerfächer. Noch kein Schleier!';

  @override
  String get bossHint_mothNoVeil =>
      'Noch kein Schleier · Schieß zwischen den Fächern!';

  @override
  String get bossHint_mothShielded =>
      'GESCHÜTZT · Ausweichen, bis der Schleier fällt';

  @override
  String get bossHint_mothShieldForming =>
      'SCHILD ENTSTEHT · Mach dich bereit auszuweichen';

  @override
  String get bossHint_mothFury =>
      'ZORN · Siebenerfächer. Der Schleier ist weg!';

  @override
  String get bossHint_mothCalm =>
      'Schleier ist weg · Schieß zwischen den Fächern!';

  @override
  String get bossHint_neferhooMailCall => 'POST IST DA! · Schieß sie zurück!';

  @override
  String get bossHint_neferhooReturn => 'ZURÜCK AN DEN ABSENDER! · −25';

  @override
  String get bossHint_neferhooReturnFaster => 'ZURÜCK AN DEN ABSENDER! · −18';

  @override
  String get bossHint_neferhooAnkh => 'DAS ANCH · Es kommt zurück!';

  @override
  String get bossHint_neferhooExpress => 'EILPOST · Fünf Briefe, schneller';

  @override
  String get bossHint_neferhooTwoAnkhs => 'ZWEI ANCHS · Weg von beiden Bahnen';

  @override
  String get bossHint_neferhooBats => 'MUMIENFLEDERMÄUSE · Schieß sie ab!';

  @override
  String get bossHint_neferhooScuff =>
      'Steine kratzen nur an seinen Binden. Schieß seine BRIEFE zurück!';

  @override
  String get bossHint_neferhooWarmUp =>
      'Schieß seine Briefe zurück · Zurück an den Absender';

  @override
  String get bossHint_neferhooCalm =>
      'Schieß seine Briefe zurück · Weich dem goldenen Anch aus';

  @override
  String get bossHint_neferhooFury => 'ZORN · Eilpost und zwei Anchs';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'DRACHENATEM · Flieg tief! Sein Herz ist offen',
      'middle': 'DRACHENATEM · Steig oder tauch ab! Sein Herz ist offen',
      'other': 'DRACHENATEM · Flieg hoch! Sein Herz ist offen',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'FEUER · Flieg tief! Triff das glühende Herz',
      'middle': 'FEUER · Steig oder tauch ab! Triff das glühende Herz',
      'other': 'FEUER · Flieg hoch! Triff das glühende Herz',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'SCHALLKREISCHEN · Flieg zur oberen Lücke!',
      'middle': 'SCHALLKREISCHEN · Flieg zur mittleren Lücke!',
      'other': 'SCHALLKREISCHEN · Flieg zur unteren Lücke!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'KREISCHEN · Bleib in der oberen Lücke',
      'middle': 'KREISCHEN · Bleib in der mittleren Lücke',
      'other': 'KREISCHEN · Bleib in der unteren Lücke',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'WEICH DEN FÄCHERN AUS  ·  SCHIESS, WENN DER SCHLEIER FÄLLT';

  @override
  String get encounterCaption_pirate =>
      'WEICH DER KANONE AUS  ·  BLEIB AUS DEM WASSER';

  @override
  String get encounterCaption_dragon =>
      'WEICH DEN FEUERBÄLLEN AUS  ·  ENTKOMM DEM DRACHENATEM';

  @override
  String get encounterCaption_kingCoo =>
      'RAUS AUS DEN RINGEN  ·  SCHIESS AUF DIE PLUSTERBRUST';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'BLEIB AUS DEM LICHT  ·  SCHIESS AUF DIE OFFENE LAMPE';

  @override
  String get encounterCaption_neferhoo =>
      'MACH DICH BEREIT  ·  SCHIESS SEINE BRIEFE ZURÜCK';

  @override
  String get encounterCaption_screech => 'WENN ER KREISCHT  ·  FLIEG ZUR LÜCKE';

  @override
  String get encounterCaption_default =>
      'MACH DICH BEREIT  ·  FLATTERN, AUSWEICHEN, SCHIESSEN';

  @override
  String get encounterCoasting => 'Dein Vogel gleitet sicher dahin';

  @override
  String get encounterOpenSky => 'Zurück in den offenen Himmel';

  @override
  String get encounterOmenTitle_duskMoth => 'DIE DÄMMERUNG ERHEBT SICH';

  @override
  String get encounterOmenLine_duskMoth =>
      'Ein Seidenschleier sammelt sich in der Dämmerung…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'DA BRAUT SICH WAS ZUSAMMEN';

  @override
  String get encounterOmenLine_spitterBeetle => 'Die Luft beginnt zu prickeln…';

  @override
  String get encounterOmenTitle_dragon => 'DER HIMMEL FÄNGT FEUER';

  @override
  String get encounterOmenLine_dragon =>
      'Mächtige Flügel schlagen über den Wolken…';

  @override
  String get encounterOmenTitle_kingCoo => 'KANTSTEIN GESPERRT';

  @override
  String get encounterOmenLine_kingCoo =>
      'Jemand ist sehr sauer wegen des Brotwagens…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => 'STURMWARNUNG';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      'Etwas auf dem Sims schaut zu…';

  @override
  String get encounterOmenTitle_neferhoo => 'DIE PYRAMIDE ERWACHT';

  @override
  String get encounterOmenLine_neferhoo =>
      'Der Staub der Pyramide wirbelt auf…';

  @override
  String get encounterOmenTitle_baronReturns => 'DER BARON KEHRT ZURÜCK';

  @override
  String get encounterOmenLine_baronReturns =>
      'Er ist zurück, und er ist viel lauter…';

  @override
  String get encounterOmenTitle_default => 'EIN SCHATTEN NAHT';

  @override
  String get encounterOmenLine_default => 'Der Himmel gehört jemand anderem…';

  @override
  String get encounterOmenTitle_pirate => 'SEGEL IN SICHT!';

  @override
  String get encounterOmenLine_pirate =>
      'Ein Schiff reitet auf der steigenden Flut heran…';

  @override
  String get bossGuardianEyebrow => 'WÄCHTER';

  @override
  String bossEncounterEyebrow(String number) {
    return 'BEGEGNUNG $number';
  }

  @override
  String get bossGuardianDown => 'WÄCHTER BESIEGT!';

  @override
  String get bossSkyReclaimed => 'HIMMEL BEFREIT';

  @override
  String bossVictoryPoints(int points) {
    return '+$points PUNKTE   ·   SCHILD ERNEUERT';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'BARON FLEDERMAUS BESIEGT',
      'spitterBeetle': 'SPUCKKÖNIG BESIEGT',
      'duskMoth': 'DÄMMERKAISERIN BESIEGT',
      'pirate': 'PIRATENKAPITÄN BESIEGT',
      'dragon': 'GLUTDRACHE BESIEGT',
      'kingCoo': 'KÖNIG GURR BESIEGT',
      'searchlightGargoyle': 'SCHEINWERFER-WASSERSPEIER BESIEGT',
      'other': 'NEFERHOO BESIEGT',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '„$line“';
  }

  @override
  String get bossPirateRoar => 'ARRR!';

  @override
  String get bossGargoyleCardSmall => 'SCHEINWERFER-';

  @override
  String get bossGargoyleCardBig => 'WASSERSPEIER';

  @override
  String get bossGargoyleCardOrder => 'small-big';

  @override
  String get bossDodgeFlyLow => 'FLIEG TIEF';

  @override
  String get bossDodgeFlyHigh => 'FLIEG HOCH';

  @override
  String get bossDodgeClimbOrDive => 'HOCH ODER RUNTER';

  @override
  String get bossDodgeSlipBetween => 'ZWISCHEN DEN\nSTRAHLEN DURCH';

  @override
  String get bossSpotted => 'ENTDECKT!';

  @override
  String get bossShieldLost => 'SCHILD VERLOREN';

  @override
  String get bossHeartLost => '-1 HERZ';

  @override
  String get bossGargoyleLampOpen => 'LAMPE OFFEN';

  @override
  String get bossGargoyleShoot => 'SCHIESS!';

  @override
  String get bossScreechFlyToGap => 'FLIEG ZUR LÜCKE';

  @override
  String get bossScreechHoldGap => 'LÜCKE HALTEN';

  @override
  String get bossPirateHighTide => 'HOCHWASSER';

  @override
  String get bossBarDefeated => 'BESIEGT';

  @override
  String get bossBarIncoming => 'IM ANFLUG';

  @override
  String get bossBarFury => 'ZORN';

  @override
  String get bossBarHeartDouble => 'HERZ ×2';

  @override
  String get bossStronger => 'STÄRKER!';

  @override
  String get bossKingCooPuffed => 'GEBLÄHT';

  @override
  String get bossKingCooShout => 'GURR!';

  @override
  String get bossKingCooPop => 'PLOPP!';

  @override
  String get bossKingCooPoof => 'PUFF!';

  @override
  String get bossSquadOpenLane => 'FREIE BAHN = LOS';

  @override
  String get bossSquadUseGap => 'NUTZ DIE LÜCKE';

  @override
  String get bossSquadThenV => 'DANN: V';

  @override
  String get bossSquadThenGap => 'DANN: LÜCKE';

  @override
  String get bossSquadCancelled => 'STAFFEL ABGESAGT';

  @override
  String get bossNeferhooFound => 'DER VERLORENE BRIEF IST GEFUNDEN';

  @override
  String get bossNeferhooHoo => 'SCHU';

  @override
  String get bossNeferhooPoo => 'HU';

  @override
  String get bossNeferhooMailCall => 'POST IST DA';

  @override
  String get bossNeferhooExpressPost => 'EILPOST';

  @override
  String get bossNeferhooShootBack => 'Schieß sie zurück!';

  @override
  String get bossNeferhooAnkh => 'DAS ANCH';

  @override
  String get bossNeferhooTwoAnkhs => 'ZWEI ANCHS';

  @override
  String get bossNeferhooComesBack => 'Es kommt zurück!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'LAUFFEUER!',
      'skyfall': 'HIMMELSSTURZ!',
      'eruption': 'AUSBRUCH!',
      'other': 'SCHWARM!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Schnapp dir die Sprintringe und entkomm ihm!',
      'skyfall': 'Schnapp dir die Sprintringe und flieh vor den Meteoren!',
      'eruption': 'Schnapp dir die Sprintringe und entkomm den Fontänen!',
      'other': 'Schnapp dir die Sprintringe und pflüg hindurch!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return 'ENTKOMMEN! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'FEHLERLOS! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Du bist dem Lauffeuer entkommen',
      'skyfall': 'Du hast den Himmelssturz überlebt',
      'eruption': 'Du hast den Ausbruch überstanden',
      'other': 'Du bist durch den Schwarm gepflügt',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => 'STURM!';

  @override
  String encounterGaleDetail(String mark) {
    return 'Weich den Trümmern aus, wo das $mark blinkt!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'ÜBERSTANDEN! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail => 'Du hast den Sturm überstanden';

  @override
  String get encounterAllRings => 'ALLE RINGE!';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'Turbo-Schub +$seconds s';
  }

  @override
  String get encounterFinish => 'ZIEL';

  @override
  String get builderMode_pushUp => 'Liegestütze';

  @override
  String get builderMode_squat => 'Kniebeugen';

  @override
  String get builderMode_jump => 'Sprünge';

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
      other: '$count Liegestütze',
      one: '1 Liegestütz',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kniebeugen',
      one: '1 Kniebeuge',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'Mein Tipplevel';

  @override
  String get builderNewLevel_pushUp => 'Mein Liegestützlevel';

  @override
  String get builderNewLevel_squat => 'Mein Kniebeugenlevel';

  @override
  String get builderNewLevel_jump => 'Mein Sprunglevel';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'Mein Level';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Flieg mein Beakbound-Level „$name“ ($mode): $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$earned von $total Sternen';
  }

  @override
  String get builderBackSemantics => 'Zurück';

  @override
  String get builderKeepIt => 'Behalten';

  @override
  String builderLessSemantics(String name) {
    return 'Weniger: $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'Mehr: $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => 'Duplizieren';

  @override
  String get builderCopy => 'Kopieren';

  @override
  String get builderDeleteSemantics => 'Löschen';

  @override
  String get builderDelete => 'Löschen';

  @override
  String get builderMoreBelow => 'Weiter unten';

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
  String get builderLane => 'Bahn';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'oben oder unten in der Kniebeuge',
      'other': 'oben oder unten im Liegestütz',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'Oben';

  @override
  String get builderLaneBottom => 'Unten';

  @override
  String get builderHeight => 'Höhe';

  @override
  String get builderHeightHint => 'des Himmels';

  @override
  String get builderLowerSemantics => 'Tiefer';

  @override
  String get builderHigherSemantics => 'Höher';

  @override
  String get builderOpening => 'Öffnung';

  @override
  String builderOpeningHint(int percent) {
    return 'mindestens $percent %';
  }

  @override
  String get builderNarrowerSemantics => 'Schmaler';

  @override
  String get builderWiderSemantics => 'Breiter';

  @override
  String get builderMotion => 'Bewegung';

  @override
  String get builderMotionGardenHint => 'Gartentore stehen still';

  @override
  String get builderMotionStill => 'Still';

  @override
  String get builderMotionGentle => 'Sanft';

  @override
  String get builderMotionLively => 'Lebhaft';

  @override
  String get builderMotionGardenToast =>
      'Gartentore stehen still: Wähl eine andere Torart, damit es sich bewegt.';

  @override
  String get builderSway => 'Schwingen';

  @override
  String builderSwayHint(String seconds) {
    return 'ein Schwung: $seconds';
  }

  @override
  String get builderSwayFast => 'Schnell';

  @override
  String get builderSwayMedium => 'Mittel';

  @override
  String get builderSwaySlow => 'Langsam';

  @override
  String get builderPhase => 'Beim Ankommen';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position von $count';
  }

  @override
  String get builderPhaseHint => 'wo es gerade im Schwung ist';

  @override
  String get builderPhaseEarlierSemantics => 'Früher im Schwung';

  @override
  String get builderPhaseLaterSemantics => 'Später im Schwung';

  @override
  String get builderLook => 'Aussehen';

  @override
  String builderLookSemantics(int number) {
    return 'Aussehen $number';
  }

  @override
  String get builderDoor => 'Steintür';

  @override
  String get builderDoorHint => 'schieß sie auf';

  @override
  String get builderDoorNone => 'Keine Tür';

  @override
  String get builderDoorNeedsShootToast =>
      'Schalte Schießen in den Level-Einstellungen ein, um Türen zu nutzen.';

  @override
  String get builderPlace => 'Position';

  @override
  String get builderPlaceHint => 'ab dem Start';

  @override
  String get builderEarlierSemantics => 'Früher';

  @override
  String get builderLaterSemantics => 'Später';

  @override
  String builderFamilySemantics(String family) {
    return 'Torart: $family. Ändern';
  }

  @override
  String get builderChangeFamily => 'Torart ändern';

  @override
  String get builderItemStar => 'Stern';

  @override
  String get builderItemTrio => 'Sterntrio';

  @override
  String get builderItemHeart => 'Herz';

  @override
  String get builderItemEnemy => 'Gegner';

  @override
  String get builderItemGate => 'Tor';

  @override
  String get builderItemStarDetail => 'Ein Stern zum Sammeln';

  @override
  String get builderItemTrioDetail => 'Alle drei geben einen Bonus';

  @override
  String get builderItemHeartDetail => 'Ein Herz zurück';

  @override
  String get builderEnemyKind => 'Art';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Der Vogel fliegt auf zwei Bahnen, oben und unten in der Kniebeuge: Setz Extras auf oder zwischen die gelben Linien.',
      'other':
          'Der Vogel fliegt auf zwei Bahnen, oben und unten im Liegestütz: Setz Extras auf oder zwischen die gelben Linien.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'Lila Fledermaus';

  @override
  String get builderEnemy_caveBat => 'Höhlenfledermaus';

  @override
  String get builderEnemy_spitterBeetle => 'Spuckkäfer';

  @override
  String get builderEnemy_duskMoth => 'Dämmerfalter';

  @override
  String get builderEnemy_alleyPigeon => 'Gassentaube';

  @override
  String get builderEnemy_mummyBat => 'Mumienfledermaus';

  @override
  String get builderSummaryTitle => 'Dieses Level';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'Länge';

  @override
  String get builderFactStars => 'Sterne';

  @override
  String get builderFactMarks => 'Marken';

  @override
  String get builderFactWorkout => 'Training';

  @override
  String get builderFactPace => 'Tempo';

  @override
  String get builderFactBoss => 'Boss';

  @override
  String get builderPace_relaxed => 'Gemütlich';

  @override
  String get builderPace_steady => 'Gleichmäßig';

  @override
  String get builderPace_brisk => 'Flott';

  @override
  String get builderSummaryStarterNote =>
      'Ein Startlevel zum Fliegen, wie es ist – oder remixe es zu deinem eigenen Level.';

  @override
  String get builderSummaryClearedNote =>
      'Von dir geschafft: Du bist es bis zum Ende geflogen.';

  @override
  String get builderSummaryClearNote =>
      'Flieg es im Testflug bis ins Ziel, um es als geschafft zu markieren.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat':
          'Mach einen Testflug, besiege den $boss und flieg ins Ziel, dann ist es geschafft.',
      'spitterBeetle':
          'Mach einen Testflug, besiege den $boss und flieg ins Ziel, dann ist es geschafft.',
      'duskMoth':
          'Mach einen Testflug, besiege die $boss und flieg ins Ziel, dann ist es geschafft.',
      'pirate':
          'Mach einen Testflug, besiege den $boss und flieg ins Ziel, dann ist es geschafft.',
      'dragon':
          'Mach einen Testflug, besiege den Glutdrachen und flieg ins Ziel, dann ist es geschafft.',
      'searchlightGargoyle':
          'Mach einen Testflug, besiege den $boss und flieg ins Ziel, dann ist es geschafft.',
      'other':
          'Mach einen Testflug, besiege $boss und flieg ins Ziel, dann ist es geschafft.',
    });
    return '$_temp0';
  }

  @override
  String get builderSummaryHowTo =>
      'Wähl links ein Werkzeug und tipp dann in den Himmel. Tipp etwas an, um es zu ändern; zieh es, um es zu verschieben.';

  @override
  String get builderFamily_garden_detail =>
      'Steht still. Kann eine Steintür haben.';

  @override
  String get builderFamily_windLift_detail => 'Die Öffnung steigt und sinkt.';

  @override
  String get builderFamily_petalGate_detail =>
      'Die Öffnung wird enger und weiter.';

  @override
  String get builderFamily_switchback_detail =>
      'Zwei Öffnungen, die auseinandergleiten.';

  @override
  String get builderFamily_lanternDrift_detail =>
      'Hängende Laternen, die wippen.';

  @override
  String get builderFamily_sunWheels_detail =>
      'Räder, die zusammen- und zurückrollen.';

  @override
  String get builderFamily_crystalSteps_detail => 'Drei Stufen in einer Welle.';

  @override
  String get builderFamiliesCloseSemantics => 'Torarten schließen';

  @override
  String get builderFamiliesTitle => 'Torart';

  @override
  String get builderFamiliesSubtitle => 'Wie das Tor aussieht und sich bewegt.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gib dem Level einen Namen mit bis zu $count Zeichen.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort =>
      'Schieb die Ziellinie weiter nach hinten: Das Level ist zu kurz.';

  @override
  String get reach_tooLong =>
      'Hol die Ziellinie näher heran: Das Level ist zu lang.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zu viele Dinge: Ein Level fasst höchstens $count.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap =>
      'Nur „Tipp & Flieg“-Level enden mit einem Boss.';

  @override
  String get reach_noGates =>
      'Füg Tore hinzu, durch die der Vogel fliegen kann.';

  @override
  String get reach_startZone =>
      'Zu nah am Start: Schieb es hinter die Startzone.';

  @override
  String get reach_finishRoom =>
      'Lass nach diesem Tor Platz vor der Ziellinie.';

  @override
  String get reach_overlap => 'Zwei Tore überlappen: Schieb sie auseinander.';

  @override
  String get reach_gateHeight => 'Dieses Tor ist zu hoch oder zu tief.';

  @override
  String get reach_gateMotion => 'Dieses Tor kann sich so nicht bewegen.';

  @override
  String get reach_gateLook => 'Dieses Tor hat ein unbekanntes Aussehen.';

  @override
  String get reach_gateNarrow =>
      'Öffne dieses Tor weiter: Der Vogel passt nicht durch.';

  @override
  String get reach_gateWide => 'Dieses Tor ist zu weit offen.';

  @override
  String get reach_doorNeedsShoot =>
      'Eine Steintür braucht Tipp & Flieg mit Schießen an.';

  @override
  String get reach_doorNeedsGarden =>
      'Nur ein Gartentor kann eine Steintür haben.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Knapper Wechsel: Eine ruhige Kniebeuge schafft es vielleicht nicht rechtzeitig.',
      'other':
          'Knapper Wechsel: Ein ruhiger Liegestütz schafft es vielleicht nicht rechtzeitig.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'Steiler Anstieg: Lass mehr Platz, um zu diesem Tor hochzuspringen.';

  @override
  String get reach_enemyNeedsTap =>
      'Gegner gibt es nur in „Tipp & Flieg“-Leveln.';

  @override
  String get reach_outsideSky => 'Halte es innerhalb des Himmels.';

  @override
  String get reach_pastFinish => 'Setz es vor die Ziellinie.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Außer Reichweite einer Kniebeuge: Rück es näher an die Bahnen.',
      'other':
          'Außer Reichweite eines Liegestützes: Rück es näher an die Bahnen.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'In einer Wand: Schieb es in die Öffnung.';

  @override
  String get reach_noStars => 'Setz mindestens einen Stern.';

  @override
  String get reach_marks =>
      'Die Sternmarken verlangen mehr Sterne, als das Level hat.';

  @override
  String reach_cannotFly(String problem) {
    return 'Dieses Level kann noch nicht fliegen ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'Das Level wurde nicht gespeichert und kann nicht fliegen. Tipp auf seinen Namen zum Wiederholen.';

  @override
  String get builderShareBlockedToast =>
      'Behebe erst die roten Fahnen: Dann kannst du das Level teilen.';

  @override
  String get builderEditorBackSemantics => 'Zurück zum Baukasten';

  @override
  String get builderSettingsSemantics => 'Level-Einstellungen';

  @override
  String get builderFly => 'FLIEG';

  @override
  String get builderTestFly => 'TESTFLUG';

  @override
  String get builderFlySemantics => 'Dieses Level fliegen';

  @override
  String get builderTestFlySemantics => 'Das ganze Level im Testflug fliegen';

  @override
  String get builderUndoSemantics => 'Rückgängig';

  @override
  String get builderRedoSemantics => 'Wiederholen';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice Tipps',
      one: '$advice Tipp',
    );
    return '$blocking zu beheben, $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice Tipps',
      one: '$advice Tipp',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => 'Bereit zum Fliegen';

  @override
  String get builderShareSemantics => 'Level-Code';

  @override
  String get builderFromHereSemantics => 'Testflug ab hier';

  @override
  String get builderFromHere => 'Ab hier';

  @override
  String get builderStatusStarter => 'Startlevel · sehen, fliegen, remixen';

  @override
  String get builderStatusSaveFailed => 'Nicht gespeichert · nochmal tippen';

  @override
  String get builderStatusSaving => 'Speichert…';

  @override
  String get builderStatusSaved => 'Alles gespeichert';

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
    return '$name. $mode. $status. Tippen zum Umbenennen.';
  }

  @override
  String get builderStarterBanner => 'Remixe es – dann gehört es dir';

  @override
  String get builderRemix => 'Remixen';

  @override
  String get builderRemixSemantics => 'Remixen';

  @override
  String get builderIssuesCloseSemantics => 'Probleme und Tipps schließen';

  @override
  String get builderIssuesReadyTitle => 'Bereit zum Fliegen!';

  @override
  String get builderIssuesFixTitle => 'Vor dem Flug zu beheben';

  @override
  String get builderIssuesTipsTitle => 'Bereit, mit ein paar Tipps';

  @override
  String get builderIssuesReadyDetail =>
      'Nichts zu beheben. Testflug bis ins Ziel, dann ist es geschafft.';

  @override
  String get builderIssuesDetail =>
      'Tipp einen an, um zu seiner Stelle auf der Route zu springen.';

  @override
  String get builderSettingsCloseSemantics => 'Einstellungen schließen';

  @override
  String get builderSettingsTitle => 'Level-Einstellungen';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · Änderungen werden sofort gespeichert';
  }

  @override
  String get builderSettingsName => 'Name';

  @override
  String get builderRename => 'Umbenennen';

  @override
  String get builderRenameSemantics => 'Umbenennen';

  @override
  String get builderSettingsRegion => 'Region';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Orte · wischen für mehr',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'Tempo';

  @override
  String get builderSettingsPaceHint => 'wie schnell der Himmel scrollt';

  @override
  String get builderSettingsMarks => 'Sternmarken';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne gesetzt',
      one: '1 Stern gesetzt',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'Zwei-Sterne-Marke';

  @override
  String get builderMarkThreeSemantics => 'Drei-Sterne-Marke';

  @override
  String get builderMarksAuto => 'Auto: folgt den Sternen';

  @override
  String get builderMarksByHand => 'Von Hand festlegen';

  @override
  String get builderSettingsControls => 'Steuerung';

  @override
  String get builderShootOn => 'Schießen an';

  @override
  String get builderShootOff => 'Schießen aus';

  @override
  String get builderSprintOn => 'Sprint an';

  @override
  String get builderSprintOff => 'Sprint aus';

  @override
  String get builderSettingsBoss => 'Boss-Finale';

  @override
  String get builderSettingsBossHint => 'wartet am Ende';

  @override
  String get builderNoBossSemantics => 'Kein Boss: eine Ziellinie';

  @override
  String get builderNoBoss => 'Keiner';

  @override
  String get builderBossShort_baronBat => 'Baron';

  @override
  String get builderBossShort_spitterBeetle => 'Spuckkönig';

  @override
  String get builderBossShort_duskMoth => 'Kaiserin';

  @override
  String get builderBossShort_pirate => 'Pirat';

  @override
  String get builderBossShort_dragon => 'Drache';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Der Vogel fliegt zwei Bahnen: oben und unten in jeder Kniebeuge. Wer langsamer ist, fliegt dasselbe Level sanfter. Hier gibt es kein Schießen, kein Sprinten und keine Bosse.',
      'other':
          'Der Vogel fliegt zwei Bahnen: oben und unten in jedem Liegestütz. Wer langsamer ist, fliegt dasselbe Level sanfter. Hier gibt es kein Schießen, kein Sprinten und keine Bosse.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'Jeder Sprung hebt den Vogel an; dazwischen gleitet er. Hier gibt es kein Schießen, kein Sprinten und keine Bosse.';

  @override
  String get builderStartZoneToast =>
      'Halte die Startzone frei: Setz Dinge rechts von der gestrichelten Linie.';

  @override
  String get builderSkySemantics =>
      'Level-Himmel. Tippen zum Setzen, ziehen zum Verschieben oder Scrollen.';

  @override
  String get builderSkyReadOnlySemantics =>
      'Level-Himmel. Tipp etwas an, um es anzusehen.';

  @override
  String get builderCoachTitle => 'Bau dein Level';

  @override
  String get builderCoachPickTool => 'Wähl links ein Werkzeug';

  @override
  String get builderCoachTapSky => 'Tipp in den Himmel zum Setzen';

  @override
  String get builderCoachTestFly => 'Testflug starten!';

  @override
  String get builderCoachDrag =>
      'Zieh etwas zum Verschieben · zieh den Himmel zum Scrollen';

  @override
  String get builderTipDrag =>
      'Zieh es zum Verschieben · zieh den Himmel zum Scrollen';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'OBEN IN DER KNIEBEUGE',
      'other': 'OBEN IM LIEGESTÜTZ',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'OBEN';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'UNTEN IN DER KNIEBEUGE',
      'other': 'UNTEN IM LIEGESTÜTZ',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'UNTEN';

  @override
  String get builderCanvasStartZoneFull => 'STARTZONE · FREIHALTEN';

  @override
  String get builderCanvasStartZone => 'STARTZONE';

  @override
  String get builderCanvasFinishHere => 'ZIEL HIER';

  @override
  String get builderTool_select => 'Auswahl';

  @override
  String get builderToolHint_select =>
      'Auswahl: Tipp etwas an, um es zu ändern, zieh es zum Verschieben';

  @override
  String get builderTool_gate => 'Tor';

  @override
  String get builderToolHint_gate =>
      'Tor: Tipp in den Himmel, um ein Tor zu setzen';

  @override
  String get builderTool_star => 'Stern';

  @override
  String get builderToolHint_star =>
      'Stern: Tipp in den Himmel, um einen Stern zu setzen';

  @override
  String get builderTool_trio => 'Trio';

  @override
  String get builderToolHint_trio =>
      'Sterntrio: Tipp in den Himmel, um drei Sterne zu setzen';

  @override
  String get builderTool_heart => 'Herz';

  @override
  String get builderToolHint_heart =>
      'Herz: Tipp in den Himmel, um ein Herz zu setzen';

  @override
  String get builderTool_enemy => 'Gegner';

  @override
  String get builderToolHint_enemy =>
      'Gegner: Tipp in den Himmel, um einen Gegner zu setzen';

  @override
  String get builderTool_finish => 'Ziel';

  @override
  String get builderToolHint_finish =>
      'Ziel: Tipp in den Himmel, um die Ziellinie zu verschieben';

  @override
  String get builderTool_boss => 'Boss';

  @override
  String get builderToolHint_boss =>
      'Boss-Marke: Tipp in den Himmel, um zu verschieben, wo der Boss wartet';

  @override
  String get builderStarterToolsToast =>
      'Startlevel bleiben, wie sie sind: Remixe es, um es zu ändern.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Routenübersicht. $length bis zum Boss. Ziehen, um dich entlang der Route zu bewegen.',
      'other':
          'Routenübersicht. $length bis zum Ziel. Ziehen, um dich entlang der Route zu bewegen.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Routenübersicht. $length bis zum Boss. $reps. Ziehen, um dich entlang der Route zu bewegen.',
      'other':
          'Routenübersicht. $length bis zum Ziel. $reps. Ziehen, um dich entlang der Route zu bewegen.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '$length bis zum Boss';
  }

  @override
  String get builtResultTestFlight => 'TESTFLUG';

  @override
  String get builtResultCleared => 'Geschafft!';

  @override
  String get builtResultBonk => 'Klonk!';

  @override
  String get builtResultLanded => 'Gelandet';

  @override
  String get builtResultTestTab => 'TEST';

  @override
  String get builtResultGoalFinish => 'Ziel';

  @override
  String get builtResultGoalBoss => 'Boss';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. Geschafft.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sammle $count Sterne.',
      one: 'Sammle $count Stern.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sammle $count Sterne. Geschafft.',
      one: 'Sammle $count Stern. Geschafft.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'Geschafft';

  @override
  String get builtResultNotYet => 'Noch nicht';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'Erst ins Ziel';

  @override
  String get builtResultClearedByYou => 'VON DIR GESCHAFFT';

  @override
  String get builtResultNewBest => 'NEUER REKORD!';

  @override
  String get builtResultPractice => 'Übung';

  @override
  String builtResultBest(int count) {
    return 'Bestwert $count';
  }

  @override
  String get builtResultFirstClear => 'Premiere!';

  @override
  String get builtResultStarsCollected => 'GESAMMELTE STERNE';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count von 3 Levelsternen',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'VORGABE';

  @override
  String get builtResultWorkout => 'TRAINING';

  @override
  String get builtResultGotTo => 'ERREICHT';

  @override
  String get builtResultScore => 'PUNKTE';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liegestütze',
      one: 'Liegestütz',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kniebeugen',
      one: 'Kniebeuge',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprünge',
      one: 'Sprung',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liegestütze mit Kamera',
      one: 'Liegestütz mit Kamera',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kniebeugen mit Kamera',
      one: 'Kniebeuge mit Kamera',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'von $length';
  }

  @override
  String get builtResultNotKept => 'Nicht gezählt';

  @override
  String get builtResultNoBest => 'Kein Bestwert';

  @override
  String get builtResultClearedStrip =>
      'Von dir geschafft · bereit zum Teilen!';

  @override
  String builtResultFlownFrom(String from) {
    return 'Ab $from geflogen. Flieg alles, um es zu schaffen.';
  }

  @override
  String get builtResultTestNothingSaved =>
      'Testflug · nichts wird gespeichert';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'Testflug · $reached von $length geschafft';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return '$reached von $length geschafft. Erreiche das Ziel für Sterne.';
  }

  @override
  String get builtResultReachFinish => 'Erreiche das Ziel für Sterne.';

  @override
  String get builtResultSaved => 'Auf diesem Handy gespeichert';

  @override
  String get builtResultSaving => 'Dein Flug wird gespeichert…';

  @override
  String get builtResultBuilder => 'Baukasten';

  @override
  String get builtResultEditLevel => 'Level bearbeiten';

  @override
  String get builtResultEdit => 'Bearbeiten';

  @override
  String get builtResultFlyAgain => 'Nochmal fliegen';

  @override
  String get builtResultWatchReplay => 'Nochmal ansehen';

  @override
  String get builtResultPreparing => 'Vorbereiten…';

  @override
  String get builtResultSessionSaving => 'Speichert…';

  @override
  String get builtResultSaveSession => 'Flug speichern';

  @override
  String get builderShelfTitle => 'Level-Baukasten';

  @override
  String get builderShelfPasteCode => 'Code einfügen';

  @override
  String get builderShelfNewLevel => 'Neues Level';

  @override
  String get builderShelfSaveFailed =>
      'Das hat nicht geklappt. Bitte versuch es noch mal.';

  @override
  String builderShelfDeleteTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get builderShelfDeleteBody =>
      'Seine Bestwerte verschwinden mit. Liegestütze, Kniebeugen und Sprünge, die du darin geflogen bist, zählen weiter.';

  @override
  String get builderShelfDelete => 'Löschen';

  @override
  String builderShelfDeleted(String name) {
    return '„$name“ gelöscht.';
  }

  @override
  String get builderShelfFixFirst =>
      'Behebe vor dem Teilen, was rot markiert ist: Tipp auf Beheben.';

  @override
  String get builderShelfCodeCopied => 'Code kopiert! Schick ihn einem Freund.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'Code kopiert! Flieg es auch bis ins Ziel, damit Freunde sehen, dass es schaffbar ist.';

  @override
  String get builderShelfNotReady =>
      'Dieses Level ist noch nicht flugbereit: Tipp auf Beheben.';

  @override
  String get builderShelfPasteMissingTitle => 'Kein Level-Code zum Einfügen';

  @override
  String get builderShelfPasteNewerTitle =>
      'Ein Level aus einem neueren Beakbound';

  @override
  String get builderShelfPasteDamagedTitle =>
      'Der Code ist durcheinandergeraten';

  @override
  String get builderShelfPasteMissingBody =>
      'Kopier den Level-Code eines Freundes (er beginnt mit BEAK1.) und tipp nochmal auf Code einfügen.';

  @override
  String get builderShelfPasteNewerBody =>
      'Aktualisiere Beakbound, um es zu fliegen, und füg den Code dann nochmal ein.';

  @override
  String get builderShelfPasteDamagedBody =>
      'Ein Teil fehlt oder ist vertippt. Bitte deinen Freund, den ganzen Code nochmal zu kopieren.';

  @override
  String builderShelfImported(String name) {
    return '„$name“ ist in deinem Regal!';
  }

  @override
  String get builderShelfUnavailable => 'Deine Level brauchen noch kurz.';

  @override
  String get builderShelfMine => 'Meine Level';

  @override
  String get builderShelfStarters => 'Startlevel';

  @override
  String get builderShelfStartersHint =>
      'Flieg eins oder remixe es zu deinem eigenen Level';

  @override
  String get builderShelfEmptyTitle => 'Bau dein erstes Level';

  @override
  String get builderShelfEmptyBody =>
      'Setz Tore, Sterne und Herzen von Hand, leg die Ziellinie fest und mach einen Testflug.';

  @override
  String get builderShelfPasteFriend => 'Code von Freunden einfügen';

  @override
  String get builderShelfNeedsWork => 'Noch nicht fertig';

  @override
  String get builderShelfClearedByYou => 'Von dir geschafft';

  @override
  String get builderShelfFromFriend => 'Von Freunden';

  @override
  String get builderShelfFly => 'Flieg!';

  @override
  String builderShelfFlySemantics(String name) {
    return '$name fliegen';
  }

  @override
  String get builderShelfFixIt => 'Beheben';

  @override
  String builderShelfFixSemantics(String name) {
    return '$name beheben';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return '$name ändern';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return '$name teilen';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return '$name teilen: Du hast es geschafft';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'Mehr zu $name';
  }

  @override
  String get builderShelfRemix => 'Remixen';

  @override
  String builderShelfRemixSemantics(String name) {
    return '$name remixen';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sachen im Editor zu beheben',
      one: '1 Sache im Editor zu beheben',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '$count Stern',
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
      other: 'Bestwert: $stars von 3 Sternen.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch nicht fertig: $count Sachen zu beheben.',
      one: 'Noch nicht fertig: 1 Sache zu beheben.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'Von dir geschafft.';

  @override
  String get builderShelfFromFriendSemantics => 'Von Freunden.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return '$name ansehen. $mode, $length, $fact.';
  }

  @override
  String get builderShelfRemixSuffix => 'Remix';

  @override
  String get builderShelfCopySuffix => 'Kopie';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get starter_t_tap_1_name => 'Gartenhüpfer';

  @override
  String get starter_t_push_1_name => 'Zehn Liegestütze';

  @override
  String get starter_t_squat_1_name => 'Treppen-Hocke';

  @override
  String get starter_t_jump_1_name => 'Hüpfbucht';

  @override
  String get starter_t_tap_boss_name => 'Barons Brücke';

  @override
  String get builderPickCloseNewLevel => 'Neues Level schließen';

  @override
  String get builderPickModeTitle => 'Was soll es werden?';

  @override
  String get builderPickRegionTitle => 'Wo soll es fliegen?';

  @override
  String get builderPickModeSubtitle =>
      'Wähl, wie es geflogen wird (später nicht änderbar). Testflüge machst du immer per Touch.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · Wähl, wo es fliegt. Das kannst du später ändern.';
  }

  @override
  String get builderPickTouchLine =>
      'Tippen zum Flattern. Tore, Sterne, Gegner und ein Boss.';

  @override
  String get builderPickPushUpLine =>
      'Eine Bahn oben, eine unten: Jedes Abtauchen ist ein Liegestütz.';

  @override
  String get builderPickSquatLine =>
      'Eine Bahn oben, eine unten: Jedes Abtauchen ist eine Kniebeuge.';

  @override
  String get builderPickJumpLine =>
      'Spring für Auftrieb. Tore überall am Himmel.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'Kamera';

  @override
  String get builderPickSuggested => 'Empfohlen';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, empfohlen';
  }

  @override
  String get builderPickClose => 'Schließen';

  @override
  String get builderPickNotYet =>
      'Noch nicht: Behebe erst, was rot markiert ist.';

  @override
  String get builderPickShare => 'Level-Code teilen';

  @override
  String get builderPickShareLine =>
      'Kopier einen Code, den Freunde in ihr Beakbound einfügen können.';

  @override
  String get builderPickDuplicate => 'Duplizieren';

  @override
  String get builderPickDuplicateLine => 'Mach eine Kopie für eine neue Idee.';

  @override
  String get builderPickDeleteLine =>
      'Wirf das Level weg. Vorher wirst du gefragt.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'Import abbrechen';

  @override
  String get builderPickImportTitle => 'Ein Level zum Fliegen!';

  @override
  String get builderPickImportSubtitle =>
      'Jemand hat dieses Level mit dir geteilt.';

  @override
  String get builderPickClearedByMaker => 'Vom Ersteller geschafft';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne zum Sammeln',
      one: '$count Stern zum Sammeln',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Endet mit dem $boss',
      'spitterBeetle': 'Endet mit dem $boss',
      'duskMoth': 'Endet mit der $boss',
      'pirate': 'Endet mit dem $boss',
      'dragon': 'Endet mit dem Glutdrachen',
      'searchlightGargoyle': 'Endet mit dem $boss',
      'other': 'Endet mit $boss',
    });
    return '$_temp0';
  }

  @override
  String get builderPickNotFlown =>
      'Der Ersteller hat es noch nicht bis ins Ziel geflogen.';

  @override
  String get builderPickRoute => 'Die Route';

  @override
  String builderPickAlreadyHave(String name) {
    return 'Du hast dieses Level schon: „$name“.';
  }

  @override
  String get builderPickImportCopy => 'Kopie importieren';

  @override
  String get builderPickOpenYours => 'Deins öffnen';

  @override
  String get builderPickImport => 'Importieren';

  @override
  String get builderShelfRenameCancelSemantics => 'Umbenennen abbrechen';

  @override
  String get builderShelfRenameTitle => 'Benenne dein Level';

  @override
  String get builderShelfRenameEmpty => 'Ein Name braucht ein, zwei Buchstaben';

  @override
  String get builderShelfRenameSaveSemantics => 'Name speichern';

  @override
  String get builderShelfRenameSave => 'Speichern';

  @override
  String get coopMode_roped => 'Am Seil';

  @override
  String get coopMode_free => 'Ohne Seil';

  @override
  String get coopMode_duel => '1 gegen 1';

  @override
  String get coopTitle => 'Zusammen fliegen';

  @override
  String get coopPlayersTag => 'ZWEI SPIELER · EIN HANDY';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode · REKORD $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: NOCH KEIN REKORD';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count DUELLE',
      one: '$mode · $count DUELL',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode: ERSTES DUELL';
  }

  @override
  String get coopRopedLead => 'Eure Vögel teilen sich ein Seil.';

  @override
  String get coopRopedBody =>
      'Flattert gemeinsam, um hoch zu steigen: Ein Vogel allein hebt beide, aber nur ein bisschen. Mit Sprint zieht ihr euren Partner mit.';

  @override
  String get coopFreeLead => 'Ohne Seil:';

  @override
  String get coopFreeBody =>
      'Jeder Vogel fliegt für sich und rempelt den anderen nur an. Herzen, Schild und Punkte teilt ihr trotzdem.';

  @override
  String get duelLead => 'Kämpft!';

  @override
  String get duelBody =>
      'Jeder Vogel hat eigene Herzen. Schnappt euch Wunderkisten: Manche schicken Fledermäuse, einen Spuckkäfer oder Meteore zum Gegner, andere bringen ein Herz, ein Schild oder Sternenkraft. Der letzte Vogel in der Luft gewinnt.';

  @override
  String get coopStart => 'Zusammen fliegen';

  @override
  String get duelStart => 'Kämpft!';

  @override
  String get coopFlightSemantics =>
      'Spieler 1 tippt links zum Flattern, Spieler 2 rechts';

  @override
  String get coopPauseSemantics => 'Flug pausieren';

  @override
  String coopShootSemantics(int player) {
    return 'Spieler $player: Schießen';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'Spieler $player: Sprint';
  }

  @override
  String coopPlayerShort(int player) {
    return 'S$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'SPIELER $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Sternmagnet: noch $seconds Sekunden',
      one: 'Sternmagnet: noch $seconds Sekunde',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Magnet lädt: $charge von $gates perfekten Toren',
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
  String get coopCountdownRoped => 'Seil dran. Achtung, fertig…';

  @override
  String get coopCountdownFree => 'Achtung, fertig…';

  @override
  String get duelCountdown => 'Bereit zum Duell…';

  @override
  String get coopCountdownRopedHint =>
      'Flattert gemeinsam, um hoch zu steigen.\nMit Sprint zieht ihr euren Partner mit!';

  @override
  String get coopCountdownFreeHint =>
      'Jeder Vogel fliegt für sich.\nTeilt die Herzen, schafft die Tore!';

  @override
  String get duelCountdownHint =>
      'Schnappt euch die Wunderkisten!\nDer letzte Vogel in der Luft gewinnt.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Sternenkraft von Spieler $player: noch $seconds Sekunden',
      one: 'Sternenkraft von Spieler $player: noch $seconds Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'Hauptmenü';

  @override
  String get coopChangeBirds => 'Vögel wechseln';

  @override
  String get coopSaved => 'Gespeichert';

  @override
  String get coopSaving => 'Speichert…';

  @override
  String get coopSaveSession => 'Flug speichern';

  @override
  String get duelRematch => 'Revanche';

  @override
  String get coopFlyAgain => 'Nochmal fliegen';

  @override
  String duelWinner(int player) {
    return 'Spieler $player gewinnt!';
  }

  @override
  String get duelDraw => 'Unentschieden!';

  @override
  String get duelStopped => 'Duell abgebrochen';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first gegen $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner hat $loser besiegt';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize auf S$rival!';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize!';
  }

  @override
  String get duelPrize_batSwarm => 'Fledermäuse';

  @override
  String get duelPrize_spitter => 'Spuckkäfer';

  @override
  String get duelPrize_meteorShower => 'Meteorschauer';

  @override
  String get duelPrize_heart => 'Herz';

  @override
  String get duelPrize_shield => 'Schild';

  @override
  String get duelPrize_starPower => 'Sternenkraft';

  @override
  String get coopTapLeftHalf => 'Tipp auf die linke Hälfte';

  @override
  String get coopTapRightHalf => 'Tipp auf die rechte Hälfte';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'Spieler $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'S$player · hier tippen';
  }

  @override
  String get coopKeysP1 => 'S1 · W Flattern · D Schuss · A Sprint';

  @override
  String get coopKeysP2 => 'S2 · ↑ Flattern · → Schuss · ← Sprint';

  @override
  String get coopRopedSemantics => 'Am Seil: Die Vögel teilen sich ein Seil';

  @override
  String get coopFreeSemantics => 'Ohne Seil: Jeder Vogel fliegt für sich';

  @override
  String get duelModeSemantics => '1 gegen 1: Die Vögel kämpfen gegeneinander';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'Flug gespeichert · Siehe Rekorde';

  @override
  String get coopNewTeamBest => 'Neuer Team-Rekord!';

  @override
  String get coopWhatATeam => 'Was für ein Team.';

  @override
  String coopPairCaption(String first, String second) {
    return '$first & $second';
  }

  @override
  String get coopTeamScore => 'TEAMPUNKTE';

  @override
  String get coopTeamBest => 'TEAM-REKORD';

  @override
  String get coopNewTeamBestRibbon => 'NEUER TEAM-REKORD!';

  @override
  String get coopStatFlightTime => 'Flugzeit';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sterne',
      one: 'Stern',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tore',
      one: 'Tor',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'FLATTER-ANTEIL';

  @override
  String coopPercent(int percent) {
    return '$percent %';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Schläge S$player',
      one: 'Schlag S$player',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'Duelldauer $time';
  }

  @override
  String get duelSeries => 'SERIE';

  @override
  String get duelHeartsLeft => 'Herzen übrig';

  @override
  String get duelBoxesOpened => 'Kisten geöffnet';

  @override
  String get duelHitsLanded => 'Treffer erzielt';

  @override
  String get coopPauseSubtitle =>
      'Ihr sitzt beide und wartet. Wir zählen euch beide wieder rein.';

  @override
  String get coopFinishFlight => 'Flug beenden';

  @override
  String get cameraLabIntro =>
      'Stell dein Handy tief und quer auf, mit Blick zu dir oder seitlich neben dir.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'Fast geschafft · zeig deutlicher: $parts';
  }

  @override
  String get cameraLabJointShoulder => 'Schulter';

  @override
  String get cameraLabJointElbow => 'Ellbogen';

  @override
  String get cameraLabJointWrist => 'Handgelenk';

  @override
  String get cameraLabJointHip => 'Hüfte';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => 'Kamera startet…';

  @override
  String get cameraLabDenied =>
      'Kamerazugriff ist aus. Erlaube ihn in den App-Einstellungen und versuch es noch mal.';

  @override
  String cameraLabFailed(String error) {
    return 'Kamera konnte nicht starten: $error';
  }

  @override
  String get cameraLabStopped =>
      'Kamera gestoppt. Tipp auf Kamera starten, um neu zu kalibrieren.';

  @override
  String get cameraLabBack => 'KAMERA-LABOR · Zurück zum Hauptmenü';

  @override
  String get cameraLabStepShow => '1. Zeig Arme & Hüfte';

  @override
  String get cameraLabStepPushUps => '2. Mach zwei Liegestütze';

  @override
  String get cameraLabStepMove => '3. Beweg deinen Vogel!';

  @override
  String get cameraLabStepSquat => 'Finde deine Kniebeuge';

  @override
  String get cameraLabStepJump => 'Finde deine Standposition';

  @override
  String get cameraLabPushUpHelp =>
      'Handy tief, mit Blick zu dir oder seitlich.\nFrontal? Zeig beide Schultern, einen Arm und die Hüfte.\nZweimal runter und hoch, in deinem Tempo.';

  @override
  String get cameraLabSquatHelp =>
      'Steh still, geh bequem in die Hocke, halte kurz und steh wieder auf. Hock dich hin zum Sinken; steh auf zum Steigen.';

  @override
  String get cameraLabJumpHelp =>
      'Stell dich vor das Handy, ganzer Körper und Füße im Bild. Halte still, dann mach kleine Sprünge. Ein Sprung = ein großer Schub.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'KALIBRIERUNG\n$done / $total kalibriert',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'KALIBRIERUNG\n$percent % kalibriert';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'STEUERUNGSTEST\n$count Liegestütze',
      one: 'STEUERUNGSTEST\n$count Liegestütz',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'STEUERUNGSTEST\n$count Kniebeugen',
      one: 'STEUERUNGSTEST\n$count Kniebeuge',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'STEUERUNGSTEST\n$count Sprünge',
      one: 'STEUERUNGSTEST\n$count Sprung',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Hz · $ms ms p95';
  }

  @override
  String get cameraLabStartingButton => 'Startet…';

  @override
  String get cameraLabRecalibrate => 'Neu kalibrieren';

  @override
  String get cameraLabStartCamera => 'Kamera starten';

  @override
  String get cameraLabTapStart => 'Tipp auf Kamera starten';

  @override
  String cameraLabTry(String mode) {
    return '$mode ausprobieren';
  }

  @override
  String get cameraBadgeWaking => 'WACHT AUF';

  @override
  String get cameraBadgeLive => 'LIVE';

  @override
  String get cameraBadgeLockedOn => 'ERFASST';

  @override
  String get cameraBadgeOffline => 'OFFLINE';

  @override
  String get trackingCatchingUp => 'Kamera holt auf';

  @override
  String get trackingStepIntoOutline => 'Stell dich in den Körperumriss';

  @override
  String get trackingKeepShoulders => 'Halte beide Schultern im Bild';

  @override
  String get trackingShowSide =>
      'Zeig eine Schulter, einen Ellbogen, ein Handgelenk und eine Hüfte von der Seite';

  @override
  String get trackingMoveCloser => 'Komm ein bisschen näher';

  @override
  String get trackingGetDown => 'Geh in die Liegestütz-Position';

  @override
  String get trackingHandsOnFloor =>
      'Stell die Hände auf den Boden und streck den Körper nach hinten aus';

  @override
  String get trackingExtendBody =>
      'Streck deinen Körper etwas weiter hinter die Hände';

  @override
  String get trackingComfortableRange =>
      'Bleib in einem bequemen Liegestütz-Bereich';

  @override
  String get trackingPlaceHands =>
      'Stell die Hände auf den Boden, den Körper dahinter';

  @override
  String get trackingFrontTracked =>
      'Frontansicht erkannt · Hände im Bild lassen';

  @override
  String get trackingBodyInView =>
      'Körper im Bild · Blick darf nach unten gehen';

  @override
  String get trackingArmsTracked => 'Arme erkannt · Beine nur eingeschränkt';

  @override
  String get trackingFindTop => 'Geh bequem in den Stütz';

  @override
  String get trackingCalibrated => 'Kalibriert! Beweg mal deinen Vogel.';

  @override
  String get trackingFreshFrame => 'Warte auf ein neues Bild';

  @override
  String get trackingDistanceChanged =>
      'Kameraabstand geändert · neu kalibrieren';

  @override
  String get trackingKeepArm => 'Halte einen Arm im Bild';

  @override
  String get trackingSquatStepBack =>
      'Geh zurück, damit Schultern, Hüften, Knie und Füße im Bild sind';

  @override
  String get trackingSquatFaceCamera =>
      'Schau zur Kamera, beide Füße auf dem Boden';

  @override
  String get trackingSquatControls =>
      'Hock dich hin zum Sinken · steh auf zum Steigen';

  @override
  String get trackingStartingDistance =>
      'Stell dich im Startabstand zur Kamera · neu kalibrieren, wenn du dich bewegt hast';

  @override
  String get trackingFeetPlanted => 'Lass beide Füße auf deinem Startplatz';

  @override
  String get trackingSquatStandTall =>
      'Steh gerade und still, beide Füße im Bild';

  @override
  String get trackingStandStill => 'Steh kurz gerade und still';

  @override
  String get trackingSquatDepth =>
      'Geh bequem tief in die Hocke und halte kurz';

  @override
  String get trackingSquatHold => 'Geh bequem in die Hocke und halte dann kurz';

  @override
  String get trackingSquatHoldBriefly => 'Halte diese bequeme Hocke kurz';

  @override
  String get trackingSquatStandUp =>
      'Steh wieder auf, um die Kalibrierung abzuschließen';

  @override
  String get trackingSquatReady =>
      'Bereit! Hock dich hin zum Sinken · steh auf zum Steigen';

  @override
  String get trackingJumpStepBack =>
      'Geh zurück, damit Schultern, Hüften und beide Füße im Bild sind';

  @override
  String get trackingJumpFaceCamera =>
      'Stell dich vor die Kamera, mit Platz über dir zum Springen';

  @override
  String get trackingJumpSmall =>
      'Kleine Sprünge reichen · lande, bevor du wieder springst';

  @override
  String get trackingJumpStandStill =>
      'Steh still, ganzer Körper und beide Füße im Bild';

  @override
  String get trackingJumpReady =>
      'Bereit! Ein kleiner Sprung gibt einen großen Schub.';

  @override
  String get trackingFindPosition => 'Finde deine Position';

  @override
  String get trackingInterrupted => 'Tracking unterbrochen';

  @override
  String get trackingCameraInterrupted =>
      'Kamera unterbrochen. Prüf die Kamera-Berechtigung und versuch es noch mal.';

  @override
  String get trackingCameraAway =>
      'Kamera wurde gestoppt, während die App im Hintergrund war';

  @override
  String get trackingJumpBoost => 'Spring für einen großen Schub';

  @override
  String get trackingJumpLand => 'Lande für den nächsten Sprung';

  @override
  String trackingLowerMore(int step, int total) {
    return 'Etwas tiefer runter · $step von $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'Bequem runter · $step von $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'Drück dich wieder hoch · $step von $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'So tief wie beim ersten Mal · $step von $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Diese Änderung konnte nicht gespeichert werden. Bitte versuch es noch mal. ($error)';
  }

  @override
  String get commonDelete => 'Löschen';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count fehlen',
      one: 'Noch $count fehlt',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'Dein Nest braucht noch kurz.';

  @override
  String get homeSettings => 'Einstellungen';

  @override
  String homeGreetingFirst(String bird) {
    return 'Hi, ich bin $bird! Bereit zum Fliegen?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Abenteuer geschafft! $bird ist stolz.',
      'female': 'Abenteuer geschafft! $bird ist stolz.',
      'other': 'Abenteuer geschafft! $bird ist stolz.',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird ist bereit. Und du?',
      'female': '$bird ist bereit. Und du?',
      'other': '$bird ist bereit. Und du?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'ENDLOS';

  @override
  String get homeEndlessDetail => 'Flieg, so weit du kannst';

  @override
  String get homeEndlessSemantics => 'Endlos. Flieg, so weit du kannst.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: 'Endlos. Flieg, so weit du kannst. Bestwert: $best Sterne.',
      one: 'Endlos. Flieg, so weit du kannst. Bestwert: $best Stern.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'Bestwert';

  @override
  String get homeBestNone => 'Hol dir einen Bestwert';

  @override
  String get homeCampaignTitle => 'KAMPAGNE';

  @override
  String get homeCampaignDone => 'Jeder Brief zugestellt';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Kampagne. Als Nächstes: $level. $stars von $total Sternen.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Kampagne. Jeder Brief zugestellt. $stars von $total Sternen.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'MINISPIELE';

  @override
  String get homeMiniGamesDetail => 'Training · 2 Spieler';

  @override
  String get homeMiniGamesSemantics =>
      'Minispiele. Liegestütze, Kniebeugen, Sprünge oder zu zweit.';

  @override
  String get homeBuilderTitle => 'LEVEL-BAUKASTEN';

  @override
  String get homeBuilderDetail => 'Bauen · fliegen · teilen';

  @override
  String get homeBuilderSemantics =>
      'Level-Baukasten. Bau eigene Level, flieg sie und teile sie.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Frei nach $count Flügen',
      one: 'Frei nach 1 Flug',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Level-Baukasten. Gesperrt. Frei nach $count Flügen.',
      one: 'Level-Baukasten. Gesperrt. Frei nach 1 Flug.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'Abenteuer';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Heutiges Abenteuer. $done von 3 Zielen geschafft.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'Vögel';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'Vögel. Du fliegst mit $bird.';
  }

  @override
  String get homeDockUpgrades => 'Upgrades';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Upgrades. $stars Sterne zum Ausgeben.',
      one: 'Upgrades. $stars Stern zum Ausgeben.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'Himmelspass';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Himmelspass. $earned von $total Medaillen.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'Rekorde';

  @override
  String get homeMiniGamesPickerTitle => 'Minispiele';

  @override
  String get homeMiniGamesPickerIntro =>
      'Beweg dich zum Fliegen oder teil das Handy mit einem Freund.';

  @override
  String get homeMiniGamesCloseSemantics => 'Minispiele schließen';

  @override
  String get homeMiniGamesPushUpCard =>
      'Runter zum Abtauchen.\nHoch zum Steigen.';

  @override
  String get homeMiniGamesSquatCard =>
      'Tief in die Hocke.\nSteh auf zum Steigen.';

  @override
  String get homeMiniGamesJumpCard =>
      'Spring für Auftrieb.\nGleite für Sterne.';

  @override
  String get homeMiniGamesCoopCard =>
      'Zwei Spieler, ein Handy.\nTeam oder Duell.';

  @override
  String get homeMiniGamesCamera => 'Kamera';

  @override
  String get homeMiniGamesPlayers => '2 Spieler';

  @override
  String get homeMiniGamesCoop => 'Zusammen fliegen';

  @override
  String get birdsTitle => 'Lerne deine Flugcrew kennen.';

  @override
  String birdsFlownTag(int flown, int total) {
    return '$flown VON $total GEFLOGEN';
  }

  @override
  String get birdsStatusCopilot => 'DEIN COPILOT';

  @override
  String get birdsStatusReady => 'STARTKLAR';

  @override
  String get birdsStatusLocked => 'GESPERRT';

  @override
  String get birdsNotFlown => 'Noch nie geflogen';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Flüge',
      one: '1 Flug',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return 'Flieg mit $bird';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return 'Mit $bird statt $current fliegen';
  }

  @override
  String birdsUnlock(String bird) {
    return '$bird freischalten';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird für $price Sterne freischalten',
      one: '$bird für $price Stern freischalten',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird für $price Sterne freischalten, noch nicht genug Sterne',
      one: '$bird für $price Stern freischalten, noch nicht genug Sterne',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'Fliegt mit dir';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, fliegt mit dir';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, fliegt mit dir, neu';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, gesperrt, $price Sterne',
      one: '$bird, gesperrt, $price Stern',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird, neu';
  }

  @override
  String get birdsTagFlying => 'IM FLUG';

  @override
  String get birdsTagNew => 'NEU';

  @override
  String get bird_0_description => 'Kleiner Vogel. Großer Himmel.';

  @override
  String get bird_0_trail => 'Sonnenblasen';

  @override
  String get bird_1_description =>
      'Rosa Bäckchen, Lockenschopf, ganz viel Herz.';

  @override
  String get bird_1_trail => 'Pfirsichherzen';

  @override
  String get bird_2_description => 'Winziger Kolibri. Frische Minze. Vollgas.';

  @override
  String get bird_2_trail => 'Minzblätter';

  @override
  String get bird_3_description =>
      'Verträumte Eule, die im Sternenlicht fliegt.';

  @override
  String get bird_3_trail => 'Sternenstaub-Glitzer';

  @override
  String get upgradesWalletLabel => 'DEINE\nSTERNE';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars Sterne zum Ausgeben',
      one: '$stars Stern zum Ausgeben',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'Mach deinen Vogel stärker.';

  @override
  String get upgradesIntro =>
      'Tipp auf ein Zahnrad, um zu sehen, was es kann. Jeden gesammelten Stern kannst du ausgeben.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, Stufe $level von $max. Nächste Stufe $cost Sterne',
      one: '$power, Stufe $level von $max. Nächste Stufe $cost Stern',
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
          '$power, Stufe $level von $max. Nächste Stufe $cost Sterne, noch nicht genug',
      one:
          '$power, Stufe $level von $max. Nächste Stufe $cost Stern, noch nicht genug',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, Stufe $level von $max. Maximal';
  }

  @override
  String get upgradesMax => 'MAX';

  @override
  String upgradesLevel(int level) {
    return 'Stufe $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'Stufe $level, ganz oben';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now, nächste Stufe $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value %';
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
      other: 'Dann hast du noch $count Sterne.',
      one: 'Dann hast du noch $count Stern.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'Verbessern';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Verbessern für $cost Sterne',
      one: 'Verbessern für $cost Stern',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Verbessern für $cost Sterne, noch nicht genug Sterne',
      one: 'Verbessern für $cost Stern, noch nicht genug Sterne',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'Voll ausgebaut';

  @override
  String get power_shot_name => 'Schusskraft';

  @override
  String get power_shot_blurb =>
      'Halte Schießen gedrückt für einen größeren, härteren Stein.';

  @override
  String get power_sprint_name => 'Sprint';

  @override
  String get power_sprint_blurb => 'Ein Tempostoß, der Gegner im Weg wegfegt.';

  @override
  String get power_shield_name => 'Schild';

  @override
  String get power_shield_blurb =>
      'Hält einen Treffer ab. Sammle im Flug Sterne zum Aufladen.';

  @override
  String get power_magnet_name => 'Magnet';

  @override
  String get power_magnet_blurb =>
      'Flieg perfekt durch Tore, um ihn zu holen. Er zieht Sterne an.';

  @override
  String get power_stat_maxCharge => 'Max. Aufladung';

  @override
  String get power_stat_burstLength => 'Sprintdauer';

  @override
  String get power_stat_cooldown => 'Abklingzeit';

  @override
  String get power_stat_starsToRefill => 'Sterne zum Aufladen';

  @override
  String get power_stat_safeTime => 'Schutzzeit nach dem Bruch';

  @override
  String get power_stat_perfectGates => 'Nötige perfekte Tore';

  @override
  String get power_stat_lasts => 'Dauer';

  @override
  String get power_stat_reach => 'Reichweite';

  @override
  String get passportTitle => 'Dein Himmelspass.';

  @override
  String get passportDailyCard => 'Tageskarte';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total MEDAILLEN';
  }

  @override
  String get passportIntro =>
      'Kleine Abenteuer. Bleibende Andenken. Bronze, Silber und Gold für jeden Stempel.';

  @override
  String get passportNoMedal => 'Noch keine Medaille';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Bronzemedaille',
      'silver': 'Silbermedaille',
      'other': 'Goldmedaille',
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
    return '$stamp. $held. Als Nächstes $next: $goal $current von $target.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. Goldmedaille. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'BIS BRONZE',
      'silver': 'BIS SILBER',
      'other': 'BIS GOLD',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'GESTEMPELT';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: noch keine';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'Bronze';

  @override
  String get passportMedal_silver => 'Silber';

  @override
  String get passportMedal_gold => 'Gold';

  @override
  String get stamp_frequentFlyer_name => 'Vielflieger';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Schließ $n gewertete Flüge ab.',
      one: 'Schließ $n gewerteten Flug ab.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'Auf den Punkt';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flieg $n perfekte Durchflüge entlang der Zielmarken.',
      one: 'Flieg $n perfekten Durchflug entlang der Zielmarken.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'Sternenjäger';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sammle $n Sterne.',
      one: 'Sammle $n Stern.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => 'Sternbild';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sammle $n Sterne in einer ununterbrochenen Serie.',
      one: 'Sammle $n Stern in einer ununterbrochenen Serie.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'Himmelskapitän';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Erziele $n Punkte in einem Endlosflug.',
      one: 'Erziele $n Punkt in einem Endlosflug.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'Wegbereiter';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flieg in $n Endlosflügen mindestens 60 Sekunden.',
      one: 'Flieg in $n Endlosflug mindestens 60 Sekunden.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'Bunter Schwarm';

  @override
  String get stamp_allRounder_name => 'Alleskönner';

  @override
  String get stamp_flockTogether_goalBronze =>
      'Flieg gewertete Flüge mit zwei verschiedenen Vögeln.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'Flieg gewertete Flüge mit allen vier Vögeln.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flieg $n gewertete Flüge mit jedem Vogel.',
      one: 'Flieg $n gewerteten Flug mit jedem Vogel.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'Flieg ein Liegestütz-, Kniebeugen- oder Sprung-Minispiel.';

  @override
  String get stamp_allRounder_goalSilver =>
      'Flieg alle drei Minispiele: Liegestütz, Kniebeuge, Sprung.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flieg $n gewertete Flüge in jedem Minispiel.',
      one: 'Flieg $n gewerteten Flug in jedem Minispiel.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals Medaillen · bei $level',
      one: '$stars★ · $medals Medaille · bei $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'Dein Abenteuer braucht noch kurz.';

  @override
  String get dailyTitle => 'Dein kleines Abenteuer heute.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · $done/3 ZIELE';
  }

  @override
  String get dailyIntro =>
      'Drei Ziele. Jede Steuerung. Ein Endlosflug schafft alle drei.';

  @override
  String get dailyLaunchEndless => 'Endlos';

  @override
  String get dailyPostcardKicker => 'HIMMELSCLUB-POSTKARTE';

  @override
  String get dailyStamped => 'POSTKARTE GESTEMPELT!';

  @override
  String dailyGoalsComplete(int done) {
    return '$done / 3 ZIELE GESCHAFFT';
  }

  @override
  String get dailyDoneNote => 'Ein kleines Abenteuer, nur für dich.';

  @override
  String get dailyOpenNote => 'Schaff alle drei für den Stempel.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal Geschafft';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current von $target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: Postkarte gestempelt';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: $done/3 Ziele';
  }

  @override
  String get dailyNoStreak => 'Neue Ziele. Keine Serie zu verlieren.';

  @override
  String get dailyTheme_0 => 'Morgenrot-Post';

  @override
  String get dailyTheme_1 => 'Pfirsich-Picknick';

  @override
  String get dailyTheme_2 => 'Mondscheinpost';

  @override
  String get dailyTheme_3 => 'Wolkenparade';

  @override
  String get dailyTheme_4 => 'Dämmerschatz';

  @override
  String get dailyTheme_5 => 'Gartenparty';

  @override
  String get task_flights_title => 'Flügel ausbreiten';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Schließ heute $count gewertete Flüge ab.',
      one: 'Schließ heute $count gewerteten Flug ab.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'Weite Horizonte';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Schaff heute $count Tore in gewerteten Flügen.',
      one: 'Schaff heute $count Tor in gewerteten Flügen.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'Taschen voller Sterne';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sammle heute $count Sterne in deinen Flügen.',
      one: 'Sammle heute $count Stern in deinen Flügen.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'Weiterfunkeln';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sammle $count Sterne in einer ununterbrochenen Serie.',
      one: 'Sammle $count Stern in einer ununterbrochenen Serie.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'Genau ins Schwarze';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flieg heute $count perfekte Durchflüge.',
      one: 'Flieg heute $count perfekten Durchflug.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'Die ganze Reise';

  @override
  String get task_finishTrail_goal =>
      'Flieg mindestens 60 Sekunden in einem Endlosflug.';

  @override
  String get recordsTitle => 'Deine kleinen Siege.';

  @override
  String get recordsBestsTitle => 'Deine Sternpunkte zum Schlagen';

  @override
  String get recordsSectionMain => 'HAUPTSPIEL';

  @override
  String get recordsSectionMini => 'MINISPIELE';

  @override
  String get recordsEndless => 'Endlos · Tipp & Flieg';

  @override
  String get recordsCampaignStars => 'Kampagnensterne';

  @override
  String recordsCoopName(String mode) {
    return 'Zusammen fliegen · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gewertete Flüge',
      one: 'gewerteter Flug',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tore',
      one: 'Tor',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zusammen',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Duelle',
      one: 'Duell',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liegestütze',
      one: 'Liegestütz',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kniebeugen',
      one: 'Kniebeuge',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'Letzte Flüge';

  @override
  String get recordsEmptyTitle => 'Großer Himmel. Leeres Blatt.';

  @override
  String get recordsEmptyBody =>
      'Dein erster gewerteter Flug schreibt Geschichte.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds Sek.';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'Klassisch · $date · $seconds Sek.';
  }

  @override
  String get replaySavedSessions => 'Gespeicherte Flüge';

  @override
  String get replayBackToRecordsSemantics => 'Zurück zu den Rekorden';

  @override
  String get replaySessionsLoadFailed => 'Konnte Flüge nicht laden. Nochmal';

  @override
  String get replayEmptyTitle => 'Hier wohnen deine Flüge';

  @override
  String get replayEmptyBody =>
      'Speichere einen Flug nach der Landung, um ihn hier anzusehen.';

  @override
  String get replayEmptyButton => 'Flug auswählen';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds Sek. · $score Sternpunkte',
      one: '$date · $seconds Sek. · $score Sternpunkt',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds Sek. · $score Tore',
      one: '$date · $seconds Sek. · $score Tor',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'Flug löschen';

  @override
  String get replayDeleteTitle => 'Diesen Flug löschen?';

  @override
  String get replayDeleteBody =>
      'Kameravideo und Wiederholung werden entfernt. Deine Punkte bleiben in den Rekorden.';

  @override
  String get replayDeleteFailed =>
      'Flug konnte nicht gelöscht werden. Versuch es noch mal.';

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
    return '$mode · Endlos';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · Übung';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · Endlos · Übung';
  }

  @override
  String get replayOpenFailed => 'Dieser Flug konnte nicht geöffnet werden.';

  @override
  String get replayBackToSessions => 'Zurück zu den Flügen';

  @override
  String get replayCameraPaused =>
      'Die Kamera war in diesem Teil des Flugs pausiert';

  @override
  String get replayCameraUnavailable =>
      'Kameraclip nicht verfügbar · Spiel läuft trotzdem';

  @override
  String get replayCameraLoading => 'Kamera lädt…';

  @override
  String get replayPaused => 'Kurze Verschnaufpause';

  @override
  String get replayHideControlsSemantics => 'Wiedergabe-Steuerung ausblenden';

  @override
  String get replayShowControlsSemantics => 'Wiedergabe-Steuerung einblenden';

  @override
  String get replayBackToSavedSemantics => 'Zurück zu den gespeicherten Flügen';

  @override
  String get replayTitle => 'WIEDERHOLUNG';

  @override
  String replayTitleSession(String session) {
    return 'WIEDERHOLUNG · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'Punkte: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts Herzen',
      one: '$hearts Herz',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'S1 $p1 · S2 $p2 Herzen · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String replayMagnet(int seconds) {
    return 'Magnet $seconds s';
  }

  @override
  String get replayPauseSemantics => 'Pausieren';

  @override
  String get replayPlaySemantics => 'Abspielen';

  @override
  String get replayRestartSemantics => 'Neu starten';

  @override
  String get replayBack5Semantics => '5 Sekunden zurück';

  @override
  String get replayForward5Semantics => '5 Sekunden vor';

  @override
  String get replayHighlightsFinding => 'Suche Flug-Highlights';

  @override
  String get replayHighlightsNone => 'Keine Flug-Highlights verfügbar';

  @override
  String get replayHighlights => 'Flug-Highlights';

  @override
  String get replayHighlightsCloseSemantics => 'Highlights schließen';

  @override
  String get replayHighlightsHint => 'Wähl einen Moment. Schau ab kurz davor.';

  @override
  String get replayViewCorner => 'Kamera in der Ecke';

  @override
  String get replayViewBackground => 'Kamerahintergrund';

  @override
  String get replayViewGameplay => 'Nur das Spiel';

  @override
  String get replayMoveCornerSemantics => 'Kamera-Ecke wechseln';

  @override
  String get replayMuteRecordedSemantics => 'Aufnahmeton stummschalten';

  @override
  String get replayUnmuteRecordedSemantics => 'Aufnahmeton einschalten';

  @override
  String get replayMuteGameSemantics => 'Spielsound stummschalten';

  @override
  String get replayUnmuteGameSemantics => 'Spielsound einschalten';

  @override
  String get replayFullScreenSemantics => 'Steuerung ausblenden / Vollbild';

  @override
  String get replayMomentTakeoff => 'Abflug';

  @override
  String get replayMomentTakeoffDetail => 'Der Himmel gehört dir.';

  @override
  String get replayMomentMagnet => 'Sternmagnet';

  @override
  String get replayMomentMagnetDetail =>
      'Drei perfekte Durchflüge holen die Sterne näher.';

  @override
  String get replayMomentStarTrio => 'Erstes Sterntrio';

  @override
  String get replayMomentStarTrioDetail =>
      'Drei Sterne werden zum Sternbild. +5 Punkte!';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'Jeder Stern der Gruppe gesammelt. +5 Punkte!';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier× Sternenkraft';
  }

  @override
  String get replayMomentStreakDetail => 'Eine funkelnde Sternenserie.';

  @override
  String get replayMomentShield => 'Schild hält';

  @override
  String get replayMomentShieldDetail => 'Knapp vorbei – und noch eine Chance.';

  @override
  String get replayMomentPerfect => 'Erster perfekter Durchflug';

  @override
  String get replayMomentPerfectDetail => 'Mitten durch die Zielmarke.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tore geschafft',
      one: '$count Tor geschafft',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'Ein Stückchen weiter in den Himmel.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Kein Kratzer. +$points Punkte!',
      one: 'Kein Kratzer. +$points Punkt!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Mit Sprintringen in Sicherheit. +$points Punkte!',
      one: 'Mit Sprintringen in Sicherheit. +$points Punkt!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'Sturm überstanden';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Den Trümmern ausgewichen. +$points Punkte!',
      one: 'Den Trümmern ausgewichen. +$points Punkt!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'Route geschafft';

  @override
  String get replayMomentFinal => 'Letzter Moment';

  @override
  String get replayMomentCompleteDetail =>
      'Du hast das Ende der Route erreicht.';

  @override
  String get replayMomentCollisionDetail => 'Sieh dir den letzten Anflug an.';

  @override
  String get replayMomentEndDetail => 'Das Ende dieses Flugs.';

  @override
  String get welcomeTitle => 'Wähle deine Sprache';

  @override
  String get welcomeContinue => 'Auf in die Luft!';

  @override
  String get welcomeHint =>
      'Du kannst sie jederzeit in den Einstellungen ändern.';

  @override
  String get welcomeDevice => 'Sprache deines Handys';

  @override
  String get tutorialTitle => 'Flugschule';

  @override
  String get tutorialSkip => 'Lektion auslassen';

  @override
  String get tutorialSkipTitle => 'Flugschule auslassen?';

  @override
  String get tutorialSkipBody =>
      'Du kannst die Lektion jederzeit in den Einstellungen wiederholen.';

  @override
  String get tutorialSkipConfirm => 'Auslassen';

  @override
  String get tutorialSkipCancel => 'Weiterlernen';

  @override
  String get tutorialRestart => 'Neu starten';

  @override
  String get tutorialGoalFlaps => 'Flattern';

  @override
  String get tutorialGoalStars => 'Sterne sammeln';

  @override
  String get tutorialGoalGates => 'Durch Tore fliegen';

  @override
  String get tutorialGoalBats => 'Fledermäuse k.o.';

  @override
  String get tutorialGoalDoor => 'Steintür knacken';

  @override
  String get tutorialGoalSprint => 'Sprinten';

  @override
  String get tutorialGoalBoss => 'Käpt’n besiegen';

  @override
  String get tutorialPromptTap => 'Tipp!';

  @override
  String get tutorialPromptShoot => 'Drück Schießen';

  @override
  String get tutorialPromptHoldShoot => 'Halte Schießen';

  @override
  String get tutorialPromptSprint => 'Drück Sprint';

  @override
  String get tutorialPraiseNice => 'Gut so!';

  @override
  String get tutorialPraiseGreat => 'Klasse!';

  @override
  String get tutorialPraiseSuper => 'Spitze!';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return 'Die Lektion wartet: $prompt';
  }

  @override
  String get licenceTitle => 'Kurierschein';

  @override
  String get licenceIssuer => 'Himmelsclub-Post';

  @override
  String get licenceHolder => 'Kurier';

  @override
  String get licenceRank => 'Rang';

  @override
  String get licenceRankRookie => 'Grünschnabel';

  @override
  String get licenceSkills => 'Fähigkeiten';

  @override
  String get licenceStamp => 'Geprüft';

  @override
  String licenceSignedBy(String name) {
    return 'Gezeichnet: $name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '1 Stern',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => 'Auf zur ersten Route!';

  @override
  String get licenceAgain => 'Noch mal fliegen';

  @override
  String get settingsTutorial => 'Flugschule';

  @override
  String get settingsTutorialDetail => 'Erste Lektion wiederholen';
}
