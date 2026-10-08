// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonTryAgain => 'Réessayer';

  @override
  String get languageKeyLabel => 'Langue';

  @override
  String languageKeySemantics(String language) {
    return 'Langue : $language. Changer la langue du jeu.';
  }

  @override
  String get languageSystemDefault => 'Langue du téléphone';

  @override
  String languageSystemDetail(String language) {
    return 'Suit ton téléphone : $language';
  }

  @override
  String get languageCurrent => 'Langue actuelle';

  @override
  String get languageName_en => 'Anglais';

  @override
  String get languageName_es_419 => 'Espagnol (Am. latine)';

  @override
  String get languageName_pt_br => 'Portugais (Brésil)';

  @override
  String get languageName_id => 'Indonésien';

  @override
  String get languageName_fr => 'Français';

  @override
  String get languageName_de => 'Allemand';

  @override
  String get languageName_ja => 'Japonais';

  @override
  String get languageName_ko => 'Coréen';

  @override
  String get languageName_tr => 'Turc';

  @override
  String get languageName_zh_hant => 'Chinois traditionnel';

  @override
  String get languageName_ru => 'Russe';

  @override
  String get languageName_ar => 'Arabe';

  @override
  String get voicePackReady => 'Voix prêtes';

  @override
  String get voicePackDownload => 'Obtenir les voix';

  @override
  String voicePackDownloading(int percent) {
    return 'Voix $percent %';
  }

  @override
  String get voicePackStarting => 'Voix en route…';

  @override
  String get voicePackEnglish => 'Voix en anglais';

  @override
  String get voicePackFailed => 'Échec des voix';

  @override
  String get settingsTitle => 'Fais comme chez toi.';

  @override
  String get settingsSectionSound => 'Son';

  @override
  String get settingsSectionComfort => 'Confort';

  @override
  String get settingsMusicTitle => 'Musique du Club du Ciel';

  @override
  String get settingsMusicDetail =>
      'Thèmes des menus, de l’aventure et des boss.';

  @override
  String get settingsEffectsTitle => 'Effets sonores';

  @override
  String get settingsEffectsDetail => 'Vol, combat, bonus et sons des menus.';

  @override
  String get settingsVoicesTitle => 'Voix des personnages';

  @override
  String get settingsVoicesDetail =>
      'Scènes, mots de remerciement et cris de sprint.';

  @override
  String get settingsReducedMotionTitle => 'Animations réduites';

  @override
  String get settingsReducedMotionDetail =>
      'Menus calmes, moins d’effets décoratifs.';

  @override
  String get settingsSwitchOn => 'OUI';

  @override
  String get settingsSwitchOff => 'NON';

  @override
  String get settingsUnavailable => 'Tes réglages se font attendre.';

  @override
  String get settingsPrivacyKicker => 'EN LOCAL. TOUJOURS.';

  @override
  String get settingsPrivacyTitle => 'Ta caméra reste à toi.';

  @override
  String get settingsPrivacyBody =>
      'La vidéo et le son du micro (facultatif) restent sur ce téléphone. Clips non gardés effacés. Aucun envoi.';

  @override
  String get settingsCameraLab => 'Labo caméra et suivi';

  @override
  String get settingsAbout => 'À propos et licences';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'À propos et licences, version $version';
  }

  @override
  String get settingsReset => 'Effacer la progression';

  @override
  String settingsResetDone(String bird) {
    return 'Un nouveau départ. $bird t’attend.';
  }

  @override
  String get settingsResetTitle => 'Repartir à zéro ?';

  @override
  String get settingsResetBody =>
      'Cela efface de ce téléphone tes vidéos, rediffusions, scores, parties, niveaux créés et réglages. C’est définitif.';

  @override
  String get settingsResetBodyCloud =>
      'Cela efface de ce téléphone tes vidéos, rediffusions, scores, parties, niveaux créés et réglages, ainsi que ta sauvegarde cloud Google Play Jeux. C’est définitif.';

  @override
  String get settingsResetConfirm => 'Tout effacer';

  @override
  String get settingsResetKeep => 'Garder mes progrès';

  @override
  String get playGamesName => 'Google Play Jeux';

  @override
  String get playGamesConnected => 'Connecté';

  @override
  String get playGamesNotConnected => 'Non connecté';

  @override
  String get playGamesConnecting => 'Connexion…';

  @override
  String get playGamesConnectFailed => 'Connexion impossible';

  @override
  String get playGamesIdle => 'Sauvegarde cloud et succès';

  @override
  String get playGamesSaving => 'Sauvegarde dans le cloud…';

  @override
  String get playGamesOfflineUnsaved => 'Hors ligne · pas encore sauvé';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'Hors ligne · sauvé il y a $ago';
  }

  @override
  String get playGamesUpdateNeeded => 'Mets à jour pour synchroniser';

  @override
  String get playGamesUnreadable => 'Sauvegarde cloud illisible';

  @override
  String get playGamesOn => 'Sauvegarde cloud activée';

  @override
  String get playGamesResetElsewhere => 'Effacé sur un autre téléphone';

  @override
  String playGamesRestored(String ago) {
    return 'Cloud restauré il y a $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'Cloud : sauvé il y a $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Succès Google Play Jeux';

  @override
  String get playGamesConnectSemantics => 'Se connecter à Google Play Jeux';

  @override
  String get playGamesAchievements => 'Succès';

  @override
  String get playGamesConnect => 'Se connecter';

  @override
  String get timeAgoJustNow => 'un instant';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours h',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days j',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '+1 VIE !';

  @override
  String calloutStarTrio(int points) {
    return '3 ÉTOILES +$points !';
  }

  @override
  String get calloutNiceShot => 'BEAU TIR !';

  @override
  String calloutNiceShotPoints(int points) {
    return 'BEAU TIR +$points !';
  }

  @override
  String get calloutSmash => 'CRAC !';

  @override
  String calloutSmashPoints(int points) {
    return 'CRAC +$points !';
  }

  @override
  String calloutSmashChain(int count) {
    return 'CRAC ×$count !';
  }

  @override
  String get calloutBossDown => 'BOSS BATTU !';

  @override
  String calloutBossDownPoints(int points) {
    return 'BOSS BATTU +$points !';
  }

  @override
  String calloutStarPower(int multiplier) {
    return 'ÉTOILES ×$multiplier !';
  }

  @override
  String get calloutPerfect => 'PARFAIT !';

  @override
  String calloutPerfectChain(int count) {
    return 'PARFAIT ×$count';
  }

  @override
  String get calloutShieldReady => 'BOUCLIER PRÊT';

  @override
  String get calloutShieldSave => 'COUP BLOQUÉ !';

  @override
  String get calloutKeepFlying => 'TIENS BON !';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PORTES !',
      one: '$count PORTE !',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds SECONDES !',
      one: '$seconds SECONDE !',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => 'AIMANT !';

  @override
  String get calloutSprintRing => 'ANNEAU DORÉ !';

  @override
  String calloutRushChain(int count) {
    return 'RUÉE ×$count !';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'MÉTÉORE +$points !';
  }

  @override
  String calloutBatPoints(int points) {
    return 'VLAN +$points !';
  }

  @override
  String get calloutScorched => 'ÇA BRÛLE !';

  @override
  String get region_jungle => 'Jungle';

  @override
  String get region_antarctica => 'Antarctique';

  @override
  String get region_aztec => 'Pays aztèque';

  @override
  String get region_paris => 'Paris';

  @override
  String get region_egypt => 'Égypte';

  @override
  String get region_cyberpunk => 'Cité cyberpunk';

  @override
  String get region_china => 'Chine';

  @override
  String get region_brazil => 'Brésil';

  @override
  String get region_newYork => 'New York';

  @override
  String get region_arabia => 'Arabie antique';

  @override
  String get region_rome => 'Rome antique';

  @override
  String get region_mexico => 'Mexique';

  @override
  String get region_sea => 'Haute mer';

  @override
  String get boss_baronBat_name => 'Baron Chauve-Souris';

  @override
  String get boss_spitterBeetle_name => 'Roi Cracheur';

  @override
  String get boss_duskMoth_name => 'Impératrice du Crépuscule';

  @override
  String get boss_pirate_name => 'Capitaine Pirate';

  @override
  String get boss_dragon_name => 'Dragon des Braises';

  @override
  String get boss_kingCoo_name => 'Roi Roucou';

  @override
  String get boss_searchlightGargoyle_name => 'Gargouille aux Projecteurs';

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
  String get playMode_pushUp => 'Vol en pompes';

  @override
  String get playMode_jump => 'Saute & Vole';

  @override
  String get playMode_touch => 'Tape & Vole';

  @override
  String get playMode_squat => 'Squat & Vole';

  @override
  String get chapter_1_route => 'La Route de la Canopée';

  @override
  String get chapter_1_postmark => 'ROUTE DE LA CANOPÉE';

  @override
  String get chapter_1_postcard =>
      'Les lettres arrivent de nouveau à la cime des arbres ! Les toucans te disent merci (très fort). La couronne du Baron trône sur notre cheminée.';

  @override
  String get chapter_1_postscript =>
      'Sur la Voie antique, ça sent la potion qui mijote.';

  @override
  String get chapter_2_route => 'La Voie antique';

  @override
  String get chapter_2_postmark => 'VOIE ANTIQUE';

  @override
  String get chapter_2_postcard =>
      'Les caravanes roulent et la seule chose qui mijote, c’est le thé à la menthe. La couronne-fiole du Roi nous sert de vase.';

  @override
  String get chapter_2_postscript =>
      'Cette nuit, les lampadaires se sont éteints. Prends une lampe.';

  @override
  String get chapter_3_route => 'La Ligne des Lampadaires';

  @override
  String get chapter_3_postmark => 'LIGNE LAMPADAIRES';

  @override
  String get chapter_3_postcard =>
      'Les lampadaires brillent et le courrier de nuit est bien réveillé ! Paris t’envoie un croissant. New York, un bretzel.';

  @override
  String get chapter_3_postscript => 'Les cloches du port ont cessé de sonner.';

  @override
  String get chapter_4_route => 'La Route des Marées';

  @override
  String get chapter_4_postmark => 'ROUTE DES MARÉES';

  @override
  String get chapter_4_postcard =>
      'Les cloches du port sonnent de nouveau pour les lettres, plus pour les canons. Le perroquet est resté. Il te dit bonjour.';

  @override
  String get chapter_4_postscript =>
      'On dit que le ciel brûle au bout de la carte.';

  @override
  String get chapter_5_route => 'Le Bout de la carte';

  @override
  String get chapter_5_postmark => 'BOUT DE LA CARTE';

  @override
  String get chapter_5_postcard =>
      'Le ciel est dégagé d’un pôle à l’autre et toutes les routes tournent. Tout le Club du Ciel est fier de toi.';

  @override
  String get chapter_5_postscript =>
      'Le ciel infini t’attend toujours, quand tu veux.';

  @override
  String get level_1_1_name => 'Première livraison';

  @override
  String get level_1_1_cargo =>
      'Une carte d’anniversaire pour les jumeaux toucans';

  @override
  String get level_1_1_sender => 'Les jumeaux toucans';

  @override
  String get level_1_1_hint =>
      'Tape pour battre des ailes. Attrape les étoiles.';

  @override
  String get level_1_2_name => 'Série d’étoiles';

  @override
  String get level_1_2_cargo =>
      'Des cartes du ciel pour le paresseux astronome';

  @override
  String get level_1_2_sender => 'Le paresseux astronome';

  @override
  String get level_1_2_hint =>
      'Enchaîne les étoiles pour un ×3 ; trois portes parfaites donnent un aimant.';

  @override
  String get level_1_3_name => 'Ronde des chauves-souris';

  @override
  String get level_1_3_cargo => 'Des veilleuses pour la crèche des lucioles';

  @override
  String get level_1_3_sender => 'La crèche des lucioles';

  @override
  String get level_1_3_hint =>
      'Tirer ! Touche Tirer pour assommer les chauves-souris.';

  @override
  String get level_1_4_name => 'Ciel de carnaval';

  @override
  String get level_1_4_cargo => 'Des boas à plumes pour le défilé du carnaval';

  @override
  String get level_1_4_sender => 'Les aras de la samba';

  @override
  String get level_1_4_hint =>
      'Bourrasque ! Guette le « ! » et évite les ballons de foot.';

  @override
  String get level_1_5_name => 'Poste express';

  @override
  String get level_1_5_cargo => 'Invitation urgente pour le chef des tambours';

  @override
  String get level_1_5_sender => 'Le chef des tambours';

  @override
  String get level_1_5_hint =>
      'Le Sprint écrase les chauves-souris et te propulse en avant.';

  @override
  String get level_1_6_name => 'Les Marches du temple';

  @override
  String get level_1_6_cargo =>
      'Des fèves de cacao pour les cuisiniers du temple';

  @override
  String get level_1_6_sender => 'Les cuisiniers du temple';

  @override
  String get level_1_7_name => 'Perchoir de l’aube';

  @override
  String get level_1_7_cargo => 'Un cadran solaire pour le gardien de l’aube';

  @override
  String get level_1_7_sender => 'Le gardien de l’aube';

  @override
  String get level_1_8_name => 'Baron Chauve-Souris';

  @override
  String get level_1_8_cargo => 'Un dernier avis pour le Baron Chauve-Souris';

  @override
  String get level_1_8_sender => 'Baron Chauve-Souris';

  @override
  String get level_2_1_name => 'La Voie des scarabées';

  @override
  String get level_2_1_cargo => 'Des lauriers pour les coureurs de chars';

  @override
  String get level_2_1_sender => 'Les coureurs de chars';

  @override
  String get level_2_1_hint =>
      'Les scarabées crachent des graines. Tire pour les abattre.';

  @override
  String get level_2_2_name => 'Portes scellées';

  @override
  String get level_2_2_cargo => 'Un ciseau neuf pour le sculpteur';

  @override
  String get level_2_2_sender => 'Le sculpteur';

  @override
  String get level_2_2_hint =>
      'Maintiens Tirer pour lancer un gros caillou qui brise la pierre.';

  @override
  String get level_2_3_name => 'Course contre l’incendie';

  @override
  String get level_2_3_cargo => 'Des seaux d’eau pour les pompiers';

  @override
  String get level_2_3_sender => 'Les pompiers';

  @override
  String get level_2_3_hint =>
      'Passe dans les anneaux dorés pour semer l’incendie !';

  @override
  String get level_2_4_name => 'Les Lacets du Nil';

  @override
  String get level_2_4_cargo => 'Un livre de nouvelles énigmes pour le Sphinx';

  @override
  String get level_2_4_sender => 'Le Sphinx';

  @override
  String get level_2_5_name => 'Le ciel tombe';

  @override
  String get level_2_5_cargo => 'Un télescope pour l’astronome de la pyramide';

  @override
  String get level_2_5_sender => 'L’astronome de la pyramide';

  @override
  String get level_2_5_hint => 'Les sprints d’anneau pulvérisent les météores.';

  @override
  String get level_2_6_name => 'Retour à l’envoyeur';

  @override
  String get level_2_6_cargo => 'Un plumeau pour la gardienne';

  @override
  String get level_2_6_sender => 'La gardienne de la pyramide';

  @override
  String get level_2_6_hint =>
      'Tire sur ses lettres pour les renvoyer. Retour à l’envoyeur !';

  @override
  String get level_2_7_name => 'Le Souk aux lanternes';

  @override
  String get level_2_7_cargo => 'De l’huile pour les marchands de lanternes';

  @override
  String get level_2_7_sender => 'Les marchands de lanternes';

  @override
  String get level_2_8_name => 'La Longue Caravane';

  @override
  String get level_2_8_cargo => 'Des gourdes pour la longue caravane';

  @override
  String get level_2_8_sender => 'Le chef de caravane';

  @override
  String get level_2_9_name => 'Roi Cracheur';

  @override
  String get level_2_9_cargo => 'Interdiction de potion pour le Roi Cracheur';

  @override
  String get level_2_9_sender => 'Roi Cracheur';

  @override
  String get level_3_1_name => 'Papillons et lumières';

  @override
  String get level_3_1_cargo => 'Des ampoules pour la marquise du théâtre';

  @override
  String get level_3_1_sender => 'Le régisseur';

  @override
  String get level_3_1_hint =>
      'Les papillons tirent en éventails de trois. Glisse-toi entre eux.';

  @override
  String get level_3_2_name => 'Roulons sous la pluie';

  @override
  String get level_3_2_cargo => 'Des parapluies pour les pigeons du kiosque';

  @override
  String get level_3_2_sender => 'Les pigeons du kiosque';

  @override
  String get level_3_2_hint =>
      'Les pigeons des ruelles piquent pour voler les étoiles. Abats-les d’abord !';

  @override
  String get level_3_3_name => 'La Ruelle à vapeur';

  @override
  String get level_3_3_cargo => 'Des bretzels chauds pour les taxis de nuit';

  @override
  String get level_3_3_sender => 'Les taxis de nuit';

  @override
  String get level_3_3_hint =>
      'Les bouches sifflent puis jaillissent. Saute les chaudes, monte sur les douces.';

  @override
  String get level_3_4_name => 'Alerte tempête';

  @override
  String get level_3_4_cargo => 'Une girouette pour la plus haute tour';

  @override
  String get level_3_4_sender => 'Le gardien de la tour';

  @override
  String get level_3_4_hint =>
      'Reste hors de la lumière. Tire sur la lampe quand elle s’ouvre ! Pas de Sprint ici.';

  @override
  String get level_3_5_name => 'Toits de cristal';

  @override
  String get level_3_5_cargo => 'Des croissants pour les peintres des toits';

  @override
  String get level_3_5_sender => 'Les peintres des toits';

  @override
  String get level_3_6_name => 'Après la bourrasque';

  @override
  String get level_3_6_cargo => 'Des partitions pour l’accordéoniste';

  @override
  String get level_3_6_sender => 'L’accordéoniste';

  @override
  String get level_3_6_hint =>
      'Bourrasque ! Guette le « ! » et prends le côté libre.';

  @override
  String get level_3_7_name => 'Express de minuit';

  @override
  String get level_3_7_cargo =>
      'Une lettre d’amour de minuit pour la boulangère';

  @override
  String get level_3_7_sender => 'La boulangère';

  @override
  String get level_3_7_hint => 'Traverse les nuées en Sprint.';

  @override
  String get level_3_8_name => 'Impératrice du Crépuscule';

  @override
  String get level_3_8_cargo => 'Un réveil en fanfare pour l’Impératrice';

  @override
  String get level_3_8_sender => 'Impératrice du Crépuscule';

  @override
  String get level_4_1_name => 'Lumières du port';

  @override
  String get level_4_1_cargo => 'Une lentille neuve pour la gardienne du phare';

  @override
  String get level_4_1_sender => 'La gardienne du phare';

  @override
  String get level_4_2_name => 'Le Col du volcan';

  @override
  String get level_4_2_cargo => 'Des maniques pour la pâtissière du volcan';

  @override
  String get level_4_2_sender => 'La pâtissière du volcan';

  @override
  String get level_4_2_hint => 'Saute par-dessus les jets de lave.';

  @override
  String get level_4_3_name => 'Le Long de la côte';

  @override
  String get level_4_3_cargo => 'Du fil à cerf-volant pour la fête de la plage';

  @override
  String get level_4_3_sender => 'Les cerfs-volistes';

  @override
  String get level_4_4_name => 'Marée basse';

  @override
  String get level_4_4_cargo => 'Une réponse pour l’ermite de l’île';

  @override
  String get level_4_4_sender => 'L’ermite de l’île';

  @override
  String get level_4_4_hint => 'Ne touche pas l’eau.';

  @override
  String get level_4_5_name => 'Grande Marée';

  @override
  String get level_4_5_cargo =>
      'Un horaire des marées pour l’équipage du ferry';

  @override
  String get level_4_5_sender => 'L’équipage du ferry';

  @override
  String get level_4_5_hint => 'Quand la cloche sonne, vole haut.';

  @override
  String get level_4_6_name => 'Baie de la Bordée';

  @override
  String get level_4_6_cargo =>
      'Des biscuits au poisson pour la colonie de mouettes';

  @override
  String get level_4_6_sender => 'La colonie de mouettes';

  @override
  String get level_4_7_name => 'Traversée houleuse';

  @override
  String get level_4_7_cargo =>
      'Des chaussettes sèches pour les marins de vigie';

  @override
  String get level_4_7_sender => 'La vigie des tempêtes';

  @override
  String get level_4_8_name => 'Capitaine Pirate';

  @override
  String get level_4_8_cargo =>
      'Ordre de rendre le courrier, pour le Capitaine';

  @override
  String get level_4_8_sender => 'Capitaine Pirate';

  @override
  String get level_5_1_name => 'Poste de l’aurore';

  @override
  String get level_5_1_cargo => 'Des bonnets pour la chorale des manchots';

  @override
  String get level_5_1_sender => 'La chorale des manchots';

  @override
  String get level_5_1_hint =>
      'Désormais, n’importe quelle ruée peut arriver. Lis le bandeau !';

  @override
  String get level_5_2_name => 'Nuit polaire';

  @override
  String get level_5_2_cargo => 'Du chocolat chaud pour la station polaire';

  @override
  String get level_5_2_sender => 'La station polaire';

  @override
  String get level_5_3_name => 'Néon Express';

  @override
  String get level_5_3_cargo =>
      'Des fusibles pour l’enseigne du bar à nouilles';

  @override
  String get level_5_3_sender => 'Le chef du bar à nouilles';

  @override
  String get level_5_4_name => 'Tempête de données';

  @override
  String get level_5_4_cargo => 'Une lettre en papier pour un robot curieux';

  @override
  String get level_5_4_sender => 'Unité 7';

  @override
  String get level_5_5_name => 'Sprint sur les toits';

  @override
  String get level_5_5_cargo =>
      'Des billets de course pour les coureurs des toits';

  @override
  String get level_5_5_sender => 'Les coureurs des toits';

  @override
  String get level_5_6_name => 'Fête des lanternes';

  @override
  String get level_5_6_cargo => 'Des lanternes en papier pour la fête';

  @override
  String get level_5_6_sender => 'Les fabricants de lanternes';

  @override
  String get level_5_7_name => 'La Dernière Ligne droite';

  @override
  String get level_5_7_cargo => 'Du thé des montagnes pour le monastère';

  @override
  String get level_5_7_sender => 'Les moines de la montagne';

  @override
  String get level_5_8_name => 'Dragon des Braises';

  @override
  String get level_5_8_cargo => 'La toute première lettre envoyée au Dragon';

  @override
  String get level_5_8_sender => 'Dragon des Braises';

  @override
  String get storyPostmasterName => 'Maître de poste Bill';

  @override
  String get storySkip => 'Passer';

  @override
  String get storyNextLineSemantics => 'Réplique suivante';

  @override
  String get storyFinishSemantics => 'Terminer';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name : $line';
  }

  @override
  String get campaignMotto => 'Chaque lettre arrive à bon port.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => 'Vole !';

  @override
  String levelIntroRunUp(int seconds) {
    return 'D’abord $seconds s d’approche';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'Environ $seconds s jusqu’à l’arrivée';
  }

  @override
  String get campaignGuardian => 'GARDIEN';

  @override
  String get levelIntroBossFight => 'COMBAT DE BOSS';

  @override
  String get levelIntroNew => 'NOUVEAU';

  @override
  String get levelIntroTip => 'ASTUCE';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Bats le $boss',
      'spitterBeetle': 'Bats le $boss',
      'duskMoth': 'Bats l’$boss',
      'pirate': 'Bats le $boss',
      'dragon': 'Bats le $boss',
      'kingCoo': 'Bats le $boss',
      'searchlightGargoyle': 'Bats la $boss',
      'other': 'Bats $boss',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroGoalFinish => 'Atteins l’arrivée';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attrape $count étoiles',
      one: 'Attrape $count étoile',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Une étoile : $goal.',
      'two': 'Deux étoiles : $goal.',
      'other': 'Trois étoiles : $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Une étoile : $goal. Obtenue.',
      'two': 'Deux étoiles : $goal. Obtenues.',
      'other': 'Trois étoiles : $goal. Obtenues.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Record : $count étoiles',
      one: 'Record : $count étoile',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'Pas encore livré';

  @override
  String get levelIntroFirstFlight => 'Premier vol';

  @override
  String get levelIntroControlFlap => 'Voler';

  @override
  String get levelIntroControlShoot => 'Tirer';

  @override
  String get levelIntroControlSprint => 'Sprint';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Commandes : Voler.',
      'shoot': 'Commandes : Voler, Tirer.',
      'sprint': 'Commandes : Voler, Sprint.',
      'other': 'Commandes : Voler, Tirer, Sprint.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => 'LIVRAISON SPÉCIALE';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return 'Livraison spéciale : $cargo.';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return 'Niveau $level, $name. $region.';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return 'Niveau $level, $name. $region. Gardien : $boss.';
  }

  @override
  String get levelIntroStory => 'Histoire';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonHome => 'Accueil';

  @override
  String get commonBackHome => 'Retour à l’accueil';

  @override
  String get campaignComingSoon => 'Bientôt';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — bientôt';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Bats d’abord le $boss',
      'spitterBeetle': 'Bats d’abord le $boss',
      'duskMoth': 'Bats d’abord l’$boss',
      'pirate': 'Bats d’abord le $boss',
      'dragon': 'Bats d’abord le $boss',
      'kingCoo': 'Bats d’abord le $boss',
      'searchlightGargoyle': 'Bats d’abord la $boss',
      'other': 'Bats d’abord $boss',
    });
    return '$_temp0';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'Termine le $level pour débloquer';
  }

  @override
  String get campaignMapUnavailable => 'La carte se fait attendre.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return 'Fermer $name';
  }

  @override
  String get campaignMapPreviousStop => 'Étape précédente';

  @override
  String get campaignMapNextStop => 'Étape suivante';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. Chapitre $chapter, $route. Bientôt.',
      'locked': '$region. Chapitre $chapter, $route. Verrouillé.',
      'other': '$region. Chapitre $chapter, $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return 'CHAPITRE $chapter · $route';
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
      'guardian': 'Niveau $level, $name, gardien : $boss',
      'other': 'Niveau $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. Verrouillé.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. Verrouillé. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars étoiles sur 3',
      one: '$stars étoile sur 3',
    );
    return '$node. Prochain niveau. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars étoiles sur 3',
      one: '$stars étoile sur 3',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'Gargouille',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return 'Carte postale du chapitre $chapter';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars sur $total étoiles de la campagne',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'Cher facteur,';

  @override
  String get campaignPostcardPs => 'P.-S.';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'Carte postale — $route. Cher facteur, $body P.-S. $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'Bons baisers de';

  @override
  String get campaignPostcardHeader => 'CARTE POSTALE · CLUB DU CIEL';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'Le facteur';

  @override
  String get campaignPostcardAddressStreet => 'Poste du Club';

  @override
  String get campaignPostcardAddressCity => 'Au septième ciel';

  @override
  String get campaignPostmarkDelivered => 'LIVRÉ';

  @override
  String get campaignPostmarkClub => 'CLUB DU CIEL';

  @override
  String get campaignStampSkyClub => 'CLUB CIEL';

  @override
  String campaignThanksQuoted(String thanks) {
    return '« $thanks »';
  }

  @override
  String campaignThanksSignature(String sender) {
    return '— $sender';
  }

  @override
  String campaignThanksSemantics(String sender, String thanks) {
    return 'Mot de remerciement — $sender : $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'Un peu de réglages, beaucoup de ciel.';

  @override
  String get flightSetupTitleSquat => 'Pieds au sol. Ailes ouvertes.';

  @override
  String get flightSetupTitleJump => 'Petits sauts. Grandes ailes.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'NIVEAU · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · AVEC SCORE';
  }

  @override
  String get flightSetupRoomPushUp => 'Fais un peu de place pour bouger.';

  @override
  String get flightSetupRoomBody => 'Montre tout ton corps.';

  @override
  String get flightSetupTipsPushUp =>
      'Téléphone bas. Montre un bras et une hanche.\nDe face ? Garde les deux épaules visibles.';

  @override
  String get flightSetupTipsSquat =>
      'Accroupis-toi pour descendre. Lève-toi pour monter.\nGarde les deux pieds au sol.';

  @override
  String get flightSetupTipsJump =>
      'Saute pour un élan + 3 s de vol plané.\nAtterris avant de ressauter.';

  @override
  String get flightSetupHowToFly => 'COMMENT VOLER';

  @override
  String get flightSetupStep1PushUp => 'Montre ton bras et ta hanche';

  @override
  String get flightSetupStep1Squat => 'De la place pour t’accroupir';

  @override
  String get flightSetupStep1Jump => 'De la place pour sauter';

  @override
  String get flightSetupStep1DetailPushUp =>
      'Face au téléphone ? Montre les deux épaules, un bras et une hanche.';

  @override
  String get flightSetupStep1DetailBody =>
      'Téléphone à l’horizontale. Montre ton corps et tes deux pieds.';

  @override
  String get flightSetupStep2PushUp => 'Trouve ton amplitude';

  @override
  String get flightSetupStep2Squat => 'Trouve ton squat confortable';

  @override
  String get flightSetupStep2Jump => 'Debout, sans bouger';

  @override
  String get flightSetupStep2DetailPushUp =>
      'Trouve une position haute confortable, puis descends et remonte deux fois.';

  @override
  String get flightSetupStep2DetailSquat =>
      'Reste immobile, accroupis-toi un instant, puis relève-toi.';

  @override
  String get flightSetupStep2DetailJump =>
      'Ne bouge plus un instant. Puis saute pour un grand élan.';

  @override
  String get flightSetupStep3Stars => 'Attrape des étoiles';

  @override
  String get flightSetupStep3DetailJump =>
      'Chaque étoile ajoute 0,75 s de vol plané, jusqu’à 5 s. Les trios valent +5 points.';

  @override
  String get flightSetupLivesEndless =>
      'Trois cœurs + un bouclier. Pause possible à tout moment.';

  @override
  String get flightSetupLivesClassic =>
      'Une collision ou une perte de position met fin au vol comptabilisé. Pause possible à tout moment.';

  @override
  String get flightSetupCameraButton => 'Régler ma caméra';

  @override
  String get flightMicTitle => 'Enregistrer le micro';

  @override
  String get flightMicOn => 'Activé';

  @override
  String get flightMicOptional => 'Facultatif';

  @override
  String get flightMicDetail =>
      'Ajoute ta voix et le son ambiant aux rediffusions. Micro utilisé pendant le vol uniquement. Enregistré sur ce téléphone.';

  @override
  String get flightMicSemantics => 'Enregistrer le micro pour les rediffusions';

  @override
  String get flightMicSettings => 'Réglages du micro';

  @override
  String get flightCalibrationTitleReady => 'Tu as trouvé tes ailes !';

  @override
  String get flightCalibrationTitleWaking => 'On réveille ta caméra…';

  @override
  String get flightCalibrationTitleError => 'Reconnectons ta caméra.';

  @override
  String get flightCalibrationTitleRange => 'Trouve ton amplitude.';

  @override
  String get flightCalibrationTitleStill => 'Debout, sans bouger.';

  @override
  String get flightCalibrationStepTry => 'Essaie de diriger ton oiseau.';

  @override
  String get flightCalibrationStepTop => 'Trouve une position haute.';

  @override
  String get flightCalibrationStepLower => 'Descends doucement.';

  @override
  String get flightCalibrationStepPushBack => 'Remonte.';

  @override
  String get flightCalibrationStepStill => 'Debout, sans bouger.';

  @override
  String get flightCalibrationStepSquat => 'Accroupis-toi tranquillement.';

  @override
  String get flightCalibrationStepStandUp => 'Relève-toi.';

  @override
  String get flightCalibrationStepDone => 'Tu as trouvé tes ailes !';

  @override
  String get flightCalibrationReadyPushUp =>
      'Pousse pour monter. Descends pour planer.';

  @override
  String get flightCalibrationReadySquat =>
      'Accroupis-toi pour descendre. Lève-toi pour monter.';

  @override
  String get flightCalibrationReadyJump =>
      'Saute, puis repose-toi pendant que ton oiseau plane.';

  @override
  String get flightCalibrationKeepPushUp =>
      'Garde tes épaules, un bras et une hanche visibles. Bouge à ton aise.';

  @override
  String get flightCalibrationKeepBody =>
      'Garde tes épaules, tes hanches et tes deux pieds visibles.';

  @override
  String get flightCalibrationLearning => 'Bouge, on apprend ton amplitude.';

  @override
  String get flightCalibrationAfter => 'Ton oiseau bouge après le calibrage.';

  @override
  String get flightCalibrationJump => 'Saute !';

  @override
  String get flightCalibrationTagCheck => 'TEST DES COMMANDES';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '$count / 2 POMPES';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return 'CALIBRÉ À $percent %';
  }

  @override
  String get flightCalibrationTakeoff => 'On décolle !';

  @override
  String get flightCalibrationStarting => 'Démarrage…';

  @override
  String get flightCalibrationRestart => 'Recommencer le calibrage';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate mises à jour/s · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate mises à jour/s · $p95 ms p95 (traitement seul)';
  }

  @override
  String get flightCalibrationStatusReady => 'PRÊT';

  @override
  String get flightCalibrationStatusStarting => 'DÉMARRAGE';

  @override
  String get flightCalibrationStatusCameraOff => 'CAMÉRA COUPÉE';

  @override
  String get flightCalibrationStatusCalibrating => 'CALIBRAGE';

  @override
  String get flightSwitchCameraSemantics => 'Changer de caméra';

  @override
  String get flightCalibrationStepIntoView => 'Mets-toi dans le champ';

  @override
  String get flightCameraTroubleTitle => 'Un nouveau départ aide souvent.';

  @override
  String get flightCameraTroubleAllow =>
      'Autorise l’accès à la caméra dans les Paramètres.';

  @override
  String get flightCameraTroubleClose =>
      'Ferme toute autre appli de caméra, puis réessaie.';

  @override
  String get flightCameraPermissionSemantics =>
      'Paramètres d’autorisation de la caméra';

  @override
  String get flightNoteRememberFailed =>
      'Modifié pour ce vol. Impossible de mémoriser ton choix.';

  @override
  String get flightNoteMicUnavailable =>
      'Micro indisponible. La vidéo et le jeu fonctionnent quand même.';

  @override
  String get flightNoteMicBlocked =>
      'Micro bloqué. Tu peux l’autoriser dans les Paramètres ; la vidéo fonctionne toujours.';

  @override
  String get flightNoteMicOff =>
      'Micro coupé. Tu peux quand même jouer et enregistrer la vidéo.';

  @override
  String get flightNoteVideoUnavailable =>
      'Vidéo de la caméra indisponible. La partie peut quand même être enregistrée.';

  @override
  String get flightNoteMicAudioLost =>
      'Le son du micro était indisponible. Ta vidéo et ta partie peuvent quand même être enregistrées.';

  @override
  String get flightNoteVideoInterrupted =>
      'Vidéo de la caméra interrompue. Les images disponibles et la partie peuvent quand même être enregistrées.';

  @override
  String get flightNoteSessionSaveFailed =>
      'Impossible d’enregistrer la séance. Touche Garder la séance pour réessayer.';

  @override
  String get flightNoteWakingCamera => 'On réveille ta caméra…';

  @override
  String get flightNoteCameraOff =>
      'L’accès à la caméra est désactivé. Autorise-le dans les paramètres Android, puis reviens réessayer.';

  @override
  String get flightNoteCameraFailed =>
      'La caméra n’a pas pu démarrer. Réessaie ou change de caméra.';

  @override
  String get flightNotePreparing => 'Préparation de ta séance…';

  @override
  String get flightNoteSaveFailed =>
      'Impossible d’enregistrer ton vol. Touche pour réessayer.';

  @override
  String get flightNoteWelcomeBack =>
      'Te revoilà ! Vérifions à nouveau ta position.';

  @override
  String get flightNoteCameraInterrupted =>
      'Caméra interrompue. Vérifie l’autorisation de la caméra et réessaie.';

  @override
  String get flightNoteTrackingInterrupted => 'Suivi interrompu';

  @override
  String get flightFindPosition => 'Trouve ta position';

  @override
  String get flightTapSemantics => 'Touche pour battre des ailes';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'Touche pour battre des ailes. Avant-garde du boss : $group';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'Touche pour battre des ailes. $boss : $hp points de vie sur $maxHp';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'Touche pour battre des ailes. $boss : $hp points de vie sur $maxHp. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'Passer aux résultats';

  @override
  String get hudPauseSemantics => 'Mettre le vol en pause';

  @override
  String get flightHintTestSteerKeys =>
      'Vol d’essai : flèches Haut et Bas pour diriger.';

  @override
  String get flightHintTestSteerDrag =>
      'Vol d’essai : glisse vers le haut ou le bas pour diriger.';

  @override
  String get flightHintTestJumpKeys => 'Vol d’essai : Espace pour sauter.';

  @override
  String get flightHintTestJumpTap =>
      'Vol d’essai : touche l’écran pour sauter.';

  @override
  String get flightHintKeysStars =>
      'Espace pour battre des ailes. Attrape les étoiles.';

  @override
  String get flightHintKeysShoot =>
      'Espace pour battre des ailes. Maintiens D pour charger un tir.';

  @override
  String get flightHintKeysCombat =>
      'Espace pour battre des ailes. Maintiens D pour charger un tir. A pour sprinter !';

  @override
  String get flightHintKeysPause =>
      'Espace pour battre des ailes. Échap pour la pause.';

  @override
  String get flightHintTapStars =>
      'Touche le ciel pour battre des ailes. Attrape les étoiles.';

  @override
  String get flightHintTapShoot =>
      'Touche le ciel pour battre des ailes. Maintiens Tirer pour charger.';

  @override
  String get flightHintTapCombat =>
      'Touche le ciel pour battre des ailes. Maintiens Tirer pour charger. Sprint pour tout casser !';

  @override
  String get flightHintTapRelease =>
      'Touche pour battre des ailes. Relâche entre deux touches.';

  @override
  String get flightHintTrail => 'Suis les étoiles. Ton bouclier est prêt.';

  @override
  String get flightHintSky => 'Le ciel est à toi.';

  @override
  String hudClockSemantics(String time) {
    return 'Temps restant : $time';
  }

  @override
  String flightSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Aimant à étoiles : $seconds secondes restantes',
      one: 'Aimant à étoiles : $seconds seconde restante',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Aimant en charge : $charge sur $gates portes parfaites',
      one: 'Aimant en charge : $charge sur $gates porte parfaite',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'Je te cherche…';

  @override
  String get hudShoot => 'Tirer';

  @override
  String get hudSprint => 'Sprint';

  @override
  String get flightTestNothingSaved => 'rien n’est gardé';

  @override
  String get flightCountdownReady => 'À vos marques…';

  @override
  String get flightPauseTitle => 'On souffle un peu.';

  @override
  String get flightPauseKeepFlying => 'Continuer';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. Ton oiseau est perché et t’attend.';
  }

  @override
  String flightPausedTest(String name) {
    return 'Vol d’essai de $name. Rien n’est enregistré.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. Ton oiseau est perché et t’attend.';
  }

  @override
  String get flightPausedTouch =>
      'Ton oiseau est perché et t’attend. Un compte à rebours te relancera.';

  @override
  String get flightPausedCamera =>
      'Secoue-toi un peu, puis reprends ta position. Un compte à rebours te relancera.';

  @override
  String get flightPauseEdit => 'Modifier';

  @override
  String get flightPauseBuilder => 'Créateur';

  @override
  String get flightPauseFinish => 'Terminer le vol';

  @override
  String get hudShieldRecovering => 'Récupération';

  @override
  String get hudShieldReady => 'Bouclier prêt';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Bouclier en charge : $charge sur $stars étoiles',
      one: 'Bouclier en charge : $charge sur $stars étoile',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cœurs restants',
      one: '$count cœur restant',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'Sprint en cours';

  @override
  String get hudSprintReady => 'Prêt';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Recharge, $seconds secondes',
      one: 'Recharge, $seconds seconde',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint =>
      'Fonce pour écraser les chauves-souris et les dalles de pierre';

  @override
  String get hudShotReloading => 'Rechargement…';

  @override
  String hudShotFullCharge(int ms) {
    return 'Charge complète, $ms ms restantes';
  }

  @override
  String hudShotCharging(int percent) {
    return 'Charge $percent %';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'Munitions $percent %';
  }

  @override
  String get hudShotHint => 'Maintiens pour charger un plus gros caillou';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles atteintes',
      one: '$count étoile atteinte',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles à $at',
      one: '$count étoile à $at',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars étoiles récoltées',
      one: '$stars étoile récoltée',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'MAX';

  @override
  String hudRouteSemantics(int percent) {
    return 'Route parcourue à $percent %';
  }

  @override
  String hudGlideCompact(String time) {
    return 'Planer · $time';
  }

  @override
  String get hudJumpToGlide => 'Saute et plane';

  @override
  String get hudJump => 'Saute';

  @override
  String hudGlideSemantics(String time) {
    return 'Vol plané, encore $time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'Fin du vol plané, encore $time';
  }

  @override
  String get hudJumpChargeSemantics =>
      'Saute pour charger 3 secondes de vol plané';

  @override
  String get hudRecordNewBest => 'Record battu !';

  @override
  String get hudRecordMatched => 'Record égalé !';

  @override
  String hudRecordBest(int best) {
    return 'Record $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '+$points au-delà du record';
  }

  @override
  String get hudRecordOneMore => 'À 1 point du record';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'À $count points du record',
      one: 'À $count point du record',
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
    return 'Score $score, multiplicateur ×$multiplier';
  }

  @override
  String get commonBusySemantics => 'En cours';

  @override
  String get flightResultBumpClouds => 'Un petit accroc dans les nuages.';

  @override
  String get flightResultPersonalBest => 'RECORD PERSO';

  @override
  String get flightResultNewPersonalBest => 'NOUVEAU RECORD PERSO !';

  @override
  String get flightResultStarsCollected => 'ÉTOILES RÉCOLTÉES';

  @override
  String get flightResultDailyStamped => 'Carte postale du jour tamponnée !';

  @override
  String flightResultNextStamp(String stamp) {
    return 'Prochain tampon : $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'Enregistré sur ce téléphone';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Enregistré ici · $total portes au total',
      one: 'Enregistré ici · $total porte au total',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'Enregistrement de ton vol…';

  @override
  String get flightResultSessionSaved =>
      'Séance enregistrée · Voir dans Records';

  @override
  String get flightResultWatchReplay => 'Revoir le vol';

  @override
  String get flightResultPreparing => 'Préparation…';

  @override
  String get flightResultSavingShort => 'Enregistrement…';

  @override
  String get flightResultSaveSession => 'Garder la séance';

  @override
  String get flightResultFlyAgain => 'Encore un vol';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonMap => 'Carte';

  @override
  String get commonNext => 'Suivant';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pompes',
      one: 'pompe',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squats',
      one: 'squat',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sauts',
      one: 'saut',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'battements',
      one: 'battement',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'temps de vol';

  @override
  String get flightStatPerfect => 'parfaits';

  @override
  String get flightStatBestStreak => 'série record';

  @override
  String get flightStatRank => 'rang';

  @override
  String get flightRankSkyCaptain => 'As du ciel';

  @override
  String get flightRankCloudExplorer => 'Nuage-trotteur';

  @override
  String get flightRankFirstWings => 'Premier envol';

  @override
  String flightPercent(int percent) {
    return '$percent %';
  }

  @override
  String get gameOverCaptionBest =>
      'Un petit choc, mais un tout nouveau record !';

  @override
  String get gameOverCaptionSea => 'Un petit plouf dans la mer.';

  @override
  String get gameOverSplash => 'Plouf !';

  @override
  String get gameOverBonk => 'Bong !';

  @override
  String get gameOverEveryMarkSemantics => 'Tous les repères atteints';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count étoiles pour $mark étoiles',
      one: 'Encore $count étoile pour $mark étoiles',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss : $hp points de vie sur $maxHp';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '$percent pour cent de la route parcourue';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss : ENCORE $hp PV';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$boss : PV RESTANTS';
  }

  @override
  String get gameOverRouteFlown => 'ROUTE PARCOURUE';

  @override
  String gameOverHp(int hp) {
    return '$hp PV';
  }

  @override
  String gameOverMoreFor(int count) {
    return 'Encore $count pour';
  }

  @override
  String get gameOverBothMarks => 'Deux repères atteints';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Repères atteints. Bats le $boss !',
      'spitterBeetle': 'Repères atteints. Bats le $boss !',
      'duskMoth': 'Repères atteints. Bats l’$boss !',
      'pirate': 'Repères atteints. Bats le $boss !',
      'dragon': 'Repères atteints. Bats le $boss !',
      'kingCoo': 'Repères atteints. Bats le $boss !',
      'searchlightGargoyle': 'Repères atteints. Bats la $boss !',
      'other': 'Repères atteints. Bats $boss !',
    });
    return '$_temp0';
  }

  @override
  String get miniResultTitle => 'Chaque vol compte.';

  @override
  String get miniResultComplete => 'VOL TERMINÉ';

  @override
  String get miniResultCheerBest => 'Quelle envolée !';

  @override
  String get miniResultCheerComplete => 'Vol terminé !';

  @override
  String get miniResultCheerNice => 'Joli vol.';

  @override
  String get miniResultNew => 'NOUVEAU';

  @override
  String get flightEndTrackingLost => 'On t’a perdu de vue un instant.';

  @override
  String get flightEndPostureLost => 'Ta position est sortie du champ.';

  @override
  String get flightEndBackgrounded => 'Tu as quitté le ciel un moment.';

  @override
  String get flightEndBreak => 'Une pause bien méritée.';

  @override
  String get flightEndQuit => 'À la prochaine aventure.';

  @override
  String get flightEndStalled => 'La partie a été interrompue.';

  @override
  String get flightEndCompleted => 'Tout un ciel d’étoiles. Rien que pour toi.';

  @override
  String get levelResultTryAgain => 'Réessaie !';

  @override
  String get levelResultVictory => 'Victoire !';

  @override
  String get levelResultGuardianDown => 'Gardien vaincu !';

  @override
  String get levelResultDelivered => 'Livré !';

  @override
  String levelResultComingSoon(String region) {
    return '$region arrive bientôt !';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned sur 3 étoiles';
  }

  @override
  String levelResultBest(int best) {
    return 'Record $best';
  }

  @override
  String get levelResultNoBest => 'Pas de record';

  @override
  String get levelResultFirstClear => 'Première fois !';

  @override
  String get levelResultNewBest => 'NOUVEAU RECORD';

  @override
  String get levelResultScore => 'SCORE';

  @override
  String get levelResultGoalBoss => 'Boss';

  @override
  String get levelResultGoalGuardian => 'Gardien';

  @override
  String get levelResultGoalFinish => 'Arrivée';

  @override
  String get levelResultGoalDone => 'Réussi';

  @override
  String get levelResultGoalNotYet => 'Pas encore';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'Finis d’abord';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. Réussi.';
  }

  @override
  String get levelResultPostcardWaiting =>
      'Nouvelle carte postale sur la carte !';

  @override
  String levelResultLevelOpen(String id, String name) {
    return 'Niveau $id débloqué : $name !';
  }

  @override
  String get levelResultReachFinish => 'Les étoiles se gagnent à l’arrivée.';

  @override
  String get course_classic_title => 'Classique';

  @override
  String get course_starTrail_title => 'Infini';

  @override
  String get course_classic_instructions =>
      'Trouve les passages. Suis les mires pour un passage parfait.';

  @override
  String get course_starTrail_instructions =>
      'Attrape les 3 étoiles d’un groupe pour +5. Enchaîne les étoiles jusqu’à 3×. Les étoiles rechargent ton bouclier ; les portes parfaites donnent un aimant à étoiles. Améliore les deux avec des étoiles !';

  @override
  String get course_classic_scoreLabel => 'OBSTACLES';

  @override
  String get course_starTrail_scoreLabel => 'POINTS ÉTOILES';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portes',
      one: 'porte',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'points étoiles',
      one: 'point étoile',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics =>
      'Classique : passe dans les trous.';

  @override
  String get course_starTrail_previewSemantics =>
      'Infini : attrape des étoiles avec trois cœurs et un bouclier.';

  @override
  String get obstacle_garden_name => 'Portail de jardin';

  @override
  String get obstacle_windLift_name => 'Ascenseur de vent';

  @override
  String get obstacle_petalGate_name => 'Volets de pétales';

  @override
  String get obstacle_switchback_name => 'Lacet';

  @override
  String get obstacle_lanternDrift_name => 'Lanternes au vent';

  @override
  String get obstacle_sunWheels_name => 'Roues solaires';

  @override
  String get obstacle_crystalSteps_name => 'Marches de cristal';

  @override
  String get rush_wildfire_name => 'Incendie';

  @override
  String get rush_wildfire_escape => 'Plus rapide que l’incendie';

  @override
  String get rush_skyfall_name => 'Le ciel tombe';

  @override
  String get rush_skyfall_escape => 'Le ciel t’a raté !';

  @override
  String get rush_eruption_name => 'Éruption';

  @override
  String get rush_eruption_escape => 'Éruption vaincue';

  @override
  String get rush_swarm_name => 'Essaim';

  @override
  String get rush_swarm_escape => 'Tu as fendu l’essaim';

  @override
  String get boss_baronBat_title => 'SEIGNEUR DE LA TEMPÊTE';

  @override
  String get boss_spitterBeetle_title => 'BRASSEUR DE L’ESSAIM';

  @override
  String get boss_duskMoth_title => 'GARDIENNE DU VOILE CRÉPUSCULAIRE';

  @override
  String get boss_pirate_title => 'TERREUR DE LA MARÉE HAUTE';

  @override
  String get boss_dragon_title => 'SOUVERAIN DU CIEL ARDENT';

  @override
  String get boss_kingCoo_title => 'COMMISSAIRE DU CANIVEAU';

  @override
  String get boss_searchlightGargoyle_title => 'VEILLEUR DE LA PLUS HAUTE TOUR';

  @override
  String get boss_neferhoo_title => 'GARDIEN DE LA LETTRE PERDUE';

  @override
  String get boss_baronBat_returnTitle => 'LA TEMPÊTE REVIENT';

  @override
  String get boss_baronBat_barName => 'BARON';

  @override
  String get boss_spitterBeetle_barName => 'ROI CRACHEUR';

  @override
  String get boss_duskMoth_barName => 'IMPÉRATRICE';

  @override
  String get boss_pirate_barName => 'CAPITAINE PIRATE';

  @override
  String get boss_dragon_barName => 'DRAGON';

  @override
  String get boss_kingCoo_barName => 'ROI ROUCOU';

  @override
  String get boss_searchlightGargoyle_barName => 'GARGOUILLE';

  @override
  String get boss_neferhoo_barName => 'NEFERHOO';

  @override
  String get vanguard_baronBat_title => 'LES CHAUVES-SOURIS DU BARON';

  @override
  String get vanguard_baronBat_call =>
      'Les voilà ! Le Baron arrive juste derrière.';

  @override
  String get vanguard_spitterBeetle_title => 'LA COUVÉE DU ROI CRACHEUR';

  @override
  String get vanguard_spitterBeetle_call =>
      'Les voilà ! Le Roi Cracheur arrive juste derrière.';

  @override
  String get vanguard_duskMoth_title => 'LES PAPILLONS DE L’IMPÉRATRICE';

  @override
  String get vanguard_duskMoth_call =>
      'Les voilà ! L’Impératrice arrive juste derrière.';

  @override
  String get vanguard_kingCoo_title => 'L’ESCADRILLE DU ROI ROUCOU';

  @override
  String get vanguard_kingCoo_call =>
      'Les voilà ! Le Roi Roucou arrive juste derrière.';

  @override
  String get vanguard_kingCoo_callCrusts => 'Les voilà ! Esquive les croûtes !';

  @override
  String get vanguard_kingCoo_callReturns =>
      'Esquive les croûtes ! Un pigeon raté revient !';

  @override
  String get bossVanguardClear => 'DÉGAGÉ !';

  @override
  String get bossVanguardLeft => 'RESTANTS';

  @override
  String get bossStragglersCaught => 'TOUS ATTRAPÉS !';

  @override
  String get bossHint_strongerBaronBat =>
      'PLUS FORT · Tirs triples, et ses chauves-souris s’en mêlent !';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'PLUS FORT · Éventails complets, et ses scarabées s’en mêlent !';

  @override
  String get bossHint_strongerDuskMoth =>
      'PLUS FORTE · Éventails de sept tirs, et ses papillons s’en mêlent !';

  @override
  String get bossHint_strongerPirate => 'PLUS FORT · La marée tourne !';

  @override
  String get bossHint_strongerDragon =>
      'PLUS FORT · Gare au souffle et aux nuées !';

  @override
  String get bossHint_strongerKingCoo =>
      'PLUS FORT · Il siffle son escadrille !';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'PLUS FORT · Des plumes tombent sur la lampe ouverte !';

  @override
  String get bossHint_strongerGargoyle =>
      'PLUS FORT · Les plumes de pierre tombent !';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'PLUS FORT · L’ankh, et ses chauves-souris momies !';

  @override
  String get bossHint_strongerNeferhoo => 'PLUS FORT · L’ankh d’or revient !';

  @override
  String get bossHint_tideRising => 'LA MARÉE MONTE · Vole haut !';

  @override
  String get bossHint_highTide => 'MARÉE HAUTE · Reste au-dessus de l’eau';

  @override
  String get bossHint_tideFury => 'FURIE · Bordées entre les déferlantes';

  @override
  String get bossHint_tideCalm => 'Évite les boulets · Reste hors de l’eau';

  @override
  String get bossHint_dragonSwarm =>
      'ESSAIM · Évite les chauves-souris ou traverse-les en Sprint';

  @override
  String get bossHint_dragonFuryDebut => 'FURIE · Boules de feu plus rapides';

  @override
  String get bossHint_dragonFury =>
      'FURIE · Les boules de feu éclatent en braises';

  @override
  String get bossHint_dragonCalm => 'Évite les boules de feu · Gare au souffle';

  @override
  String get bossHint_screechFury =>
      'FURIE · Boules de feu plus rapides, plus de chauves-souris';

  @override
  String get bossHint_screechCalm =>
      'Évite les boules de feu et les chauves-souris · Gare au cri';

  @override
  String get bossHint_cooPopped => 'PLOP ! · Pas d’escadrille';

  @override
  String get bossHint_cooSquadron => 'ESCADRILLE · Suis le couloir libre !';

  @override
  String get bossHint_cooPuffed => 'GONFLÉ · Tire sur son torse (x2) !';

  @override
  String get bossHint_cooCrumbBomb => 'BOMBE DE MIETTES · Sors du cercle !';

  @override
  String get bossHint_cooFury => 'FURIE · Reste entre les cercles';

  @override
  String get bossHint_cooCalm =>
      'Évite les bombes de miettes · Tire sur son torse quand il gonfle';

  @override
  String get bossHint_beamOn => 'FAISCEAU · Reste dans l’ombre';

  @override
  String get bossHint_beamFury => 'FURIE · Glisse-toi entre les faisceaux';

  @override
  String get bossHint_beamIncomingHigh => 'FAISCEAU EN APPROCHE · Vole bas !';

  @override
  String get bossHint_beamIncomingLow => 'FAISCEAU EN APPROCHE · Vole haut !';

  @override
  String get bossHint_lampOpen => 'LAMPE OUVERTE · Tire sur la lampe !';

  @override
  String get bossHint_shuttersClosed => 'VOLETS FERMÉS · Garde tes tirs';

  @override
  String get bossHint_mothFuryNoVeil =>
      'FURIE · Éventails de sept tirs. Pas encore de voile !';

  @override
  String get bossHint_mothNoVeil =>
      'Pas encore de voile · Tire entre les éventails !';

  @override
  String get bossHint_mothShielded =>
      'PROTÉGÉE · Esquive jusqu’à ce que le voile tombe';

  @override
  String get bossHint_mothShieldForming =>
      'VOILE EN FORMATION · Prépare-toi à esquiver';

  @override
  String get bossHint_mothFury =>
      'FURIE · Éventails de sept tirs. Le voile est tombé !';

  @override
  String get bossHint_mothCalm =>
      'Le voile est tombé · Tire entre les éventails !';

  @override
  String get bossHint_neferhooMailCall => 'LE COURRIER ! · Renvoie-les !';

  @override
  String get bossHint_neferhooReturn => 'RETOUR À L’ENVOYEUR ! · −25';

  @override
  String get bossHint_neferhooReturnFaster => 'RETOUR À L’ENVOYEUR ! · −18';

  @override
  String get bossHint_neferhooAnkh => 'L’ANKH · Il revient !';

  @override
  String get bossHint_neferhooExpress =>
      'POSTE EXPRESS · Cinq lettres, plus vite';

  @override
  String get bossHint_neferhooTwoAnkhs =>
      'DEUX ANKHS · Évite les deux couloirs';

  @override
  String get bossHint_neferhooBats => 'CHAUVES-SOURIS MOMIES · Abats-les !';

  @override
  String get bossHint_neferhooScuff =>
      'Les cailloux éraflent à peine ses bandelettes. Renvoie ses LETTRES !';

  @override
  String get bossHint_neferhooWarmUp =>
      'Renvoie ses lettres · Retour à l’envoyeur';

  @override
  String get bossHint_neferhooCalm => 'Renvoie ses lettres · Évite l’ankh d’or';

  @override
  String get bossHint_neferhooFury => 'FURIE · Poste express et deux ankhs';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'SOUFFLE DU DRAGON · Vole bas ! Son cœur est ouvert',
      'middle': 'SOUFFLE DU DRAGON · Monte ou plonge ! Son cœur est ouvert',
      'other': 'SOUFFLE DU DRAGON · Vole haut ! Son cœur est ouvert',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'FEU · Vole bas ! Frappe le cœur brillant',
      'middle': 'FEU · Monte ou plonge ! Frappe le cœur brillant',
      'other': 'FEU · Vole haut ! Frappe le cœur brillant',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'CRI SONIQUE · Va dans la brèche du haut !',
      'middle': 'CRI SONIQUE · Va dans la brèche du milieu !',
      'other': 'CRI SONIQUE · Va dans la brèche du bas !',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'CRI · Reste dans la brèche du haut',
      'middle': 'CRI · Reste dans la brèche du milieu',
      'other': 'CRI · Reste dans la brèche du bas',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'ÉVITE LES ÉVENTAILS  ·  TIRE QUAND LE VOILE TOMBE';

  @override
  String get encounterCaption_pirate =>
      'ÉVITE LES BOULETS  ·  RESTE HORS DE L’EAU';

  @override
  String get encounterCaption_dragon =>
      'ÉVITE LES BOULES DE FEU  ·  ÉCHAPPE AU SOUFFLE';

  @override
  String get encounterCaption_kingCoo =>
      'SORS DES CERCLES  ·  TIRE SUR SON TORSE QUAND IL GONFLE';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'RESTE HORS DE LA LUMIÈRE  ·  TIRE SUR LA LAMPE QUAND ELLE S’OUVRE';

  @override
  String get encounterCaption_neferhoo => 'PRÉPARE-TOI  ·  RENVOIE SES LETTRES';

  @override
  String get encounterCaption_screech => 'QUAND IL CRIE  ·  VA DANS LA BRÈCHE';

  @override
  String get encounterCaption_default => 'PRÉPARE-TOI  ·  VOLE, ESQUIVE, TIRE';

  @override
  String get encounterCoasting => 'Ton oiseau plane en sécurité';

  @override
  String get encounterOpenSky => 'Retour en plein ciel';

  @override
  String get encounterOmenTitle_duskMoth => 'LE CRÉPUSCULE PREND SON ENVOL';

  @override
  String get encounterOmenLine_duskMoth =>
      'Un voile de soie se forme dans le crépuscule…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'QUELQUE CHOSE MIJOTE';

  @override
  String get encounterOmenLine_spitterBeetle => 'L’air commence à pétiller…';

  @override
  String get encounterOmenTitle_dragon => 'LE CIEL S’EMBRASE';

  @override
  String get encounterOmenLine_dragon =>
      'De grandes ailes battent au-dessus des nuages…';

  @override
  String get encounterOmenTitle_kingCoo => 'LE CANIVEAU EST FERMÉ';

  @override
  String get encounterOmenLine_kingCoo =>
      'Quelqu’un est très fâché à cause du chariot à pain…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => 'ALERTE TEMPÊTE';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      'Quelque chose nous observe depuis la corniche…';

  @override
  String get encounterOmenTitle_neferhoo => 'LA PYRAMIDE S’ÉVEILLE';

  @override
  String get encounterOmenLine_neferhoo =>
      'La poussière de la pyramide s’agite…';

  @override
  String get encounterOmenTitle_baronReturns => 'LE BARON EST DE RETOUR';

  @override
  String get encounterOmenLine_baronReturns =>
      'Il est revenu, et il crie bien plus fort…';

  @override
  String get encounterOmenTitle_default => 'UNE OMBRE APPROCHE';

  @override
  String get encounterOmenLine_default =>
      'Le ciel appartient à quelqu’un d’autre…';

  @override
  String get encounterOmenTitle_pirate => 'VOILE EN VUE !';

  @override
  String get encounterOmenLine_pirate =>
      'Un navire arrive avec la marée montante…';

  @override
  String get bossGuardianEyebrow => 'GARDIEN';

  @override
  String bossEncounterEyebrow(String number) {
    return 'RENCONTRE $number';
  }

  @override
  String get bossGuardianDown => 'GARDIEN VAINCU !';

  @override
  String get bossSkyReclaimed => 'CIEL RECONQUIS';

  @override
  String bossVictoryPoints(int points) {
    return '+$points POINTS   ·   BOUCLIER RÉTABLI';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'BARON CHAUVE-SOURIS VAINCU',
      'spitterBeetle': 'ROI CRACHEUR VAINCU',
      'duskMoth': 'IMPÉRATRICE DU CRÉPUSCULE VAINCUE',
      'pirate': 'CAPITAINE PIRATE VAINCU',
      'dragon': 'DRAGON DES BRAISES VAINCU',
      'kingCoo': 'ROI ROUCOU VAINCU',
      'searchlightGargoyle': 'GARGOUILLE AUX PROJECTEURS VAINCUE',
      'other': 'NEFERHOO VAINCU',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '« $line »';
  }

  @override
  String get bossPirateRoar => 'ARRR !';

  @override
  String get bossGargoyleCardSmall => 'AUX PROJECTEURS';

  @override
  String get bossGargoyleCardBig => 'GARGOUILLE';

  @override
  String get bossGargoyleCardOrder => 'big-small';

  @override
  String get bossDodgeFlyLow => 'VOLE BAS';

  @override
  String get bossDodgeFlyHigh => 'VOLE HAUT';

  @override
  String get bossDodgeClimbOrDive => 'MONTE OU PLONGE';

  @override
  String get bossDodgeSlipBetween => 'GLISSE ENTRE\nLES FAISCEAUX';

  @override
  String get bossSpotted => 'REPÉRÉ !';

  @override
  String get bossShieldLost => 'BOUCLIER PERDU';

  @override
  String get bossHeartLost => '-1 CŒUR';

  @override
  String get bossGargoyleLampOpen => 'LAMPE À NU';

  @override
  String get bossGargoyleShoot => 'TIRE !';

  @override
  String get bossScreechFlyToGap => 'VA À LA BRÈCHE';

  @override
  String get bossScreechHoldGap => 'TIENS LA BRÈCHE';

  @override
  String get bossPirateHighTide => 'MARÉE HAUTE';

  @override
  String get bossBarDefeated => 'K.O.';

  @override
  String get bossBarIncoming => 'EN APPROCHE';

  @override
  String get bossBarFury => 'FURIE';

  @override
  String get bossBarHeartDouble => 'CŒUR ×2';

  @override
  String get bossStronger => 'PLUS FORT !';

  @override
  String get bossKingCooPuffed => 'GONFLÉ';

  @override
  String get bossKingCooShout => 'ROUCOU !';

  @override
  String get bossKingCooPop => 'PLOP !';

  @override
  String get bossKingCooPoof => 'POUF !';

  @override
  String get bossSquadOpenLane => 'COULOIR LIBRE !';

  @override
  String get bossSquadUseGap => 'PAR LE TROU !';

  @override
  String get bossSquadThenV => 'PUIS : V';

  @override
  String get bossSquadThenGap => 'PUIS : TROU';

  @override
  String get bossSquadCancelled => 'PAS D’ESCADRILLE';

  @override
  String get bossNeferhooFound => 'LA LETTRE PERDUE EST RETROUVÉE';

  @override
  String get bossNeferhooHoo => 'HOU';

  @override
  String get bossNeferhooPoo => 'HOU';

  @override
  String get bossNeferhooMailCall => 'LE COURRIER !';

  @override
  String get bossNeferhooExpressPost => 'POSTE EXPRESS';

  @override
  String get bossNeferhooShootBack => 'Renvoie-les !';

  @override
  String get bossNeferhooAnkh => 'L’ANKH';

  @override
  String get bossNeferhooTwoAnkhs => 'DEUX ANKHS';

  @override
  String get bossNeferhooComesBack => 'Il revient !';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'INCENDIE !',
      'skyfall': 'LE CIEL TOMBE !',
      'eruption': 'ÉRUPTION !',
      'other': 'ESSAIM !',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Prends les anneaux de sprint et sème-le !',
      'skyfall': 'Prends les anneaux de sprint et devance les météores !',
      'eruption': 'Prends les anneaux de sprint et esquive les jets !',
      'other': 'Prends les anneaux de sprint et fonce dans le tas !',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return 'ÉVASION ! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'SANS FAUTE ! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Tu as semé l’incendie',
      'skyfall': 'Tu as survécu au ciel qui tombe',
      'eruption': 'Tu as vaincu l’éruption',
      'other': 'Tu as fendu l’essaim',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => 'BOURRASQUE !';

  @override
  String encounterGaleDetail(String mark) {
    return 'Esquive les débris là où le $mark clignote !';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'TU AS TENU ! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail => 'Tu as tenu face à la bourrasque';

  @override
  String get encounterAllRings => 'TOUT ATTRAPÉ !';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'Bonus turbo +$seconds s';
  }

  @override
  String get encounterFinish => 'ARRIVÉE';

  @override
  String get builderMode_pushUp => 'Pompes';

  @override
  String get builderMode_squat => 'Squats';

  @override
  String get builderMode_jump => 'Sauts';

  @override
  String builderSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pompes',
      one: '$count pompe',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count squats',
      one: '$count squat',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'Mon niveau tactile';

  @override
  String get builderNewLevel_pushUp => 'Mon niveau pompes';

  @override
  String get builderNewLevel_squat => 'Mon niveau squats';

  @override
  String get builderNewLevel_jump => 'Mon niveau sauts';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'Mon niveau';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Essaie mon niveau Beakbound « $name » ($mode) : $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$earned sur $total étoiles';
  }

  @override
  String get builderBackSemantics => 'Retour';

  @override
  String get builderKeepIt => 'Le garder';

  @override
  String builderLessSemantics(String name) {
    return 'Diminuer $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'Augmenter $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name : $value';
  }

  @override
  String get builderDuplicateSemantics => 'Dupliquer';

  @override
  String get builderCopy => 'Copier';

  @override
  String get builderDeleteSemantics => 'Supprimer';

  @override
  String get builderDelete => 'Supprimer';

  @override
  String get builderMoreBelow => 'Suite en bas';

  @override
  String builderStepSemantics(String caption, String value) {
    return '$caption : $value';
  }

  @override
  String builderStepHintSemantics(String caption, String value, String hint) {
    return '$caption : $value, $hint';
  }

  @override
  String builderPercent(int percent) {
    return '$percent %';
  }

  @override
  String get builderLane => 'Couloir';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'haut ou bas du squat',
      'other': 'haut ou bas de la pompe',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'Haut';

  @override
  String get builderLaneBottom => 'Bas';

  @override
  String get builderHeight => 'Hauteur';

  @override
  String get builderHeightHint => 'du ciel';

  @override
  String get builderLowerSemantics => 'Plus bas';

  @override
  String get builderHigherSemantics => 'Plus haut';

  @override
  String get builderOpening => 'Ouverture';

  @override
  String builderOpeningHint(int percent) {
    return 'au moins $percent %';
  }

  @override
  String get builderNarrowerSemantics => 'Plus étroit';

  @override
  String get builderWiderSemantics => 'Plus large';

  @override
  String get builderMotion => 'Mouvement';

  @override
  String get builderMotionGardenHint => 'les portails de jardin sont fixes';

  @override
  String get builderMotionStill => 'Fixe';

  @override
  String get builderMotionGentle => 'Doux';

  @override
  String get builderMotionLively => 'Vif';

  @override
  String get builderMotionGardenToast =>
      'Les portails de jardin ne bougent pas : choisis une autre famille pour le faire bouger.';

  @override
  String get builderSway => 'Balancement';

  @override
  String builderSwayHint(String seconds) {
    return 'un balancement : $seconds';
  }

  @override
  String get builderSwayFast => 'Rapide';

  @override
  String get builderSwayMedium => 'Moyen';

  @override
  String get builderSwaySlow => 'Lent';

  @override
  String get builderPhase => 'À ton arrivée';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position sur $count';
  }

  @override
  String get builderPhaseHint => 'où en est son balancement';

  @override
  String get builderPhaseEarlierSemantics => 'Plus tôt dans son balancement';

  @override
  String get builderPhaseLaterSemantics => 'Plus tard dans son balancement';

  @override
  String get builderLook => 'Style';

  @override
  String builderLookSemantics(int number) {
    return 'Style $number';
  }

  @override
  String get builderDoor => 'Porte de roche';

  @override
  String get builderDoorHint => 'tire pour l’ouvrir';

  @override
  String get builderDoorNone => 'Sans porte';

  @override
  String get builderDoorNeedsShootToast =>
      'Active Tirer dans les réglages du niveau pour utiliser les portes.';

  @override
  String get builderPlace => 'Position';

  @override
  String get builderPlaceHint => 'depuis le départ';

  @override
  String get builderEarlierSemantics => 'Plus tôt';

  @override
  String get builderLaterSemantics => 'Plus tard';

  @override
  String builderFamilySemantics(String family) {
    return 'Famille de portes : $family. Changer';
  }

  @override
  String get builderChangeFamily => 'Changer de famille';

  @override
  String get builderItemStar => 'Étoile';

  @override
  String get builderItemTrio => 'Trio d’étoiles';

  @override
  String get builderItemHeart => 'Cœur';

  @override
  String get builderItemEnemy => 'Ennemi';

  @override
  String get builderItemGate => 'Porte';

  @override
  String get builderItemStarDetail => 'Une étoile à attraper';

  @override
  String get builderItemTrioDetail => 'Les trois donnent un bonus';

  @override
  String get builderItemHeartDetail => 'Rend un cœur';

  @override
  String get builderEnemyKind => 'Type';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'L’oiseau vole en haut et en bas de chaque squat : place les bonus sur les lignes jaunes ou entre elles.',
      'other':
          'L’oiseau vole en haut et en bas de chaque pompe : place les bonus sur les lignes jaunes ou entre elles.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'Chauve-souris violette';

  @override
  String get builderEnemy_caveBat => 'Chauve-souris costaude';

  @override
  String get builderEnemy_spitterBeetle => 'Scarabée cracheur';

  @override
  String get builderEnemy_duskMoth => 'Papillon du crépuscule';

  @override
  String get builderEnemy_alleyPigeon => 'Pigeon des ruelles';

  @override
  String get builderEnemy_mummyBat => 'Chauve-souris momie';

  @override
  String get builderSummaryTitle => 'Ce niveau';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'Durée';

  @override
  String get builderFactStars => 'Étoiles';

  @override
  String get builderFactMarks => 'Repères';

  @override
  String get builderFactWorkout => 'Exercice';

  @override
  String get builderFactPace => 'Rythme';

  @override
  String get builderFactBoss => 'Boss';

  @override
  String get builderPace_relaxed => 'Tranquille';

  @override
  String get builderPace_steady => 'Régulier';

  @override
  String get builderPace_brisk => 'Soutenu';

  @override
  String get builderSummaryStarterNote =>
      'Un niveau de départ à jouer tel quel, ou à remixer pour en faire le tien.';

  @override
  String get builderSummaryClearedNote =>
      'Terminé par toi : tu l’as parcouru jusqu’au bout.';

  @override
  String get builderSummaryClearNote =>
      'Fais un vol d’essai jusqu’à l’arrivée pour le marquer comme terminé.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat':
          'Fais un vol d’essai, bats le $boss et franchis la ligne pour le marquer comme terminé.',
      'spitterBeetle':
          'Fais un vol d’essai, bats le $boss et franchis la ligne pour le marquer comme terminé.',
      'duskMoth':
          'Fais un vol d’essai, bats l’$boss et franchis la ligne pour le marquer comme terminé.',
      'pirate':
          'Fais un vol d’essai, bats le $boss et franchis la ligne pour le marquer comme terminé.',
      'dragon':
          'Fais un vol d’essai, bats le $boss et franchis la ligne pour le marquer comme terminé.',
      'kingCoo':
          'Fais un vol d’essai, bats le $boss et franchis la ligne pour le marquer comme terminé.',
      'searchlightGargoyle':
          'Fais un vol d’essai, bats la $boss et franchis la ligne pour le marquer comme terminé.',
      'other':
          'Fais un vol d’essai, bats $boss et franchis la ligne pour le marquer comme terminé.',
    });
    return '$_temp0';
  }

  @override
  String get builderSummaryHowTo =>
      'Choisis un outil à gauche, puis touche le ciel. Touche un objet pour le modifier ; fais-le glisser pour le déplacer.';

  @override
  String get builderFamily_garden_detail =>
      'Reste immobile. Peut avoir une porte de roche.';

  @override
  String get builderFamily_windLift_detail => 'L’ouverture monte et descend.';

  @override
  String get builderFamily_petalGate_detail =>
      'L’ouverture rétrécit et s’élargit.';

  @override
  String get builderFamily_switchback_detail =>
      'Deux ouvertures qui s’écartent.';

  @override
  String get builderFamily_lanternDrift_detail =>
      'Des lanternes suspendues qui se balancent.';

  @override
  String get builderFamily_sunWheels_detail =>
      'Des roues qui se referment et s’écartent.';

  @override
  String get builderFamily_crystalSteps_detail => 'Trois marches en vague.';

  @override
  String get builderFamiliesCloseSemantics => 'Fermer les familles de portes';

  @override
  String get builderFamiliesTitle => 'Famille de portes';

  @override
  String get builderFamiliesSubtitle =>
      'L’allure de la porte et ses mouvements.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Donne au niveau un nom de $count lettres au plus.',
      one: 'Donne au niveau un nom de $count lettre au plus.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort =>
      'Éloigne la ligne d’arrivée : le niveau est trop court.';

  @override
  String get reach_tooLong =>
      'Rapproche la ligne d’arrivée : le niveau est trop long.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trop d’objets : un niveau en contient $count au plus.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap =>
      'Seuls les niveaux Tape & Vole finissent par un boss.';

  @override
  String get reach_noGates => 'Ajoute des portes que l’oiseau doit traverser.';

  @override
  String get reach_startZone =>
      'Trop près du départ : place-le après la zone de départ.';

  @override
  String get reach_finishRoom =>
      'Laisse de la place avant la ligne d’arrivée après cette porte.';

  @override
  String get reach_overlap => 'Deux portes se chevauchent : écarte-les.';

  @override
  String get reach_gateHeight => 'Cette porte est trop haute ou trop basse.';

  @override
  String get reach_gateMotion => 'Cette porte ne peut pas bouger comme ça.';

  @override
  String get reach_gateLook => 'Cette porte a un style inconnu.';

  @override
  String get reach_gateNarrow =>
      'Ouvre davantage cette porte : l’oiseau ne passe pas.';

  @override
  String get reach_gateWide => 'Cette porte est trop ouverte.';

  @override
  String get reach_doorNeedsShoot =>
      'Une porte de roche demande Tape & Vole avec Tirer activé.';

  @override
  String get reach_doorNeedsGarden =>
      'Seul un portail de jardin peut avoir une porte de roche.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Changement serré : un squat régulier risque d’arriver trop tard.',
      'other':
          'Changement serré : une pompe régulière risque d’arriver trop tard.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'Montée raide : laisse plus de place pour sauter jusqu’à cette porte.';

  @override
  String get reach_enemyNeedsTap =>
      'Les ennemis ne volent que dans les niveaux Tape & Vole.';

  @override
  String get reach_outsideSky => 'Garde-le dans le ciel.';

  @override
  String get reach_pastFinish => 'Place-le avant la ligne d’arrivée.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Hors de portée d’un squat : rapproche-le des couloirs.',
      'other': 'Hors de portée d’une pompe : rapproche-le des couloirs.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'Dans un mur : place-le dans l’ouverture.';

  @override
  String get reach_noStars => 'Place au moins une étoile.';

  @override
  String get reach_marks =>
      'Les repères d’étoiles demandent plus d’étoiles que le niveau n’en a.';

  @override
  String reach_cannotFly(String problem) {
    return 'Ce niveau n’est pas encore jouable ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'Le niveau n’a pas été enregistré, il n’est donc pas encore jouable. Touche son nom pour réessayer.';

  @override
  String get builderShareBlockedToast =>
      'Corrige d’abord les drapeaux rouges : ensuite, le niveau pourra être partagé.';

  @override
  String get builderEditorBackSemantics => 'Retour au créateur';

  @override
  String get builderSettingsSemantics => 'Réglages du niveau';

  @override
  String get builderFly => 'VOLE !';

  @override
  String get builderTestFly => 'ESSAYER';

  @override
  String get builderFlySemantics => 'Voler dans ce niveau';

  @override
  String get builderTestFlySemantics => 'Essayer tout le niveau';

  @override
  String get builderUndoSemantics => 'Annuler';

  @override
  String get builderRedoSemantics => 'Rétablir';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice conseils',
      one: '$advice conseil',
    );
    return '$blocking à corriger, $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice conseils',
      one: '$advice conseil',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => 'Prêt à voler';

  @override
  String get builderShareSemantics => 'Code de partage';

  @override
  String get builderFromHereSemantics => 'Essayer à partir d’ici';

  @override
  String get builderFromHere => 'À partir d’ici';

  @override
  String get builderStatusStarter => 'Niveau de départ · joue ou remixe';

  @override
  String get builderStatusSaveFailed => 'Non sauvé · touche pour réessayer';

  @override
  String get builderStatusSaving => 'Enregistrement…';

  @override
  String get builderStatusSaved => 'Modifications enregistrées';

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
    return '$name. $mode. $status. Touche pour renommer.';
  }

  @override
  String get builderStarterBanner => 'Remixe-le pour le faire tien';

  @override
  String get builderRemix => 'Remixer';

  @override
  String get builderRemixSemantics => 'Remixer';

  @override
  String get builderIssuesCloseSemantics => 'Fermer les problèmes et conseils';

  @override
  String get builderIssuesReadyTitle => 'Prêt à voler !';

  @override
  String get builderIssuesFixTitle => 'À corriger avant de voler';

  @override
  String get builderIssuesTipsTitle => 'Prêt, avec quelques conseils';

  @override
  String get builderIssuesReadyDetail =>
      'Rien à corriger. Fais un essai jusqu’à l’arrivée pour le terminer.';

  @override
  String get builderIssuesDetail =>
      'Touches-en un pour aller à sa place sur la route.';

  @override
  String get builderSettingsCloseSemantics => 'Fermer les réglages';

  @override
  String get builderSettingsTitle => 'Réglages du niveau';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · tes changements s’enregistrent tout seuls';
  }

  @override
  String get builderSettingsName => 'Nom';

  @override
  String get builderRename => 'Renommer';

  @override
  String get builderRenameSemantics => 'Renommer';

  @override
  String get builderSettingsRegion => 'Région';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lieux · fais défiler',
      one: '$count lieu · fais défiler',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'Rythme';

  @override
  String get builderSettingsPaceHint => 'vitesse de défilement du ciel';

  @override
  String get builderSettingsMarks => 'Repères';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles placées',
      one: '$count étoile placée',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'le repère à deux étoiles';

  @override
  String get builderMarkThreeSemantics => 'le repère à trois étoiles';

  @override
  String get builderMarksAuto => 'Auto : suit les étoiles';

  @override
  String get builderMarksByHand => 'À la main';

  @override
  String get builderSettingsControls => 'Commandes';

  @override
  String get builderShootOn => 'Tirer : oui';

  @override
  String get builderShootOff => 'Tirer : non';

  @override
  String get builderSprintOn => 'Sprint : oui';

  @override
  String get builderSprintOff => 'Sprint : non';

  @override
  String get builderSettingsBoss => 'Boss final';

  @override
  String get builderSettingsBossHint => 'attend à la fin';

  @override
  String get builderNoBossSemantics => 'Pas de boss : une ligne d’arrivée';

  @override
  String get builderNoBoss => 'Aucun';

  @override
  String get builderBossShort_baronBat => 'Baron';

  @override
  String get builderBossShort_spitterBeetle => 'Cracheur';

  @override
  String get builderBossShort_duskMoth => 'Crépuscule';

  @override
  String get builderBossShort_pirate => 'Pirate';

  @override
  String get builderBossShort_dragon => 'Dragon';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'L’oiseau vole sur deux couloirs : le haut et le bas de chaque squat. Un joueur plus lent vit le même niveau à une vitesse plus douce. Ici, pas de tir, de sprint ni de boss.',
      'other':
          'L’oiseau vole sur deux couloirs : le haut et le bas de chaque pompe. Un joueur plus lent vit le même niveau à une vitesse plus douce. Ici, pas de tir, de sprint ni de boss.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'Chaque saut fait monter l’oiseau ; il plane entre deux sauts. Ici, pas de tir, de sprint ni de boss.';

  @override
  String get builderStartZoneToast =>
      'Laisse la zone de départ libre : place les objets à droite de la ligne pointillée.';

  @override
  String get builderSkySemantics =>
      'Ciel du niveau. Touche pour placer, glisse pour déplacer ou faire défiler.';

  @override
  String get builderSkyReadOnlySemantics =>
      'Ciel du niveau. Touche un objet pour le regarder.';

  @override
  String get builderCoachTitle => 'Crée ton niveau';

  @override
  String get builderCoachPickTool => 'Choisis un outil à gauche';

  @override
  String get builderCoachTapSky => 'Touche le ciel pour le placer';

  @override
  String get builderCoachTestFly => 'Essaie-le !';

  @override
  String get builderCoachDrag =>
      'Glisse un objet pour le déplacer · glisse le ciel pour défiler';

  @override
  String get builderTipDrag =>
      'Glisse-le pour le déplacer · glisse le ciel pour défiler';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'HAUT DU SQUAT',
      'other': 'HAUT DE LA POMPE',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'HAUT';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'BAS DU SQUAT',
      'other': 'BAS DE LA POMPE',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'BAS';

  @override
  String get builderCanvasStartZoneFull => 'ZONE DE DÉPART · LAISSE VIDE';

  @override
  String get builderCanvasStartZone => 'ZONE DE DÉPART';

  @override
  String get builderCanvasFinishHere => 'ARRIVÉE ICI';

  @override
  String get builderTool_select => 'Choisir';

  @override
  String get builderToolHint_select =>
      'Choisir : touche un objet pour le modifier, glisse pour le déplacer';

  @override
  String get builderTool_gate => 'Porte';

  @override
  String get builderToolHint_gate =>
      'Porte : touche le ciel pour placer une porte';

  @override
  String get builderTool_star => 'Étoile';

  @override
  String get builderToolHint_star =>
      'Étoile : touche le ciel pour placer une étoile';

  @override
  String get builderTool_trio => 'Trio';

  @override
  String get builderToolHint_trio =>
      'Trio d’étoiles : touche le ciel pour placer trois étoiles';

  @override
  String get builderTool_heart => 'Cœur';

  @override
  String get builderToolHint_heart =>
      'Cœur : touche le ciel pour placer un cœur';

  @override
  String get builderTool_enemy => 'Ennemi';

  @override
  String get builderToolHint_enemy =>
      'Ennemi : touche le ciel pour placer un ennemi';

  @override
  String get builderTool_finish => 'Arrivée';

  @override
  String get builderToolHint_finish =>
      'Arrivée : touche le ciel pour déplacer la ligne d’arrivée';

  @override
  String get builderTool_boss => 'Boss';

  @override
  String get builderToolHint_boss =>
      'Repère du boss : touche le ciel pour déplacer l’endroit où le boss attend';

  @override
  String get builderStarterToolsToast =>
      'Les niveaux de départ restent tels quels : remixe-le pour le modifier.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Vue de la route. $length jusqu’au boss. Glisse pour te déplacer sur la route.',
      'other':
          'Vue de la route. $length jusqu’à l’arrivée. Glisse pour te déplacer sur la route.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Vue de la route. $length jusqu’au boss. $reps. Glisse pour te déplacer sur la route.',
      'other':
          'Vue de la route. $length jusqu’à l’arrivée. $reps. Glisse pour te déplacer sur la route.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '$length jusqu’au boss';
  }

  @override
  String get builtResultTestFlight => 'VOL D’ESSAI';

  @override
  String get builtResultCleared => 'Terminé !';

  @override
  String get builtResultBonk => 'Bong !';

  @override
  String get builtResultLanded => 'Atterrissage';

  @override
  String get builtResultTestTab => 'ESSAI';

  @override
  String get builtResultGoalFinish => 'Arrivée';

  @override
  String get builtResultGoalBoss => 'Boss';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. Réussi.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attrape $count étoiles.',
      one: 'Attrape $count étoile.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attrape $count étoiles. Réussi.',
      one: 'Attrape $count étoile. Réussi.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'Réussi';

  @override
  String get builtResultNotYet => 'Pas encore';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'Finis d’abord';

  @override
  String get builtResultClearedByYou => 'TERMINÉ PAR TOI';

  @override
  String get builtResultNewBest => 'NOUVEAU RECORD';

  @override
  String get builtResultPractice => 'Entraînement';

  @override
  String builtResultBest(int count) {
    return 'Record $count';
  }

  @override
  String get builtResultFirstClear => 'Une première !';

  @override
  String get builtResultStarsCollected => 'ÉTOILES RÉCOLTÉES';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles de niveau sur 3',
      one: '$count étoile de niveau sur 3',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'OBJECTIF';

  @override
  String get builtResultWorkout => 'EXERCICE';

  @override
  String get builtResultGotTo => 'PARCOURU';

  @override
  String get builtResultScore => 'SCORE';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pompes',
      one: 'pompe',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squats',
      one: 'squat',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sauts',
      one: 'saut',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pompes face caméra',
      one: 'pompe face caméra',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squats face caméra',
      one: 'squat face caméra',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'sur $length';
  }

  @override
  String get builtResultNotKept => 'Non gardé';

  @override
  String get builtResultNoBest => 'Pas de record';

  @override
  String get builtResultClearedStrip => 'Terminé par toi · prêt à partager !';

  @override
  String builtResultFlownFrom(String from) {
    return 'Vol depuis $from. Fais-le en entier pour le terminer.';
  }

  @override
  String get builtResultTestNothingSaved =>
      'Vol d’essai · rien n’est enregistré';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'Vol d’essai · $reached sur $length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return '$reached sur $length. Atteins l’arrivée pour les étoiles.';
  }

  @override
  String get builtResultReachFinish =>
      'Atteins l’arrivée pour gagner des étoiles.';

  @override
  String get builtResultSaved => 'Enregistré sur ce téléphone';

  @override
  String get builtResultSaving => 'Enregistrement de ton vol…';

  @override
  String get builtResultBuilder => 'Créateur';

  @override
  String get builtResultEditLevel => 'Modifier le niveau';

  @override
  String get builtResultEdit => 'Modifier';

  @override
  String get builtResultFlyAgain => 'Encore un vol';

  @override
  String get builtResultWatchReplay => 'Revoir le vol';

  @override
  String get builtResultPreparing => 'Préparation…';

  @override
  String get builtResultSessionSaving => 'Enregistrement…';

  @override
  String get builtResultSaveSession => 'Garder la séance';

  @override
  String get builderShelfTitle => 'Créateur de niveaux';

  @override
  String get builderShelfPasteCode => 'Coller un code';

  @override
  String get builderShelfNewLevel => 'Nouveau niveau';

  @override
  String get builderShelfSaveFailed => 'Ça n’a pas été enregistré. Réessaie.';

  @override
  String builderShelfDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get builderShelfDeleteBody =>
      'Ses records partent avec lui. Les pompes, squats et sauts faits dessus comptent toujours.';

  @override
  String get builderShelfDelete => 'Supprimer';

  @override
  String builderShelfDeleted(String name) {
    return '« $name » supprimé.';
  }

  @override
  String get builderShelfFixFirst =>
      'Corrige ce qui est en rouge avant de partager : touche Corriger.';

  @override
  String get builderShelfCodeCopied => 'Code copié ! Envoie-le à un ami.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'Code copié ! Termine-le aussi jusqu’à l’arrivée, pour que tes amis sachent que c’est faisable.';

  @override
  String get builderShelfNotReady =>
      'Ce niveau n’est pas encore prêt : touche Corriger.';

  @override
  String get builderShelfPasteMissingTitle => 'Aucun code de niveau à coller';

  @override
  String get builderShelfPasteNewerTitle =>
      'Un niveau d’un Beakbound plus récent';

  @override
  String get builderShelfPasteDamagedTitle => 'Ce code s’est emmêlé';

  @override
  String get builderShelfPasteMissingBody =>
      'Copie le code de niveau d’un ami (il commence par BEAK1.) et touche à nouveau Coller un code.';

  @override
  String get builderShelfPasteNewerBody =>
      'Mets Beakbound à jour pour y jouer, puis colle à nouveau le code.';

  @override
  String get builderShelfPasteDamagedBody =>
      'Il en manque un bout ou il y a une faute. Demande à ton ami de recopier tout le code.';

  @override
  String builderShelfImported(String name) {
    return '« $name » est sur ton étagère !';
  }

  @override
  String get builderShelfUnavailable => 'Tes niveaux se font attendre.';

  @override
  String get builderShelfMine => 'Mes niveaux';

  @override
  String get builderShelfStarters => 'Niveaux de départ';

  @override
  String get builderShelfStartersHint =>
      'Joue-en un, ou remixe-le pour en faire le tien';

  @override
  String get builderShelfEmptyTitle => 'Crée ton premier niveau';

  @override
  String get builderShelfEmptyBody =>
      'Place à la main portes, étoiles et cœurs, fixe la ligne d’arrivée et fais un vol d’essai.';

  @override
  String get builderShelfPasteFriend => 'Coller le code d’un ami';

  @override
  String get builderShelfNeedsWork => 'À retravailler';

  @override
  String get builderShelfClearedByYou => 'Terminé par toi';

  @override
  String get builderShelfFromFriend => 'D’un ami';

  @override
  String get builderShelfFly => 'Vole !';

  @override
  String builderShelfFlySemantics(String name) {
    return 'Voler dans $name';
  }

  @override
  String get builderShelfFixIt => 'Corriger';

  @override
  String builderShelfFixSemantics(String name) {
    return 'Corriger $name';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return 'Modifier $name';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return 'Partager $name';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return 'Partager $name : tu l’as terminé';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'Plus d’options pour $name';
  }

  @override
  String get builderShelfRemix => 'Remixer';

  @override
  String builderShelfRemixSemantics(String name) {
    return 'Remixer $name';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choses à corriger dans l’éditeur',
      one: '$count chose à corriger dans l’éditeur',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles',
      one: '$count étoile',
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
    return '$name. $mode, région : $region. $length.';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Record : $stars étoiles sur 3.',
      one: 'Record : $stars étoile sur 3.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'À retravailler : $count choses à corriger.',
      one: 'À retravailler : $count chose à corriger.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'Terminé par toi.';

  @override
  String get builderShelfFromFriendSemantics => 'D’un ami.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return 'Regarder $name. $mode, $length, $fact.';
  }

  @override
  String get builderShelfRemixSuffix => 'remix';

  @override
  String get builderShelfCopySuffix => 'copie';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get starter_t_tap_1_name => 'Saut au jardin';

  @override
  String get starter_t_push_1_name => 'Dix pompes';

  @override
  String get starter_t_squat_1_name => 'Squat d’escalier';

  @override
  String get starter_t_jump_1_name => 'Baie des bonds';

  @override
  String get starter_t_tap_boss_name => 'Le Pont du Baron';

  @override
  String get builderPickCloseNewLevel => 'Fermer le nouveau niveau';

  @override
  String get builderPickModeTitle => 'Ce sera quoi ?';

  @override
  String get builderPickRegionTitle => 'Où va-t-il voler ?';

  @override
  String get builderPickModeSubtitle =>
      'Choisis comment y jouer (impossible de changer ensuite). Chaque niveau s’essaie au doigt.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · choisis où il vole. Tu pourras changer plus tard.';
  }

  @override
  String get builderPickTouchLine =>
      'Tape pour battre des ailes. Portes, étoiles, ennemis et un boss.';

  @override
  String get builderPickPushUpLine =>
      'Un couloir haut et un bas : chaque descente est une pompe.';

  @override
  String get builderPickSquatLine =>
      'Un couloir haut et un bas : chaque descente est un squat.';

  @override
  String get builderPickJumpLine =>
      'Saute pour monter. Des portes partout dans le ciel.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'Caméra';

  @override
  String get builderPickSuggested => 'Conseillé';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, conseillé';
  }

  @override
  String get builderPickClose => 'Fermer';

  @override
  String get builderPickNotYet =>
      'Pas encore : corrige d’abord ce qui est en rouge.';

  @override
  String get builderPickShare => 'Code de partage';

  @override
  String get builderPickShareLine =>
      'Copie un code qu’un ami pourra coller dans son Beakbound.';

  @override
  String get builderPickDuplicate => 'Dupliquer';

  @override
  String get builderPickDuplicateLine =>
      'Fais une copie pour tester une autre idée.';

  @override
  String get builderPickDeleteLine =>
      'Jette le niveau. On te demandera d’abord.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'Annuler l’import';

  @override
  String get builderPickImportTitle => 'Un niveau à jouer !';

  @override
  String get builderPickImportSubtitle =>
      'Quelqu’un a partagé ce niveau avec toi.';

  @override
  String get builderPickClearedByMaker => 'Terminé par son créateur';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles à attraper',
      one: '$count étoile à attraper',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    return 'Boss final : $boss';
  }

  @override
  String get builderPickNotFlown => 'Son créateur ne l’a pas encore terminé.';

  @override
  String get builderPickRoute => 'La route';

  @override
  String builderPickAlreadyHave(String name) {
    return 'Tu as déjà ce niveau : « $name ».';
  }

  @override
  String get builderPickImportCopy => 'Importer une copie';

  @override
  String get builderPickOpenYours => 'Ouvrir le tien';

  @override
  String get builderPickImport => 'Importer';

  @override
  String get builderShelfRenameCancelSemantics =>
      'Annuler le changement de nom';

  @override
  String get builderShelfRenameTitle => 'Nomme ton niveau';

  @override
  String get builderShelfRenameEmpty => 'Il faut une lettre ou deux';

  @override
  String get builderShelfRenameSaveSemantics => 'Enregistrer le nom';

  @override
  String get builderShelfRenameSave => 'Enregistrer';

  @override
  String get coopMode_roped => 'Encordés';

  @override
  String get coopMode_free => 'Sans corde';

  @override
  String get coopMode_duel => '1 contre 1';

  @override
  String get coopTitle => 'Volons ensemble';

  @override
  String get coopPlayersTag => 'DEUX JOUEURS · UN TÉLÉPHONE';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode · RECORD $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode : PAS DE RECORD';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count DUELS',
      one: '$mode · $count DUEL',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode : PREMIER DUEL';
  }

  @override
  String get coopRopedLead => 'Vos oiseaux partagent une corde.';

  @override
  String get coopRopedBody =>
      'Battez des ailes ensemble pour monter haut : un oiseau seul soulève les deux, mais un peu seulement. Utilisez Sprint pour entraîner votre partenaire.';

  @override
  String get coopFreeLead => 'Sans corde :';

  @override
  String get coopFreeBody =>
      'chaque oiseau vole de son côté et peut seulement heurter l’autre. Cœurs, bouclier et score restent partagés.';

  @override
  String get duelLead => 'En garde !';

  @override
  String get duelBody =>
      'Chaque oiseau a ses propres cœurs. Attrapez les boîtes mystère : certaines envoient des chauves-souris, un cracheur ou des météores sur votre rival, d’autres donnent un cœur, un bouclier ou le pouvoir des étoiles. Le dernier oiseau en vol gagne.';

  @override
  String get coopStart => 'Volons ensemble';

  @override
  String get duelStart => 'En garde !';

  @override
  String get coopFlightSemantics =>
      'Le joueur 1 touche la moitié gauche pour battre des ailes, le joueur 2 la moitié droite';

  @override
  String get coopPauseSemantics => 'Mettre le vol en pause';

  @override
  String coopShootSemantics(int player) {
    return 'Joueur $player : tirer';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'Joueur $player : sprint';
  }

  @override
  String coopPlayerShort(int player) {
    return 'J$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'JOUEUR $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Aimant à étoiles : $seconds secondes restantes',
      one: 'Aimant à étoiles : $seconds seconde restante',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Aimant en charge : $charge sur $gates portes parfaites',
      one: 'Aimant en charge : $charge sur $gates porte parfaite',
    );
    return '$_temp0';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds s',
    );
    return '$_temp0';
  }

  @override
  String get coopCountdownRoped => 'Corde attachée. À vos marques…';

  @override
  String get coopCountdownFree => 'À vos marques…';

  @override
  String get duelCountdown => 'Prêts pour le duel…';

  @override
  String get coopCountdownRopedHint =>
      'Battez des ailes ensemble pour monter.\nUtilisez Sprint pour entraîner votre partenaire !';

  @override
  String get coopCountdownFreeHint =>
      'Chaque oiseau vole de son côté.\nPartagez les cœurs, passez les portes !';

  @override
  String get duelCountdownHint =>
      'Attrapez les boîtes mystère !\nLe dernier oiseau en vol gagne.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other:
          'Joueur $player, pouvoir des étoiles : $seconds secondes restantes',
      one: 'Joueur $player, pouvoir des étoiles : $seconds seconde restante',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'Accueil';

  @override
  String get coopChangeBirds => 'Autres oiseaux';

  @override
  String get coopSaved => 'Séance gardée';

  @override
  String get coopSaving => 'Enregistrement…';

  @override
  String get coopSaveSession => 'Garder la séance';

  @override
  String get duelRematch => 'Revanche';

  @override
  String get coopFlyAgain => 'Encore un vol';

  @override
  String duelWinner(int player) {
    return 'Le joueur $player gagne !';
  }

  @override
  String get duelDraw => 'Égalité !';

  @override
  String get duelStopped => 'Duel arrêté';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first contre $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner a battu $loser';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize sur J$rival !';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize !';
  }

  @override
  String get duelPrize_batSwarm => 'Essaim';

  @override
  String get duelPrize_spitter => 'Cracheur';

  @override
  String get duelPrize_meteorShower => 'Météores';

  @override
  String get duelPrize_heart => 'Cœur';

  @override
  String get duelPrize_shield => 'Bouclier';

  @override
  String get duelPrize_starPower => 'Pouvoir étoilé';

  @override
  String get coopTapLeftHalf => 'Touche la moitié gauche';

  @override
  String get coopTapRightHalf => 'Touche la moitié droite';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'Joueur $player : $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'J$player · touche ce côté';
  }

  @override
  String get coopKeysP1 => 'J1 · W vol, D tir, A sprint';

  @override
  String get coopKeysP2 => 'J2 · Haut vol, Droite tir, Gauche sprint';

  @override
  String get coopRopedSemantics => 'Encordés : les oiseaux partagent une corde';

  @override
  String get coopFreeSemantics => 'Sans corde : chaque oiseau vole de son côté';

  @override
  String get duelModeSemantics => '1 contre 1 : les oiseaux s’affrontent';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'Séance enregistrée · Voir dans Records';

  @override
  String get coopNewTeamBest => 'Record d’équipe !';

  @override
  String get coopWhatATeam => 'Quelle équipe !';

  @override
  String coopPairCaption(String first, String second) {
    return '$first et $second';
  }

  @override
  String get coopTeamScore => 'SCORE D’ÉQUIPE';

  @override
  String get coopTeamBest => 'RECORD D’ÉQUIPE';

  @override
  String get coopNewTeamBestRibbon => 'RECORD D’ÉQUIPE !';

  @override
  String get coopStatFlightTime => 'temps de vol';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'étoiles',
      one: 'étoile',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portes',
      one: 'porte',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'PART DES BATTEMENTS';

  @override
  String coopPercent(int percent) {
    return '$percent %';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'battements J$player',
      one: 'battement J$player',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'Durée du duel : $time';
  }

  @override
  String get duelSeries => 'SÉRIE';

  @override
  String get duelHeartsLeft => 'cœurs restants';

  @override
  String get duelBoxesOpened => 'boîtes ouvertes';

  @override
  String get duelHitsLanded => 'coups portés';

  @override
  String get coopPauseSubtitle =>
      'Vos oiseaux sont perchés et attendent. Un compte à rebours vous relancera.';

  @override
  String get coopFinishFlight => 'Terminer le vol';

  @override
  String get cameraLabIntro =>
      'Pose ton téléphone bas, à l’horizontale, face à toi ou à côté de toi.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'Presque ! Il faut mieux voir : $parts';
  }

  @override
  String get cameraLabJointShoulder => 'épaule';

  @override
  String get cameraLabJointElbow => 'coude';

  @override
  String get cameraLabJointWrist => 'poignet';

  @override
  String get cameraLabJointHip => 'hanche';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => 'Démarrage de la caméra…';

  @override
  String get cameraLabDenied =>
      'L’accès à la caméra est désactivé. Autorise-le dans les paramètres de l’appli, puis réessaie.';

  @override
  String cameraLabFailed(String error) {
    return 'La caméra n’a pas pu démarrer : $error';
  }

  @override
  String get cameraLabStopped =>
      'Caméra arrêtée. Touche Lancer la caméra pour recalibrer.';

  @override
  String get cameraLabBack => 'LABO CAMÉRA · Retour à l’accueil';

  @override
  String get cameraLabStepShow => '1. Montre bras et hanche';

  @override
  String get cameraLabStepPushUps => '2. Fais deux pompes';

  @override
  String get cameraLabStepMove => '3. Dirige ton oiseau !';

  @override
  String get cameraLabStepSquat => 'Trouve l’amplitude du squat';

  @override
  String get cameraLabStepJump => 'Trouve ta position debout';

  @override
  String get cameraLabPushUpHelp =>
      'Téléphone bas, face à toi ou à côté.\nDe face ? Montre les deux épaules, un bras et une hanche.\nDescends et remonte deux fois, à ton rythme.';

  @override
  String get cameraLabSquatHelp =>
      'Reste immobile, accroupis-toi tranquillement un instant, puis relève-toi. Accroupis-toi pour descendre ; lève-toi pour monter.';

  @override
  String get cameraLabJumpHelp =>
      'Tiens-toi face au téléphone, corps entier et pieds visibles. Ne bouge plus, puis fais de petits sauts. Un saut = un grand élan.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'CALIBRAGE\n$done / $total calibrées',
      one: 'CALIBRAGE\n$done / $total calibrée',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'CALIBRAGE\nCalibré à $percent %';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TEST DES COMMANDES\n$count pompes',
      one: 'TEST DES COMMANDES\n$count pompe',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TEST DES COMMANDES\n$count squats',
      one: 'TEST DES COMMANDES\n$count squat',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TEST DES COMMANDES\n$count sauts',
      one: 'TEST DES COMMANDES\n$count saut',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Hz · $ms ms p95';
  }

  @override
  String get cameraLabStartingButton => 'Démarrage…';

  @override
  String get cameraLabRecalibrate => 'Recalibrer';

  @override
  String get cameraLabStartCamera => 'Lancer la caméra';

  @override
  String get cameraLabTapStart => 'Touche Lancer la caméra';

  @override
  String cameraLabTry(String mode) {
    return 'Essayer $mode';
  }

  @override
  String get cameraBadgeWaking => 'RÉVEIL';

  @override
  String get cameraBadgeLive => 'EN DIRECT';

  @override
  String get cameraBadgeLockedOn => 'VERROUILLÉ';

  @override
  String get cameraBadgeOffline => 'HORS LIGNE';

  @override
  String get trackingCatchingUp => 'La caméra rattrape son retard';

  @override
  String get trackingStepIntoOutline => 'Place-toi dans la silhouette';

  @override
  String get trackingKeepShoulders => 'Garde les deux épaules visibles';

  @override
  String get trackingShowSide =>
      'Montre de profil une épaule, un coude, un poignet et une hanche';

  @override
  String get trackingMoveCloser => 'Rapproche-toi un peu';

  @override
  String get trackingGetDown => 'Mets-toi en position de pompe';

  @override
  String get trackingHandsOnFloor =>
      'Pose les mains au sol et allonge ton corps derrière toi';

  @override
  String get trackingExtendBody =>
      'Allonge ton corps un peu plus loin derrière tes mains';

  @override
  String get trackingComfortableRange =>
      'Reste dans une amplitude de pompe confortable';

  @override
  String get trackingPlaceHands =>
      'Pose les mains au sol, le corps derrière elles';

  @override
  String get trackingFrontTracked =>
      'Suivi de face OK · garde tes mains visibles';

  @override
  String get trackingBodyInView => 'Corps visible · tu peux regarder le sol';

  @override
  String get trackingArmsTracked => 'Bras suivis · jambes mal vues';

  @override
  String get trackingFindTop => 'Trouve une position haute confortable';

  @override
  String get trackingCalibrated => 'Calibré ! Essaie de diriger ton oiseau.';

  @override
  String get trackingFreshFrame => 'En attente d’une nouvelle image';

  @override
  String get trackingDistanceChanged =>
      'Distance à la caméra changée · recalibre';

  @override
  String get trackingKeepArm => 'Garde un bras visible';

  @override
  String get trackingSquatStepBack =>
      'Recule pour que tes épaules, hanches, genoux et pieds soient visibles';

  @override
  String get trackingSquatFaceCamera =>
      'Mets-toi face à la caméra, les deux pieds au sol';

  @override
  String get trackingSquatControls =>
      'Accroupis-toi pour descendre · lève-toi pour monter';

  @override
  String get trackingStartingDistance =>
      'Face à la caméra, à ta distance de départ · recalibre si tu as bougé';

  @override
  String get trackingFeetPlanted =>
      'Garde les deux pieds bien posés à ta place de départ';

  @override
  String get trackingSquatStandTall =>
      'Debout, sans bouger, les deux pieds visibles';

  @override
  String get trackingStandStill => 'Debout, sans bouger, un instant';

  @override
  String get trackingSquatDepth =>
      'Accroupis-toi à une profondeur confortable et tiens un instant';

  @override
  String get trackingSquatHold =>
      'Accroupis-toi tranquillement, puis tiens un instant';

  @override
  String get trackingSquatHoldBriefly =>
      'Tiens ce squat confortable un instant';

  @override
  String get trackingSquatStandUp => 'Relève-toi pour finir le calibrage';

  @override
  String get trackingSquatReady =>
      'C’est parti ! Accroupis-toi pour descendre · lève-toi pour monter';

  @override
  String get trackingJumpStepBack =>
      'Recule pour que tes épaules, hanches et pieds soient visibles';

  @override
  String get trackingJumpFaceCamera =>
      'Mets-toi face à la caméra, avec de la place au-dessus pour sauter';

  @override
  String get trackingJumpSmall =>
      'De petits sauts suffisent · atterris avant de ressauter';

  @override
  String get trackingJumpStandStill =>
      'Ne bouge plus, corps entier et pieds visibles';

  @override
  String get trackingJumpReady =>
      'C’est parti ! Un petit saut donne un grand élan.';

  @override
  String get trackingFindPosition => 'Trouve ta position';

  @override
  String get trackingInterrupted => 'Suivi interrompu';

  @override
  String get trackingCameraInterrupted =>
      'Caméra interrompue. Vérifie l’autorisation de la caméra et réessaie.';

  @override
  String get trackingCameraAway => 'La caméra s’est arrêtée en arrière-plan';

  @override
  String get trackingJumpBoost => 'Saute pour un grand élan';

  @override
  String get trackingJumpLand => 'Atterris pour préparer ton saut';

  @override
  String trackingLowerMore(int step, int total) {
    return 'Descends un peu plus · $step sur $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'Descends tranquillement · $step sur $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'Remonte · $step sur $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'Retrouve ta première amplitude · $step sur $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Impossible d’enregistrer ce changement. Réessaie. ($error)';
  }

  @override
  String get commonDelete => 'Supprimer';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il en manque $count',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'Ton nid se fait attendre.';

  @override
  String get homeSettings => 'Réglages';

  @override
  String homeGreetingFirst(String bird) {
    return 'Salut, moi c’est $bird ! On s’envole ?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Aventure finie ! $bird est fier.',
      'female': 'Aventure finie ! $bird est fière.',
      'other': 'Aventure finie ! $bird est aux anges.',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird est prêt. Et toi ?',
      'female': '$bird est prête. Et toi ?',
      'other': '$bird t’attend. On y va ?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'INFINI';

  @override
  String get homeEndlessDetail => 'Vole aussi loin que tu peux';

  @override
  String get homeEndlessSemantics => 'Infini. Vole aussi loin que tu peux.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other:
          'Infini. Vole aussi loin que tu peux. Record : $best points étoiles.',
      one: 'Infini. Vole aussi loin que tu peux. Record : $best point étoile.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'Record';

  @override
  String get homeBestNone => 'Ton premier record ?';

  @override
  String get homeCampaignTitle => 'CAMPAGNE';

  @override
  String get homeCampaignDone => 'Chaque lettre livrée';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Campagne. Ensuite : $level. $stars étoiles sur $total.',
      one: 'Campagne. Ensuite : $level. $stars étoile sur $total.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Campagne. Chaque lettre livrée. $stars étoiles sur $total.',
      one: 'Campagne. Chaque lettre livrée. $stars étoile sur $total.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'MINI-JEUX';

  @override
  String get homeMiniGamesDetail => 'Exercices · 2 joueurs';

  @override
  String get homeMiniGamesSemantics =>
      'Mini-jeux. Pompes, squats, sauts ou deux joueurs.';

  @override
  String get homeBuilderTitle => 'CRÉATEUR';

  @override
  String get homeBuilderDetail => 'Crée · vole · partage';

  @override
  String get homeBuilderSemantics =>
      'Créateur de niveaux. Crée tes propres niveaux, joue-les et partage-les.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Débloqué dans $count vols',
      one: 'Débloqué dans $count vol',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Créateur de niveaux. Verrouillé. Débloqué dans $count vols.',
      one: 'Créateur de niveaux. Verrouillé. Débloqué dans $count vol.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'Aventure';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Aventure du jour. $done objectifs sur 3 atteints.',
      one: 'Aventure du jour. $done objectif sur 3 atteint.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'Oiseaux';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'Oiseaux. Tu voles avec $bird.';
  }

  @override
  String get homeDockUpgrades => 'Pouvoirs';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Améliorations. $stars étoiles à dépenser.',
      one: 'Améliorations. $stars étoile à dépenser.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'Passeport';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Passeport. $earned médailles sur $total.',
      one: 'Passeport. $earned médaille sur $total.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'Records';

  @override
  String get homeMiniGamesPickerTitle => 'Mini-jeux';

  @override
  String get homeMiniGamesPickerIntro =>
      'Bouge pour voler, ou partage le téléphone avec un ami.';

  @override
  String get homeMiniGamesCloseSemantics => 'Fermer les mini-jeux';

  @override
  String get homeMiniGamesPushUpCard =>
      'Descends, il plonge.\nPousse, il monte.';

  @override
  String get homeMiniGamesSquatCard => 'Accroupis-toi.\nLève-toi pour monter.';

  @override
  String get homeMiniGamesJumpCard =>
      'Saute et monte.\nPlane vers les étoiles.';

  @override
  String get homeMiniGamesCoopCard =>
      'Deux joueurs, un écran.\nEn équipe ou en duel.';

  @override
  String get homeMiniGamesCamera => 'Caméra';

  @override
  String get homeMiniGamesPlayers => '2 joueurs';

  @override
  String get homeMiniGamesCoop => 'Volons ensemble';

  @override
  String get birdsTitle => 'Voici ton équipage de vol.';

  @override
  String birdsFlownTag(int flown, int total) {
    return '$flown SUR $total ESSAYÉS';
  }

  @override
  String get birdsStatusCopilot => 'TON COPILOTE';

  @override
  String get birdsStatusReady => 'DISPONIBLE';

  @override
  String get birdsStatusLocked => 'À DÉBLOQUER';

  @override
  String get birdsNotFlown => 'Aucun vol';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vols',
      one: '$count vol',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return 'Voler avec $bird';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return 'Voler avec $bird au lieu de $current';
  }

  @override
  String birdsUnlock(String bird) {
    return 'Débloquer $bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Débloquer $bird pour $price étoiles',
      one: 'Débloquer $bird pour $price étoile',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Débloquer $bird pour $price étoiles, pas encore assez d’étoiles',
      one: 'Débloquer $bird pour $price étoile, pas encore assez d’étoiles',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'Vole avec toi';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, vole avec toi';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, vole avec toi, pas encore de vol';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, à débloquer, $price étoiles',
      one: '$bird, à débloquer, $price étoile',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird, pas encore de vol';
  }

  @override
  String get birdsTagFlying => 'EN VOL';

  @override
  String get birdsTagNew => 'ESSAIE';

  @override
  String get bird_0_description => 'Petit oiseau. Grand ciel.';

  @override
  String get bird_0_trail => 'Bulles de soleil';

  @override
  String get bird_1_description => 'Joues roses, crête frisée, tout en cœur.';

  @override
  String get bird_1_trail => 'Cœurs de pêche';

  @override
  String get bird_2_description =>
      'Mini colibri. Brin de menthe. Pleine vitesse.';

  @override
  String get bird_2_trail => 'Feuilles de menthe';

  @override
  String get bird_3_description =>
      'Une chouette rêveuse qui vole sous les étoiles.';

  @override
  String get bird_3_trail => 'Poussière d’étoiles';

  @override
  String get upgradesWalletLabel => 'TES\nÉTOILES';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars étoiles à dépenser',
      one: '$stars étoile à dépenser',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'Booste ton oiseau.';

  @override
  String get upgradesIntro =>
      'Touche un engrenage pour voir son effet. Chaque étoile ramassée en vol se dépense ici.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, niveau $level sur $max. Niveau suivant : $cost étoiles',
      one: '$power, niveau $level sur $max. Niveau suivant : $cost étoile',
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
          '$power, niveau $level sur $max. Niveau suivant : $cost étoiles, pas encore assez',
      one:
          '$power, niveau $level sur $max. Niveau suivant : $cost étoile, pas encore assez',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, niveau $level sur $max. Au maximum';
  }

  @override
  String get upgradesMax => 'MAX';

  @override
  String upgradesLevel(int level) {
    return 'Niveau $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'Niveau $level, au max';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label : $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label : $now, niveau suivant : $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value %';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value s';
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
      other: 'Il te restera $count étoiles.',
      one: 'Il te restera $count étoile.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'Améliorer';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Améliorer pour $cost étoiles',
      one: 'Améliorer pour $cost étoile',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Améliorer pour $cost étoiles, pas encore assez d’étoiles',
      one: 'Améliorer pour $cost étoile, pas encore assez d’étoiles',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'Au maximum';

  @override
  String get power_shot_name => 'Force de tir';

  @override
  String get power_shot_blurb =>
      'Maintiens Tirer pour charger un caillou plus gros et plus dur.';

  @override
  String get power_sprint_name => 'Sprint';

  @override
  String get power_sprint_blurb =>
      'Une pointe de vitesse qui écrase les ennemis sur ton chemin.';

  @override
  String get power_shield_name => 'Bouclier';

  @override
  String get power_shield_blurb =>
      'Bloque un coup pour toi. Attrape des étoiles en vol pour le recharger.';

  @override
  String get power_magnet_name => 'Aimant';

  @override
  String get power_magnet_blurb =>
      'Gagne-le avec des passages parfaits. Il attire les étoiles vers toi.';

  @override
  String get power_stat_maxCharge => 'Charge max';

  @override
  String get power_stat_burstLength => 'Durée du sprint';

  @override
  String get power_stat_cooldown => 'Recharge';

  @override
  String get power_stat_starsToRefill => 'Étoiles pour recharger';

  @override
  String get power_stat_safeTime => 'Répit après la casse';

  @override
  String get power_stat_perfectGates => 'Portes parfaites requises';

  @override
  String get power_stat_lasts => 'Durée';

  @override
  String get power_stat_reach => 'Portée';

  @override
  String get passportTitle => 'Ton passeport du ciel.';

  @override
  String get passportDailyCard => 'Carte du jour';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total MÉDAILLES';
  }

  @override
  String get passportIntro =>
      'Petites aventures. Souvenirs durables. Bronze, argent et or pour chaque tampon.';

  @override
  String get passportNoMedal => 'Pas encore de médaille';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Médaille de bronze',
      'silver': 'Médaille d’argent',
      'other': 'Médaille d’or',
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
    return '$stamp. $held. Ensuite, $next : $goal $current sur $target.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. Médaille d’or. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'VERS BRONZE',
      'silver': 'VERS ARGENT',
      'other': 'VERS L’OR',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'TAMPONNÉ';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp : $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp : pas encore';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'Bronze';

  @override
  String get passportMedal_silver => 'Argent';

  @override
  String get passportMedal_gold => 'Or';

  @override
  String get stamp_frequentFlyer_name => 'Grand voyageur';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Termine $n vols comptabilisés.',
      one: 'Termine $n vol comptabilisé.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'Pile au centre';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Réussis $n passages parfaits le long des mires.',
      one: 'Réussis $n passage parfait le long des mires.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'Chasseur d’étoiles';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attrape $n étoiles.',
      one: 'Attrape $n étoile.',
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
      other: 'Attrape $n étoiles en une seule série.',
      one: 'Attrape $n étoile en une seule série.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'Capitaine du ciel';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Marque $n points en un seul vol infini.',
      one: 'Marque $n point en un seul vol infini.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'Pionnier';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vole au moins 60 secondes lors de $n vols infinis.',
      one: 'Vole au moins 60 secondes lors de $n vol infini.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'Toute la volée';

  @override
  String get stamp_allRounder_name => 'Touche-à-tout';

  @override
  String get stamp_flockTogether_goalBronze =>
      'Emmène deux oiseaux différents en vols comptabilisés.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'Emmène les quatre oiseaux en vols comptabilisés.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fais $n vols comptabilisés avec chaque oiseau.',
      one: 'Fais $n vol comptabilisé avec chaque oiseau.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'Joue à un mini-jeu de pompes, squats ou sauts.';

  @override
  String get stamp_allRounder_goalSilver =>
      'Joue aux trois mini-jeux : pompes, squats, sauts.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fais $n vols comptabilisés dans chaque mini-jeu.',
      one: 'Fais $n vol comptabilisé dans chaque mini-jeu.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals médailles · niveau $level',
      one: '$stars★ · $medals médaille · niveau $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'Ton aventure se fait attendre.';

  @override
  String get dailyTitle => 'Ta petite aventure du jour.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · $done/3 RÉUSSIS';
  }

  @override
  String get dailyIntro =>
      'Trois objectifs. Joue comme tu veux. Un seul vol infini peut tous les remplir.';

  @override
  String get dailyLaunchEndless => 'Infini';

  @override
  String get dailyPostcardKicker => 'CARTE DU CLUB DU CIEL';

  @override
  String get dailyStamped => 'CARTE TAMPONNÉE !';

  @override
  String dailyGoalsComplete(int done) {
    return 'OBJECTIFS : $done / 3';
  }

  @override
  String get dailyDoneNote => 'Une petite aventure, rien qu’à toi.';

  @override
  String get dailyOpenNote => 'Finis les trois pour tamponner la carte.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal Réussi';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current sur $target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date : carte tamponnée';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date : $done/3 objectifs';
  }

  @override
  String get dailyNoStreak => 'Objectifs neufs. Pas de série à perdre.';

  @override
  String get dailyTheme_0 => 'Livraison à l’aube';

  @override
  String get dailyTheme_1 => 'Pique-nique pêche';

  @override
  String get dailyTheme_2 => 'Poste au clair de lune';

  @override
  String get dailyTheme_3 => 'Parade des nuages';

  @override
  String get dailyTheme_4 => 'Trésor du crépuscule';

  @override
  String get dailyTheme_5 => 'Fête au jardin';

  @override
  String get task_flights_title => 'Déploie tes ailes';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Termine $count vols comptabilisés aujourd’hui.',
      one: 'Termine $count vol comptabilisé aujourd’hui.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'Horizons ouverts';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Passe $count portes lors des vols comptabilisés du jour.',
      one: 'Passe $count porte lors des vols comptabilisés du jour.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'Plein les poches';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attrape $count étoiles lors des vols du jour.',
      one: 'Attrape $count étoile lors des vols du jour.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'Garde l’étincelle';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attrape $count étoiles en une seule série.',
      one: 'Attrape $count étoile en une seule série.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'En plein dans le mille';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Réussis $count passages parfaits aujourd’hui.',
      one: 'Réussis $count passage parfait aujourd’hui.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'Tout le voyage';

  @override
  String get task_finishTrail_goal =>
      'Vole au moins 60 secondes en un seul vol infini.';

  @override
  String get recordsTitle => 'Tes petites victoires.';

  @override
  String get recordsBestsTitle => 'Tes points étoiles à battre';

  @override
  String get recordsSectionMain => 'JEU PRINCIPAL';

  @override
  String get recordsSectionMini => 'MINI-JEUX';

  @override
  String get recordsEndless => 'Infini · Tape & Vole';

  @override
  String get recordsCampaignStars => 'Étoiles de campagne';

  @override
  String recordsCoopName(String mode) {
    return 'Volons ensemble · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vols comptabilisés',
      one: 'vol comptabilisé',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portes',
      one: 'porte',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'à deux',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'duels',
      one: 'duel',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pompes',
      one: 'pompe',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squats',
      one: 'squat',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'Vols récents';

  @override
  String get recordsEmptyTitle => 'Grand ciel, page blanche.';

  @override
  String get recordsEmptyBody =>
      'Ton premier vol comptabilisé lance l’histoire.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds s';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'Classique · $date · $seconds s';
  }

  @override
  String get replaySavedSessions => 'Séances gardées';

  @override
  String get replayBackToRecordsSemantics => 'Retour aux records';

  @override
  String get replaySessionsLoadFailed => 'Chargement impossible. Réessayer';

  @override
  String get replayEmptyTitle => 'Tes vols ont leur place ici';

  @override
  String get replayEmptyBody =>
      'Garde une séance après un vol pour la revoir ici.';

  @override
  String get replayEmptyButton => 'Choisir un vol';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds s · $score points étoiles',
      one: '$date · $seconds s · $score point étoile',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds s · $score portes',
      one: '$date · $seconds s · $score porte',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'Supprimer la séance';

  @override
  String get replayDeleteTitle => 'Supprimer cette séance ?';

  @override
  String get replayDeleteBody =>
      'La vidéo de la caméra et la rediffusion seront supprimées. Tes scores restent dans Records.';

  @override
  String get replayDeleteFailed =>
      'Impossible de supprimer la séance. Réessaie.';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return 'Niveau $id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · Infini';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · Entraînement';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · Infini · Entraînement';
  }

  @override
  String get replayOpenFailed => 'Impossible d’ouvrir cette séance.';

  @override
  String get replayBackToSessions => 'Retour aux séances';

  @override
  String get replayCameraPaused =>
      'La caméra était en pause pendant ce moment de la séance';

  @override
  String get replayCameraUnavailable =>
      'Clip caméra indisponible · Le jeu se rejoue quand même';

  @override
  String get replayCameraLoading => 'Chargement de la caméra…';

  @override
  String get replayPaused => 'On souffle un peu';

  @override
  String get replayHideControlsSemantics => 'Masquer les commandes de lecture';

  @override
  String get replayShowControlsSemantics => 'Afficher les commandes de lecture';

  @override
  String get replayBackToSavedSemantics => 'Retour aux séances gardées';

  @override
  String get replayTitle => 'REDIFFUSION';

  @override
  String replayTitleSession(String session) {
    return 'REDIFFUSION · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'Score : $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts cœurs',
      one: '$hearts cœur',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'Cœurs J1 $p1 · J2 $p2 · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String replayMagnet(int seconds) {
    return 'Aimant $seconds s';
  }

  @override
  String get replayPauseSemantics => 'Mettre la rediffusion en pause';

  @override
  String get replayPlaySemantics => 'Lire la rediffusion';

  @override
  String get replayRestartSemantics => 'Recommencer la rediffusion';

  @override
  String get replayBack5Semantics => 'Reculer de 5 secondes';

  @override
  String get replayForward5Semantics => 'Avancer de 5 secondes';

  @override
  String get replayHighlightsFinding => 'Recherche des temps forts du vol';

  @override
  String get replayHighlightsNone => 'Aucun temps fort disponible';

  @override
  String get replayHighlights => 'Temps forts du vol';

  @override
  String get replayHighlightsCloseSemantics => 'Fermer les temps forts';

  @override
  String get replayHighlightsHint =>
      'Choisis un moment. Regarde-le à partir de juste avant.';

  @override
  String get replayViewCorner => 'Caméra dans un coin';

  @override
  String get replayViewBackground => 'Caméra en fond';

  @override
  String get replayViewGameplay => 'Jeu seulement';

  @override
  String get replayMoveCornerSemantics =>
      'Déplacer la caméra dans un autre coin';

  @override
  String get replayMuteRecordedSemantics => 'Couper le son enregistré';

  @override
  String get replayUnmuteRecordedSemantics => 'Activer le son enregistré';

  @override
  String get replayMuteGameSemantics => 'Couper le son du jeu';

  @override
  String get replayUnmuteGameSemantics => 'Activer le son du jeu';

  @override
  String get replayFullScreenSemantics => 'Masquer les commandes / plein écran';

  @override
  String get replayMomentTakeoff => 'Décollage';

  @override
  String get replayMomentTakeoffDetail => 'Le ciel est à toi.';

  @override
  String get replayMomentMagnet => 'Aimant à étoiles';

  @override
  String get replayMomentMagnetDetail =>
      'Trois passages parfaits rapprochent les étoiles.';

  @override
  String get replayMomentStarTrio => 'Premier trio d’étoiles';

  @override
  String get replayMomentStarTrioDetail =>
      'Trois étoiles deviennent une constellation. +5 points !';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'Toutes les étoiles du groupe attrapées. +5 points !';

  @override
  String replayMomentStreak(int multiplier) {
    return 'Étoiles ×$multiplier';
  }

  @override
  String get replayMomentStreakDetail => 'Une série d’étoiles étincelante.';

  @override
  String get replayMomentShield => 'Coup bloqué';

  @override
  String get replayMomentShieldDetail =>
      'C’était moins une, et voilà une autre chance.';

  @override
  String get replayMomentPerfect => 'Premier passage parfait';

  @override
  String get replayMomentPerfectDetail => 'Pile dans la mire.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portes passées',
      one: '$count porte passée',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'Un peu plus loin dans le ciel.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Pas une égratignure. +$points points !',
      one: 'Pas une égratignure. +$points point !',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Les anneaux de sprint t’ont sauvé la mise. +$points points !',
      one: 'Les anneaux de sprint t’ont sauvé la mise. +$points point !',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'Bourrasque bravée';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Débris évités. +$points points !',
      one: 'Débris évités. +$points point !',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'Route terminée';

  @override
  String get replayMomentFinal => 'Dernier moment';

  @override
  String get replayMomentCompleteDetail => 'Tu as atteint le bout de la route.';

  @override
  String get replayMomentCollisionDetail => 'Regarde l’approche finale.';

  @override
  String get replayMomentEndDetail => 'La fin de ce vol.';

  @override
  String get welcomeTitle => 'Choisis ta langue';

  @override
  String get welcomeContinue => 'On s’envole !';

  @override
  String get welcomeHint =>
      'Tu peux la changer à tout moment dans les Réglages.';

  @override
  String get welcomeDevice => 'Langue du téléphone';

  @override
  String get tutorialTitle => 'École de vol';

  @override
  String get tutorialSkip => 'Passer la leçon';

  @override
  String get tutorialSkipTitle => 'Passer l’école de vol ?';

  @override
  String get tutorialSkipBody =>
      'Tu pourras refaire la leçon à tout moment depuis les Réglages.';

  @override
  String get tutorialSkipConfirm => 'Passer';

  @override
  String get tutorialSkipCancel => 'Continuer la leçon';

  @override
  String get tutorialRestart => 'Recommencer';

  @override
  String get tutorialGoalFlaps => 'Bats des ailes';

  @override
  String get tutorialGoalStars => 'Attrape les étoiles';

  @override
  String get tutorialGoalGates => 'Passe les portes';

  @override
  String get tutorialGoalBats => 'Chauves-souris K.-O.';

  @override
  String get tutorialGoalDoor => 'Brise la dalle';

  @override
  String get tutorialGoalSprint => 'Utilise le Sprint';

  @override
  String get tutorialGoalBoss => 'Bats le Capitaine';

  @override
  String get tutorialPromptTap => 'Touche !';

  @override
  String get tutorialPromptShoot => 'Touche Tirer';

  @override
  String get tutorialPromptHoldShoot => 'Maintiens Tirer';

  @override
  String get tutorialPromptSprint => 'Touche Sprint';

  @override
  String get tutorialPraiseNice => 'Bien joué !';

  @override
  String get tutorialPraiseGreat => 'Super !';

  @override
  String get tutorialPraiseSuper => 'Génial !';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return 'La leçon t’attend : $prompt';
  }

  @override
  String get licenceTitle => 'Permis de facteur';

  @override
  String get licenceIssuer => 'Poste du Club du Ciel';

  @override
  String get licenceHolder => 'Facteur';

  @override
  String get licenceRank => 'Grade';

  @override
  String get licenceRankRookie => 'Jeune recrue';

  @override
  String get licenceSkills => 'Compétences';

  @override
  String get licenceStamp => 'Certifié';

  @override
  String licenceSignedBy(String name) {
    return 'Signé : $name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles',
      one: '$count étoile',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => 'Ma première route !';

  @override
  String get licenceAgain => 'Rejouer la leçon';

  @override
  String get settingsTutorial => 'École de vol';

  @override
  String get settingsTutorialDetail => 'Refaire la première leçon';
}
