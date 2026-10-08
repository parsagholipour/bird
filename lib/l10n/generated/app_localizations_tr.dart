// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get commonTryAgain => 'Tekrar dene';

  @override
  String get languageKeyLabel => 'Dil';

  @override
  String languageKeySemantics(String language) {
    return 'Dil: $language. Oyunun dilini değiştir.';
  }

  @override
  String get languageSystemDefault => 'Sistem varsayılanı';

  @override
  String languageSystemDetail(String language) {
    return 'Telefonun dili: $language';
  }

  @override
  String get languageCurrent => 'Şu anki dil';

  @override
  String get languageName_en => 'İngilizce';

  @override
  String get languageName_es_419 => 'İspanyolca (Latin Amer.)';

  @override
  String get languageName_pt_br => 'Portekizce (Brezilya)';

  @override
  String get languageName_id => 'Endonezce';

  @override
  String get languageName_fr => 'Fransızca';

  @override
  String get languageName_de => 'Almanca';

  @override
  String get languageName_ja => 'Japonca';

  @override
  String get languageName_ko => 'Korece';

  @override
  String get languageName_tr => 'Türkçe';

  @override
  String get languageName_zh_hant => 'Geleneksel Çince';

  @override
  String get languageName_ru => 'Rusça';

  @override
  String get languageName_ar => 'Arapça';

  @override
  String get voicePackReady => 'Sesler hazır';

  @override
  String get voicePackDownload => 'Sesleri indir';

  @override
  String voicePackDownloading(int percent) {
    return 'Sesler %$percent';
  }

  @override
  String get voicePackStarting => 'Sesler geliyor';

  @override
  String get voicePackEnglish => 'İngilizce sesler';

  @override
  String get voicePackFailed => 'Sesler inemedi';

  @override
  String get settingsTitle => 'Kendini evinde hisset.';

  @override
  String get settingsSectionSound => 'Ses';

  @override
  String get settingsSectionComfort => 'Rahatlık';

  @override
  String get settingsMusicTitle => 'Gök Kulübü müzikleri';

  @override
  String get settingsMusicDetail => 'Menü, macera ve boss müzikleri.';

  @override
  String get settingsEffectsTitle => 'Ses efektleri';

  @override
  String get settingsEffectsDetail =>
      'Uçuş, dövüş, toplananlar ve menü sesleri.';

  @override
  String get settingsVoicesTitle => 'Karakter sesleri';

  @override
  String get settingsVoicesDetail =>
      'Hikâyeler, teşekkür notları ve sprint sesleri.';

  @override
  String get settingsReducedMotionTitle => 'Hareketi azalt';

  @override
  String get settingsReducedMotionDetail =>
      'Daha sakin menüler, daha az süs efekti.';

  @override
  String get settingsSwitchOn => 'AÇIK';

  @override
  String get settingsSwitchOff => 'KAPALI';

  @override
  String get settingsUnavailable => 'Ayarlar biraz zaman istiyor.';

  @override
  String get settingsPrivacyKicker => 'CİHAZDA. HER ZAMAN.';

  @override
  String get settingsPrivacyTitle => 'Kameran sende kalır.';

  @override
  String get settingsPrivacyBody =>
      'Video ve isteğe bağlı mikrofon sesi bu telefonda kalır. Kaydedilmeyen klipler silinir. Yükleme yok.';

  @override
  String get settingsCameraLab => 'Kamera ve takip testi';

  @override
  String get settingsAbout => 'Hakkında & lisanslar';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'Hakkında ve lisanslar, sürüm $version';
  }

  @override
  String get settingsReset => 'Yerel ilerlemeyi sıfırla';

  @override
  String settingsResetDone(String bird) {
    return 'Tertemiz bir başlangıç. $bird seni bekliyor.';
  }

  @override
  String get settingsResetTitle => 'Baştan başlamak ister misin?';

  @override
  String get settingsResetBody =>
      'Bu işlem kayıtlı videolarını, tekrarlarını, puanlarını, uçuşlarını, yaptığın seviyeleri ve ayarlarını bu telefondan siler. Geri alınamaz.';

  @override
  String get settingsResetBodyCloud =>
      'Bu işlem kayıtlı videolarını, tekrarlarını, puanlarını, uçuşlarını, yaptığın seviyeleri ve ayarlarını bu telefondan siler; Play Oyunlar bulut kaydını da siler. Geri alınamaz.';

  @override
  String get settingsResetConfirm => 'Her şeyi sıfırla';

  @override
  String get settingsResetKeep => 'İlerlememi koru';

  @override
  String get playGamesName => 'Play Oyunlar';

  @override
  String get playGamesConnected => 'Bağlı';

  @override
  String get playGamesNotConnected => 'Bağlı değil';

  @override
  String get playGamesConnecting => 'Bağlanıyor…';

  @override
  String get playGamesConnectFailed => 'Bağlanılamadı';

  @override
  String get playGamesIdle => 'Bulut kaydı ve başarılar';

  @override
  String get playGamesSaving => 'Buluta kaydediliyor…';

  @override
  String get playGamesOfflineUnsaved => 'Çevrimdışı · henüz kayıt yok';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'Çevrimdışı · $ago kaydedildi';
  }

  @override
  String get playGamesUpdateNeeded => 'Eşitlemek için oyunu güncelle';

  @override
  String get playGamesUnreadable => 'Bulut kaydı okunamıyor';

  @override
  String get playGamesOn => 'Bulut kaydı açık';

  @override
  String get playGamesResetElsewhere => 'Başka telefonda sıfırlandı';

  @override
  String playGamesRestored(String ago) {
    return 'Buluttan yüklendi · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'Buluta kaydedildi · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Play Oyunlar başarıları';

  @override
  String get playGamesConnectSemantics => 'Play Oyunlar\'a bağlan';

  @override
  String get playGamesAchievements => 'Başarılar';

  @override
  String get playGamesConnect => 'Bağlan';

  @override
  String get timeAgoJustNow => 'az önce';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes dk önce',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours sa önce',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün önce',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '+1 CAN!';

  @override
  String calloutStarTrio(int points) {
    return 'ÜÇLÜ YILDIZ +$points!';
  }

  @override
  String get calloutNiceShot => 'İYİ ATIŞ!';

  @override
  String calloutNiceShotPoints(int points) {
    return 'İYİ ATIŞ +$points!';
  }

  @override
  String get calloutSmash => 'ÇAT!';

  @override
  String calloutSmashPoints(int points) {
    return 'ÇAT +$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return 'ÇAT ×$count!';
  }

  @override
  String get calloutBossDown => 'BOSS DÜŞTÜ!';

  @override
  String calloutBossDownPoints(int points) {
    return 'BOSS DÜŞTÜ +$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier× YILDIZ GÜCÜ!';
  }

  @override
  String get calloutPerfect => 'KUSURSUZ!';

  @override
  String calloutPerfectChain(int count) {
    return 'KUSURSUZ ×$count';
  }

  @override
  String get calloutShieldReady => 'KALKAN HAZIR';

  @override
  String get calloutShieldSave => 'KALKAN KORUDU!';

  @override
  String get calloutKeepFlying => 'UÇMAYA DEVAM!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count KAPI!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'SON $seconds SANİYE',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => 'MIKNATIS!';

  @override
  String get calloutSprintRing => 'ALTIN HALKA!';

  @override
  String calloutRushChain(int count) {
    return 'AKIN ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'GÖKTAŞI +$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return 'YARASA +$points!';
  }

  @override
  String get calloutScorched => 'KAVRULDUN!';

  @override
  String get region_jungle => 'Yağmur Ormanı';

  @override
  String get region_antarctica => 'Antarktika';

  @override
  String get region_aztec => 'Aztek';

  @override
  String get region_paris => 'Paris';

  @override
  String get region_egypt => 'Mısır';

  @override
  String get region_cyberpunk => 'Siberpunk Şehri';

  @override
  String get region_china => 'Çin';

  @override
  String get region_brazil => 'Brezilya';

  @override
  String get region_newYork => 'New York';

  @override
  String get region_arabia => 'Antik Arabistan';

  @override
  String get region_rome => 'Antik Roma';

  @override
  String get region_mexico => 'Meksika';

  @override
  String get region_sea => 'Açık Deniz';

  @override
  String get boss_baronBat_name => 'Baron Yarasa';

  @override
  String get boss_spitterBeetle_name => 'Tükürükçü Kral';

  @override
  String get boss_duskMoth_name => 'Alacakaranlık İmparatoriçesi';

  @override
  String get boss_pirate_name => 'Korsan Kaptan';

  @override
  String get boss_dragon_name => 'Kor Ejderha';

  @override
  String get boss_kingCoo_name => 'Kral Gugu';

  @override
  String get boss_searchlightGargoyle_name => 'Işıldaklı Gargoyl';

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
  String get playMode_pushUp => 'Şınav Uçuşu';

  @override
  String get playMode_jump => 'Zıpla ve Uç';

  @override
  String get playMode_touch => 'Dokun ve Uç';

  @override
  String get playMode_squat => 'Çömel ve Uç';

  @override
  String get chapter_1_route => 'Ağaç Tepeleri Rotası';

  @override
  String get chapter_1_postmark => 'AĞAÇ TEPELERİ ROTASI';

  @override
  String get chapter_1_postcard =>
      'Mektuplar yine ağaç tepelerine iniyor! Tukanlar teşekkür ediyor (hem de avaz avaz). Baron Yarasa\'nın tacı artık şöminemizin üstünde.';

  @override
  String get chapter_1_postscript =>
      'Antik yoldan bir şeyler kaynıyormuş gibi kokular geliyor.';

  @override
  String get chapter_2_route => 'Antik Yol';

  @override
  String get chapter_2_postmark => 'ANTİK YOL';

  @override
  String get chapter_2_postcard =>
      'Kervanlar yine yolda ve kaynayan tek şey nane çayı. Kral\'ın şişe tacını vazo yaptık.';

  @override
  String get chapter_2_postscript =>
      'Dün gece şehrin lambaları söndü. Yanında ışık getir.';

  @override
  String get chapter_3_route => 'Lamba Işığı Hattı';

  @override
  String get chapter_3_postmark => 'LAMBA IŞIĞI HATTI';

  @override
  String get chapter_3_postcard =>
      'Lambalar yandı, gece postası cin gibi uyanık! Paris bir kruvasan, New York bir pretzel yolluyor.';

  @override
  String get chapter_3_postscript => 'Liman çanları sustu.';

  @override
  String get chapter_4_route => 'Gelgit Rotası';

  @override
  String get chapter_4_postmark => 'GELGİT ROTASI';

  @override
  String get chapter_4_postcard =>
      'Liman çanları yine toplar için değil, mektuplar için çalıyor. Papağan bizde kaldı. Selamı var.';

  @override
  String get chapter_4_postscript =>
      'Haritanın ucunda gökyüzü alev almış diyorlar.';

  @override
  String get chapter_5_route => 'Haritanın Ucu';

  @override
  String get chapter_5_postmark => 'HARİTANIN UCU';

  @override
  String get chapter_5_postcard =>
      'Gökyüzü kutuptan kutba pırıl pırıl, bütün rotalar işliyor. Bütün Gök Kulübü seninle gurur duyuyor.';

  @override
  String get chapter_5_postscript =>
      'Sonsuz gök seni bekliyor, ne zaman hazır olursan.';

  @override
  String get level_1_1_name => 'İlk Teslimat';

  @override
  String get level_1_1_cargo => 'Tukan ikizlere doğum günü kartı';

  @override
  String get level_1_1_sender => 'Tukan ikizler';

  @override
  String get level_1_1_hint =>
      'Kanat çırpmak için dokun. Yıldızların içinden uç.';

  @override
  String get level_1_2_name => 'Yıldız Serisi';

  @override
  String get level_1_2_cargo => 'Tembel hayvana yıldız haritaları';

  @override
  String get level_1_2_sender => 'Yıldız gözlemcisi tembel hayvan';

  @override
  String get level_1_2_hint =>
      'Yıldızları art arda topla: 3×! Üç kusursuz geçiş mıknatıs kazandırır.';

  @override
  String get level_1_3_name => 'Yarasa Devriyesi';

  @override
  String get level_1_3_cargo => 'Ateş böceği kreşine gece lambaları';

  @override
  String get level_1_3_sender => 'Ateş böceği kreşi';

  @override
  String get level_1_3_hint =>
      'Ateş et. Yarasaları bayıltmak için Ateş tuşuna dokun.';

  @override
  String get level_1_4_name => 'Karnaval Gökleri';

  @override
  String get level_1_4_cargo => 'Karnaval geçidine tüylü şallar';

  @override
  String get level_1_4_sender => 'Samba papağanları';

  @override
  String get level_1_4_hint =>
      'Bora! ! işaretini izle ve futbol toplarından kaç.';

  @override
  String get level_1_5_name => 'Ekspres Posta';

  @override
  String get level_1_5_cargo => 'Davul şefine acil davetiye';

  @override
  String get level_1_5_sender => 'Davul şefi';

  @override
  String get level_1_5_hint =>
      'Sprint yarasaları devirir ve seni ileri fırlatır.';

  @override
  String get level_1_6_name => 'Tapınak Basamakları';

  @override
  String get level_1_6_cargo => 'Tapınak aşçılarına kakao çekirdekleri';

  @override
  String get level_1_6_sender => 'Tapınak aşçıları';

  @override
  String get level_1_7_name => 'Gün Doğumu Tüneği';

  @override
  String get level_1_7_cargo => 'Şafak bekçisine güneş saati';

  @override
  String get level_1_7_sender => 'Şafak bekçisi';

  @override
  String get level_1_8_name => 'Baron Yarasa';

  @override
  String get level_1_8_cargo => 'Baron Yarasa\'ya son ihtar';

  @override
  String get level_1_8_sender => 'Baron Yarasa';

  @override
  String get level_2_1_name => 'Böcek Yolu';

  @override
  String get level_2_1_cargo => 'Araba yarışçılarına defne tacı';

  @override
  String get level_2_1_sender => 'Araba yarışçıları';

  @override
  String get level_2_1_hint => 'Böcekler tohum tükürür. Tohumları vurup düşür.';

  @override
  String get level_2_2_name => 'Mühürlü Kapılar';

  @override
  String get level_2_2_cargo => 'Heykeltıraşa yeni bir keski';

  @override
  String get level_2_2_sender => 'Heykeltıraş';

  @override
  String get level_2_2_hint =>
      'Ateş tuşuna basılı tut: büyük taş, taşı bile kırar.';

  @override
  String get level_2_3_name => 'Yangından Kaçış';

  @override
  String get level_2_3_cargo => 'İtfaiye ekibine su kovaları';

  @override
  String get level_2_3_sender => 'İtfaiye ekibi';

  @override
  String get level_2_3_hint => 'Yangından kaçmak için altın halkalardan geç!';

  @override
  String get level_2_4_name => 'Nil Zikzakları';

  @override
  String get level_2_4_cargo => 'Sfenks\'e yeni bilmeceler kitabı';

  @override
  String get level_2_4_sender => 'Sfenks';

  @override
  String get level_2_5_name => 'Gök Çöküşü';

  @override
  String get level_2_5_cargo => 'Piramit gökbilimcisine teleskop';

  @override
  String get level_2_5_sender => 'Piramit gökbilimcisi';

  @override
  String get level_2_5_hint => 'Halka sprintleri göktaşlarını parçalar.';

  @override
  String get level_2_6_name => 'Göndericiye İade';

  @override
  String get level_2_6_cargo => 'Piramit bakıcısına tüy süpürge';

  @override
  String get level_2_6_sender => 'Piramit bakıcısı';

  @override
  String get level_2_6_hint =>
      'Mektuplarını vurup geri yolla. Göndericiye iade!';

  @override
  String get level_2_7_name => 'Fener Çarşısı';

  @override
  String get level_2_7_cargo => 'Fenercilere lamba yağı';

  @override
  String get level_2_7_sender => 'Fenerciler';

  @override
  String get level_2_8_name => 'Uzun Kervan';

  @override
  String get level_2_8_cargo => 'Uzun kervana su mataraları';

  @override
  String get level_2_8_sender => 'Kervanbaşı';

  @override
  String get level_2_9_name => 'Tükürükçü Kral';

  @override
  String get level_2_9_cargo => 'Tükürükçü Kral\'a kaynatma yasağı';

  @override
  String get level_2_9_sender => 'Tükürükçü Kral';

  @override
  String get level_3_1_name => 'Güve Işığı';

  @override
  String get level_3_1_cargo => 'Tiyatro tentesine ampuller';

  @override
  String get level_3_1_sender => 'Sahne amiri';

  @override
  String get level_3_1_hint => 'Güveler üçlü yelpaze atar. Aralarından süzül.';

  @override
  String get level_3_2_name => 'Yağmurda Tekerlekler';

  @override
  String get level_3_2_cargo => 'Gazete bayii güvercinlerine şemsiyeler';

  @override
  String get level_3_2_sender => 'Gazete bayii güvercinleri';

  @override
  String get level_3_2_hint =>
      'Ara sokak güvercinleri yıldız kapmaya dalar. Önce onları vur!';

  @override
  String get level_3_3_name => 'Buhar Sokağı';

  @override
  String get level_3_3_cargo => 'Gece taksicilerine sıcak pretzel';

  @override
  String get level_3_3_sender => 'Gece taksicileri';

  @override
  String get level_3_3_hint =>
      'Delikler tıslar, sonra fışkırır. Sıcakların üstünden atla, yumuşaklara bin.';

  @override
  String get level_3_4_name => 'Fırtına Uyarısı';

  @override
  String get level_3_4_cargo => 'En yüksek kuleye rüzgâr gülü';

  @override
  String get level_3_4_sender => 'Kule bekçisi';

  @override
  String get level_3_4_hint =>
      'Işıktan uzak dur. Lamba açılınca vur! Burada Sprint yok.';

  @override
  String get level_3_5_name => 'Kristal Çatılar';

  @override
  String get level_3_5_cargo => 'Çatı ressamlarına kruvasanlar';

  @override
  String get level_3_5_sender => 'Çatı ressamları';

  @override
  String get level_3_6_name => 'Boradan Sonra';

  @override
  String get level_3_6_cargo => 'Akordeoncuya nota kâğıtları';

  @override
  String get level_3_6_sender => 'Akordeoncu';

  @override
  String get level_3_6_hint => 'Bora! ! işaretini izle ve açık taraftan geç.';

  @override
  String get level_3_7_name => 'Gece Yarısı Postası';

  @override
  String get level_3_7_cargo => 'Fırıncıya gece yarısı aşk mektubu';

  @override
  String get level_3_7_sender => 'Fırıncı';

  @override
  String get level_3_7_hint => 'Sürülerin arasından sprint atarak geç.';

  @override
  String get level_3_8_name => 'Alacakaranlık İmparatoriçesi';

  @override
  String get level_3_8_cargo => 'İmparatoriçeye uyandırma servisi';

  @override
  String get level_3_8_sender => 'Alacakaranlık İmparatoriçesi';

  @override
  String get level_4_1_name => 'Liman Işıkları';

  @override
  String get level_4_1_cargo => 'Fener bekçisine yeni mercek';

  @override
  String get level_4_1_sender => 'Fener bekçisi';

  @override
  String get level_4_2_name => 'Yanardağ Geçidi';

  @override
  String get level_4_2_cargo => 'Yanardağ fırıncısına fırın eldiveni';

  @override
  String get level_4_2_sender => 'Yanardağ fırıncısı';

  @override
  String get level_4_2_hint => 'Lav fışkırmalarının üstünden atla.';

  @override
  String get level_4_3_name => 'Kıyı Boyunca';

  @override
  String get level_4_3_cargo => 'Plaj festivaline uçurtma ipi';

  @override
  String get level_4_3_sender => 'Uçurtmacılar';

  @override
  String get level_4_4_name => 'Çekilen Sular';

  @override
  String get level_4_4_cargo => 'Ada münzevisine bir cevap';

  @override
  String get level_4_4_sender => 'Ada münzevisi';

  @override
  String get level_4_4_hint => 'Suya değme.';

  @override
  String get level_4_5_name => 'Kabaran Sular';

  @override
  String get level_4_5_cargo => 'Feribot mürettebatına gelgit cetveli';

  @override
  String get level_4_5_sender => 'Feribot mürettebatı';

  @override
  String get level_4_5_hint => 'Çan çalınca yükseğe uç.';

  @override
  String get level_4_6_name => 'Borda Koyu';

  @override
  String get level_4_6_cargo => 'Martı kolonisine balıklı bisküvi';

  @override
  String get level_4_6_sender => 'Martı kolonisi';

  @override
  String get level_4_7_name => 'Fırtınalı Geçiş';

  @override
  String get level_4_7_cargo => 'Fırtına nöbetçilerine kuru çorap';

  @override
  String get level_4_7_sender => 'Fırtına nöbetçileri';

  @override
  String get level_4_8_name => 'Korsan Kaptan';

  @override
  String get level_4_8_cargo => 'Kaptan\'a posta iade emri';

  @override
  String get level_4_8_sender => 'Korsan Kaptan';

  @override
  String get level_5_1_name => 'Aurora Postası';

  @override
  String get level_5_1_cargo => 'Penguen korosuna yün bereler';

  @override
  String get level_5_1_sender => 'Penguen korosu';

  @override
  String get level_5_1_hint => 'Artık her akın gelebilir. Uyarıyı oku!';

  @override
  String get level_5_2_name => 'Kutup Gecesi';

  @override
  String get level_5_2_cargo => 'Kutup istasyonuna sıcak kakao';

  @override
  String get level_5_2_sender => 'Kutup istasyonu';

  @override
  String get level_5_3_name => 'Neon Ekspres';

  @override
  String get level_5_3_cargo => 'Erişteci tabelasına yedek sigorta';

  @override
  String get level_5_3_sender => 'Erişte ustası';

  @override
  String get level_5_4_name => 'Veri Fırtınası';

  @override
  String get level_5_4_cargo => 'Meraklı bir robota kâğıt mektup';

  @override
  String get level_5_4_sender => 'Birim 7';

  @override
  String get level_5_5_name => 'Silüet Sprinti';

  @override
  String get level_5_5_cargo => 'Çatı koşucularına yarış biletleri';

  @override
  String get level_5_5_sender => 'Çatı koşucuları';

  @override
  String get level_5_6_name => 'Fener Festivali';

  @override
  String get level_5_6_cargo => 'Festivale kâğıt fenerler';

  @override
  String get level_5_6_sender => 'Fener ustaları';

  @override
  String get level_5_7_name => 'Son Etap';

  @override
  String get level_5_7_cargo => 'Manastıra dağ çayı';

  @override
  String get level_5_7_sender => 'Dağ keşişleri';

  @override
  String get level_5_8_name => 'Kor Ejderha';

  @override
  String get level_5_8_cargo => 'Ejderhaya gönderilen ilk mektup';

  @override
  String get level_5_8_sender => 'Kor Ejderha';

  @override
  String get storyPostmasterName => 'Postacıbaşı Bill';

  @override
  String get storySkip => 'Geç';

  @override
  String get storyNextLineSemantics => 'Sonraki satır';

  @override
  String get storyFinishSemantics => 'Bitir';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => 'Her mektup yerini bulur.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => 'Uç!';

  @override
  String levelIntroRunUp(int seconds) {
    return 'Önce $seconds sn ısınma uçuşu';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'Bitişe yaklaşık $seconds sn';
  }

  @override
  String get campaignGuardian => 'MUHAFIZ';

  @override
  String get levelIntroBossFight => 'BOSS SAVAŞI';

  @override
  String get levelIntroNew => 'YENİ';

  @override
  String get levelIntroTip => 'İPUCU';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': '$boss\'yı yen',
      'spitterBeetle': '$boss\'ı yen',
      'duskMoth': '$boss\'ni yen',
      'pirate': '$boss\'ı yen',
      'dragon': '$boss\'yı yen',
      'kingCoo': '$boss\'yu yen',
      'searchlightGargoyle': '$boss\'u yen',
      'neferhoo': '$boss\'yu yen',
      'other': '$boss karşısında kazan',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroGoalFinish => 'Bitiş çizgisine ulaş';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız topla',
      one: '1 yıldız topla',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Bir yıldız: $goal.',
      'two': 'İki yıldız: $goal.',
      'other': 'Üç yıldız: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Bir yıldız: $goal. Kazanıldı.',
      'two': 'İki yıldız: $goal. Kazanıldı.',
      'other': 'Üç yıldız: $goal. Kazanıldı.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En iyi: $count yıldız',
      one: 'En iyi: 1 yıldız',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'Henüz teslim edilmedi';

  @override
  String get levelIntroFirstFlight => 'İlk uçuş';

  @override
  String get levelIntroControlFlap => 'Kanat çırp';

  @override
  String get levelIntroControlShoot => 'Ateş';

  @override
  String get levelIntroControlSprint => 'Sprint';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Kontroller: Kanat çırp.',
      'shoot': 'Kontroller: Kanat çırp, Ateş.',
      'sprint': 'Kontroller: Kanat çırp, Sprint.',
      'other': 'Kontroller: Kanat çırp, Ateş, Sprint.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => 'ÖZEL TESLİMAT';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return 'Özel teslimat: $cargo.';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return 'Seviye $level, $name. $region.';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return 'Seviye $level, $name. $region. Muhafız seviyesi: $boss.';
  }

  @override
  String get levelIntroStory => 'Hikâye';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonContinue => 'Devam et';

  @override
  String get commonHome => 'Ana menü';

  @override
  String get commonBackHome => 'Ana menüye dön';

  @override
  String get campaignComingSoon => 'Çok yakında';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — çok yakında';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Önce $boss\'yı yen',
      'spitterBeetle': 'Önce $boss\'ı yen',
      'duskMoth': 'Önce $boss\'ni yen',
      'pirate': 'Önce $boss\'ı yen',
      'dragon': 'Önce $boss\'yı yen',
      'kingCoo': 'Önce $boss\'yu yen',
      'searchlightGargoyle': 'Önce $boss\'u yen',
      'neferhoo': 'Önce $boss\'yu yen',
      'other': 'Önce $boss karşısında kazan',
    });
    return '$_temp0';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'Önce $level seviyesini bitir';
  }

  @override
  String get campaignMapUnavailable => 'Harita biraz zaman istiyor.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return 'Kapat: $name';
  }

  @override
  String get campaignMapPreviousStop => 'Önceki durak';

  @override
  String get campaignMapNextStop => 'Sonraki durak';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. Bölüm $chapter, $route. Çok yakında.',
      'locked': '$region. Bölüm $chapter, $route. Kilitli.',
      'other': '$region. Bölüm $chapter, $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return 'BÖLÜM $chapter · $route';
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
      'guardian': 'Seviye $level, $name, muhafız $boss',
      'other': 'Seviye $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. Kilitli.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. Kilitli. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '3 üzerinden $stars yıldız',
    );
    return '$node. Sıradaki. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '3 üzerinden $stars yıldız',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'Gargoyl',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return 'Bölüm $chapter kartpostalı';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Kampanya yıldızı: $total üzerinden $stars',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'Sevgili kurye,';

  @override
  String get campaignPostcardPs => 'Not:';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'Kartpostal, gönderen: $route. Sevgili kurye, $body Not: $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'Selamlar';

  @override
  String get campaignPostcardHeader => 'GÖK KULÜBÜ KARTPOSTALI';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'Kuryemize';

  @override
  String get campaignPostcardAddressStreet => 'Gök Kulübü';

  @override
  String get campaignPostcardAddressCity => 'Bulutların üstü';

  @override
  String get campaignPostmarkDelivered => 'TESLİM';

  @override
  String get campaignPostmarkClub => 'GÖK KULÜBÜ POSTA';

  @override
  String get campaignStampSkyClub => 'GÖK KULÜBÜ';

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
    return 'Teşekkür notu, $sender imzalı: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'Biraz hazırlık. Bolca gökyüzü.';

  @override
  String get flightSetupTitleSquat => 'Ayaklar yerde. Kanatlar açık.';

  @override
  String get flightSetupTitleJump => 'Küçük zıplayışlar. Koca kanatlar.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'SEVİYE · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · PUANLI';
  }

  @override
  String get flightSetupRoomPushUp => 'Hareket etmek için biraz yer aç.';

  @override
  String get flightSetupRoomBody => 'Bütün vücudunu göster.';

  @override
  String get flightSetupTipsPushUp =>
      'Telefon alçakta. Bir kolunu ve kalçanı göster.\nKarşıdan mı? İki omzun da görünsün.';

  @override
  String get flightSetupTipsSquat =>
      'Alçalmak için çömel. Yükselmek için kalk.\nİki ayağın da yerde kalsın.';

  @override
  String get flightSetupTipsJump =>
      'Zıpla: itiş + 3 sn süzülme.\nTekrar zıplamadan önce yere in.';

  @override
  String get flightSetupHowToFly => 'NASIL UÇULUR';

  @override
  String get flightSetupStep1PushUp => 'Kolunu ve kalçanı göster';

  @override
  String get flightSetupStep1Squat => 'Çömelmek için yer aç';

  @override
  String get flightSetupStep1Jump => 'Zıplamak için yer aç';

  @override
  String get flightSetupStep1DetailPushUp =>
      'Telefona karşıdan mı bakıyorsun? İki omzunu, bir kolunu ve kalçanı göster.';

  @override
  String get flightSetupStep1DetailBody =>
      'Telefon yatay. Vücudunu ve iki ayağını göster.';

  @override
  String get flightSetupStep2PushUp => 'Hareket aralığını bul';

  @override
  String get flightSetupStep2Squat => 'Rahat çömelişini bul';

  @override
  String get flightSetupStep2Jump => 'Dik ve hareketsiz dur';

  @override
  String get flightSetupStep2DetailPushUp =>
      'Rahat bir üst nokta bul, sonra iki kez in ve kalk.';

  @override
  String get flightSetupStep2DetailSquat =>
      'Hareketsiz dur, çömel ve biraz bekle, sonra yeniden kalk.';

  @override
  String get flightSetupStep2DetailJump =>
      'Kısa bir süre hareketsiz dur. Sonra büyük bir itiş için zıpla.';

  @override
  String get flightSetupStep3Stars => 'Yıldız topla';

  @override
  String get flightSetupStep3DetailJump =>
      'Her yıldız 0,75 sn süzülme ekler, en fazla 5 sn. Yıldız üçlüleri +5 puan getirir.';

  @override
  String get flightSetupLivesEndless =>
      'Üç kalp + bir kalkan. İstediğin zaman durdurabilirsin.';

  @override
  String get flightSetupLivesClassic =>
      'Puanlı uçuşta bir çarpışma ya da pozisyonunu kaybetmek uçuşu bitirir. İstediğin zaman durdurabilirsin.';

  @override
  String get flightSetupCameraButton => 'Kamerayı hazırla';

  @override
  String get flightMicTitle => 'Mikrofon kaydı';

  @override
  String get flightMicOn => 'Açık';

  @override
  String get flightMicOptional => 'Opsiyonel';

  @override
  String get flightMicDetail =>
      'Tekrarlara sesini ve ortam sesini ekle. Mikrofon yalnızca uçuş sırasında kullanılır. Bu telefonda saklanır.';

  @override
  String get flightMicSemantics => 'Tekrarlar için mikrofon kaydı';

  @override
  String get flightMicSettings => 'Mikrofon ayarları';

  @override
  String get flightCalibrationTitleReady => 'Kanatlarını buldun!';

  @override
  String get flightCalibrationTitleWaking => 'Kameran uyanıyor…';

  @override
  String get flightCalibrationTitleError => 'Kameranı yeniden bağlayalım.';

  @override
  String get flightCalibrationTitleRange => 'Hareket aralığını bul.';

  @override
  String get flightCalibrationTitleStill => 'Dik ve hareketsiz dur.';

  @override
  String get flightCalibrationStepTry => 'Kuşunu oynatmayı dene.';

  @override
  String get flightCalibrationStepTop => 'Rahat bir üst nokta bul.';

  @override
  String get flightCalibrationStepLower => 'Yavaşça aşağı in.';

  @override
  String get flightCalibrationStepPushBack => 'Tekrar yukarı kalk.';

  @override
  String get flightCalibrationStepStill => 'Dik ve hareketsiz dur.';

  @override
  String get flightCalibrationStepSquat => 'Rahatça çömel.';

  @override
  String get flightCalibrationStepStandUp => 'Yeniden ayağa kalk.';

  @override
  String get flightCalibrationStepDone => 'Kanatlarını buldun!';

  @override
  String get flightCalibrationReadyPushUp =>
      'Yükselmek için kalk. Süzülmek için alçal.';

  @override
  String get flightCalibrationReadySquat =>
      'Alçalmak için çömel. Yükselmek için kalk.';

  @override
  String get flightCalibrationReadyJump =>
      'Zıpla, sonra kuşun süzülürken dinlen.';

  @override
  String get flightCalibrationKeepPushUp =>
      'Omuzların, bir kolun ve kalçan görünsün. Rahatça hareket et.';

  @override
  String get flightCalibrationKeepBody =>
      'Omuzların, kalçan ve iki ayağın görünsün.';

  @override
  String get flightCalibrationLearning =>
      'Hareket ettikçe aralığın öğreniliyor.';

  @override
  String get flightCalibrationAfter =>
      'Kuşun kalibrasyondan sonra hareket eder.';

  @override
  String get flightCalibrationJump => 'Hop!';

  @override
  String get flightCalibrationTagCheck => 'KONTROL TESTİ';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '$count / 2 ŞINAV';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '%$percent KALİBRE';
  }

  @override
  String get flightCalibrationTakeoff => 'Kalkışa hazır';

  @override
  String get flightCalibrationStarting => 'Başlıyor…';

  @override
  String get flightCalibrationRestart => 'Yeniden kalibre et';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate güncelleme/sn · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate güncelleme/sn · $p95 ms p95 (yalnızca işleme)';
  }

  @override
  String get flightCalibrationStatusReady => 'HAZIR';

  @override
  String get flightCalibrationStatusStarting => 'BAŞLIYOR';

  @override
  String get flightCalibrationStatusCameraOff => 'KAMERA KAPALI';

  @override
  String get flightCalibrationStatusCalibrating => 'AYARLANIYOR';

  @override
  String get flightSwitchCameraSemantics => 'Kamerayı değiştir';

  @override
  String get flightCalibrationStepIntoView => 'Görüş alanına gir';

  @override
  String get flightCameraTroubleTitle => 'Baştan almak genelde işe yarar.';

  @override
  String get flightCameraTroubleAllow =>
      'Ayarlar\'dan kamera erişimine izin ver.';

  @override
  String get flightCameraTroubleClose =>
      'Diğer kamera uygulamalarını kapat, sonra tekrar dene.';

  @override
  String get flightCameraPermissionSemantics => 'Kamera izni ayarları';

  @override
  String get flightNoteRememberFailed =>
      'Bu uçuş için değişti. Tercihin hatırlanamadı.';

  @override
  String get flightNoteMicUnavailable =>
      'Mikrofon kullanılamıyor. Video ve oyun yine çalışır.';

  @override
  String get flightNoteMicBlocked =>
      'Mikrofon engelli. Ayarlar\'dan izin verebilirsin; video yine çalışır.';

  @override
  String get flightNoteMicOff =>
      'Mikrofon kapalı. Yine de oynayıp video kaydedebilirsin.';

  @override
  String get flightNoteVideoUnavailable =>
      'Kamera videosu kullanılamıyor. Oyun yine de kaydedilebilir.';

  @override
  String get flightNoteMicAudioLost =>
      'Mikrofon sesi alınamadı. Videon ve oyunun yine de kaydedilebilir.';

  @override
  String get flightNoteVideoInterrupted =>
      'Kamera videosu yarıda kesildi. Kaydedilen görüntü ve oyun yine de saklanabilir.';

  @override
  String get flightNoteSessionSaveFailed =>
      'Oturum kaydedilemedi. Tekrar denemek için Oturumu kaydet\'e dokun.';

  @override
  String get flightNoteWakingCamera => 'Kameran uyanıyor…';

  @override
  String get flightNoteCameraOff =>
      'Kamera erişimi kapalı. Android ayarlarından izin ver, sonra geri gelip tekrar dene.';

  @override
  String get flightNoteCameraFailed =>
      'Kamera başlatılamadı. Tekrar dene ya da kamerayı değiştir.';

  @override
  String get flightNotePreparing => 'Oturumun hazırlanıyor…';

  @override
  String get flightNoteSaveFailed =>
      'Uçuşun kaydedilemedi. Tekrar denemek için dokun.';

  @override
  String get flightNoteWelcomeBack =>
      'Tekrar hoş geldin. Yerini bir daha kontrol edelim.';

  @override
  String get flightNoteCameraInterrupted =>
      'Kamera kesildi. Kamera iznini kontrol edip tekrar dene.';

  @override
  String get flightNoteTrackingInterrupted => 'Takip kesildi';

  @override
  String get flightFindPosition => 'Pozisyonunu al';

  @override
  String get flightTapSemantics => 'Dokun, kanat çırp';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'Dokun, kanat çırp. $group, boss\'tan önce geliyor';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'Dokun, kanat çırp. $boss: $maxHp üzerinden $hp sağlık';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'Dokun, kanat çırp. $boss: $maxHp üzerinden $hp sağlık. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'Sonuçlara geç';

  @override
  String get hudPauseSemantics => 'Uçuşu durdur';

  @override
  String get flightHintTestSteerKeys =>
      'Deneme uçuşu: yön için Yukarı ve Aşağı.';

  @override
  String get flightHintTestSteerDrag =>
      'Deneme uçuşu: yönlendirmek için yukarı aşağı sürükle.';

  @override
  String get flightHintTestJumpKeys =>
      'Deneme uçuşu: zıplamak için Space\'e bas.';

  @override
  String get flightHintTestJumpTap => 'Deneme uçuşu: zıplamak için dokun.';

  @override
  String get flightHintKeysStars =>
      'Space ile kanat çırp. Yıldızların içinden uç.';

  @override
  String get flightHintKeysShoot =>
      'Space ile kanat çırp. Atışı doldurmak için D\'yi basılı tut.';

  @override
  String get flightHintKeysCombat =>
      'Space ile kanat çırp. Atışı doldurmak için D\'yi basılı tut. Sprint için A!';

  @override
  String get flightHintKeysPause => 'Space ile kanat çırp. Esc durdurur.';

  @override
  String get flightHintTapStars =>
      'Gökyüzüne dokun, kanat çırp. Yıldızların içinden uç.';

  @override
  String get flightHintTapShoot =>
      'Gökyüzüne dokun, kanat çırp. Doldurmak için Ateş\'i basılı tut.';

  @override
  String get flightHintTapCombat =>
      'Gökyüzüne dokun, kanat çırp. Ateş\'i basılı tut, doldur. Sprint\'le dağıt!';

  @override
  String get flightHintTapRelease =>
      'Dokun, kanat çırp. Aralarda parmağını kaldır.';

  @override
  String get flightHintTrail => 'Yıldızları izle. Kalkanın hazır.';

  @override
  String get flightHintSky => 'Gökyüzü senin.';

  @override
  String hudClockSemantics(String time) {
    return '$time kaldı';
  }

  @override
  String flightSeconds(String seconds) {
    return '${seconds}sn';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Yıldız mıknatısı: $seconds saniye kaldı',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Mıknatıs doluyor: $gates üzerinden $charge kusursuz geçiş',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'Seni arıyorum…';

  @override
  String get hudShoot => 'Ateş';

  @override
  String get hudSprint => 'Sprint';

  @override
  String get flightTestNothingSaved => 'kayıt yapılmaz';

  @override
  String get flightCountdownReady => 'Hazır… dikkat…';

  @override
  String get flightPauseTitle => 'Biraz soluklan.';

  @override
  String get flightPauseKeepFlying => 'Uçmaya devam';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. Kuşun tünekte, seni bekliyor.';
  }

  @override
  String flightPausedTest(String name) {
    return 'Deneme uçuşu: $name. Hiçbir şey kaydedilmez.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. Kuşun tünekte, seni bekliyor.';
  }

  @override
  String get flightPausedTouch =>
      'Kuşun tünekte, seni bekliyor. Dönünce geri sayımla başlarız.';

  @override
  String get flightPausedCamera =>
      'Biraz silkelen, sonra yerine geç. Geri sayımla başlarız.';

  @override
  String get flightPauseEdit => 'Düzenle';

  @override
  String get flightPauseBuilder => 'Atölye';

  @override
  String get flightPauseFinish => 'Uçuşu bitir';

  @override
  String get hudShieldRecovering => 'Toparlanıyor';

  @override
  String get hudShieldReady => 'Kalkan hazır';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Kalkan doluyor: $stars üzerinden $charge yıldız',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kalp kaldı',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'Sprint sürüyor';

  @override
  String get hudSprintReady => 'Hazır';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Doluyor, $seconds saniye',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint =>
      'Yarasaları ve taş levhaları parçalamak için ileri atıl';

  @override
  String get hudShotReloading => 'Dolduruluyor…';

  @override
  String hudShotFullCharge(int ms) {
    return 'Tam dolu, $ms ms kaldı';
  }

  @override
  String hudShotCharging(int percent) {
    return 'Doluyor %$percent';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'Cephane %$percent';
  }

  @override
  String get hudShotHint => 'Daha büyük bir taş için basılı tut';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldıza ulaşıldı',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$at yıldızda $count yıldız',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars yıldız toplandı',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'MAKS';

  @override
  String hudRouteSemantics(int percent) {
    return 'Rota: %$percent uçuldu';
  }

  @override
  String hudGlideCompact(String time) {
    return 'Süzülme · $time';
  }

  @override
  String get hudJumpToGlide => 'Zıpla, süzül';

  @override
  String get hudJump => 'Zıpla';

  @override
  String hudGlideSemantics(String time) {
    return 'Süzülme, $time kaldı';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'Süzülme bitiyor, $time kaldı';
  }

  @override
  String get hudJumpChargeSemantics => '3 saniyelik süzülme için zıpla';

  @override
  String get hudRecordNewBest => 'Yeni en iyi!';

  @override
  String get hudRecordMatched => 'Eşitledin!';

  @override
  String hudRecordBest(int best) {
    return 'En iyi $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return 'En iyinin +$points üstünde';
  }

  @override
  String get hudRecordOneMore => 'Rekora bir puan kaldı';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rekora $count puan kaldı',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'Puan $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'Puan $score, $multiplier kat çarpan';
  }

  @override
  String get commonBusySemantics => 'Meşgul';

  @override
  String get flightResultBumpClouds => 'Bulutlarda ufak bir tökezleme.';

  @override
  String get flightResultPersonalBest => 'KİŞİSEL EN İYİ';

  @override
  String get flightResultNewPersonalBest => 'YENİ KİŞİSEL EN İYİ!';

  @override
  String get flightResultStarsCollected => 'TOPLANAN YILDIZ';

  @override
  String get flightResultDailyStamped => 'Bugünün kartpostalı damgalandı!';

  @override
  String flightResultNextStamp(String stamp) {
    return 'Sıradaki: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'Bu telefona kaydedildi';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Bu telefona kaydedildi · toplam $total kapı',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'Uçuşun kaydediliyor…';

  @override
  String get flightResultSessionSaved =>
      'Oturum kaydedildi · Rekorlar\'da izle';

  @override
  String get flightResultWatchReplay => 'Tekrarı izle';

  @override
  String get flightResultPreparing => 'Hazırlanıyor…';

  @override
  String get flightResultSavingShort => 'Kaydediliyor…';

  @override
  String get flightResultSaveSession => 'Oturumu kaydet';

  @override
  String get flightResultFlyAgain => 'Tekrar uç';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonMap => 'Harita';

  @override
  String get commonNext => 'Sıradaki';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şınav',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'çömelme',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zıplama',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kanat çırpma',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'uçuş süresi';

  @override
  String get flightStatPerfect => 'kusursuz';

  @override
  String get flightStatBestStreak => 'en iyi seri';

  @override
  String get flightStatRank => 'rütbe';

  @override
  String get flightRankSkyCaptain => 'Gök kaptanı';

  @override
  String get flightRankCloudExplorer => 'Bulut kâşifi';

  @override
  String get flightRankFirstWings => 'İlk kanatlar';

  @override
  String flightPercent(int percent) {
    return '%$percent';
  }

  @override
  String get gameOverCaptionBest => 'Küt! Ama yepyeni bir en iyiyle!';

  @override
  String get gameOverCaptionSea => 'Denize küçük bir dalış.';

  @override
  String get gameOverSplash => 'Cup!';

  @override
  String get gameOverBonk => 'Küt!';

  @override
  String get gameOverEveryMarkSemantics => 'Bütün çentiklere ulaşıldı';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mark yıldız için $count yıldız daha',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: $maxHp üzerinden $hp sağlık kaldı';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return 'Rotanın yüzde $percent kadarı uçuldu';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: $hp CAN KALDI';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$boss · KALAN CAN';
  }

  @override
  String get gameOverRouteFlown => 'UÇULAN ROTA';

  @override
  String gameOverHp(int hp) {
    return '$hp CAN';
  }

  @override
  String gameOverMoreFor(int count) {
    return '$count kaldı:';
  }

  @override
  String get gameOverBothMarks => 'İki çentik de tamam';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    return 'Çentikler tamam. Sıra: $boss!';
  }

  @override
  String get miniResultTitle => 'Her uçuş sayılır.';

  @override
  String get miniResultComplete => 'UÇUŞ TAMAM';

  @override
  String get miniResultCheerBest => 'Vay canına, süpersin!';

  @override
  String get miniResultCheerComplete => 'Uçuş tamam!';

  @override
  String get miniResultCheerNice => 'Güzel uçuş.';

  @override
  String get miniResultNew => 'YENİ';

  @override
  String get flightEndTrackingLost => 'Bir an seni gözden kaybettik.';

  @override
  String get flightEndPostureLost => 'Pozisyonun alanın dışına çıktı.';

  @override
  String get flightEndBackgrounded => 'Gökyüzünden bir süre uzaklaştın.';

  @override
  String get flightEndBreak => 'Hak edilmiş bir mola.';

  @override
  String get flightEndQuit => 'Bir sonraki maceraya dek.';

  @override
  String get flightEndStalled => 'Oyun yarıda kesildi.';

  @override
  String get flightEndCompleted => 'Koca bir gök dolusu yıldız. Hepsi senin.';

  @override
  String get levelResultTryAgain => 'Tekrar dene!';

  @override
  String get levelResultVictory => 'Zafer!';

  @override
  String get levelResultGuardianDown => 'Muhafız düştü!';

  @override
  String get levelResultDelivered => 'Teslim edildi!';

  @override
  String levelResultComingSoon(String region) {
    return '$region çok yakında!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '3 üzerinden $earned yıldız';
  }

  @override
  String levelResultBest(int best) {
    return 'En iyi $best';
  }

  @override
  String get levelResultNoBest => 'Henüz en iyi yok';

  @override
  String get levelResultFirstClear => 'İlk kez bitti!';

  @override
  String get levelResultNewBest => 'YENİ EN İYİ!';

  @override
  String get levelResultScore => 'PUAN';

  @override
  String get levelResultGoalBoss => 'Boss';

  @override
  String get levelResultGoalGuardian => 'Muhafız';

  @override
  String get levelResultGoalFinish => 'Bitiş';

  @override
  String get levelResultGoalDone => 'Tamam';

  @override
  String get levelResultGoalNotYet => 'Henüz değil';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaldı',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'Önce bitir';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. Tamam.';
  }

  @override
  String get levelResultPostcardWaiting =>
      'Haritada bir kartpostal seni bekliyor!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '$id $name açıldı!';
  }

  @override
  String get levelResultReachFinish => 'Yıldız kazanmak için bitişe ulaş.';

  @override
  String get course_classic_title => 'Klasik';

  @override
  String get course_starTrail_title => 'Sonsuz';

  @override
  String get course_classic_instructions =>
      'Boşlukları bul. Kusursuz geçiş için nişan noktalarını izle.';

  @override
  String get course_starTrail_instructions =>
      'Bir gruptaki 3 yıldızın hepsini topla, +5 kazan. Yıldızları art arda topla, en fazla 3× çarpan kazan. Yıldızlar kalkanını doldurur; kusursuz geçişler yıldız mıknatısı kazandırır. İkisini de yıldızlarla geliştir!';

  @override
  String get course_classic_scoreLabel => 'ENGELLER';

  @override
  String get course_starTrail_scoreLabel => 'YILDIZ PUANI';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kapı',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'yıldız puanı',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics =>
      'Klasik: boşlukların içinden uç.';

  @override
  String get course_starTrail_previewSemantics =>
      'Sonsuz: üç kalp ve bir kalkanla yıldız topla.';

  @override
  String get obstacle_garden_name => 'Bahçe kapısı';

  @override
  String get obstacle_windLift_name => 'Rüzgâr asansörü';

  @override
  String get obstacle_petalGate_name => 'Çiçek kepenkleri';

  @override
  String get obstacle_switchback_name => 'Zikzak';

  @override
  String get obstacle_lanternDrift_name => 'Süzülen fenerler';

  @override
  String get obstacle_sunWheels_name => 'Güneş çarkları';

  @override
  String get obstacle_crystalSteps_name => 'Kristal basamaklar';

  @override
  String get rush_wildfire_name => 'Yangın';

  @override
  String get rush_wildfire_escape => 'Yangından kurtuldun';

  @override
  String get rush_skyfall_name => 'Gök Çöküşü';

  @override
  String get rush_skyfall_escape => 'Gök çöküşünden sağ çıktın';

  @override
  String get rush_eruption_name => 'Püskürme';

  @override
  String get rush_eruption_escape => 'Püskürmeyi atlattın';

  @override
  String get rush_swarm_name => 'Sürü';

  @override
  String get rush_swarm_escape => 'Sürüyü yarıp geçtin';

  @override
  String get boss_baronBat_title => 'FIRTINANIN EFENDİSİ';

  @override
  String get boss_spitterBeetle_title => 'SÜRÜNÜN İKSİRCİSİ';

  @override
  String get boss_duskMoth_title => 'ALACAKARANLIK TÜLÜNÜN BEKÇİSİ';

  @override
  String get boss_pirate_title => 'KABARAN SULARIN DEHŞETİ';

  @override
  String get boss_dragon_title => 'YANAN GÖKLERİN HÜKÜMDARI';

  @override
  String get boss_kingCoo_title => 'KALDIRIM KOMİSERİ';

  @override
  String get boss_searchlightGargoyle_title => 'EN YÜKSEK KULENİN NÖBETÇİSİ';

  @override
  String get boss_neferhoo_title => 'KAYIP MEKTUBUN BEKÇİSİ';

  @override
  String get boss_baronBat_returnTitle => 'FIRTINA GERİ DÖNDÜ';

  @override
  String get boss_baronBat_barName => 'BARON YARASA';

  @override
  String get boss_spitterBeetle_barName => 'TÜKÜRÜKÇÜ KRAL';

  @override
  String get boss_duskMoth_barName => 'İMPARATORİÇE';

  @override
  String get boss_pirate_barName => 'KORSAN KAPTAN';

  @override
  String get boss_dragon_barName => 'KOR EJDERHA';

  @override
  String get boss_kingCoo_barName => 'KRAL GUGU';

  @override
  String get boss_searchlightGargoyle_barName => 'GARGOYL';

  @override
  String get boss_neferhoo_barName => 'NEFERHOO';

  @override
  String get vanguard_baronBat_title => 'BARON YARASA\'NIN YARASALARI';

  @override
  String get vanguard_baronBat_call =>
      'İşte geliyorlar! Baron hemen arkalarında.';

  @override
  String get vanguard_spitterBeetle_title => 'TÜKÜRÜKÇÜ KRAL\'IN YAVRULARI';

  @override
  String get vanguard_spitterBeetle_call =>
      'İşte geliyorlar! Tükürükçü Kral hemen arkalarında.';

  @override
  String get vanguard_duskMoth_title => 'İMPARATORİÇENİN GÜVELERİ';

  @override
  String get vanguard_duskMoth_call =>
      'İşte geliyorlar! İmparatoriçe hemen arkalarında.';

  @override
  String get vanguard_kingCoo_title => 'KRAL GUGU\'NUN FİLOSU';

  @override
  String get vanguard_kingCoo_call =>
      'İşte geliyorlar! Kral Gugu hemen arkalarında.';

  @override
  String get vanguard_kingCoo_callCrusts =>
      'İşte geliyorlar! Ekmek kabuklarından kaç!';

  @override
  String get vanguard_kingCoo_callReturns =>
      'Kabuklardan kaç! Vurmadığın güvercin geri döner!';

  @override
  String get bossVanguardClear => 'TEMİZ!';

  @override
  String get bossVanguardLeft => 'KALDI';

  @override
  String get bossStragglersCaught => 'HEPSİ YAKALANDI!';

  @override
  String get bossHint_strongerBaronBat =>
      'GÜÇLENDİ · Üçlü atışlar, yarasaları da katılıyor!';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'GÜÇLENDİ · Tam yelpazeler, böcekleri de katılıyor!';

  @override
  String get bossHint_strongerDuskMoth =>
      'GÜÇLENDİ · Yedili yelpazeler, güveleri de katılıyor!';

  @override
  String get bossHint_strongerPirate => 'GÜÇLENDİ · Sular kabarıyor!';

  @override
  String get bossHint_strongerDragon =>
      'GÜÇLENDİ · Nefesine ve sürülere dikkat!';

  @override
  String get bossHint_strongerKingCoo =>
      'GÜÇLENDİ · Düdüğüyle filosunu çağırıyor!';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'GÜÇLENDİ · Lamba açıkken tüyler yağıyor!';

  @override
  String get bossHint_strongerGargoyle => 'GÜÇLENDİ · Taş tüyler yağıyor!';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'GÜÇLENDİ · Ankh ve mumya yarasaları!';

  @override
  String get bossHint_strongerNeferhoo => 'GÜÇLENDİ · Altın ankh geri dönüyor!';

  @override
  String get bossHint_tideRising => 'SULAR YÜKSELİYOR · Yükseğe uç!';

  @override
  String get bossHint_highTide => 'KABARAN SULAR · Suyun üstünde kal';

  @override
  String get bossHint_tideFury => 'ÖFKE · Dalgaların arasında borda ateşi';

  @override
  String get bossHint_tideCalm => 'Güllelerden kaç · Sudan uzak dur';

  @override
  String get bossHint_dragonSwarm =>
      'SÜRÜ · Yarasalardan kaç ya da sprintle içlerinden geç';

  @override
  String get bossHint_dragonFuryDebut => 'ÖFKE · Daha hızlı ateş topları';

  @override
  String get bossHint_dragonFury => 'ÖFKE · Ateş topları korlara bölünüyor';

  @override
  String get bossHint_dragonCalm => 'Ateş toplarından kaç · Nefesine dikkat et';

  @override
  String get bossHint_screechFury =>
      'ÖFKE · Daha hızlı ateş topları, daha çok yarasa';

  @override
  String get bossHint_screechCalm =>
      'Ateş toplarından ve yarasalardan kaç · Çığlığa dikkat';

  @override
  String get bossHint_cooPopped => 'PAT! · Filo yok';

  @override
  String get bossHint_cooSquadron => 'FİLO · Açık şeridi izle!';

  @override
  String get bossHint_cooPuffed => 'KABARDI · Göğsüne ateş et (x2)!';

  @override
  String get bossHint_cooCrumbBomb => 'KIRINTI BOMBASI · Halkadan çık!';

  @override
  String get bossHint_cooFury => 'ÖFKE · Halkaların arasında kal';

  @override
  String get bossHint_cooCalm =>
      'Kırıntı bombalarından kaç · Göğsü kabarınca ateş et';

  @override
  String get bossHint_beamOn => 'IŞIK HUZMESİ · Karanlıkta kal';

  @override
  String get bossHint_beamFury => 'ÖFKE · Huzmelerin arasından süzül';

  @override
  String get bossHint_beamIncomingHigh => 'HUZME GELİYOR · Alçaktan uç!';

  @override
  String get bossHint_beamIncomingLow => 'HUZME GELİYOR · Yüksekten uç!';

  @override
  String get bossHint_lampOpen => 'LAMBA AÇIK · Lambaya ateş et!';

  @override
  String get bossHint_shuttersClosed => 'KEPENKLER KAPALI · Atışlarını sakla';

  @override
  String get bossHint_mothFuryNoVeil =>
      'ÖFKE · Yedili yelpazeler. Henüz tül yok!';

  @override
  String get bossHint_mothNoVeil =>
      'Henüz tül yok · Yelpazelerin arasından ateş et!';

  @override
  String get bossHint_mothShielded => 'KALKANLI · Tül inene dek kaç';

  @override
  String get bossHint_mothShieldForming => 'KALKAN ÖRÜLÜYOR · Kaçmaya hazırlan';

  @override
  String get bossHint_mothFury => 'ÖFKE · Yedili yelpazeler. Tül indi!';

  @override
  String get bossHint_mothCalm => 'Tül indi · Yelpazelerin arasından ateş et!';

  @override
  String get bossHint_neferhooMailCall => 'POSTANIZ VAR! · Vurup geri yolla!';

  @override
  String get bossHint_neferhooReturn => 'GÖNDERİCİYE İADE! · −25';

  @override
  String get bossHint_neferhooReturnFaster => 'GÖNDERİCİYE İADE! · −18';

  @override
  String get bossHint_neferhooAnkh => 'ANKH · Geri dönüyor!';

  @override
  String get bossHint_neferhooExpress =>
      'EKSPRES POSTA · Beş mektup, daha hızlı';

  @override
  String get bossHint_neferhooTwoAnkhs => 'İKİ ANKH · İki şeritten de uzak dur';

  @override
  String get bossHint_neferhooBats => 'MUMYA YARASALAR · Vurup düşür!';

  @override
  String get bossHint_neferhooScuff =>
      'Taşlar sargılarını sadece çizer. MEKTUPLARINI geri vur!';

  @override
  String get bossHint_neferhooWarmUp =>
      'Mektuplarını geri vur · Göndericiye iade';

  @override
  String get bossHint_neferhooCalm =>
      'Mektuplarını geri vur · Altın ankh\'tan kaç';

  @override
  String get bossHint_neferhooFury => 'ÖFKE · Ekspres posta ve iki ankh';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'EJDERHA NEFESİ · Alçaktan uç! Kalbi açık',
      'middle': 'EJDERHA NEFESİ · Tırman ya da dal! Kalbi açık',
      'other': 'EJDERHA NEFESİ · Yüksekten uç! Kalbi açık',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'ATEŞ · Alçaktan uç! Parlayan kalbi vur',
      'middle': 'ATEŞ · Tırman ya da dal! Parlayan kalbi vur',
      'other': 'ATEŞ · Yüksekten uç! Parlayan kalbi vur',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'SONİK ÇIĞLIK · Üstteki boşluğa uç!',
      'middle': 'SONİK ÇIĞLIK · Ortadaki boşluğa uç!',
      'other': 'SONİK ÇIĞLIK · Alttaki boşluğa uç!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'ÇIĞLIK · Üstteki boşlukta kal',
      'middle': 'ÇIĞLIK · Ortadaki boşlukta kal',
      'other': 'ÇIĞLIK · Alttaki boşlukta kal',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'YELPAZELERDEN KAÇ  ·  TÜL İNİNCE ATEŞ ET';

  @override
  String get encounterCaption_pirate => 'GÜLLELERDEN KAÇ  ·  SUDAN UZAK DUR';

  @override
  String get encounterCaption_dragon =>
      'ATEŞ TOPLARINDAN KAÇ  ·  NEFESTEN KURTUL';

  @override
  String get encounterCaption_kingCoo =>
      'HALKALARDAN ÇIK  ·  GÖĞSÜ KABARINCA ATEŞ ET';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'IŞIKTAN UZAK DUR  ·  LAMBA AÇILINCA ATEŞ ET';

  @override
  String get encounterCaption_neferhoo => 'HAZIR OL  ·  MEKTUPLARINI GERİ VUR';

  @override
  String get encounterCaption_screech => 'ÇIĞLIK ATINCA  ·  BOŞLUĞA UÇ';

  @override
  String get encounterCaption_default =>
      'HAZIR OL  ·  KANAT ÇIRP, KAÇ, ATEŞ ET';

  @override
  String get encounterCoasting => 'Kuşun güvenle süzülüyor';

  @override
  String get encounterOpenSky => 'Yeniden açık gökyüzüne';

  @override
  String get encounterOmenTitle_duskMoth => 'ALACAKARANLIK KANATLANIYOR';

  @override
  String get encounterOmenLine_duskMoth =>
      'Akşamın içinde ipekten bir tül toplanıyor…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'BİR ŞEYLER KAYNIYOR';

  @override
  String get encounterOmenLine_spitterBeetle => 'Hava köpürmeye başladı…';

  @override
  String get encounterOmenTitle_dragon => 'GÖKYÜZÜ ALEV ALIYOR';

  @override
  String get encounterOmenLine_dragon =>
      'Bulutların üstünde dev kanatlar çırpıyor…';

  @override
  String get encounterOmenTitle_kingCoo => 'KALDIRIM KAPANDI';

  @override
  String get encounterOmenLine_kingCoo =>
      'Biri simit arabası yüzünden çok kızgın…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => 'FIRTINA UYARISI';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      'Pervazda bir şey seni izliyor…';

  @override
  String get encounterOmenTitle_neferhoo => 'PİRAMİT KIPIRDANIYOR';

  @override
  String get encounterOmenLine_neferhoo => 'Piramidin tozu kıpırdanıyor…';

  @override
  String get encounterOmenTitle_baronReturns => 'BARON GERİ DÖNDÜ';

  @override
  String get encounterOmenLine_baronReturns =>
      'Geri döndü, hem de çok daha gürültülü…';

  @override
  String get encounterOmenTitle_default => 'BİR GÖLGE YAKLAŞIYOR';

  @override
  String get encounterOmenLine_default => 'Gökyüzü başkasına ait…';

  @override
  String get encounterOmenTitle_pirate => 'UFUKTA YELKEN!';

  @override
  String get encounterOmenLine_pirate => 'Kabaran sularla bir gemi geliyor…';

  @override
  String get bossGuardianEyebrow => 'MUHAFIZ';

  @override
  String bossEncounterEyebrow(String number) {
    return 'KARŞILAŞMA $number';
  }

  @override
  String get bossGuardianDown => 'MUHAFIZ DÜŞTÜ!';

  @override
  String get bossSkyReclaimed => 'GÖK GERİ ALINDI';

  @override
  String bossVictoryPoints(int points) {
    return '+$points PUAN   ·   KALKAN YENİLENDİ';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'BARON YARASA YENİLDİ',
      'spitterBeetle': 'TÜKÜRÜKÇÜ KRAL YENİLDİ',
      'duskMoth': 'ALACAKARANLIK İMPARATORİÇESİ YENİLDİ',
      'pirate': 'KORSAN KAPTAN YENİLDİ',
      'dragon': 'KOR EJDERHA YENİLDİ',
      'kingCoo': 'KRAL GUGU YENİLDİ',
      'searchlightGargoyle': 'IŞILDAKLI GARGOYL YENİLDİ',
      'other': 'NEFERHOO YENİLDİ',
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
  String get bossGargoyleCardSmall => 'IŞILDAKLI';

  @override
  String get bossGargoyleCardBig => 'GARGOYL';

  @override
  String get bossGargoyleCardOrder => 'small-big';

  @override
  String get bossDodgeFlyLow => 'ALÇAKTAN UÇ';

  @override
  String get bossDodgeFlyHigh => 'YÜKSEKTEN UÇ';

  @override
  String get bossDodgeClimbOrDive => 'TIRMAN YA DA DAL';

  @override
  String get bossDodgeSlipBetween => 'HUZMELERİN\nARASINDAN SÜZÜL';

  @override
  String get bossSpotted => 'GÖRÜLDÜN!';

  @override
  String get bossShieldLost => 'KALKAN GİTTİ';

  @override
  String get bossHeartLost => '-1 KALP';

  @override
  String get bossGargoyleLampOpen => 'LAMBA AÇIK';

  @override
  String get bossGargoyleShoot => 'ATEŞ!';

  @override
  String get bossScreechFlyToGap => 'BOŞLUĞA UÇ';

  @override
  String get bossScreechHoldGap => 'BOŞLUKTA KAL';

  @override
  String get bossPirateHighTide => 'KABARAN SULAR';

  @override
  String get bossBarDefeated => 'YENİLDİ';

  @override
  String get bossBarIncoming => 'GELİYOR';

  @override
  String get bossBarFury => 'ÖFKE';

  @override
  String get bossBarHeartDouble => 'KALP ×2';

  @override
  String get bossStronger => 'GÜÇLENDİ!';

  @override
  String get bossKingCooPuffed => 'KABARDI';

  @override
  String get bossKingCooShout => 'GUU!';

  @override
  String get bossKingCooPop => 'PAT!';

  @override
  String get bossKingCooPoof => 'PUF!';

  @override
  String get bossSquadOpenLane => 'AÇIK ŞERİT = GİT';

  @override
  String get bossSquadUseGap => 'BOŞLUKTAN GEÇ';

  @override
  String get bossSquadThenV => 'SONRA: V';

  @override
  String get bossSquadThenGap => 'SONRA: DUVAR';

  @override
  String get bossSquadCancelled => 'FİLO İPTAL';

  @override
  String get bossNeferhooFound => 'KAYIP MEKTUP BULUNDU';

  @override
  String get bossNeferhooHoo => 'HUU';

  @override
  String get bossNeferhooPoo => 'HU';

  @override
  String get bossNeferhooMailCall => 'POSTANIZ VAR!';

  @override
  String get bossNeferhooExpressPost => 'EKSPRES POSTA';

  @override
  String get bossNeferhooShootBack => 'Vurup geri yolla!';

  @override
  String get bossNeferhooAnkh => 'ANKH';

  @override
  String get bossNeferhooTwoAnkhs => 'İKİ ANKH';

  @override
  String get bossNeferhooComesBack => 'Geri dönüyor!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'YANGIN!',
      'skyfall': 'GÖK ÇÖKÜŞÜ!',
      'eruption': 'PÜSKÜRME!',
      'other': 'SÜRÜ!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Sprint halkalarını kap, yangını geride bırak!',
      'skyfall': 'Sprint halkalarını kap, göktaşlarıyla yarış!',
      'eruption': 'Sprint halkalarını kap, patlamaları atlat!',
      'other': 'Sprint halkalarını kap, sürüyü yarıp geç!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return 'KURTULDUN! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'KUSURSUZ! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Yangını geride bıraktın',
      'skyfall': 'Gök çöküşünden sağ çıktın',
      'eruption': 'Püskürmeyi atlattın',
      'other': 'Sürüyü yarıp geçtin',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => 'BORA!';

  @override
  String encounterGaleDetail(String mark) {
    return '$mark yanıp sönen yerden çerçöp gelir. Kaç!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'ATLATTIN! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail => 'Borayı atlattın';

  @override
  String get encounterAllRings => 'TÜM HALKALAR!';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'Turbo hız +$seconds sn';
  }

  @override
  String get encounterFinish => 'BİTİŞ';

  @override
  String get builderMode_pushUp => 'Şınav';

  @override
  String get builderMode_squat => 'Çömelme';

  @override
  String get builderMode_jump => 'Zıplama';

  @override
  String builderSeconds(String seconds) {
    return '$seconds sn';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes dk $seconds sn';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şınav',
      one: '1 şınav',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çömelme',
      one: '1 çömelme',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'Dokunma seviyem';

  @override
  String get builderNewLevel_pushUp => 'Şınav seviyem';

  @override
  String get builderNewLevel_squat => 'Çömelme seviyem';

  @override
  String get builderNewLevel_jump => 'Zıplama seviyem';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'Seviyem';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Beakbound\'daki “$name” seviyemde uç ($mode): $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$total üzerinden $earned yıldız';
  }

  @override
  String get builderBackSemantics => 'Geri';

  @override
  String get builderKeepIt => 'Kalsın';

  @override
  String builderLessSemantics(String name) {
    return 'Azalt: $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'Artır: $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => 'Çoğalt';

  @override
  String get builderCopy => 'Kopyala';

  @override
  String get builderDeleteSemantics => 'Sil';

  @override
  String get builderDelete => 'Sil';

  @override
  String get builderMoreBelow => 'Devamı aşağıda';

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
    return '%$percent';
  }

  @override
  String get builderLane => 'Şerit';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'çömelmenin üst ya da alt noktası',
      'other': 'şınavın üst ya da alt noktası',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'Üst';

  @override
  String get builderLaneBottom => 'Alt';

  @override
  String get builderHeight => 'Yükseklik';

  @override
  String get builderHeightHint => 'gök yüksekliği';

  @override
  String get builderLowerSemantics => 'Alçalt';

  @override
  String get builderHigherSemantics => 'Yükselt';

  @override
  String get builderOpening => 'Açıklık';

  @override
  String builderOpeningHint(int percent) {
    return 'en az %$percent';
  }

  @override
  String get builderNarrowerSemantics => 'Daralt';

  @override
  String get builderWiderSemantics => 'Genişlet';

  @override
  String get builderMotion => 'Hareket';

  @override
  String get builderMotionGardenHint => 'bahçe kapıları hareket etmez';

  @override
  String get builderMotionStill => 'Sabit';

  @override
  String get builderMotionGentle => 'Hafif';

  @override
  String get builderMotionLively => 'Canlı';

  @override
  String get builderMotionGardenToast =>
      'Bahçe kapıları hareket etmez: hareket etmesi için başka bir tür seç.';

  @override
  String get builderSway => 'Salınım';

  @override
  String builderSwayHint(String seconds) {
    return 'bir salınım: $seconds';
  }

  @override
  String get builderSwayFast => 'Hızlı';

  @override
  String get builderSwayMedium => 'Orta';

  @override
  String get builderSwaySlow => 'Yavaş';

  @override
  String get builderPhase => 'Vardığında';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position / $count';
  }

  @override
  String get builderPhaseHint => 'salınımın neresinde';

  @override
  String get builderPhaseEarlierSemantics => 'Salınımda daha erken';

  @override
  String get builderPhaseLaterSemantics => 'Salınımda daha geç';

  @override
  String get builderLook => 'Görünüm';

  @override
  String builderLookSemantics(int number) {
    return 'Görünüm $number';
  }

  @override
  String get builderDoor => 'Taş kapı';

  @override
  String get builderDoorHint => 'vurarak aç';

  @override
  String get builderDoorNone => 'Kapı yok';

  @override
  String get builderDoorNeedsShootToast =>
      'Kapıları kullanmak için seviye ayarlarında Ateş\'i aç.';

  @override
  String get builderPlace => 'Konum';

  @override
  String get builderPlaceHint => 'başlangıçtan';

  @override
  String get builderEarlierSemantics => 'Daha erken';

  @override
  String get builderLaterSemantics => 'Daha geç';

  @override
  String builderFamilySemantics(String family) {
    return 'Kapı türü: $family. Değiştir';
  }

  @override
  String get builderChangeFamily => 'Türü değiştir';

  @override
  String get builderItemStar => 'Yıldız';

  @override
  String get builderItemTrio => 'Yıldız üçlüsü';

  @override
  String get builderItemHeart => 'Kalp';

  @override
  String get builderItemEnemy => 'Düşman';

  @override
  String get builderItemGate => 'Kapı';

  @override
  String get builderItemStarDetail => 'Toplanacak bir yıldız';

  @override
  String get builderItemTrioDetail => 'Üçü birden bonus verir';

  @override
  String get builderItemHeartDetail => 'Bir kalp geri verir';

  @override
  String get builderEnemyKind => 'Tür';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Kuş her çömelmenin üstünde ve altında uçar: toplanacakları sarı çizgilerin üstüne ya da arasına koy.',
      'other':
          'Kuş her şınavın üstünde ve altında uçar: toplanacakları sarı çizgilerin üstüne ya da arasına koy.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'Mor yarasa';

  @override
  String get builderEnemy_caveBat => 'Mağara yarasası';

  @override
  String get builderEnemy_spitterBeetle => 'Tükürükçü böcek';

  @override
  String get builderEnemy_duskMoth => 'Alacakaranlık güvesi';

  @override
  String get builderEnemy_alleyPigeon => 'Ara sokak güvercini';

  @override
  String get builderEnemy_mummyBat => 'Mumya yarasa';

  @override
  String get builderSummaryTitle => 'Bu seviye';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'Süre';

  @override
  String get builderFactStars => 'Yıldız';

  @override
  String get builderFactMarks => 'Çentikler';

  @override
  String get builderFactWorkout => 'Egzersiz';

  @override
  String get builderFactPace => 'Tempo';

  @override
  String get builderFactBoss => 'Boss';

  @override
  String get builderPace_relaxed => 'Rahat';

  @override
  String get builderPace_steady => 'Dengeli';

  @override
  String get builderPace_brisk => 'Hızlı';

  @override
  String get builderSummaryStarterNote =>
      'Bir başlangıç seviyesi: olduğu gibi uç ya da remiksleyip kendi seviyen yap.';

  @override
  String get builderSummaryClearedNote => 'Sen bitirdin: sonuna kadar uçtun.';

  @override
  String get builderSummaryClearNote =>
      'Bitirildi olarak işaretlemek için bitişe kadar deneme uçuşu yap.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss\'yı yen ve çizgiyi geç.',
      'spitterBeetle':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss\'ı yen ve çizgiyi geç.',
      'duskMoth':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss\'ni yen ve çizgiyi geç.',
      'pirate':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss\'ı yen ve çizgiyi geç.',
      'dragon':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss\'yı yen ve çizgiyi geç.',
      'kingCoo':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss\'yu yen ve çizgiyi geç.',
      'searchlightGargoyle':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss\'u yen ve çizgiyi geç.',
      'neferhoo':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss\'yu yen ve çizgiyi geç.',
      'other':
          'Bitirildi olarak işaretlemek için deneme uçuşu yap, $boss karşısında kazan ve çizgiyi geç.',
    });
    return '$_temp0';
  }

  @override
  String get builderSummaryHowTo =>
      'Soldan bir araç seç, sonra gökyüzüne dokun. Değiştirmek için bir şeye dokun; taşımak için sürükle.';

  @override
  String get builderFamily_garden_detail => 'Sabit durur. Taş kapı alabilir.';

  @override
  String get builderFamily_windLift_detail => 'Açıklık yükselip alçalır.';

  @override
  String get builderFamily_petalGate_detail => 'Açıklık daralıp genişler.';

  @override
  String get builderFamily_switchback_detail =>
      'Birbirinden kayan iki açıklık.';

  @override
  String get builderFamily_lanternDrift_detail => 'Sallanan asılı fenerler.';

  @override
  String get builderFamily_sunWheels_detail => 'Kapanıp açılan çarklar.';

  @override
  String get builderFamily_crystalSteps_detail => 'Dalga gibi üç basamak.';

  @override
  String get builderFamiliesCloseSemantics => 'Kapı türlerini kapat';

  @override
  String get builderFamiliesTitle => 'Kapı türü';

  @override
  String get builderFamiliesSubtitle => 'Kapının görünüşü ve hareketi.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seviyeye en fazla $count harfli bir ad ver.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort => 'Bitiş çizgisini ileri taşı: seviye çok kısa.';

  @override
  String get reach_tooLong => 'Bitiş çizgisini yaklaştır: seviye çok uzun.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çok fazla şey var: bir seviye en fazla $count tane alır.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap =>
      'Yalnızca Dokun ve Uç seviyeleri boss\'la biter.';

  @override
  String get reach_noGates => 'Kuşun içinden uçacağı kapılar ekle.';

  @override
  String get reach_startZone =>
      'Başlangıca çok yakın: başlangıç alanının ötesine taşı.';

  @override
  String get reach_finishRoom =>
      'Bu kapıdan sonra bitiş çizgisine kadar yer bırak.';

  @override
  String get reach_overlap => 'İki kapı üst üste: onları ayır.';

  @override
  String get reach_gateHeight => 'Bu kapı çok yüksek ya da çok alçak.';

  @override
  String get reach_gateMotion => 'Bu kapı o şekilde hareket edemez.';

  @override
  String get reach_gateLook => 'Bu kapının görünümü bilinmiyor.';

  @override
  String get reach_gateNarrow => 'Bu kapıyı genişlet: kuş sığmıyor.';

  @override
  String get reach_gateWide => 'Bu kapı fazla geniş açık.';

  @override
  String get reach_doorNeedsShoot =>
      'Taş kapı için Dokun ve Uç\'ta Ateş açık olmalı.';

  @override
  String get reach_doorNeedsGarden =>
      'Taş kapıyı yalnızca bahçe kapısı taşıyabilir.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Sıkışık geçiş: sakin bir çömelmeyle yetişmek zor olabilir.',
      'other': 'Sıkışık geçiş: sakin bir şınavla yetişmek zor olabilir.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'Dik tırmanış: bu kapıya zıplamak için daha çok yer bırak.';

  @override
  String get reach_enemyNeedsTap =>
      'Düşmanlar yalnızca Dokun ve Uç seviyelerinde uçar.';

  @override
  String get reach_outsideSky => 'Gökyüzünün içinde tut.';

  @override
  String get reach_pastFinish => 'Bitiş çizgisinden önceye koy.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Çömelmenin erişemeyeceği yerde: şeritlere yaklaştır.',
      'other': 'Şınavın erişemeyeceği yerde: şeritlere yaklaştır.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'Duvarın içinde: açıklığa taşı.';

  @override
  String get reach_noStars => 'En az bir yıldız koy.';

  @override
  String get reach_marks =>
      'Yıldız çentikleri, seviyedekinden fazla yıldız istiyor.';

  @override
  String reach_cannotFly(String problem) {
    return 'Bu seviye henüz uçulamaz ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'Seviye kaydedilmedi, bu yüzden henüz uçulamaz. Tekrar denemek için adına dokun.';

  @override
  String get builderShareBlockedToast =>
      'Önce kırmızı bayrakları düzelt: sonra seviye paylaşılabilir.';

  @override
  String get builderEditorBackSemantics => 'Atölyeye dön';

  @override
  String get builderSettingsSemantics => 'Seviye ayarları';

  @override
  String get builderFly => 'UÇ';

  @override
  String get builderTestFly => 'UÇUP DENE';

  @override
  String get builderFlySemantics => 'Bu seviyede uç';

  @override
  String get builderTestFlySemantics => 'Bütün seviyeyi uçup dene';

  @override
  String get builderUndoSemantics => 'Geri al';

  @override
  String get builderRedoSemantics => 'Yinele';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice ipucu',
    );
    return '$blocking düzeltilecek, $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice ipucu',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => 'Uçmaya hazır';

  @override
  String get builderShareSemantics => 'Paylaşım kodu';

  @override
  String get builderFromHereSemantics => 'Buradan uçup dene';

  @override
  String get builderFromHere => 'Buradan';

  @override
  String get builderStatusStarter => 'Başlangıç · bak, uç ya da remiksle';

  @override
  String get builderStatusSaveFailed => 'Kaydedilemedi · tekrar için dokun';

  @override
  String get builderStatusSaving => 'Kaydediliyor…';

  @override
  String get builderStatusSaved => 'Tüm değişiklikler kaydedildi';

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
    return '$name. $mode. $status. Yeniden adlandırmak için dokun.';
  }

  @override
  String get builderStarterBanner => 'Remiksle, senin olsun';

  @override
  String get builderRemix => 'Remiksle';

  @override
  String get builderRemixSemantics => 'Remiksle';

  @override
  String get builderIssuesCloseSemantics => 'Sorunları ve ipuçlarını kapat';

  @override
  String get builderIssuesReadyTitle => 'Uçmaya hazır!';

  @override
  String get builderIssuesFixTitle => 'Uçmadan önce düzelt';

  @override
  String get builderIssuesTipsTitle => 'Hazır, birkaç ipucuyla';

  @override
  String get builderIssuesReadyDetail =>
      'Düzeltilecek bir şey yok. Bitirmek için bitişe kadar uçup dene.';

  @override
  String get builderIssuesDetail => 'Rotadaki yerine gitmek için birine dokun.';

  @override
  String get builderSettingsCloseSemantics => 'Ayarları kapat';

  @override
  String get builderSettingsTitle => 'Seviye ayarları';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · değişiklikler anında kaydedilir';
  }

  @override
  String get builderSettingsName => 'İsim';

  @override
  String get builderRename => 'Ad değiştir';

  @override
  String get builderRenameSemantics => 'Adı değiştir';

  @override
  String get builderSettingsRegion => 'Bölge';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yer · fazlası için kaydır',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'Tempo';

  @override
  String get builderSettingsPaceHint => 'gökyüzü ne kadar hızlı kayar';

  @override
  String get builderSettingsMarks => 'Çentikler';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız var',
      one: '1 yıldız var',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'iki yıldız çentiği';

  @override
  String get builderMarkThreeSemantics => 'üç yıldız çentiği';

  @override
  String get builderMarksAuto => 'Otomatik: yıldızlara göre';

  @override
  String get builderMarksByHand => 'Elle ayarla';

  @override
  String get builderSettingsControls => 'Kontroller';

  @override
  String get builderShootOn => 'Ateş açık';

  @override
  String get builderShootOff => 'Ateş kapalı';

  @override
  String get builderSprintOn => 'Sprint açık';

  @override
  String get builderSprintOff => 'Sprint kapalı';

  @override
  String get builderSettingsBoss => 'Boss finali';

  @override
  String get builderSettingsBossHint => 'sonda bekler';

  @override
  String get builderNoBossSemantics => 'Boss yok: bitiş çizgisi';

  @override
  String get builderNoBoss => 'Yok';

  @override
  String get builderBossShort_baronBat => 'Baron';

  @override
  String get builderBossShort_spitterBeetle => 'Kral';

  @override
  String get builderBossShort_duskMoth => 'İmparatoriçe';

  @override
  String get builderBossShort_pirate => 'Korsan';

  @override
  String get builderBossShort_dragon => 'Ejderha';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Kuş iki şeritte uçar: her çömelmenin üst ve alt noktasında. Daha yavaş bir oyuncu aynı seviyeyi daha sakin bir hızda oynar. Burada ateş, sprint ya da boss yok.',
      'other':
          'Kuş iki şeritte uçar: her şınavın üst ve alt noktasında. Daha yavaş bir oyuncu aynı seviyeyi daha sakin bir hızda oynar. Burada ateş, sprint ya da boss yok.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'Her zıplama kuşu yükseltir; arada süzülür. Burada ateş, sprint ya da boss yok.';

  @override
  String get builderStartZoneToast =>
      'Başlangıç alanını boş bırak: bir şeyleri kesikli çizginin sağına koy.';

  @override
  String get builderSkySemantics =>
      'Seviye göğü. Koymak için dokun, taşımak ya da kaydırmak için sürükle.';

  @override
  String get builderSkyReadOnlySemantics =>
      'Seviye göğü. Bakmak için bir şeye dokun.';

  @override
  String get builderCoachTitle => 'Seviyeni kur';

  @override
  String get builderCoachPickTool => 'Soldan bir araç seç';

  @override
  String get builderCoachTapSky => 'Koymak için gökyüzüne dokun';

  @override
  String get builderCoachTestFly => 'Uçup dene!';

  @override
  String get builderCoachDrag =>
      'Taşımak için bir şeyi sürükle · kaydırmak için göğü sürükle';

  @override
  String get builderTipDrag =>
      'Taşımak için sürükle · kaydırmak için göğü sürükle';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'ÇÖMELMENİN ÜSTÜ',
      'other': 'ŞINAVIN ÜSTÜ',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'ÜST';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'ÇÖMELMENİN ALTI',
      'other': 'ŞINAVIN ALTI',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'ALT';

  @override
  String get builderCanvasStartZoneFull => 'BAŞLANGIÇ ALANI · BOŞ BIRAK';

  @override
  String get builderCanvasStartZone => 'BAŞLANGIÇ';

  @override
  String get builderCanvasFinishHere => 'BİTİŞ BURADA';

  @override
  String get builderTool_select => 'Seç';

  @override
  String get builderToolHint_select =>
      'Seç: değiştirmek için bir şeye dokun, taşımak için sürükle';

  @override
  String get builderTool_gate => 'Kapı';

  @override
  String get builderToolHint_gate => 'Kapı: kapı koymak için gökyüzüne dokun';

  @override
  String get builderTool_star => 'Yıldız';

  @override
  String get builderToolHint_star =>
      'Yıldız: yıldız koymak için gökyüzüne dokun';

  @override
  String get builderTool_trio => 'Üçlü';

  @override
  String get builderToolHint_trio =>
      'Yıldız üçlüsü: üç yıldız koymak için gökyüzüne dokun';

  @override
  String get builderTool_heart => 'Kalp';

  @override
  String get builderToolHint_heart => 'Kalp: kalp koymak için gökyüzüne dokun';

  @override
  String get builderTool_enemy => 'Düşman';

  @override
  String get builderToolHint_enemy =>
      'Düşman: düşman koymak için gökyüzüne dokun';

  @override
  String get builderTool_finish => 'Bitiş';

  @override
  String get builderToolHint_finish =>
      'Bitiş: bitiş çizgisini taşımak için gökyüzüne dokun';

  @override
  String get builderTool_boss => 'Boss';

  @override
  String get builderToolHint_boss =>
      'Boss işareti: boss\'un beklediği yeri taşımak için gökyüzüne dokun';

  @override
  String get builderStarterToolsToast =>
      'Başlangıç seviyeleri olduğu gibi kalır: değiştirmek için remiksle.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss': 'Rota özeti. Boss\'a $length. Rotada ilerlemek için sürükle.',
      'other': 'Rota özeti. Bitişe $length. Rotada ilerlemek için sürükle.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Rota özeti. Boss\'a $length. $reps. Rotada ilerlemek için sürükle.',
      'other':
          'Rota özeti. Bitişe $length. $reps. Rotada ilerlemek için sürükle.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return 'Boss\'a $length';
  }

  @override
  String get builtResultTestFlight => 'DENEME UÇUŞU';

  @override
  String get builtResultCleared => 'Tamamlandı!';

  @override
  String get builtResultBonk => 'Küt!';

  @override
  String get builtResultLanded => 'Kondun';

  @override
  String get builtResultTestTab => 'DENEME';

  @override
  String get builtResultGoalFinish => 'Bitiş';

  @override
  String get builtResultGoalBoss => 'Boss';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. Tamam.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız topla.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız topla. Tamam.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'Tamam';

  @override
  String get builtResultNotYet => 'Henüz değil';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaldı',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'Önce bitir';

  @override
  String get builtResultClearedByYou => 'SEN BİTİRDİN';

  @override
  String get builtResultNewBest => 'YENİ EN İYİ!';

  @override
  String get builtResultPractice => 'Antrenman';

  @override
  String builtResultBest(int count) {
    return 'En iyi $count';
  }

  @override
  String get builtResultFirstClear => 'İlk kez bitti!';

  @override
  String get builtResultStarsCollected => 'TOPLANAN YILDIZ';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '3 üzerinden $count seviye yıldızı',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'İSTENEN';

  @override
  String get builtResultWorkout => 'EGZERSİZ';

  @override
  String get builtResultGotTo => 'ULAŞILAN';

  @override
  String get builtResultScore => 'PUAN';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şınav',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'çömelme',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zıplama',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kamerayla şınav',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kamerayla çömelme',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'toplam $length';
  }

  @override
  String get builtResultNotKept => 'Saklanmaz';

  @override
  String get builtResultNoBest => 'En iyi yok';

  @override
  String get builtResultClearedStrip => 'Sen bitirdin · paylaşmaya hazır!';

  @override
  String builtResultFlownFrom(String from) {
    return 'Başlangıç: $from. Bitirmek için baştan sona uç.';
  }

  @override
  String get builtResultTestNothingSaved =>
      'Deneme uçuşu · hiçbir şey kaydedilmez';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'Deneme uçuşu · ulaşılan: $reached / $length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return 'Ulaşılan: $reached / $length. Yıldız için bitişe ulaş.';
  }

  @override
  String get builtResultReachFinish => 'Yıldız kazanmak için bitişe ulaş.';

  @override
  String get builtResultSaved => 'Bu telefona kaydedildi';

  @override
  String get builtResultSaving => 'Uçuşun kaydediliyor…';

  @override
  String get builtResultBuilder => 'Atölye';

  @override
  String get builtResultEditLevel => 'Seviyeyi düzenle';

  @override
  String get builtResultEdit => 'Düzenle';

  @override
  String get builtResultFlyAgain => 'Tekrar uç';

  @override
  String get builtResultWatchReplay => 'Tekrarı izle';

  @override
  String get builtResultPreparing => 'Hazırlanıyor…';

  @override
  String get builtResultSessionSaving => 'Kaydediliyor…';

  @override
  String get builtResultSaveSession => 'Oturumu kaydet';

  @override
  String get builderShelfTitle => 'Seviye Atölyesi';

  @override
  String get builderShelfPasteCode => 'Kodu yapıştır';

  @override
  String get builderShelfNewLevel => 'Yeni seviye';

  @override
  String get builderShelfSaveFailed => 'Kaydedilemedi. Lütfen tekrar dene.';

  @override
  String builderShelfDeleteTitle(String name) {
    return '“$name” silinsin mi?';
  }

  @override
  String get builderShelfDeleteBody =>
      'En iyi sonuçları da silinir. Üzerinde yaptığın şınav, çömelme ve zıplamalar yine sayılır.';

  @override
  String get builderShelfDelete => 'Sil';

  @override
  String builderShelfDeleted(String name) {
    return '“$name” silindi.';
  }

  @override
  String get builderShelfFixFirst =>
      'Paylaşmadan önce kırmızıyla işaretlileri düzelt: Düzelt\'e dokun.';

  @override
  String get builderShelfCodeCopied =>
      'Kod kopyalandı! Bir arkadaşına yapıştır.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'Kod kopyalandı! Bitişe kadar sen de uç ki arkadaşların yapılabildiğini bilsin.';

  @override
  String get builderShelfNotReady =>
      'Bu seviye henüz uçmaya hazır değil: Düzelt\'e dokun.';

  @override
  String get builderShelfPasteMissingTitle => 'Yapıştırılacak seviye kodu yok';

  @override
  String get builderShelfPasteNewerTitle =>
      'Daha yeni bir Beakbound\'dan seviye';

  @override
  String get builderShelfPasteDamagedTitle => 'Bu kod karman çorman olmuş';

  @override
  String get builderShelfPasteMissingBody =>
      'Bir arkadaşının seviye kodunu kopyala (BEAK1. ile başlar) ve yine Kodu yapıştır\'a dokun.';

  @override
  String get builderShelfPasteNewerBody =>
      'Uçmak için Beakbound\'u güncelle, sonra kodu yine yapıştır.';

  @override
  String get builderShelfPasteDamagedBody =>
      'Bir kısmı eksik ya da yanlış yazılmış. Arkadaşından kodun tamamını yeniden kopyalamasını iste.';

  @override
  String builderShelfImported(String name) {
    return '“$name” rafında!';
  }

  @override
  String get builderShelfUnavailable => 'Seviyelerin biraz zaman istiyor.';

  @override
  String get builderShelfMine => 'Seviyelerim';

  @override
  String get builderShelfStarters => 'Başlangıç seviyeleri';

  @override
  String get builderShelfStartersHint =>
      'Birinde uç ya da remiksleyip kendi seviyen yap';

  @override
  String get builderShelfEmptyTitle => 'İlk seviyeni kur';

  @override
  String get builderShelfEmptyBody =>
      'Kapıları, yıldızları ve kalpleri elle yerleştir, bitiş çizgisini koy ve uçup dene.';

  @override
  String get builderShelfPasteFriend => 'Arkadaşının kodunu yapıştır';

  @override
  String get builderShelfNeedsWork => 'Düzeltilmeli';

  @override
  String get builderShelfClearedByYou => 'Sen bitirdin';

  @override
  String get builderShelfFromFriend => 'Arkadaştan';

  @override
  String get builderShelfFly => 'Uç';

  @override
  String builderShelfFlySemantics(String name) {
    return 'Uç: $name';
  }

  @override
  String get builderShelfFixIt => 'Düzelt';

  @override
  String builderShelfFixSemantics(String name) {
    return 'Düzelt: $name';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return 'Düzenle: $name';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return 'Paylaş: $name';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return 'Paylaş: $name. Sen bitirdin';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'Seçenekler: $name';
  }

  @override
  String get builderShelfRemix => 'Remiksle';

  @override
  String builderShelfRemixSemantics(String name) {
    return 'Remiksle: $name';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Düzenleyicide düzeltilecek $count şey',
      one: 'Düzenleyicide düzeltilecek 1 şey',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız',
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
      other: 'En iyi: 3 üzerinden $stars yıldız.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Düzeltilmeli: $count sorun var.',
      one: 'Düzeltilmeli: 1 sorun var.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'Sen bitirdin.';

  @override
  String get builderShelfFromFriendSemantics => 'Arkadaştan.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return 'İncele: $name. $mode, $length, $fact.';
  }

  @override
  String get builderShelfRemixSuffix => 'remiks';

  @override
  String get builderShelfCopySuffix => 'kopya';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonCancel => 'İptal';

  @override
  String get starter_t_tap_1_name => 'Bahçede Hoplama';

  @override
  String get starter_t_push_1_name => 'On Şınav';

  @override
  String get starter_t_squat_1_name => 'Merdivende Çömel';

  @override
  String get starter_t_jump_1_name => 'Zıp Zıp Koyu';

  @override
  String get starter_t_tap_boss_name => 'Baron\'un Köprüsü';

  @override
  String get builderPickCloseNewLevel => 'Yeni seviyeyi kapat';

  @override
  String get builderPickModeTitle => 'Hangisi olsun?';

  @override
  String get builderPickRegionTitle => 'Nerede uçsun?';

  @override
  String get builderPickModeSubtitle =>
      'Nasıl uçulacağını seç (sonra değiştiremezsin). Her seviyeyi dokunarak uçup denersin.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · nerede uçacağını seç. Bunu sonra değiştirebilirsin.';
  }

  @override
  String get builderPickTouchLine =>
      'Dokun, kanat çırp. Kapılar, yıldızlar, düşmanlar ve bir boss.';

  @override
  String get builderPickPushUpLine =>
      'Bir üst, bir alt şerit: her iniş bir şınav.';

  @override
  String get builderPickSquatLine =>
      'Bir üst, bir alt şerit: her iniş bir çömelme.';

  @override
  String get builderPickJumpLine =>
      'Yükselmek için zıpla. Kapılar gökyüzünün her yerinde.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'Kamera';

  @override
  String get builderPickSuggested => 'Önerilen';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, önerilen';
  }

  @override
  String get builderPickClose => 'Kapat';

  @override
  String get builderPickNotYet =>
      'Henüz değil: önce kırmızıyla işaretlileri düzelt.';

  @override
  String get builderPickShare => 'Paylaşım kodu';

  @override
  String get builderPickShareLine =>
      'Bir arkadaşının kendi Beakbound\'una yapıştırabileceği bir kod kopyala.';

  @override
  String get builderPickDuplicate => 'Çoğalt';

  @override
  String get builderPickDuplicateLine =>
      'Başka bir fikri denemek için kopyasını yap.';

  @override
  String get builderPickDeleteLine => 'Seviyeyi at. Önce sana sorulacak.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'Eklemekten vazgeç';

  @override
  String get builderPickImportTitle => 'Uçulacak bir seviye!';

  @override
  String get builderPickImportSubtitle => 'Biri bu seviyeyi seninle paylaştı.';

  @override
  String get builderPickClearedByMaker => 'Yapımcısı bitirdi';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toplanacak $count yıldız',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    return 'Sonunda $boss bekliyor';
  }

  @override
  String get builderPickNotFlown => 'Yapımcısı henüz sonuna kadar uçmadı.';

  @override
  String get builderPickRoute => 'Rota';

  @override
  String builderPickAlreadyHave(String name) {
    return 'Bu seviye sende zaten var: “$name”.';
  }

  @override
  String get builderPickImportCopy => 'Kopya olarak al';

  @override
  String get builderPickOpenYours => 'Seninkini aç';

  @override
  String get builderPickImport => 'Rafa ekle';

  @override
  String get builderShelfRenameCancelSemantics => 'Vazgeç';

  @override
  String get builderShelfRenameTitle => 'Seviyene ad ver';

  @override
  String get builderShelfRenameEmpty => 'Bir ada bir iki harf gerek';

  @override
  String get builderShelfRenameSaveSemantics => 'Adı kaydet';

  @override
  String get builderShelfRenameSave => 'Kaydet';

  @override
  String get coopMode_roped => 'İpli';

  @override
  String get coopMode_free => 'İpsiz';

  @override
  String get coopMode_duel => '1\'e 1';

  @override
  String get coopTitle => 'Birlikte Uç';

  @override
  String get coopPlayersTag => 'İKİ OYUNCU · TEK TELEFON';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode EN İYİ $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: EN İYİ YOK';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count DÜELLO',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode: İLK DÜELLO';
  }

  @override
  String get coopRopedLead => 'Kuşlarınız tek bir ipi paylaşıyor.';

  @override
  String get coopRopedBody =>
      'Yükseğe tırmanmak için birlikte kanat çırpın: tek başına çırpan kuş ikisini de kaldırır, ama sadece biraz. Ortağınızı sürüklemek için Sprint atın.';

  @override
  String get coopFreeLead => 'İpsiz:';

  @override
  String get coopFreeBody =>
      'her kuş kendi başına uçar, diğerine sadece çarpar. Kalpler, kalkan ve puan yine ortaktır.';

  @override
  String get duelLead => 'Kapışın!';

  @override
  String get duelBody =>
      'Her kuşun kendi kalpleri var. Sürpriz kutuları kapın: kimi rakibinize yarasa, tükürükçü böcek ya da göktaşı yollar, kimi kalp, kalkan ya da yıldız gücü getirir. Son uçan kuş kazanır.';

  @override
  String get coopStart => 'Birlikte uç';

  @override
  String get duelStart => 'Kapışın!';

  @override
  String get coopFlightSemantics =>
      '1. oyuncu kanat çırpmak için sol yarıya, 2. oyuncu sağ yarıya dokunur';

  @override
  String get coopPauseSemantics => 'Uçuşu durdur';

  @override
  String coopShootSemantics(int player) {
    return 'Oyuncu $player ateş';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'Oyuncu $player sprint';
  }

  @override
  String coopPlayerShort(int player) {
    return 'O$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'OYUNCU $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Yıldız mıknatısı: $seconds saniye kaldı',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Mıknatıs doluyor: $gates üzerinden $charge kusursuz geçiş',
    );
    return '$_temp0';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '${seconds}sn',
    );
    return '$_temp0';
  }

  @override
  String get coopCountdownRoped => 'İp bağlandı. Hazır… dikkat…';

  @override
  String get coopCountdownFree => 'Hazır… dikkat…';

  @override
  String get duelCountdown => 'Düelloya hazır…';

  @override
  String get coopCountdownRopedHint =>
      'Yükselmek için birlikte kanat çırpın.\nOrtağınızı sürüklemek için Sprint!';

  @override
  String get coopCountdownFreeHint =>
      'Her kuş kendi başına uçar.\nKalpleri paylaşın, kapıları geçin!';

  @override
  String get duelCountdownHint =>
      'Sürpriz kutuları kapın!\nSon uçan kuş kazanır.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Oyuncu $player yıldız gücü: $seconds saniye kaldı',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'Ana menü';

  @override
  String get coopChangeBirds => 'Kuşları değiştir';

  @override
  String get coopSaved => 'Kaydedildi';

  @override
  String get coopSaving => 'Kaydediliyor…';

  @override
  String get coopSaveSession => 'Oturumu kaydet';

  @override
  String get duelRematch => 'Rövanş';

  @override
  String get coopFlyAgain => 'Tekrar uç';

  @override
  String duelWinner(int player) {
    return 'Oyuncu $player kazandı!';
  }

  @override
  String get duelDraw => 'Berabere!';

  @override
  String get duelStopped => 'Düello durdu';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first – $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    String _temp0 = intl.Intl.selectLogic(loser, {
      'Minty': 'Minty\'yi',
      'other': '$loser\'i',
    });
    return '$winner, $_temp0 yendi';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize! Hedef: O$rival';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize!';
  }

  @override
  String get duelPrize_batSwarm => 'Yarasa sürüsü';

  @override
  String get duelPrize_spitter => 'Tükürükçü böcek';

  @override
  String get duelPrize_meteorShower => 'Göktaşı yağmuru';

  @override
  String get duelPrize_heart => 'Kalp';

  @override
  String get duelPrize_shield => 'Kalkan';

  @override
  String get duelPrize_starPower => 'Yıldız gücü';

  @override
  String get coopTapLeftHalf => 'Sol yarıya dokun';

  @override
  String get coopTapRightHalf => 'Sağ yarıya dokun';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'Oyuncu $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'O$player · bu tarafa dokun';
  }

  @override
  String get coopKeysP1 => 'O1 · W çırp · D ateş · A sprint';

  @override
  String get coopKeysP2 => 'O2 · Yukarı çırp · Sağ ateş · Sol sprint';

  @override
  String get coopRopedSemantics => 'İpli: kuşlar bir ipi paylaşır';

  @override
  String get coopFreeSemantics => 'İpsiz: her kuş kendi başına uçar';

  @override
  String get duelModeSemantics => '1\'e 1: kuşlar birbiriyle kapışır';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'Oturum kaydedildi · Rekorlar\'da izle';

  @override
  String get coopNewTeamBest => 'Takımın yeni en iyisi!';

  @override
  String get coopWhatATeam => 'Ne takım ama!';

  @override
  String coopPairCaption(String first, String second) {
    return '$first ve $second';
  }

  @override
  String get coopTeamScore => 'TAKIM PUANI';

  @override
  String get coopTeamBest => 'TAKIMIN EN İYİSİ';

  @override
  String get coopNewTeamBestRibbon => 'TAKIMIN YENİ EN İYİSİ!';

  @override
  String get coopStatFlightTime => 'uçuş süresi';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'yıldız',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kapı',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'KANAT ÇIRPMA PAYI';

  @override
  String coopPercent(int percent) {
    return '%$percent';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'O$player çırpış',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'Düello süresi $time';
  }

  @override
  String get duelSeries => 'SERİ';

  @override
  String get duelHeartsLeft => 'kalan kalp';

  @override
  String get duelBoxesOpened => 'açılan kutu';

  @override
  String get duelHitsLanded => 'isabetli vuruş';

  @override
  String get coopPauseSubtitle =>
      'İkiniz de tünekte bekliyorsunuz. Geri sayımla başlarız.';

  @override
  String get coopFinishFlight => 'Uçuşu bitir';

  @override
  String get cameraLabIntro =>
      'Telefonunu yatay ve alçağa, karşına ya da yanına yasla.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'Neredeyse tamam · daha net görünmeli: $parts';
  }

  @override
  String get cameraLabJointShoulder => 'omuz';

  @override
  String get cameraLabJointElbow => 'dirsek';

  @override
  String get cameraLabJointWrist => 'bilek';

  @override
  String get cameraLabJointHip => 'kalça';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => 'Kamera başlatılıyor…';

  @override
  String get cameraLabDenied =>
      'Kamera erişimi kapalı. Uygulama ayarlarından izin ver, sonra tekrar dene.';

  @override
  String cameraLabFailed(String error) {
    return 'Kamera başlatılamadı: $error';
  }

  @override
  String get cameraLabStopped =>
      'Kamera durdu. Yeniden kalibre için Kamerayı başlat\'a dokun.';

  @override
  String get cameraLabBack => 'KAMERA TESTİ · Ana menüye dön';

  @override
  String get cameraLabStepShow => '1. Kollarını ve kalçanı göster';

  @override
  String get cameraLabStepPushUps => '2. İki şınav çek';

  @override
  String get cameraLabStepMove => '3. Kuşunu hareket ettir!';

  @override
  String get cameraLabStepSquat => 'Çömelme aralığını bul';

  @override
  String get cameraLabStepJump => 'Duruş pozisyonunu bul';

  @override
  String get cameraLabPushUpHelp =>
      'Telefon alçakta, karşında ya da yanında.\nKarşıdan mı? İki omzunu, bir kolunu ve kalçanı göster.\nKendi hızında iki kez in ve kalk.';

  @override
  String get cameraLabSquatHelp =>
      'Hareketsiz dur, rahatça çömel ve kısa bir süre bekle, sonra kalk. Alçalmak için çömel; yükselmek için kalk.';

  @override
  String get cameraLabJumpHelp =>
      'Bütün vücudun ve ayakların görünecek şekilde telefona dönük dur. Hareketsiz bekle, sonra küçük zıplamalar yap. Bir zıplama = bir büyük itiş.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'KALİBRASYON\n$done / $total tamam',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'KALİBRASYON\n%$percent tamam';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'KONTROL TESTİ\n$count şınav',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'KONTROL TESTİ\n$count çömelme',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'KONTROL TESTİ\n$count zıplama',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Hz · p95 $ms ms';
  }

  @override
  String get cameraLabStartingButton => 'Başlıyor…';

  @override
  String get cameraLabRecalibrate => 'Yeniden kalibre et';

  @override
  String get cameraLabStartCamera => 'Kamerayı başlat';

  @override
  String get cameraLabTapStart => 'Kamerayı başlat\'a dokun';

  @override
  String cameraLabTry(String mode) {
    return 'Dene: $mode';
  }

  @override
  String get cameraBadgeWaking => 'UYANIYOR';

  @override
  String get cameraBadgeLive => 'CANLI';

  @override
  String get cameraBadgeLockedOn => 'KİLİTLENDİ';

  @override
  String get cameraBadgeOffline => 'KAPALI';

  @override
  String get trackingCatchingUp => 'Kamera yetişmeye çalışıyor';

  @override
  String get trackingStepIntoOutline => 'Vücut çizgisinin içine gir';

  @override
  String get trackingKeepShoulders => 'İki omzun da görünsün';

  @override
  String get trackingShowSide =>
      'Yandan bir omzunu, dirseğini, bileğini ve kalçanı göster';

  @override
  String get trackingMoveCloser => 'Biraz yaklaş';

  @override
  String get trackingGetDown => 'Şınav pozisyonuna geç';

  @override
  String get trackingHandsOnFloor =>
      'Ellerini yere koy, vücudunu arkaya doğru uzat';

  @override
  String get trackingExtendBody =>
      'Vücudunu ellerinin biraz daha gerisine uzat';

  @override
  String get trackingComfortableRange => 'Rahat bir şınav aralığında kal';

  @override
  String get trackingPlaceHands => 'Ellerini yere koy, vücudun arkada kalsın';

  @override
  String get trackingFrontTracked => 'Önden takip ediliyor · ellerin görünsün';

  @override
  String get trackingBodyInView => 'Vücudun görünüyor · yüzün yere bakabilir';

  @override
  String get trackingArmsTracked => 'Kollar takipte · bacak kontrolü sınırlı';

  @override
  String get trackingFindTop => 'Rahat bir üst pozisyon bul';

  @override
  String get trackingCalibrated => 'Kalibre edildi! Kuşunu oynatmayı dene.';

  @override
  String get trackingFreshFrame => 'Yeni bir kare bekleniyor';

  @override
  String get trackingDistanceChanged =>
      'Kamera mesafesi değişti · yeniden kalibre et';

  @override
  String get trackingKeepArm => 'Bir kolun görünsün';

  @override
  String get trackingSquatStepBack =>
      'Omuzların, kalçan, dizlerin ve ayakların görünsün diye geri çekil';

  @override
  String get trackingSquatFaceCamera => 'İki ayağın yerde, kameraya dön';

  @override
  String get trackingSquatControls =>
      'Alçalmak için çömel · yükselmek için kalk';

  @override
  String get trackingStartingDistance =>
      'Başlangıç mesafende kameraya dön · yer değiştirdiysen yeniden kalibre et';

  @override
  String get trackingFeetPlanted => 'İki ayağın da başlangıç yerinde kalsın';

  @override
  String get trackingSquatStandTall =>
      'İki ayağın görünür, dik ve hareketsiz dur';

  @override
  String get trackingStandStill => 'Bir an dik ve hareketsiz dur';

  @override
  String get trackingSquatDepth =>
      'Rahat bir derinliğe çömel ve kısa bir süre bekle';

  @override
  String get trackingSquatHold => 'Rahatça çömel, sonra bir an bekle';

  @override
  String get trackingSquatHoldBriefly =>
      'Bu rahat çömelmede kısa bir süre bekle';

  @override
  String get trackingSquatStandUp => 'Kalibrasyonu bitirmek için yeniden kalk';

  @override
  String get trackingSquatReady =>
      'Hazır! Alçalmak için çömel · yükselmek için kalk';

  @override
  String get trackingJumpStepBack =>
      'Omuzların, kalçan ve iki ayağın görünsün diye geri çekil';

  @override
  String get trackingJumpFaceCamera =>
      'Üstünde zıplayacak yer olsun, kameraya dönük dur';

  @override
  String get trackingJumpSmall =>
      'Küçük zıplamalar yeter · tekrar zıplamadan önce yere in';

  @override
  String get trackingJumpStandStill =>
      'Bütün vücudun ve iki ayağın görünür, hareketsiz dur';

  @override
  String get trackingJumpReady => 'Hazır! Bir küçük zıplama, bir büyük itiş.';

  @override
  String get trackingFindPosition => 'Pozisyonunu al';

  @override
  String get trackingInterrupted => 'Takip kesildi';

  @override
  String get trackingCameraInterrupted =>
      'Kamera kesildi. Kamera iznini kontrol edip tekrar dene.';

  @override
  String get trackingCameraAway => 'Uygulamadan çıkınca kamera durdu';

  @override
  String get trackingJumpBoost => 'Büyük itiş için zıpla';

  @override
  String get trackingJumpLand => 'Sonraki zıplama için yere in';

  @override
  String trackingLowerMore(int step, int total) {
    return 'Biraz daha alçal · $step / $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'Rahatça alçal · $step / $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'Tekrar yukarı kalk · $step / $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'İlk rahat aralığını yakala · $step / $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Bu değişiklik kaydedilemedi. Lütfen tekrar dene. ($error)';
  }

  @override
  String get commonDelete => 'Sil';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız daha',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'Yuvan biraz zaman istiyor.';

  @override
  String get homeSettings => 'Ayarlar';

  @override
  String homeGreetingFirst(String bird) {
    return 'Merhaba, ben $bird! Uçmaya hazır mısın?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Macera tamam! $bird gurur duyuyor.',
      'female': 'Macera tamam! $bird gurur duyuyor.',
      'other': 'Macera tamam! $bird gurur duyuyor.',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird hazır. Ya sen?',
      'female': '$bird hazır. Ya sen?',
      'other': '$bird hazır. Ya sen?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'SONSUZ';

  @override
  String get homeEndlessDetail => 'Gidebildiğin kadar uç';

  @override
  String get homeEndlessSemantics => 'Sonsuz. Gidebildiğin kadar uç.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: 'Sonsuz. Gidebildiğin kadar uç. En iyi: $best yıldız.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'En iyi';

  @override
  String get homeBestNone => 'İlk rekorunu koy';

  @override
  String get homeCampaignTitle => 'KAMPANYA';

  @override
  String get homeCampaignDone => 'Her mektup teslim edildi';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Kampanya. Sıradaki: $level. $total üzerinden $stars yıldız.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other:
          'Kampanya. Her mektup teslim edildi. $total üzerinden $stars yıldız.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'MİNİ OYUNLAR';

  @override
  String get homeMiniGamesDetail => 'Egzersiz · 2 oyuncu';

  @override
  String get homeMiniGamesSemantics =>
      'Mini oyunlar. Şınav, çömelme, zıplama ya da iki oyuncu.';

  @override
  String get homeBuilderTitle => 'SEVİYE ATÖLYESİ';

  @override
  String get homeBuilderDetail => 'Yap · uç · paylaş';

  @override
  String get homeBuilderSemantics =>
      'Seviye Atölyesi. Kendi seviyelerini yap, uç ve paylaş.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uçuş sonra açılır',
      one: '1 uçuş sonra açılır',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seviye Atölyesi. Kilitli. $count uçuş sonra açılır.',
      one: 'Seviye Atölyesi. Kilitli. 1 uçuş sonra açılır.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'Macera';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Bugünün macerası. 3 hedeften $done tanesi tamam.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'Kuşlar';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'Kuşlar. $bird ile uçuyorsun.';
  }

  @override
  String get homeDockUpgrades => 'Geliştirme';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Geliştirmeler. Harcanacak $stars yıldız.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'Pasaport';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Pasaport. $total üzerinden $earned madalya.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'Rekorlar';

  @override
  String get homeMiniGamesPickerTitle => 'Mini oyunlar';

  @override
  String get homeMiniGamesPickerIntro =>
      'Hareket ederek uç ya da telefonu bir arkadaşınla paylaş.';

  @override
  String get homeMiniGamesCloseSemantics => 'Mini oyunları kapat';

  @override
  String get homeMiniGamesPushUpCard => 'İn, kuşun dalsın.\nKalk, havalansın.';

  @override
  String get homeMiniGamesSquatCard => 'Çömel, alçal.\nKalk, havalan.';

  @override
  String get homeMiniGamesJumpCard => 'Zıpla, yüksel.\nSüzül, yıldız topla.';

  @override
  String get homeMiniGamesCoopCard =>
      'İki oyuncu, tek telefon.\nTakım ol ya da kapış.';

  @override
  String get homeMiniGamesCamera => 'Kamera';

  @override
  String get homeMiniGamesPlayers => '2 oyuncu';

  @override
  String get homeMiniGamesCoop => 'Birlikte Uç';

  @override
  String get birdsTitle => 'Uçuş ekibinle tanış.';

  @override
  String birdsFlownTag(int flown, int total) {
    return 'UÇULAN: $flown/$total';
  }

  @override
  String get birdsStatusCopilot => 'YARDIMCI PİLOTUN';

  @override
  String get birdsStatusReady => 'UÇMAYA HAZIR';

  @override
  String get birdsStatusLocked => 'KİLİTLİ';

  @override
  String get birdsNotFlown => 'Henüz uçulmadı';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uçuş',
      one: '1 uçuş',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return '$bird ile uç';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return '$current yerine $bird ile uç';
  }

  @override
  String birdsUnlock(String bird) {
    return 'Kilidi aç: $bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird için kilidi aç, $price yıldız',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird için kilidi aç, $price yıldız, henüz yeterli yıldız yok',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'Seninle uçuyor';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, seninle uçuyor';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, seninle uçuyor, yeni';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, kilitli, $price yıldız',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird, yeni';
  }

  @override
  String get birdsTagFlying => 'UÇUYOR';

  @override
  String get birdsTagNew => 'YENİ';

  @override
  String get bird_0_description => 'Küçük kuş. Koca gök.';

  @override
  String get bird_0_trail => 'Güneş baloncukları';

  @override
  String get bird_1_description => 'Al yanaklar, kıvırcık tepe, kocaman yürek.';

  @override
  String get bird_1_trail => 'Şeftali kalpler';

  @override
  String get bird_2_description => 'Minik sinekkuşu. Taze nane. Tam gaz.';

  @override
  String get bird_2_trail => 'Nane yaprakları';

  @override
  String get bird_3_description =>
      'Yıldız ışığında uçan hayalperest bir baykuş.';

  @override
  String get bird_3_trail => 'Yıldız tozu pırıltısı';

  @override
  String get upgradesWalletLabel => 'KUMBARAN';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Harcanacak $stars yıldız',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'Kuşunu güçlendir.';

  @override
  String get upgradesIntro =>
      'Ne işe yaradığını görmek için bir dişliye dokun. Uçarken topladığın her yıldız harcanabilir.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other:
          '$power, seviye $level, en yüksek $max. Sonraki seviye $cost yıldız',
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
          '$power, seviye $level, en yüksek $max. Sonraki seviye $cost yıldız, henüz yetmiyor',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, seviye $level, en yüksek $max. Zirvede';
  }

  @override
  String get upgradesMax => 'MAKS';

  @override
  String upgradesLevel(int level) {
    return 'Seviye $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'Seviye $level, zirve';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now, sonraki seviye $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '%$value';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value sn';
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
      other: 'Geriye $count yıldızın kalacak.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'Geliştir';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost yıldıza geliştir',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost yıldıza geliştir, henüz yeterli yıldız yok',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'En üst seviyede';

  @override
  String get power_shot_name => 'Atış gücü';

  @override
  String get power_shot_blurb =>
      'Daha büyük, daha sert bir taş için Ateş\'i basılı tut.';

  @override
  String get power_sprint_name => 'Sprint';

  @override
  String get power_sprint_blurb =>
      'Yolundaki düşmanları dağıtan bir hız patlaması.';

  @override
  String get power_shield_name => 'Kalkan';

  @override
  String get power_shield_blurb =>
      'Bir darbeyi senin yerine karşılar. Uçarken yıldız toplayıp doldur.';

  @override
  String get power_magnet_name => 'Mıknatıs';

  @override
  String get power_magnet_blurb =>
      'Kapılardan kusursuz geçerek kazan. Yıldızları sana çeker.';

  @override
  String get power_stat_maxCharge => 'En yüksek dolum';

  @override
  String get power_stat_burstLength => 'Patlama süresi';

  @override
  String get power_stat_cooldown => 'Bekleme süresi';

  @override
  String get power_stat_starsToRefill => 'Dolum için yıldız';

  @override
  String get power_stat_safeTime => 'Kırılınca güvenli süre';

  @override
  String get power_stat_perfectGates => 'Gereken kusursuz geçiş';

  @override
  String get power_stat_lasts => 'Süre';

  @override
  String get power_stat_reach => 'Menzil';

  @override
  String get passportTitle => 'Gök pasaportun.';

  @override
  String get passportDailyCard => 'Günlük kart';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total MADALYA';
  }

  @override
  String get passportIntro =>
      'Küçük maceralar. Kalıcı hatıralar. Her damga için bronz, gümüş ve altın.';

  @override
  String get passportNoMedal => 'Henüz madalya yok';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Bronz madalya',
      'silver': 'Gümüş madalya',
      'other': 'Altın madalya',
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
    return '$stamp. $held. Sıradaki, $next: $goal $target üzerinden $current.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. Altın madalya. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'BRONZA',
      'silver': 'GÜMÜŞE',
      'other': 'ALTINA',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'DAMGALANDI';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: henüz yok';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'Bronz';

  @override
  String get passportMedal_silver => 'Gümüş';

  @override
  String get passportMedal_gold => 'Altın';

  @override
  String get stamp_frequentFlyer_name => 'Sık uçan yolcu';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n puanlı uçuş bitir.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'Tam on ikiden';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nişan noktaları boyunca $n kusursuz geçiş yap.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'Yıldız avcısı';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n yıldız topla.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => 'Takımyıldız';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hiç kesmeden tek seride $n yıldız topla.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'Gök kaptanı';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tek bir sonsuz uçuşta $n puan yap.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'Öncü';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n sonsuz uçuşta en az 60 saniye uç.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'Hep birlikte';

  @override
  String get stamp_allRounder_name => 'Her telden';

  @override
  String get stamp_flockTogether_goalBronze =>
      'Puanlı uçuşlara iki farklı kuşla çık.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'Puanlı uçuşlara dört kuşla da çık.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Her kuşla $n puanlı uçuş yap.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'Bir şınav, çömelme ya da zıplama mini oyununda uç.';

  @override
  String get stamp_allRounder_goalSilver =>
      'Üç mini oyunun hepsinde uç: şınav, çömelme, zıplama.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Her mini oyunda $n puanlı uçuş yap.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals madalya · seviye $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'Maceran biraz zaman istiyor.';

  @override
  String get dailyTitle => 'Bugünün küçük macerası.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · $done/3 HEDEF';
  }

  @override
  String get dailyIntro =>
      'Üç hedef. İstediğin kontrol. Tek bir sonsuz uçuş üçüne de sayılır.';

  @override
  String get dailyLaunchEndless => 'Sonsuz';

  @override
  String get dailyPostcardKicker => 'GÖK KULÜBÜ KARTPOSTALI';

  @override
  String get dailyStamped => 'KARTPOSTAL DAMGALANDI!';

  @override
  String dailyGoalsComplete(int done) {
    return '$done / 3 HEDEF TAMAM';
  }

  @override
  String get dailyDoneNote => 'Küçük bir macera, tamamen senin.';

  @override
  String get dailyOpenNote => 'Kartı damgalamak için üçünü de bitir.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal Tamamlandı';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $target üzerinden $current';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: Kartpostal damgalandı';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: $done/3 hedef';
  }

  @override
  String get dailyNoStreak => 'Yeni hedefler. Kaybedecek seri yok.';

  @override
  String get dailyTheme_0 => 'Şafak teslimatı';

  @override
  String get dailyTheme_1 => 'Şeftali pikniği';

  @override
  String get dailyTheme_2 => 'Mehtaplı mektup';

  @override
  String get dailyTheme_3 => 'Bulut geçidi';

  @override
  String get dailyTheme_4 => 'Alacakaranlık hazinesi';

  @override
  String get dailyTheme_5 => 'Bahçe partisi';

  @override
  String get task_flights_title => 'Kanatlarını aç';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count puanlı uçuş bitir.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'Açık ufuklar';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugünkü puanlı uçuşlarda $count kapı geç.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'Cep dolusu yıldız';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugünkü uçuşlarda $count yıldız topla.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'Işıltıyı koru';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hiç kesmeden tek seride $count yıldız topla.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'Tam isabet';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count kusursuz geçiş yap.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'Yolun tamamı';

  @override
  String get task_finishTrail_goal =>
      'Tek bir sonsuz uçuşta en az 60 saniye uç.';

  @override
  String get recordsTitle => 'Küçük zaferlerin.';

  @override
  String get recordsBestsTitle => 'Geçilecek yıldız puanların';

  @override
  String get recordsSectionMain => 'ANA OYUN';

  @override
  String get recordsSectionMini => 'MİNİ OYUNLAR';

  @override
  String get recordsEndless => 'Sonsuz · Dokun ve Uç';

  @override
  String get recordsCampaignStars => 'Kampanya yıldızları';

  @override
  String recordsCoopName(String mode) {
    return 'Birlikte Uç · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'puanlı uçuş',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kapı',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'takım uçuşu',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'düello',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şınav',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'çömelme',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'Son uçuşlar';

  @override
  String get recordsEmptyTitle => 'Koca gök. Temiz bir sayfa.';

  @override
  String get recordsEmptyBody => 'İlk puanlı uçuşun hikâyeyi başlatır.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds sn';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'Klasik · $date · $seconds sn';
  }

  @override
  String get replaySavedSessions => 'Kayıtlı oturumlar';

  @override
  String get replayBackToRecordsSemantics => 'Rekorlar\'a dön';

  @override
  String get replaySessionsLoadFailed => 'Oturumlar yüklenemedi. Tekrar dene';

  @override
  String get replayEmptyTitle => 'Uçuşlarının yeri burası';

  @override
  String get replayEmptyBody =>
      'Burada izlemek için uçuştan sonra oturumu kaydet.';

  @override
  String get replayEmptyButton => 'Bir uçuş seç';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds sn · $score yıldız puanı',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds sn · $score kapı',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'Oturumu sil';

  @override
  String get replayDeleteTitle => 'Bu oturum silinsin mi?';

  @override
  String get replayDeleteBody =>
      'Kamera videosu ve tekrar silinecek. Puanların Rekorlar\'da kalır.';

  @override
  String get replayDeleteFailed => 'Oturum silinemedi. Tekrar dene.';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return 'Seviye $id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · Sonsuz';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · Antrenman';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · Sonsuz · Antrenman';
  }

  @override
  String get replayOpenFailed => 'Bu oturum açılamadı.';

  @override
  String get replayBackToSessions => 'Oturumlara dön';

  @override
  String get replayCameraPaused => 'Oturumun bu kısmında kamera durdurulmuştu';

  @override
  String get replayCameraUnavailable => 'Kamera klibi yok · Oyun yine oynar';

  @override
  String get replayCameraLoading => 'Kamera yükleniyor…';

  @override
  String get replayPaused => 'Biraz soluklanıyor';

  @override
  String get replayHideControlsSemantics => 'Tekrar kontrollerini gizle';

  @override
  String get replayShowControlsSemantics => 'Tekrar kontrollerini göster';

  @override
  String get replayBackToSavedSemantics => 'Kayıtlı oturumlara dön';

  @override
  String get replayTitle => 'TEKRAR';

  @override
  String replayTitleSession(String session) {
    return 'TEKRAR · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'Puan: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts kalp',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'O1 $p1 · O2 $p2 kalp · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '${seconds}sn';
  }

  @override
  String replayMagnet(int seconds) {
    return 'Mıknatıs ${seconds}s';
  }

  @override
  String get replayPauseSemantics => 'Tekrarı duraklat';

  @override
  String get replayPlaySemantics => 'Tekrarı oynat';

  @override
  String get replayRestartSemantics => 'Tekrarı baştan başlat';

  @override
  String get replayBack5Semantics => '5 saniye geri';

  @override
  String get replayForward5Semantics => '5 saniye ileri';

  @override
  String get replayHighlightsFinding => 'Öne çıkan anlar bulunuyor';

  @override
  String get replayHighlightsNone => 'Öne çıkan an yok';

  @override
  String get replayHighlights => 'Öne çıkan anlar';

  @override
  String get replayHighlightsCloseSemantics => 'Öne çıkan anları kapat';

  @override
  String get replayHighlightsHint => 'Bir an seç. Hemen öncesinden izle.';

  @override
  String get replayViewCorner => 'Köşede kamera';

  @override
  String get replayViewBackground => 'Arka planda kamera';

  @override
  String get replayViewGameplay => 'Yalnızca oyun';

  @override
  String get replayMoveCornerSemantics => 'Kamera köşesini taşı';

  @override
  String get replayMuteRecordedSemantics => 'Kaydedilen sesi kapat';

  @override
  String get replayUnmuteRecordedSemantics => 'Kaydedilen sesi aç';

  @override
  String get replayMuteGameSemantics => 'Oyun sesini kapat';

  @override
  String get replayUnmuteGameSemantics => 'Oyun sesini aç';

  @override
  String get replayFullScreenSemantics => 'Kontrolleri gizle / tam ekran';

  @override
  String get replayMomentTakeoff => 'Kalkış';

  @override
  String get replayMomentTakeoffDetail => 'Gökyüzü senin.';

  @override
  String get replayMomentMagnet => 'Yıldız mıknatısı';

  @override
  String get replayMomentMagnetDetail =>
      'Üç kusursuz geçiş yıldızları yaklaştırır.';

  @override
  String get replayMomentStarTrio => 'İlk yıldız üçlüsü';

  @override
  String get replayMomentStarTrioDetail =>
      'Üç yıldız bir takımyıldız oldu. +5 puan!';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'Gruptaki her yıldız toplandı. +5 puan!';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier× yıldız gücü';
  }

  @override
  String get replayMomentStreakDetail => 'Pırıl pırıl bir yıldız serisi.';

  @override
  String get replayMomentShield => 'Kalkan korudu';

  @override
  String get replayMomentShieldDetail => 'Kıl payı, bir şans daha.';

  @override
  String get replayMomentPerfect => 'İlk kusursuz geçiş';

  @override
  String get replayMomentPerfectDetail => 'Tam nişan noktasından.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kapı geçildi',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'Göğün biraz daha derinine.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Tek çizik yok. +$points puan!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Sprint halkalarıyla kurtuluş. +$points puan!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'Borayı atlattın';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Uçan çerçöpten kaçtın. +$points puan!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'Rota tamam';

  @override
  String get replayMomentFinal => 'Son an';

  @override
  String get replayMomentCompleteDetail => 'Rotanın sonuna ulaştın.';

  @override
  String get replayMomentCollisionDetail => 'Son yaklaşmayı izle.';

  @override
  String get replayMomentEndDetail => 'Bu uçuşun sonu.';
}
