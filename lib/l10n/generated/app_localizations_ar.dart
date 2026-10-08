// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonTryAgain => 'حاول مجددًا';

  @override
  String get languageKeyLabel => 'اللغة';

  @override
  String languageKeySemantics(String language) {
    return 'اللغة: $language. غيّر لغة اللعبة.';
  }

  @override
  String get languageSystemDefault => 'لغة الهاتف';

  @override
  String languageSystemDetail(String language) {
    return 'حسب لغة هاتفك: $language';
  }

  @override
  String get languageCurrent => 'اللغة الحالية';

  @override
  String get languageName_en => 'الإنجليزية';

  @override
  String get languageName_es_419 => 'إسبانية أمريكا اللاتينية';

  @override
  String get languageName_pt_br => 'البرتغالية (البرازيل)';

  @override
  String get languageName_id => 'الإندونيسية';

  @override
  String get languageName_fr => 'الفرنسية';

  @override
  String get languageName_de => 'الألمانية';

  @override
  String get languageName_ja => 'اليابانية';

  @override
  String get languageName_ko => 'الكورية';

  @override
  String get languageName_tr => 'التركية';

  @override
  String get languageName_zh_hant => 'الصينية التقليدية';

  @override
  String get languageName_ru => 'الروسية';

  @override
  String get languageName_ar => 'العربية';

  @override
  String get voicePackReady => 'الأصوات جاهزة';

  @override
  String get voicePackDownload => 'نزّل الأصوات';

  @override
  String voicePackDownloading(int percent) {
    return 'الأصوات $percent%';
  }

  @override
  String get voicePackStarting => 'تنزيل الأصوات…';

  @override
  String get voicePackEnglish => 'أصوات إنجليزية';

  @override
  String get voicePackFailed => 'تعذّر التنزيل';

  @override
  String get settingsTitle => 'البيت بيتك.';

  @override
  String get settingsSectionSound => 'الصوت';

  @override
  String get settingsSectionComfort => 'الراحة';

  @override
  String get settingsMusicTitle => 'موسيقى نادي السماء';

  @override
  String get settingsMusicDetail => 'ألحان القوائم والمغامرة والزعماء.';

  @override
  String get settingsEffectsTitle => 'المؤثرات الصوتية';

  @override
  String get settingsEffectsDetail =>
      'أصوات الطيران والقتال والجوائز والقوائم.';

  @override
  String get settingsVoicesTitle => 'أصوات الشخصيات';

  @override
  String get settingsVoicesDetail =>
      'مشاهد القصة وبطاقات الشكر وصيحات الانطلاق.';

  @override
  String get settingsReducedMotionTitle => 'تقليل الحركة';

  @override
  String get settingsReducedMotionDetail => 'قوائم أهدأ ومؤثرات زخرفية أقل.';

  @override
  String get settingsSwitchOn => 'يعمل';

  @override
  String get settingsSwitchOff => 'مطفأ';

  @override
  String get settingsUnavailable => 'إعداداتك تحتاج إلى لحظة.';

  @override
  String get settingsPrivacyKicker => 'على جهازك. دائمًا.';

  @override
  String get settingsPrivacyTitle => 'كاميرتك تبقى لك.';

  @override
  String get settingsPrivacyBody =>
      'الفيديو وصوت الميكروفون الاختياري يبقيان على هذا الهاتف. المقاطع غير المحفوظة تُحذف. لا يُرفع شيء.';

  @override
  String get settingsCameraLab => 'مختبر الكاميرا والتتبّع';

  @override
  String get settingsAbout => 'حول اللعبة والتراخيص';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'حول اللعبة والتراخيص، الإصدار $version';
  }

  @override
  String get settingsReset => 'مسح التقدّم المحلي';

  @override
  String settingsResetDone(String bird) {
    return 'بداية جديدة. $bird بانتظارك.';
  }

  @override
  String get settingsResetTitle => 'أتبدأ مغامرة جديدة؟';

  @override
  String get settingsResetBody =>
      'يحذف هذا من الهاتف فيديوهاتك المحفوظة، وإعادات العرض، والنقاط، والجولات، والمراحل التي صنعتها، والإعدادات. لا يمكن التراجع عن ذلك.';

  @override
  String get settingsResetBodyCloud =>
      'يحذف هذا من الهاتف فيديوهاتك المحفوظة، وإعادات العرض، والنقاط، والجولات، والمراحل التي صنعتها، والإعدادات، وحفظك السحابي في ألعاب Play. لا يمكن التراجع عن ذلك.';

  @override
  String get settingsResetConfirm => 'امسح كل شيء';

  @override
  String get settingsResetKeep => 'احتفظ بتقدّمي';

  @override
  String get playGamesName => 'ألعاب Play';

  @override
  String get playGamesConnected => 'متّصل';

  @override
  String get playGamesNotConnected => 'غير متّصل';

  @override
  String get playGamesConnecting => 'جارٍ الاتصال…';

  @override
  String get playGamesConnectFailed => 'تعذّر الاتصال';

  @override
  String get playGamesIdle => 'حفظ سحابي وإنجازات';

  @override
  String get playGamesSaving => 'جارٍ الحفظ في السحابة…';

  @override
  String get playGamesOfflineUnsaved => 'بلا إنترنت · لم يُحفظ بعد';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'بلا إنترنت · حُفظ $ago';
  }

  @override
  String get playGamesUpdateNeeded => 'حدّث Beakbound للمزامنة';

  @override
  String get playGamesUnreadable => 'تعذّرت قراءة الحفظ السحابي';

  @override
  String get playGamesOn => 'الحفظ السحابي مفعّل';

  @override
  String get playGamesResetElsewhere => 'أُعيد الضبط على هاتف آخر';

  @override
  String playGamesRestored(String ago) {
    return 'استُعيد من السحابة · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'حُفظ في السحابة · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'إنجازات ألعاب Play';

  @override
  String get playGamesConnectSemantics => 'الاتصال بألعاب Play';

  @override
  String get playGamesAchievements => 'الإنجازات';

  @override
  String get playGamesConnect => 'اتّصل';

  @override
  String get timeAgoJustNow => 'قبل قليل';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'منذ $minutes د',
      many: 'منذ $minutes د',
      few: 'منذ $minutes د',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
      zero: 'قبل قليل',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'منذ $hours س',
      many: 'منذ $hours س',
      few: 'منذ $hours س',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
      zero: 'قبل قليل',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'منذ $days ي',
      many: 'منذ $days ي',
      few: 'منذ $days ي',
      two: 'منذ يومين',
      one: 'منذ يوم',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => 'حياة إضافية!';

  @override
  String calloutStarTrio(int points) {
    return 'ثلاث نجوم ‎+$points!';
  }

  @override
  String get calloutNiceShot => 'رمية رائعة!';

  @override
  String calloutNiceShotPoints(int points) {
    return 'رمية رائعة ‎+$points!';
  }

  @override
  String get calloutSmash => 'تحطيم!';

  @override
  String calloutSmashPoints(int points) {
    return 'تحطيم ‎+$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return 'تحطيم ‎×$count!';
  }

  @override
  String get calloutBossDown => 'سقط الزعيم!';

  @override
  String calloutBossDownPoints(int points) {
    return 'سقط الزعيم ‎+$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return 'قوة النجوم ‎×$multiplier!';
  }

  @override
  String get calloutPerfect => 'مثالي!';

  @override
  String calloutPerfectChain(int count) {
    return 'مثالي ‎×$count';
  }

  @override
  String get calloutShieldReady => 'الدرع جاهز';

  @override
  String get calloutShieldSave => 'الدرع حماك!';

  @override
  String get calloutKeepFlying => 'تابع الطيران!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بوابة!',
      many: '$count بوابة!',
      few: '$count بوابات!',
      two: 'بوابتان!',
      one: 'بوابة واحدة!',
      zero: '$count بوابة!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'بقيت $seconds ثانية',
      many: 'بقيت $seconds ثانية',
      few: 'بقيت $seconds ثوانٍ',
      two: 'بقيت ثانيتان',
      one: 'بقيت ثانية واحدة',
      zero: 'بقيت $seconds ثانية',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => 'مغناطيس النجوم';

  @override
  String get calloutSprintRing => 'حلقة الانطلاق!';

  @override
  String calloutRushChain(int count) {
    return 'اندفاعة ‎×$count';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'نيزك ‎+$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return 'خفاش ‎+$points!';
  }

  @override
  String get calloutScorched => 'لسعة نار!';

  @override
  String get region_jungle => 'الأدغال';

  @override
  String get region_antarctica => 'أنتاركتيكا';

  @override
  String get region_aztec => 'بلاد الأزتيك';

  @override
  String get region_paris => 'باريس';

  @override
  String get region_egypt => 'مصر';

  @override
  String get region_cyberpunk => 'مدينة السايبربانك';

  @override
  String get region_china => 'الصين';

  @override
  String get region_brazil => 'البرازيل';

  @override
  String get region_newYork => 'نيويورك';

  @override
  String get region_arabia => 'بلاد العرب القديمة';

  @override
  String get region_rome => 'روما القديمة';

  @override
  String get region_mexico => 'المكسيك';

  @override
  String get region_sea => 'عرض البحر';

  @override
  String get boss_baronBat_name => 'البارون وطواط';

  @override
  String get boss_spitterBeetle_name => 'الملك البصّاق';

  @override
  String get boss_duskMoth_name => 'إمبراطورة الغسق';

  @override
  String get boss_pirate_name => 'قبطان القراصنة';

  @override
  String get boss_dragon_name => 'تنين الجمر';

  @override
  String get boss_kingCoo_name => 'الملك كوكو';

  @override
  String get boss_searchlightGargoyle_name => 'الغرغول الكشّاف';

  @override
  String get boss_neferhoo_name => 'نِفِرهو';

  @override
  String get bird_0_name => 'بيب';

  @override
  String get bird_1_name => 'بيتشيز';

  @override
  String get bird_2_name => 'مينتي';

  @override
  String get bird_3_name => 'أوربِت';

  @override
  String get playMode_pushUp => 'طيران بالضغط';

  @override
  String get playMode_jump => 'اقفز وطِر';

  @override
  String get playMode_touch => 'انقر وطِر';

  @override
  String get playMode_squat => 'اقرفص وطِر';

  @override
  String get chapter_1_route => 'خط قمم الأشجار';

  @override
  String get chapter_1_postmark => 'خط قمم الأشجار';

  @override
  String get chapter_1_postcard =>
      'الرسائل تحطّ في قمم الأشجار من جديد! طيور الطوقان تقول شكرًا (بصوت عالٍ جدًا). وتاج البارون وطواط يزيّن رفّنا.';

  @override
  String get chapter_1_postscript =>
      'رائحة الطريق القديم توحي بأن شيئًا ما يغلي.';

  @override
  String get chapter_2_route => 'الطريق القديم';

  @override
  String get chapter_2_postmark => 'الطريق القديم';

  @override
  String get chapter_2_postcard =>
      'القوافل تسير من جديد، ولم يعد يغلي شيء سوى شاي النعناع. واحتفظنا بتاج القارورة الملكي مزهريةً.';

  @override
  String get chapter_2_postscript =>
      'انطفأت مصابيح المدينة ليلة أمس. أحضر معك ضوءًا.';

  @override
  String get chapter_3_route => 'خط المصابيح';

  @override
  String get chapter_3_postmark => 'خط المصابيح';

  @override
  String get chapter_3_postcard =>
      'المصابيح مضاءة، وبريد الليل مستيقظ تمامًا! باريس ترسل لك كرواسون، ونيويورك ترسل بريتزل.';

  @override
  String get chapter_3_postscript => 'أجراس الميناء توقفت عن الرنين.';

  @override
  String get chapter_4_route => 'خط المدّ';

  @override
  String get chapter_4_postmark => 'خط المدّ';

  @override
  String get chapter_4_postcard =>
      'أجراس الميناء ترنّ للرسائل من جديد، لا للمدافع. الببغاء بقي معنا، ويقول لك: مرحبًا.';

  @override
  String get chapter_4_postscript => 'يقولون إن السماء عند حافة الخريطة تشتعل.';

  @override
  String get chapter_5_route => 'حافة الخريطة';

  @override
  String get chapter_5_postmark => 'حافة الخريطة';

  @override
  String get chapter_5_postcard =>
      'السماء صافية من القطب إلى القطب، وكل الخطوط تعمل. نادي السماء كله فخور بك.';

  @override
  String get chapter_5_postscript =>
      'السماء التي لا تنتهي ما زالت هناك، متى شئت.';

  @override
  String get level_1_1_name => 'التوصيلة الأولى';

  @override
  String get level_1_1_cargo => 'بطاقة عيد ميلاد لتوأمَي الطوقان';

  @override
  String get level_1_1_sender => 'توأما الطوقان';

  @override
  String get level_1_1_hint => 'انقر لترفرف. طِر عبر النجوم.';

  @override
  String get level_1_2_name => 'سلسلة النجوم';

  @override
  String get level_1_2_cargo => 'خرائط نجوم لراصد النجوم الكسلان';

  @override
  String get level_1_2_sender => 'الكسلان راصد النجوم';

  @override
  String get level_1_2_hint =>
      'اجمع سلسلة نجوم لتحصل على ‎×3، وثلاث بوابات مثالية تمنحك مغناطيسًا.';

  @override
  String get level_1_3_name => 'دورية الخفافيش';

  @override
  String get level_1_3_cargo => 'مصابيح ليلية لحضانة اليراعات';

  @override
  String get level_1_3_sender => 'حضانة اليراعات';

  @override
  String get level_1_3_hint => 'الرمي: انقر على «ارمِ» لتُسقط الخفافيش.';

  @override
  String get level_1_4_name => 'سماء الكرنفال';

  @override
  String get level_1_4_cargo => 'أوشحة ريش لموكب الكرنفال';

  @override
  String get level_1_4_sender => 'ببغاوات السامبا';

  @override
  String get level_1_4_hint => 'ريح عاتية! راقب علامة ! وتفادَ كرات القدم.';

  @override
  String get level_1_5_name => 'البريد السريع';

  @override
  String get level_1_5_cargo => 'دعوة عاجلة لقائد الطبول';

  @override
  String get level_1_5_sender => 'قائد الطبول';

  @override
  String get level_1_5_hint => 'الانطلاقة تحطّم الخفافيش وتندفع بك إلى الأمام.';

  @override
  String get level_1_6_name => 'درجات المعبد';

  @override
  String get level_1_6_cargo => 'حبوب كاكاو لطهاة المعبد';

  @override
  String get level_1_6_sender => 'طهاة المعبد';

  @override
  String get level_1_7_name => 'مَبيت الشروق';

  @override
  String get level_1_7_cargo => 'مزولة شمسية لحارس الفجر';

  @override
  String get level_1_7_sender => 'حارس الفجر';

  @override
  String get level_1_8_name => 'البارون وطواط';

  @override
  String get level_1_8_cargo => 'إنذار نهائي للبارون وطواط';

  @override
  String get level_1_8_sender => 'البارون وطواط';

  @override
  String get level_2_1_name => 'طريق الخنافس';

  @override
  String get level_2_1_cargo => 'أكاليل غار لمتسابقي العربات';

  @override
  String get level_2_1_sender => 'متسابقو العربات';

  @override
  String get level_2_1_hint => 'الخنافس تبصق البذور. أسقِط البذور بالرمي.';

  @override
  String get level_2_2_name => 'البوابات المسدودة';

  @override
  String get level_2_2_cargo => 'إزميل جديد لنحّات التماثيل';

  @override
  String get level_2_2_sender => 'نحّات التماثيل';

  @override
  String get level_2_2_hint =>
      'اضغط مطولًا على «ارمِ» لترمي حجرًا كبيرًا يكسر الحجارة.';

  @override
  String get level_2_3_name => 'سباق الحريق';

  @override
  String get level_2_3_cargo => 'دلاء ماء لفرقة الإطفاء';

  @override
  String get level_2_3_sender => 'فرقة الإطفاء';

  @override
  String get level_2_3_hint => 'طِر عبر الحلقات الذهبية لتسبق الحريق!';

  @override
  String get level_2_4_name => 'منعطفات النيل';

  @override
  String get level_2_4_cargo => 'كتاب ألغاز جديدة لأبي الهول';

  @override
  String get level_2_4_sender => 'أبو الهول';

  @override
  String get level_2_5_name => 'سقوط السماء';

  @override
  String get level_2_5_cargo => 'تلسكوب لفلكيّ الهرم';

  @override
  String get level_2_5_sender => 'فلكيّ الهرم';

  @override
  String get level_2_5_hint => 'انطلاقات الحلقات تحطّم النيازك.';

  @override
  String get level_2_6_name => 'يُعاد إلى المُرسِل';

  @override
  String get level_2_6_cargo => 'منفضة ريش لحارسة الهرم';

  @override
  String get level_2_6_sender => 'حارسة الهرم';

  @override
  String get level_2_6_hint =>
      'أصِب رسائله بالحجارة لتعيدها إليه. يُعاد إلى المُرسِل!';

  @override
  String get level_2_7_name => 'سوق الفوانيس';

  @override
  String get level_2_7_cargo => 'زيت مصابيح لباعة الفوانيس';

  @override
  String get level_2_7_sender => 'باعة الفوانيس';

  @override
  String get level_2_8_name => 'القافلة الطويلة';

  @override
  String get level_2_8_cargo => 'قوارير ماء للقافلة الطويلة';

  @override
  String get level_2_8_sender => 'قائد القافلة';

  @override
  String get level_2_9_name => 'الملك البصّاق';

  @override
  String get level_2_9_cargo => 'أمر بوقف الغليان للملك البصّاق';

  @override
  String get level_2_9_sender => 'الملك البصّاق';

  @override
  String get level_3_1_name => 'فراشات الضوء';

  @override
  String get level_3_1_cargo => 'مصابيح كهربائية لسقيفة المسرح';

  @override
  String get level_3_1_sender => 'مدير المسرح';

  @override
  String get level_3_1_hint => 'الفراشات تطلق مراوح من ثلاث. انسلّ بينها.';

  @override
  String get level_3_2_name => 'عجلات تحت المطر';

  @override
  String get level_3_2_cargo => 'مظلات لحمام كشك الجرائد';

  @override
  String get level_3_2_sender => 'حمام كشك الجرائد';

  @override
  String get level_3_2_hint => 'حمام الأزقّة ينقضّ ليخطف النجوم. أسقِطه أولًا!';

  @override
  String get level_3_3_name => 'زقاق البخار';

  @override
  String get level_3_3_cargo => 'بريتزل ساخن لسائقي الأجرة الليليين';

  @override
  String get level_3_3_sender => 'سائقو الأجرة الليليون';

  @override
  String get level_3_3_hint =>
      'فتحات البخار تفحّ ثم تنفجر. اقفز فوق الساخنة، واركب اللطيفة.';

  @override
  String get level_3_4_name => 'إنذار عاصفة';

  @override
  String get level_3_4_cargo => 'دوّارة رياح لأعلى برج';

  @override
  String get level_3_4_sender => 'حارس البرج';

  @override
  String get level_3_4_hint =>
      'ابقَ بعيدًا عن الضوء. أصِب المصباح حين ينفتح! لا انطلاقة هنا.';

  @override
  String get level_3_5_name => 'الأسطح البلورية';

  @override
  String get level_3_5_cargo => 'كرواسون لرسّامي الأسطح';

  @override
  String get level_3_5_sender => 'رسّامو الأسطح';

  @override
  String get level_3_6_name => 'بعد الريح العاتية';

  @override
  String get level_3_6_cargo => 'نوتات موسيقية لعازف الأكورديون';

  @override
  String get level_3_6_sender => 'عازف الأكورديون';

  @override
  String get level_3_6_hint => 'ريح عاتية! راقب علامة ! واسلك الجهة المفتوحة.';

  @override
  String get level_3_7_name => 'سريع منتصف الليل';

  @override
  String get level_3_7_cargo => 'رسالة حب في منتصف الليل للخبّازة';

  @override
  String get level_3_7_sender => 'الخبّازة';

  @override
  String get level_3_7_hint => 'انطلق عبر الأسراب.';

  @override
  String get level_3_8_name => 'إمبراطورة الغسق';

  @override
  String get level_3_8_cargo => 'جرس إنذار لإمبراطورة الغسق';

  @override
  String get level_3_8_sender => 'إمبراطورة الغسق';

  @override
  String get level_4_1_name => 'أضواء الميناء';

  @override
  String get level_4_1_cargo => 'عدسة جديدة لحارسة المنارة';

  @override
  String get level_4_1_sender => 'حارسة المنارة';

  @override
  String get level_4_2_name => 'ممرّ البركان';

  @override
  String get level_4_2_cargo => 'قفّازات فرن لخبّازة البركان';

  @override
  String get level_4_2_sender => 'خبّازة البركان';

  @override
  String get level_4_2_hint => 'اقفز فوق نوافير الحمم.';

  @override
  String get level_4_3_name => 'على امتداد الساحل';

  @override
  String get level_4_3_cargo => 'خيط طائرات ورقية لمهرجان الشاطئ';

  @override
  String get level_4_3_sender => 'هواة الطائرات الورقية';

  @override
  String get level_4_4_name => 'ساعة الجَزْر';

  @override
  String get level_4_4_cargo => 'ردّ لناسك الجزيرة';

  @override
  String get level_4_4_sender => 'ناسك الجزيرة';

  @override
  String get level_4_4_hint => 'لا تلمس الماء.';

  @override
  String get level_4_5_name => 'المدّ الأعلى';

  @override
  String get level_4_5_cargo => 'جدول المدّ والجزر لطاقم العبّارة';

  @override
  String get level_4_5_sender => 'طاقم العبّارة';

  @override
  String get level_4_5_hint => 'حين يرنّ الجرس، حلّق عاليًا.';

  @override
  String get level_4_6_name => 'خليج المدافع';

  @override
  String get level_4_6_cargo => 'بسكويت سمك لمستعمرة النوارس';

  @override
  String get level_4_6_sender => 'مستعمرة النوارس';

  @override
  String get level_4_7_name => 'عبور عاصف';

  @override
  String get level_4_7_cargo => 'جوارب جافة لبحّارة مراقبة العواصف';

  @override
  String get level_4_7_sender => 'مراقبو العواصف';

  @override
  String get level_4_8_name => 'قبطان القراصنة';

  @override
  String get level_4_8_cargo => 'أمر بإعادة البريد للقبطان';

  @override
  String get level_4_8_sender => 'قبطان القراصنة';

  @override
  String get level_5_1_name => 'بريد الشفق القطبي';

  @override
  String get level_5_1_cargo => 'قبعات صوفية لجوقة البطاريق';

  @override
  String get level_5_1_sender => 'جوقة البطاريق';

  @override
  String get level_5_1_hint => 'قد تأتي أي اندفاعة الآن. اقرأ اللافتة!';

  @override
  String get level_5_2_name => 'الليل القطبي';

  @override
  String get level_5_2_cargo => 'كاكاو ساخن للمحطة القطبية';

  @override
  String get level_5_2_sender => 'المحطة القطبية';

  @override
  String get level_5_3_name => 'سريع النيون';

  @override
  String get level_5_3_cargo => 'صمامات احتياطية للافتة مطعم النودلز';

  @override
  String get level_5_3_sender => 'طاهي النودلز';

  @override
  String get level_5_4_name => 'عاصفة البيانات';

  @override
  String get level_5_4_cargo => 'رسالة ورقية لروبوت فضولي';

  @override
  String get level_5_4_sender => 'الوحدة 7';

  @override
  String get level_5_5_name => 'انطلاقة فوق الأفق';

  @override
  String get level_5_5_cargo => 'تذاكر سباق لعدّائي الأسطح';

  @override
  String get level_5_5_sender => 'عدّاؤو الأسطح';

  @override
  String get level_5_6_name => 'مهرجان الفوانيس';

  @override
  String get level_5_6_cargo => 'فوانيس ورقية للمهرجان';

  @override
  String get level_5_6_sender => 'صانعو الفوانيس';

  @override
  String get level_5_7_name => 'الشوط الأخير';

  @override
  String get level_5_7_cargo => 'شاي جبلي للدير';

  @override
  String get level_5_7_sender => 'رهبان الجبل';

  @override
  String get level_5_8_name => 'تنين الجمر';

  @override
  String get level_5_8_cargo => 'أول رسالة تُرسَل إلى التنين';

  @override
  String get level_5_8_sender => 'تنين الجمر';

  @override
  String get storyPostmasterName => 'مدير البريد بيل';

  @override
  String get storySkip => 'تخطٍّ';

  @override
  String get storyNextLineSemantics => 'السطر التالي';

  @override
  String get storyFinishSemantics => 'إنهاء';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => 'كل رسالة تصل.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => 'طِر!';

  @override
  String levelIntroRunUp(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'اقتراب $seconds ثانية قبل الزعيم',
      many: 'اقتراب $seconds ثانية قبل الزعيم',
      few: 'اقتراب $seconds ثوانٍ قبل الزعيم',
      two: 'اقتراب ثانيتين قبل الزعيم',
      one: 'اقتراب ثانية قبل الزعيم',
      zero: 'اقتراب $seconds ثانية قبل الزعيم',
    );
    return '$_temp0';
  }

  @override
  String levelIntroLength(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'نحو $seconds ثانية حتى النهاية',
      many: 'نحو $seconds ثانية حتى النهاية',
      few: 'نحو $seconds ثوانٍ حتى النهاية',
      two: 'نحو ثانيتين حتى النهاية',
      one: 'نحو ثانية حتى النهاية',
      zero: 'نحو $seconds ثانية حتى النهاية',
    );
    return '$_temp0';
  }

  @override
  String get campaignGuardian => 'حارس';

  @override
  String get levelIntroBossFight => 'معركة الزعيم';

  @override
  String get levelIntroNew => 'جديد';

  @override
  String get levelIntroTip => 'نصيحة';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    return 'اهزم $boss';
  }

  @override
  String get levelIntroGoalFinish => 'صِل إلى خط النهاية';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اجمع $count نجمة',
      many: 'اجمع $count نجمة',
      few: 'اجمع $count نجوم',
      two: 'اجمع نجمتين',
      one: 'اجمع نجمة واحدة',
      zero: 'اجمع $count نجمة',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'نجمة واحدة: $goal.',
      'two': 'نجمتان: $goal.',
      'other': 'ثلاث نجوم: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'نجمة واحدة: $goal. تحقّق الهدف.',
      'two': 'نجمتان: $goal. تحقّق الهدف.',
      'other': 'ثلاث نجوم: $goal. تحقّق الهدف.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الأفضل: $count نجمة',
      many: 'الأفضل: $count نجمة',
      few: 'الأفضل: $count نجوم',
      two: 'الأفضل: نجمتان',
      one: 'الأفضل: نجمة واحدة',
      zero: 'الأفضل: $count نجمة',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'لم يُسلَّم بعد';

  @override
  String get levelIntroFirstFlight => 'الرحلة الأولى';

  @override
  String get levelIntroControlFlap => 'رفرف';

  @override
  String get levelIntroControlShoot => 'ارمِ';

  @override
  String get levelIntroControlSprint => 'انطلاقة';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'أزرار التحكم: رفرف.',
      'shoot': 'أزرار التحكم: رفرف، ارمِ.',
      'sprint': 'أزرار التحكم: رفرف، انطلاقة.',
      'other': 'أزرار التحكم: رفرف، ارمِ، انطلاقة.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => 'توصيل خاص';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return 'توصيل خاص: $cargo.';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return 'المرحلة $level، $name. $region.';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return 'المرحلة $level، $name. $region. مرحلة حارس: $boss.';
  }

  @override
  String get levelIntroStory => 'القصة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonHome => 'الرئيسية';

  @override
  String get commonBackHome => 'إلى الرئيسية';

  @override
  String get campaignComingSoon => 'قريبًا';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — قريبًا';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    return 'اهزم $boss لتفتحها';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'أنهِ $level لتفتحها';
  }

  @override
  String get campaignMapUnavailable => 'الخريطة تحتاج إلى لحظة.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return 'إغلاق $name';
  }

  @override
  String get campaignMapPreviousStop => 'المحطة السابقة';

  @override
  String get campaignMapNextStop => 'المحطة التالية';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. الفصل $chapter، $route. قريبًا.',
      'locked': '$region. الفصل $chapter، $route. مقفلة.',
      'other': '$region. الفصل $chapter، $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return 'الفصل $chapter · $route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level، $name، معركة الزعيم',
      'guardian': 'المرحلة $level، $name، الحارس $boss',
      'other': 'المرحلة $level، $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. مقفلة.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. مقفلة. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars من 3 نجوم',
      many: '$stars من 3 نجوم',
      few: '$stars من 3 نجوم',
      two: 'نجمتان من 3',
      one: 'نجمة واحدة من 3',
      zero: 'لا نجوم من 3',
    );
    return '$node. التالية. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars من 3 نجوم',
      many: '$stars من 3 نجوم',
      few: '$stars من 3 نجوم',
      two: 'نجمتان من 3',
      one: 'نجمة واحدة من 3',
      zero: 'لا نجوم من 3',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'الغرغول',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return 'بطاقة بريدية من الفصل $chapter';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars من $total نجمة في الحملة',
      many: '$stars من $total نجمة في الحملة',
      few: '$stars من $total نجوم في الحملة',
      two: '$stars من نجمتين في الحملة',
      one: '$stars من نجمة واحدة في الحملة',
      zero: '$stars من $total نجمة في الحملة',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'عزيزي ساعي البريد،';

  @override
  String get campaignPostcardPs => 'ملاحظة:';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'بطاقة بريدية من $route. عزيزي ساعي البريد، $body ملاحظة: $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'تحيات من';

  @override
  String get campaignPostcardHeader => 'بطاقة نادي السماء البريدية';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'ساعي البريد';

  @override
  String get campaignPostcardAddressStreet => 'مكتب نادي السماء';

  @override
  String get campaignPostcardAddressCity => 'في أعالي السماء';

  @override
  String get campaignPostmarkDelivered => 'تم التوصيل';

  @override
  String get campaignPostmarkClub => 'بريد نادي السماء';

  @override
  String get campaignStampSkyClub => 'نادي السماء';

  @override
  String campaignThanksQuoted(String thanks) {
    return '«$thanks»';
  }

  @override
  String campaignThanksSignature(String sender) {
    return '— $sender';
  }

  @override
  String campaignThanksSemantics(String sender, String thanks) {
    return 'بطاقة شكر من $sender: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'تجهيز بسيط. وسماء واسعة.';

  @override
  String get flightSetupTitleSquat => 'القدمان ثابتتان. الجناحان مفتوحان.';

  @override
  String get flightSetupTitleJump => 'قفزات صغيرة. أجنحة كبيرة.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'مرحلة · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · محسوبة';
  }

  @override
  String get flightSetupRoomPushUp => 'أفسح مكانًا صغيرًا للحركة.';

  @override
  String get flightSetupRoomBody => 'أظهر جسمك كله.';

  @override
  String get flightSetupTipsPushUp =>
      'الهاتف منخفض. أظهر ذراعًا ووركًا.\nتواجه الهاتف؟ أبقِ كتفيك في الصورة.';

  @override
  String get flightSetupTipsSquat =>
      'اقرفص لتهبط. قِف لترتفع.\nأبقِ قدميك على الأرض.';

  @override
  String get flightSetupTipsJump =>
      'اقفز لتندفع، ثم انزلق 3 ث.\nاهبط قبل أن تقفز مجددًا.';

  @override
  String get flightSetupHowToFly => 'كيف تطير';

  @override
  String get flightSetupStep1PushUp => 'أظهر ذراعك ووركك';

  @override
  String get flightSetupStep1Squat => 'أفسح مكانًا للقرفصاء';

  @override
  String get flightSetupStep1Jump => 'أفسح مكانًا للقفز';

  @override
  String get flightSetupStep1DetailPushUp =>
      'تواجه الهاتف؟ أظهر كتفيك وذراعًا ووركًا.';

  @override
  String get flightSetupStep1DetailBody => 'الهاتف بالعرض. أظهر جسمك وقدميك.';

  @override
  String get flightSetupStep2PushUp => 'اعرف مدى حركتك';

  @override
  String get flightSetupStep2Squat => 'جد قرفصاءك المريحة';

  @override
  String get flightSetupStep2Jump => 'قِف منتصبًا وثابتًا';

  @override
  String get flightSetupStep2DetailPushUp =>
      'جد وضعية علوية مريحة، ثم انزل واصعد مرتين.';

  @override
  String get flightSetupStep2DetailSquat =>
      'قِف ثابتًا، اقرفص وابقَ قليلًا، ثم انهض.';

  @override
  String get flightSetupStep2DetailJump =>
      'اثبت قليلًا، ثم اقفز لاندفاعة كبيرة.';

  @override
  String get flightSetupStep3Stars => 'اجمع النجوم';

  @override
  String get flightSetupStep3DetailJump =>
      'كل نجمة تضيف 0.75 ث من الانزلاق، حتى 5 ث. اجمع ثلاثيات النجوم لتربح ‎+5 نقاط.';

  @override
  String get flightSetupLivesEndless =>
      'ثلاثة قلوب + درع. يمكنك الإيقاف المؤقت متى شئت.';

  @override
  String get flightSetupLivesClassic =>
      'الاصطدام أو فقدان وضعيتك ينهي الرحلة المحسوبة. يمكنك الإيقاف المؤقت متى شئت.';

  @override
  String get flightSetupCameraButton => 'جهّز كاميرتي';

  @override
  String get flightMicTitle => 'تسجيل الميكروفون';

  @override
  String get flightMicOn => 'يعمل';

  @override
  String get flightMicOptional => 'اختياري';

  @override
  String get flightMicDetail =>
      'أضف صوتك وأصوات الغرفة إلى إعادات العرض. يُستخدم الميكروفون أثناء الطيران فقط. يُحفظ على هذا الهاتف.';

  @override
  String get flightMicSemantics => 'تسجيل الميكروفون لإعادات العرض';

  @override
  String get flightMicSettings => 'إعدادات الميكروفون';

  @override
  String get flightCalibrationTitleReady => 'وجدت جناحيك!';

  @override
  String get flightCalibrationTitleWaking => 'نوقظ كاميرتك…';

  @override
  String get flightCalibrationTitleError => 'لنُعِد توصيل كاميرتك.';

  @override
  String get flightCalibrationTitleRange => 'اعرف مدى حركتك.';

  @override
  String get flightCalibrationTitleStill => 'قِف منتصبًا وثابتًا.';

  @override
  String get flightCalibrationStepTry => 'جرّب تحريك طائرك.';

  @override
  String get flightCalibrationStepTop => 'جد وضعية علوية مريحة.';

  @override
  String get flightCalibrationStepLower => 'انزل ببطء.';

  @override
  String get flightCalibrationStepPushBack => 'ادفع لتصعد من جديد.';

  @override
  String get flightCalibrationStepStill => 'قِف منتصبًا وثابتًا.';

  @override
  String get flightCalibrationStepSquat => 'اقرفص براحة.';

  @override
  String get flightCalibrationStepStandUp => 'انهض من جديد.';

  @override
  String get flightCalibrationStepDone => 'وجدت جناحيك!';

  @override
  String get flightCalibrationReadyPushUp => 'ادفع لترتفع. انزل لتنزلق.';

  @override
  String get flightCalibrationReadySquat => 'اقرفص لتهبط. قِف لترتفع.';

  @override
  String get flightCalibrationReadyJump => 'اقفز، ثم استرح بينما ينزلق طائرك.';

  @override
  String get flightCalibrationKeepPushUp =>
      'أبقِ كتفيك وذراعًا ووركًا في الصورة. تحرّك براحة.';

  @override
  String get flightCalibrationKeepBody => 'أبقِ كتفيك ووركيك وقدميك في الصورة.';

  @override
  String get flightCalibrationLearning => 'نتعلّم مدى حركتك وأنت تتحرك.';

  @override
  String get flightCalibrationAfter => 'يتحرك طائرك بعد المعايرة.';

  @override
  String get flightCalibrationJump => 'اقفز!';

  @override
  String get flightCalibrationTagCheck => 'اختبار التحكم';

  @override
  String flightCalibrationTagPushUps(int count) {
    return 'الضغط: $count من 2';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return 'المعايرة $percent%';
  }

  @override
  String get flightCalibrationTakeoff => 'هيا نُقلع!';

  @override
  String get flightCalibrationStarting => 'جارٍ البدء…';

  @override
  String get flightCalibrationRestart => 'أعد المعايرة';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate تحديث/ث · $p95 مللي ثانية (p95)';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate تحديث/ث · $p95 مللي ثانية (p95، للمعالجة فقط)';
  }

  @override
  String get flightCalibrationStatusReady => 'جاهز';

  @override
  String get flightCalibrationStatusStarting => 'جارٍ البدء';

  @override
  String get flightCalibrationStatusCameraOff => 'الكاميرا مطفأة';

  @override
  String get flightCalibrationStatusCalibrating => 'جارٍ المعايرة';

  @override
  String get flightSwitchCameraSemantics => 'تبديل الكاميرا';

  @override
  String get flightCalibrationStepIntoView => 'ادخل في الصورة';

  @override
  String get flightCameraTroubleTitle => 'البدء من جديد يفيد عادةً.';

  @override
  String get flightCameraTroubleAllow =>
      'اسمح بالوصول إلى الكاميرا من الإعدادات.';

  @override
  String get flightCameraTroubleClose =>
      'أغلق أي تطبيق كاميرا آخر، ثم حاول مجددًا.';

  @override
  String get flightCameraPermissionSemantics => 'إعدادات إذن الكاميرا';

  @override
  String get flightNoteRememberFailed =>
      'تغيّر لهذه الرحلة. تعذّر حفظ اختيارك.';

  @override
  String get flightNoteMicUnavailable =>
      'الميكروفون غير متاح. الفيديو واللعب ما زالا يعملان.';

  @override
  String get flightNoteMicBlocked =>
      'الميكروفون محظور. يمكنك السماح به من الإعدادات؛ الفيديو ما زال يعمل.';

  @override
  String get flightNoteMicOff =>
      'الميكروفون مطفأ. ما زال بإمكانك اللعب وحفظ الفيديو.';

  @override
  String get flightNoteVideoUnavailable =>
      'فيديو الكاميرا غير متاح. ما زال بإمكانك حفظ اللعب.';

  @override
  String get flightNoteMicAudioLost =>
      'صوت الميكروفون لم يكن متاحًا. ما زال بإمكانك حفظ الفيديو واللعب.';

  @override
  String get flightNoteVideoInterrupted =>
      'انقطع فيديو الكاميرا. ما زال بإمكانك حفظ ما سُجّل واللعب.';

  @override
  String get flightNoteSessionSaveFailed =>
      'تعذّر حفظ الجلسة. انقر على «احفظ الجلسة» لإعادة المحاولة.';

  @override
  String get flightNoteWakingCamera => 'نوقظ كاميرتك…';

  @override
  String get flightNoteCameraOff =>
      'الوصول إلى الكاميرا مطفأ. اسمح به في إعدادات أندرويد، ثم عُد وحاول مجددًا.';

  @override
  String get flightNoteCameraFailed =>
      'تعذّر تشغيل الكاميرا. حاول مجددًا أو بدّل الكاميرا.';

  @override
  String get flightNotePreparing => 'نجهّز جلستك…';

  @override
  String get flightNoteSaveFailed => 'تعذّر حفظ رحلتك. انقر لإعادة المحاولة.';

  @override
  String get flightNoteWelcomeBack => 'أهلًا بعودتك. لنتحقق من وضعيتك مجددًا.';

  @override
  String get flightNoteCameraInterrupted =>
      'انقطعت الكاميرا. تحقق من إذن الكاميرا وحاول مجددًا.';

  @override
  String get flightNoteTrackingInterrupted => 'انقطع التتبّع';

  @override
  String get flightFindPosition => 'اتخذ وضعيتك';

  @override
  String get flightTapSemantics => 'انقر لترفرف';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'انقر لترفرف. $group في الطليعة قبل الزعيم';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'انقر لترفرف. $boss: الصحة $hp من $maxHp';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'انقر لترفرف. $boss: الصحة $hp من $maxHp. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'تخطَّ إلى النتائج';

  @override
  String get hudPauseSemantics => 'إيقاف الرحلة مؤقتًا';

  @override
  String get flightHintTestSteerKeys =>
      'طيران تجريبي: السهمان لأعلى ولأسفل للتوجيه.';

  @override
  String get flightHintTestSteerDrag =>
      'طيران تجريبي: اسحب لأعلى ولأسفل للتوجيه.';

  @override
  String get flightHintTestJumpKeys => 'طيران تجريبي: اضغط Space للقفز.';

  @override
  String get flightHintTestJumpTap => 'طيران تجريبي: انقر للقفز.';

  @override
  String get flightHintKeysStars => 'اضغط Space لترفرف. طِر عبر النجوم.';

  @override
  String get flightHintKeysShoot =>
      'اضغط Space لترفرف. اضغط D مطولًا لشحن رمية.';

  @override
  String get flightHintKeysCombat =>
      'اضغط Space لترفرف. اضغط D مطولًا لشحن رمية. واضغط A لتنطلق!';

  @override
  String get flightHintKeysPause => 'اضغط Space لترفرف، و Esc للإيقاف المؤقت.';

  @override
  String get flightHintTapStars => 'انقر على السماء لترفرف. طِر عبر النجوم.';

  @override
  String get flightHintTapShoot =>
      'انقر على السماء لترفرف. اضغط مطولًا على «ارمِ» للشحن.';

  @override
  String get flightHintTapCombat =>
      'انقر على السماء لترفرف. اضغط مطولًا على «ارمِ» للشحن. و«انطلاقة» للتحطيم!';

  @override
  String get flightHintTapRelease => 'انقر لترفرف. ارفع إصبعك بين النقرات.';

  @override
  String get flightHintTrail => 'اتبع النجوم. درعك جاهز.';

  @override
  String get flightHintSky => 'السماء لك.';

  @override
  String hudClockSemantics(String time) {
    return 'بقي $time';
  }

  @override
  String flightSeconds(String seconds) {
    return '$seconds ث';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'مغناطيس النجوم: بقيت $seconds ثانية',
      many: 'مغناطيس النجوم: بقيت $seconds ثانية',
      few: 'مغناطيس النجوم: بقيت $seconds ثوانٍ',
      two: 'مغناطيس النجوم: بقيت ثانيتان',
      one: 'مغناطيس النجوم: بقيت ثانية واحدة',
      zero: 'مغناطيس النجوم: انتهى الوقت',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'شحن المغناطيس: $charge من $gates بوابة مثالية',
      many: 'شحن المغناطيس: $charge من $gates بوابة مثالية',
      few: 'شحن المغناطيس: $charge من $gates بوابات مثالية',
      two: 'شحن المغناطيس: $charge من بوابتين مثاليتين',
      one: 'شحن المغناطيس: $charge من بوابة مثالية واحدة',
      zero: 'شحن المغناطيس: $charge من $gates بوابة مثالية',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'نبحث عنك…';

  @override
  String get hudShoot => 'ارمِ';

  @override
  String get hudSprint => 'انطلاقة';

  @override
  String get flightTestNothingSaved => 'لا يُحفظ شيء';

  @override
  String get flightCountdownReady => 'استعد، انتباه…';

  @override
  String get flightPauseTitle => 'التقط أنفاسك.';

  @override
  String get flightPauseKeepFlying => 'تابع الطيران';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. طائرك يستريح بانتظارك.';
  }

  @override
  String flightPausedTest(String name) {
    return 'طيران تجريبي: $name. لا يُحفظ شيء.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. طائرك يستريح بانتظارك.';
  }

  @override
  String get flightPausedTouch =>
      'طائرك يستريح بانتظارك. سنعدّ لك قبل أن تعود.';

  @override
  String get flightPausedCamera =>
      'انفض التعب، ثم عُد إلى وضعيتك. سنعدّ لك قبل البدء.';

  @override
  String get flightPauseEdit => 'تعديل';

  @override
  String get flightPauseBuilder => 'الصانع';

  @override
  String get flightPauseFinish => 'أنهِ الرحلة';

  @override
  String get hudShieldRecovering => 'يتعافى';

  @override
  String get hudShieldReady => 'الدرع جاهز';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'شحن الدرع: $charge من $stars نجمة',
      many: 'شحن الدرع: $charge من $stars نجمة',
      few: 'شحن الدرع: $charge من $stars نجوم',
      two: 'شحن الدرع: $charge من نجمتين',
      one: 'شحن الدرع: $charge من نجمة واحدة',
      zero: 'شحن الدرع: $charge من $stars نجمة',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count قلب',
      many: 'بقي $count قلبًا',
      few: 'بقيت $count قلوب',
      two: 'بقي قلبان',
      one: 'بقي قلب واحد',
      zero: 'لم يبقَ أي قلب',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'انطلاق';

  @override
  String get hudSprintReady => 'جاهز';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'إعادة الشحن، $seconds ثانية',
      many: 'إعادة الشحن، $seconds ثانية',
      few: 'إعادة الشحن، $seconds ثوانٍ',
      two: 'إعادة الشحن، ثانيتان',
      one: 'إعادة الشحن، ثانية واحدة',
      zero: 'إعادة الشحن',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint => 'اندفع لتحطيم الخفافيش والألواح الحجرية';

  @override
  String get hudShotReloading => 'إعادة التعبئة…';

  @override
  String hudShotFullCharge(int ms) {
    return 'شحن كامل، بقي $ms مللي ثانية';
  }

  @override
  String hudShotCharging(int percent) {
    return 'الشحن $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'الحجارة $percent%';
  }

  @override
  String get hudShotHint => 'اضغط مطولًا لشحن حجر أكبر';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تحققت علامة $count نجمة',
      many: 'تحققت علامة $count نجمة',
      few: 'تحققت علامة $count نجوم',
      two: 'تحققت علامة النجمتين',
      one: 'تحققت علامة النجمة الواحدة',
      zero: 'تحققت علامة $count نجوم',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة عند $at',
      many: '$count نجمة عند $at',
      few: '$count نجوم عند $at',
      two: 'نجمتان عند $at',
      one: 'نجمة واحدة عند $at',
      zero: '$count نجوم عند $at',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'جُمعت $stars نجمة',
      many: 'جُمعت $stars نجمة',
      few: 'جُمعت $stars نجوم',
      two: 'جُمعت نجمتان',
      one: 'جُمعت نجمة واحدة',
      zero: 'لم تُجمع أي نجمة',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'الأقصى';

  @override
  String hudRouteSemantics(int percent) {
    return 'قطعت $percent% من الخط';
  }

  @override
  String hudGlideCompact(String time) {
    return 'انزلاق · $time';
  }

  @override
  String get hudJumpToGlide => 'اقفز لتنزلق';

  @override
  String get hudJump => 'اقفز';

  @override
  String hudGlideSemantics(String time) {
    return 'انزلاق، بقي $time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'الانزلاق ينتهي، بقي $time';
  }

  @override
  String get hudJumpChargeSemantics => 'اقفز لشحن انزلاق مدته 3 ثوانٍ';

  @override
  String get hudRecordNewBest => 'رقم قياسي!';

  @override
  String get hudRecordMatched => 'عادلت الأفضل!';

  @override
  String hudRecordBest(int best) {
    return 'الأفضل $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '‎+$points فوق أفضل نتيجة';
  }

  @override
  String get hudRecordOneMore => 'نقطة واحدة للرقم القياسي';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نقطة للرقم القياسي',
      many: '$count نقطة للرقم القياسي',
      few: '$count نقاط للرقم القياسي',
      two: 'نقطتان للرقم القياسي',
      one: 'نقطة واحدة للرقم القياسي',
      zero: '$count نقطة للرقم القياسي',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'النقاط $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'النقاط $score، المضاعِف ‎×$multiplier';
  }

  @override
  String get commonBusySemantics => 'جارٍ العمل';

  @override
  String get flightResultBumpClouds => 'اصطدام صغير في الغيوم.';

  @override
  String get flightResultPersonalBest => 'أفضل نتيجة لك';

  @override
  String get flightResultNewPersonalBest => 'أفضل نتيجة جديدة!';

  @override
  String get flightResultStarsCollected => 'النجوم المجموعة';

  @override
  String get flightResultDailyStamped => 'خُتمت بطاقة اليوم!';

  @override
  String flightResultNextStamp(String stamp) {
    return 'التالي: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'حُفظت على هذا الهاتف';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'حُفظت على الهاتف · $total بوابة إجمالًا',
      many: 'حُفظت على الهاتف · $total بوابة إجمالًا',
      few: 'حُفظت على الهاتف · $total بوابات إجمالًا',
      two: 'حُفظت على الهاتف · بوابتان إجمالًا',
      one: 'حُفظت على الهاتف · بوابة واحدة إجمالًا',
      zero: 'حُفظت على الهاتف · $total بوابة إجمالًا',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'جارٍ حفظ رحلتك…';

  @override
  String get flightResultSessionSaved => 'حُفظت الجلسة · شاهدها في السجلّات';

  @override
  String get flightResultWatchReplay => 'شاهد الإعادة';

  @override
  String get flightResultPreparing => 'جارٍ التحضير…';

  @override
  String get flightResultSavingShort => 'جارٍ الحفظ…';

  @override
  String get flightResultSaveSession => 'احفظ الجلسة';

  @override
  String get flightResultFlyAgain => 'طِر مجددًا';

  @override
  String get commonRetry => 'أعد المحاولة';

  @override
  String get commonMap => 'الخريطة';

  @override
  String get commonNext => 'التالي';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ضغطة',
      many: 'ضغطة',
      few: 'ضغطات',
      two: 'ضغطتان',
      one: 'ضغطة',
      zero: 'ضغطة',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمرين قرفصاء',
      many: 'تمرين قرفصاء',
      few: 'تمارين قرفصاء',
      two: 'تمرينا قرفصاء',
      one: 'تمرين قرفصاء',
      zero: 'تمرين قرفصاء',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قفزة',
      many: 'قفزة',
      few: 'قفزات',
      two: 'قفزتان',
      one: 'قفزة',
      zero: 'قفزة',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رفرفة',
      many: 'رفرفة',
      few: 'رفرفات',
      two: 'رفرفتان',
      one: 'رفرفة',
      zero: 'رفرفة',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'مدة الطيران';

  @override
  String get flightStatPerfect => 'عبور مثالي';

  @override
  String get flightStatBestStreak => 'أفضل سلسلة';

  @override
  String get flightStatRank => 'الرتبة';

  @override
  String get flightRankSkyCaptain => 'قائد السماء';

  @override
  String get flightRankCloudExplorer => 'مستكشف الغيوم';

  @override
  String get flightRankFirstWings => 'الأجنحة الأولى';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => 'اصطدام… لكن مع رقم قياسي جديد!';

  @override
  String get gameOverCaptionSea => 'طَشّة صغيرة في البحر.';

  @override
  String get gameOverSplash => 'طَشّ!';

  @override
  String get gameOverBonk => 'طُق!';

  @override
  String get gameOverEveryMarkSemantics => 'تحققت كل العلامات';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة أخرى للحصول على $mark من 3 نجوم',
      many: '$count نجمة أخرى للحصول على $mark من 3 نجوم',
      few: '$count نجوم أخرى للحصول على $mark من 3 نجوم',
      two: 'نجمتان أخريان للحصول على $mark من 3 نجوم',
      one: 'نجمة واحدة أخرى للحصول على $mark من 3 نجوم',
      zero: '$count نجمة أخرى للحصول على $mark من 3 نجوم',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: الصحة المتبقية $hp من $maxHp';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return 'قُطع $percent بالمئة من الخط';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: الصحة المتبقية $hp';
  }

  @override
  String gameOverBossLeft(String boss) {
    return 'صحة $boss المتبقية';
  }

  @override
  String get gameOverRouteFlown => 'المقطوع من الخط';

  @override
  String gameOverHp(int hp) {
    return '$hp صحة';
  }

  @override
  String gameOverMoreFor(int count) {
    return '$count أخرى لنيل';
  }

  @override
  String get gameOverBothMarks => 'تحققت العلامتان';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    return 'تحققت العلامتان. اهزم $boss!';
  }

  @override
  String get miniResultTitle => 'كل رحلة لها قيمتها.';

  @override
  String get miniResultComplete => 'اكتملت الرحلة';

  @override
  String get miniResultCheerBest => 'ما أروعك!';

  @override
  String get miniResultCheerComplete => 'اكتملت الرحلة!';

  @override
  String get miniResultCheerNice => 'طيران رائع.';

  @override
  String get miniResultNew => 'جديد';

  @override
  String get flightEndTrackingLost => 'فقدنا رؤيتك للحظة.';

  @override
  String get flightEndPostureLost => 'خرجت وضعيتك عن النطاق.';

  @override
  String get flightEndBackgrounded => 'ابتعدت عن السماء قليلًا.';

  @override
  String get flightEndBreak => 'استراحة مستحقة.';

  @override
  String get flightEndQuit => 'إلى المغامرة القادمة.';

  @override
  String get flightEndStalled => 'انقطعت اللعبة.';

  @override
  String get flightEndCompleted => 'سماء كاملة من النجوم. كلها لك.';

  @override
  String get levelResultTryAgain => 'حاول مجددًا!';

  @override
  String get levelResultVictory => 'انتصار!';

  @override
  String get levelResultGuardianDown => 'سقط الحارس!';

  @override
  String get levelResultDelivered => 'تم التوصيل!';

  @override
  String levelResultComingSoon(String region) {
    return '$region قريبًا!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned من 3 نجوم';
  }

  @override
  String levelResultBest(int best) {
    return 'الأفضل $best';
  }

  @override
  String get levelResultNoBest => 'لا نتيجة سابقة';

  @override
  String get levelResultFirstClear => 'أول إتمام!';

  @override
  String get levelResultNewBest => 'رقم قياسي!';

  @override
  String get levelResultScore => 'النقاط';

  @override
  String get levelResultGoalBoss => 'الزعيم';

  @override
  String get levelResultGoalGuardian => 'الحارس';

  @override
  String get levelResultGoalFinish => 'النهاية';

  @override
  String get levelResultGoalDone => 'تم';

  @override
  String get levelResultGoalNotYet => 'ليس بعد';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count',
      many: 'بقي $count',
      few: 'بقي $count',
      two: 'بقيت نجمتان',
      one: 'بقيت نجمة',
      zero: 'بقي $count',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'أكمل أولًا';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. تم.';
  }

  @override
  String get levelResultPostcardWaiting => 'بطاقة بريدية تنتظرك على الخريطة!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return 'فُتحت المرحلة $id $name!';
  }

  @override
  String get levelResultReachFinish => 'صِل إلى خط النهاية لتربح النجوم.';

  @override
  String get course_classic_title => 'كلاسيكي';

  @override
  String get course_starTrail_title => 'بلا نهاية';

  @override
  String get course_classic_instructions =>
      'اعثر على الفتحات. اتبع علامات التصويب لعبور مثالي.';

  @override
  String get course_starTrail_instructions =>
      'اجمع النجوم الثلاث في المجموعة لتربح ‎+5. اجمع سلسلة نجوم حتى ‎×3. النجوم تشحن درعك، والبوابات المثالية تمنحك مغناطيس النجوم. طوّر الاثنين بالنجوم!';

  @override
  String get course_classic_scoreLabel => 'العقبات';

  @override
  String get course_starTrail_scoreLabel => 'نقاط النجوم';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بوابة',
      many: 'بوابة',
      few: 'بوابات',
      two: 'بوابتان',
      one: 'بوابة',
      zero: 'بوابة',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نقطة نجوم',
      many: 'نقطة نجوم',
      few: 'نقاط نجوم',
      two: 'نقطتا نجوم',
      one: 'نقطة نجوم',
      zero: 'نقطة نجوم',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics => 'كلاسيكي: طِر عبر الفتحات.';

  @override
  String get course_starTrail_previewSemantics =>
      'بلا نهاية: اجمع النجوم بثلاثة قلوب ودرع.';

  @override
  String get obstacle_garden_name => 'بوابة الحديقة';

  @override
  String get obstacle_windLift_name => 'رافعة الريح';

  @override
  String get obstacle_petalGate_name => 'مصاريع البتلات';

  @override
  String get obstacle_switchback_name => 'منعطف';

  @override
  String get obstacle_lanternDrift_name => 'فوانيس عائمة';

  @override
  String get obstacle_sunWheels_name => 'عجلات الشمس';

  @override
  String get obstacle_crystalSteps_name => 'درجات بلورية';

  @override
  String get rush_wildfire_name => 'حريق';

  @override
  String get rush_wildfire_escape => 'سبقت الحريق';

  @override
  String get rush_skyfall_name => 'سقوط السماء';

  @override
  String get rush_skyfall_escape => 'نجوت من سقوط السماء';

  @override
  String get rush_eruption_name => 'ثوران';

  @override
  String get rush_eruption_escape => 'تغلّبت على الثوران';

  @override
  String get rush_swarm_name => 'سِرب';

  @override
  String get rush_swarm_escape => 'شققت طريقك عبر السرب';

  @override
  String get boss_baronBat_title => 'سيّد العاصفة';

  @override
  String get boss_spitterBeetle_title => 'خيميائيّ السِّرب';

  @override
  String get boss_duskMoth_title => 'حارسة وشاح الشفق';

  @override
  String get boss_pirate_title => 'رُعب المدّ العالي';

  @override
  String get boss_dragon_title => 'عاهل السماء المشتعلة';

  @override
  String get boss_kingCoo_title => 'مفوّض الرصيف';

  @override
  String get boss_searchlightGargoyle_title => 'رقيب أعلى برج';

  @override
  String get boss_neferhoo_title => 'أمين الرسالة الضائعة';

  @override
  String get boss_baronBat_returnTitle => 'العاصفة تعود';

  @override
  String get boss_baronBat_barName => 'البارون وطواط';

  @override
  String get boss_spitterBeetle_barName => 'الملك البصّاق';

  @override
  String get boss_duskMoth_barName => 'إمبراطورة الغسق';

  @override
  String get boss_pirate_barName => 'قبطان القراصنة';

  @override
  String get boss_dragon_barName => 'تنين الجمر';

  @override
  String get boss_kingCoo_barName => 'الملك كوكو';

  @override
  String get boss_searchlightGargoyle_barName => 'الغرغول';

  @override
  String get boss_neferhoo_barName => 'نِفِرهو';

  @override
  String get vanguard_baronBat_title => 'خفافيش البارون وطواط';

  @override
  String get vanguard_baronBat_call => 'ها هم قادمون! والبارون خلفهم مباشرة.';

  @override
  String get vanguard_spitterBeetle_title => 'صغار الملك البصّاق';

  @override
  String get vanguard_spitterBeetle_call =>
      'ها هم قادمون! والملك البصّاق خلفهم مباشرة.';

  @override
  String get vanguard_duskMoth_title => 'فراشات إمبراطورة الغسق';

  @override
  String get vanguard_duskMoth_call =>
      'ها هم قادمون! والإمبراطورة خلفهم مباشرة.';

  @override
  String get vanguard_kingCoo_title => 'فرقة الملك كوكو';

  @override
  String get vanguard_kingCoo_call => 'ها هم قادمون! والملك كوكو خلفهم مباشرة.';

  @override
  String get vanguard_kingCoo_callCrusts =>
      'ها هم قادمون! تفادَ الكِسَر اليابسة!';

  @override
  String get vanguard_kingCoo_callReturns =>
      'تفادَ الكِسَر اليابسة! وأي حمامة تفوتك تعود!';

  @override
  String get bossVanguardClear => 'خلا الطريق';

  @override
  String get bossVanguardLeft => 'متبقية';

  @override
  String get bossStragglersCaught => 'قُبض على الجميع!';

  @override
  String get bossHint_strongerBaronBat =>
      'أقوى · ثلاث كرات نارية معًا، وخفافيشه تنضمّ!';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'أقوى · مراوح كاملة، وخنافسه تنضمّ!';

  @override
  String get bossHint_strongerDuskMoth =>
      'أقوى · مراوح من سبع، وفراشاتها تنضمّ!';

  @override
  String get bossHint_strongerPirate => 'أقوى · المدّ بدأ ينقلب!';

  @override
  String get bossHint_strongerDragon => 'أقوى · احذر النفث والأسراب!';

  @override
  String get bossHint_strongerKingCoo => 'أقوى · يصفّر لفرقته!';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'أقوى · الريش يتساقط على المصباح المفتوح!';

  @override
  String get bossHint_strongerGargoyle => 'أقوى · الريش الحجري يتساقط!';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'أقوى · مفتاح الحياة، وخفافيشه المومياء!';

  @override
  String get bossHint_strongerNeferhoo => 'أقوى · مفتاح الحياة الذهبي يعود!';

  @override
  String get bossHint_tideRising => 'المدّ يرتفع · حلّق عاليًا!';

  @override
  String get bossHint_highTide => 'مدّ عالٍ · ابقَ فوق الماء';

  @override
  String get bossHint_tideFury => 'الغضب · وابل المدافع بين الموجات';

  @override
  String get bossHint_tideCalm => 'تفادَ قذائف المدفع · ابتعد عن الماء';

  @override
  String get bossHint_dragonSwarm => 'سِرب · تفادَ الخفافيش أو انطلق عبرها';

  @override
  String get bossHint_dragonFuryDebut => 'الغضب · كرات نارية أسرع';

  @override
  String get bossHint_dragonFury => 'الغضب · الكرات النارية تتفجّر جمرات';

  @override
  String get bossHint_dragonCalm => 'تفادَ الكرات النارية · احذر النفث';

  @override
  String get bossHint_screechFury => 'الغضب · كرات نارية أسرع وخفافيش أكثر';

  @override
  String get bossHint_screechCalm =>
      'تفادَ الكرات النارية والخفافيش · احذر الصرخة';

  @override
  String get bossHint_cooPopped => 'فَرقعة! · لا فرقة';

  @override
  String get bossHint_cooSquadron => 'الفرقة · اتبع المسار المفتوح!';

  @override
  String get bossHint_cooPuffed => 'منتفخ · أصِب صدره (‎×2)!';

  @override
  String get bossHint_cooCrumbBomb => 'قنبلة فُتات · اخرج من الحلقة!';

  @override
  String get bossHint_cooFury => 'الغضب · ابقَ بين الحلقات';

  @override
  String get bossHint_cooCalm => 'تفادَ قنابل الفتات · أصِب صدره حين ينتفخ';

  @override
  String get bossHint_beamOn => 'الشعاع · ابقَ في الظلام';

  @override
  String get bossHint_beamFury => 'الغضب · انسلّ بين الشعاعين';

  @override
  String get bossHint_beamIncomingHigh => 'الشعاع قادم · طِر منخفضًا!';

  @override
  String get bossHint_beamIncomingLow => 'الشعاع قادم · حلّق عاليًا!';

  @override
  String get bossHint_lampOpen => 'المصباح مفتوح · أصِب المصباح!';

  @override
  String get bossHint_shuttersClosed => 'المصاريع مغلقة · وفّر حجارتك';

  @override
  String get bossHint_mothFuryNoVeil => 'الغضب · مراوح من سبع. لا وشاح بعد!';

  @override
  String get bossHint_mothNoVeil => 'لا وشاح بعد · ارمِ بين المراوح!';

  @override
  String get bossHint_mothShielded => 'محمية · تفادَ حتى يسقط الوشاح';

  @override
  String get bossHint_mothShieldForming => 'الدرع يتشكّل · استعد للتفادي';

  @override
  String get bossHint_mothFury => 'الغضب · مراوح من سبع. سقط الوشاح!';

  @override
  String get bossHint_mothCalm => 'سقط الوشاح · ارمِ بين المراوح!';

  @override
  String get bossHint_neferhooMailCall => 'توزيع البريد · أعِدها بالرمي!';

  @override
  String get bossHint_neferhooReturn => 'يُعاد إلى المُرسِل! · ‎−25';

  @override
  String get bossHint_neferhooReturnFaster => 'يُعاد إلى المُرسِل! · ‎−18';

  @override
  String get bossHint_neferhooAnkh => 'مفتاح الحياة · إنه يعود!';

  @override
  String get bossHint_neferhooExpress => 'البريد السريع · خمس رسائل، أسرع';

  @override
  String get bossHint_neferhooTwoAnkhs => 'مفتاحا حياة · ابتعد عن المسارين';

  @override
  String get bossHint_neferhooBats => 'خفافيش مومياء · أسقِطها!';

  @override
  String get bossHint_neferhooScuff =>
      'الحجارة تخدش لفائفه فقط. أعِد إليه «رسائله»!';

  @override
  String get bossHint_neferhooWarmUp =>
      'أعِد رسائله بالرمي · يُعاد إلى المُرسِل';

  @override
  String get bossHint_neferhooCalm =>
      'أعِد رسائله بالرمي · تفادَ مفتاح الحياة الذهبي';

  @override
  String get bossHint_neferhooFury => 'الغضب · بريد سريع ومفتاحا حياة';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'نفث التنين · طِر منخفضًا! قلبه مكشوف',
      'middle': 'نفث التنين · اصعد أو اهبط! قلبه مكشوف',
      'other': 'نفث التنين · حلّق عاليًا! قلبه مكشوف',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'نار · طِر منخفضًا! أصِب القلب المتوهّج',
      'middle': 'نار · اصعد أو اهبط! أصِب القلب المتوهّج',
      'other': 'نار · حلّق عاليًا! أصِب القلب المتوهّج',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'الصرخة الصوتية · طِر إلى الفتحة العليا!',
      'middle': 'الصرخة الصوتية · طِر إلى الفتحة الوسطى!',
      'other': 'الصرخة الصوتية · طِر إلى الفتحة السفلى!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'الصرخة · ابقَ في الفتحة العليا',
      'middle': 'الصرخة · ابقَ في الفتحة الوسطى',
      'other': 'الصرخة · ابقَ في الفتحة السفلى',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'تفادَ المراوح  ·  ارمِ حين يسقط الوشاح';

  @override
  String get encounterCaption_pirate => 'تفادَ المدفع  ·  ابتعد عن الماء';

  @override
  String get encounterCaption_dragon =>
      'تفادَ الكرات النارية  ·  اهرب من النفث';

  @override
  String get encounterCaption_kingCoo =>
      'اخرج من الحلقات  ·  أصِب صدره حين ينتفخ';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'ابقَ بعيدًا عن الضوء  ·  أصِب المصباح حين ينفتح';

  @override
  String get encounterCaption_neferhoo => 'استعد  ·  أعِد رسائله بالرمي';

  @override
  String get encounterCaption_screech => 'حين يصرخ  ·  طِر إلى الفتحة';

  @override
  String get encounterCaption_default => 'استعد  ·  رفرف، تفادَ، ارمِ';

  @override
  String get encounterCoasting => 'طائرك ينساب بأمان';

  @override
  String get encounterOpenSky => 'عودة إلى السماء المفتوحة';

  @override
  String get encounterOmenTitle_duskMoth => 'الشفق يفرد جناحيه';

  @override
  String get encounterOmenLine_duskMoth => 'وشاح حريري يتجمّع في الغسق…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'شيءٌ ما يُطبَخ';

  @override
  String get encounterOmenLine_spitterBeetle => 'الهواء بدأ يفور…';

  @override
  String get encounterOmenTitle_dragon => 'السماء تشتعل';

  @override
  String get encounterOmenLine_dragon => 'أجنحة عظيمة تخفق فوق الغيوم…';

  @override
  String get encounterOmenTitle_kingCoo => 'الرصيف مغلق';

  @override
  String get encounterOmenLine_kingCoo => 'أحدهم غاضب جدًا بسبب عربة الخبز…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => 'إنذار عاصفة';

  @override
  String get encounterOmenLine_searchlightGargoyle => 'شيء على الحافة يراقب…';

  @override
  String get encounterOmenTitle_neferhoo => 'الهرم يتحرّك';

  @override
  String get encounterOmenLine_neferhoo => 'غبار الهرم يتحرّك…';

  @override
  String get encounterOmenTitle_baronReturns => 'عودة البارون';

  @override
  String get encounterOmenLine_baronReturns => 'لقد عاد، وصوته أعلى بكثير…';

  @override
  String get encounterOmenTitle_default => 'ظلٌّ يقترب';

  @override
  String get encounterOmenLine_default => 'السماء ملكٌ لأحدٍ آخر…';

  @override
  String get encounterOmenTitle_pirate => 'شراع في الأفق!';

  @override
  String get encounterOmenLine_pirate => 'سفينة تأتي مع المدّ الصاعد…';

  @override
  String get bossGuardianEyebrow => 'حارس';

  @override
  String bossEncounterEyebrow(String number) {
    return 'المواجهة $number';
  }

  @override
  String get bossGuardianDown => 'سقط الحارس!';

  @override
  String get bossSkyReclaimed => 'استعدنا السماء';

  @override
  String bossVictoryPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '‎+$points نقطة   ·   عاد الدرع',
      many: '‎+$points نقطة   ·   عاد الدرع',
      few: '‎+$points نقاط   ·   عاد الدرع',
      two: '‎+$points نقطة   ·   عاد الدرع',
      one: '‎+$points نقطة   ·   عاد الدرع',
      zero: '‎+$points نقطة   ·   عاد الدرع',
    );
    return '$_temp0';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'هُزم البارون وطواط',
      'spitterBeetle': 'هُزم الملك البصّاق',
      'duskMoth': 'هُزمت إمبراطورة الغسق',
      'pirate': 'هُزم قبطان القراصنة',
      'dragon': 'هُزم تنين الجمر',
      'kingCoo': 'هُزم الملك كوكو',
      'searchlightGargoyle': 'هُزم الغرغول الكشّاف',
      'other': 'هُزم نِفِرهو',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '«$line»';
  }

  @override
  String get bossPirateRoar => 'أررر!';

  @override
  String get bossGargoyleCardSmall => 'الكشّاف';

  @override
  String get bossGargoyleCardBig => 'الغرغول';

  @override
  String get bossGargoyleCardOrder => 'big-small';

  @override
  String get bossDodgeFlyLow => 'طِر منخفضًا';

  @override
  String get bossDodgeFlyHigh => 'طِر عاليًا';

  @override
  String get bossDodgeClimbOrDive => 'اصعد أو اهبط';

  @override
  String get bossDodgeSlipBetween => 'انسلّ بين\nالشعاعين';

  @override
  String get bossSpotted => 'انكشفت!';

  @override
  String get bossShieldLost => 'ضاع الدرع';

  @override
  String get bossHeartLost => '‎-1 قلب';

  @override
  String get bossGargoyleLampOpen => 'مصباح مفتوح';

  @override
  String get bossGargoyleShoot => 'ارمِ!';

  @override
  String get bossScreechFlyToGap => 'طِر إلى الفتحة';

  @override
  String get bossScreechHoldGap => 'ابقَ في الفتحة';

  @override
  String get bossPirateHighTide => 'مدّ عالٍ';

  @override
  String get bossBarDefeated => 'مهزوم';

  @override
  String get bossBarIncoming => 'قادم';

  @override
  String get bossBarFury => 'الغضب';

  @override
  String get bossBarHeartDouble => 'القلب ‎×2';

  @override
  String get bossStronger => 'أقوى!';

  @override
  String get bossKingCooPuffed => 'منتفخ';

  @override
  String get bossKingCooShout => 'كوو!';

  @override
  String get bossKingCooPop => 'فَرقعة!';

  @override
  String get bossKingCooPoof => 'بُف!';

  @override
  String get bossSquadOpenLane => 'مسار مفتوح = طِر';

  @override
  String get bossSquadUseGap => 'اعبر الفتحة';

  @override
  String get bossSquadThenV => 'ثم: V';

  @override
  String get bossSquadThenGap => 'ثم: فتحة';

  @override
  String get bossSquadCancelled => 'أُلغيت الفرقة';

  @override
  String get bossNeferhooFound => 'عُثر على الرسالة الضائعة';

  @override
  String get bossNeferhooHoo => 'هوو';

  @override
  String get bossNeferhooPoo => 'بوو';

  @override
  String get bossNeferhooMailCall => 'توزيع البريد';

  @override
  String get bossNeferhooExpressPost => 'البريد السريع';

  @override
  String get bossNeferhooShootBack => 'أعِدها بالرمي!';

  @override
  String get bossNeferhooAnkh => 'مفتاح الحياة';

  @override
  String get bossNeferhooTwoAnkhs => 'مفتاحا حياة';

  @override
  String get bossNeferhooComesBack => 'إنه يعود!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'حريق!',
      'skyfall': 'سقوط السماء!',
      'eruption': 'ثوران!',
      'other': 'سِرب!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'التقط حلقات الانطلاق واسبقه!',
      'skyfall': 'التقط حلقات الانطلاق وسابق النيازك!',
      'eruption': 'التقط حلقات الانطلاق وتغلّب على الانفجارات!',
      'other': 'التقط حلقات الانطلاق واشقق طريقك!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return 'نجوت! ‎+$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'بلا خدش! ‎+$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'سبقت الحريق',
      'skyfall': 'نجوت من سقوط السماء',
      'eruption': 'تغلّبت على الثوران',
      'other': 'شققت طريقك عبر السرب',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => 'ريح عاتية!';

  @override
  String encounterGaleDetail(String mark) {
    return 'تفادَ الحطام حيث تومض علامة $mark!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'صمدت! ‎+$points';
  }

  @override
  String get encounterGaleWeatheredDetail => 'صمدت أمام الريح العاتية';

  @override
  String get encounterAllRings => 'كل الحلقات!';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'دفعة توربو ‎+$seconds ث';
  }

  @override
  String get encounterFinish => 'النهاية';

  @override
  String get builderMode_pushUp => 'تمارين الضغط';

  @override
  String get builderMode_squat => 'القرفصاء';

  @override
  String get builderMode_jump => 'القفزات';

  @override
  String builderSeconds(String seconds) {
    return '$seconds ث';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes د $seconds ث';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ضغطة',
      many: '$count ضغطة',
      few: '$count ضغطات',
      two: 'ضغطتان',
      one: 'ضغطة واحدة',
      zero: '$count ضغطة',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تمرين قرفصاء',
      many: '$count تمرين قرفصاء',
      few: '$count تمارين قرفصاء',
      two: 'تمرينا قرفصاء',
      one: 'تمرين قرفصاء واحد',
      zero: '$count تمرين قرفصاء',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'مرحلتي بالنقر';

  @override
  String get builderNewLevel_pushUp => 'مرحلتي بالضغط';

  @override
  String get builderNewLevel_squat => 'مرحلتي بالقرفصاء';

  @override
  String get builderNewLevel_jump => 'مرحلتي بالقفز';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'مرحلتي';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'طِر في مرحلتي على Beakbound «$name» ($mode): $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$earned من $total نجمة',
      many: '$earned من $total نجمة',
      few: '$earned من $total نجوم',
      two: '$earned من نجمتين',
      one: '$earned من نجمة واحدة',
      zero: '$earned من $total نجمة',
    );
    return '$_temp0';
  }

  @override
  String get builderBackSemantics => 'رجوع';

  @override
  String get builderKeepIt => 'احتفظ بها';

  @override
  String builderLessSemantics(String name) {
    return 'إنقاص $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'زيادة $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => 'تكرار';

  @override
  String get builderCopy => 'نسخ';

  @override
  String get builderDeleteSemantics => 'حذف';

  @override
  String get builderDelete => 'حذف';

  @override
  String get builderMoreBelow => 'المزيد بالأسفل';

  @override
  String builderStepSemantics(String caption, String value) {
    return '$caption $value';
  }

  @override
  String builderStepHintSemantics(String caption, String value, String hint) {
    return '$caption $value، $hint';
  }

  @override
  String builderPercent(int percent) {
    return '$percent%';
  }

  @override
  String get builderLane => 'المسار';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'أعلى القرفصاء أو أسفلها',
      'other': 'أعلى تمرين الضغط أو أسفله',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'أعلى';

  @override
  String get builderLaneBottom => 'أسفل';

  @override
  String get builderHeight => 'الارتفاع';

  @override
  String get builderHeightHint => 'من السماء';

  @override
  String get builderLowerSemantics => 'تحريك للأسفل';

  @override
  String get builderHigherSemantics => 'تحريك للأعلى';

  @override
  String get builderOpening => 'الفتحة';

  @override
  String builderOpeningHint(int percent) {
    return '$percent% على الأقل';
  }

  @override
  String get builderNarrowerSemantics => 'أضيق';

  @override
  String get builderWiderSemantics => 'أوسع';

  @override
  String get builderMotion => 'الحركة';

  @override
  String get builderMotionGardenHint => 'بوابات الحديقة ثابتة';

  @override
  String get builderMotionStill => 'ثابتة';

  @override
  String get builderMotionGentle => 'هادئة';

  @override
  String get builderMotionLively => 'نشيطة';

  @override
  String get builderMotionGardenToast =>
      'بوابات الحديقة ثابتة: اختر نوعًا آخر لتجعلها تتحرك.';

  @override
  String get builderSway => 'التأرجح';

  @override
  String builderSwayHint(String seconds) {
    return 'تأرجحة واحدة: $seconds';
  }

  @override
  String get builderSwayFast => 'سريع';

  @override
  String get builderSwayMedium => 'متوسط';

  @override
  String get builderSwaySlow => 'بطيء';

  @override
  String get builderPhase => 'عند وصولك';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position من $count';
  }

  @override
  String get builderPhaseHint => 'موضعها في التأرجح';

  @override
  String get builderPhaseEarlierSemantics => 'أبكر في التأرجح';

  @override
  String get builderPhaseLaterSemantics => 'لاحقًا في التأرجح';

  @override
  String get builderLook => 'الشكل';

  @override
  String builderLookSemantics(int number) {
    return 'الشكل $number';
  }

  @override
  String get builderDoor => 'باب حجري';

  @override
  String get builderDoorHint => 'افتحه بالرمي';

  @override
  String get builderDoorNone => 'بلا باب';

  @override
  String get builderDoorNeedsShootToast =>
      'فعّل «ارمِ» في إعدادات المرحلة لتستخدم الأبواب.';

  @override
  String get builderPlace => 'الموضع';

  @override
  String get builderPlaceHint => 'من البداية';

  @override
  String get builderEarlierSemantics => 'أبكر على الخط';

  @override
  String get builderLaterSemantics => 'أبعد على الخط';

  @override
  String builderFamilySemantics(String family) {
    return 'نوع البوابة: $family. تغيير';
  }

  @override
  String get builderChangeFamily => 'غيّر النوع';

  @override
  String get builderItemStar => 'نجمة';

  @override
  String get builderItemTrio => 'ثلاثية نجوم';

  @override
  String get builderItemHeart => 'قلب';

  @override
  String get builderItemEnemy => 'عدو';

  @override
  String get builderItemGate => 'بوابة';

  @override
  String get builderItemStarDetail => 'نجمة واحدة للجمع';

  @override
  String get builderItemTrioDetail => 'الثلاث معًا تمنح مكافأة';

  @override
  String get builderItemHeartDetail => 'يعيد قلبًا واحدًا';

  @override
  String get builderEnemyKind => 'النوع';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'الطائر يطير في أعلى كل قرفصاء وأسفلها: ضع الجوائز على الخطين الأصفرين أو بينهما.',
      'other':
          'الطائر يطير في أعلى كل تمرين ضغط وأسفله: ضع الجوائز على الخطين الأصفرين أو بينهما.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'خفاش بنفسجي';

  @override
  String get builderEnemy_caveBat => 'خفاش الكهف';

  @override
  String get builderEnemy_spitterBeetle => 'خنفساء بصّاقة';

  @override
  String get builderEnemy_duskMoth => 'فراشة الغسق';

  @override
  String get builderEnemy_alleyPigeon => 'حمامة الأزقّة';

  @override
  String get builderEnemy_mummyBat => 'خفاش مومياء';

  @override
  String get builderSummaryTitle => 'هذه المرحلة';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'المدة';

  @override
  String get builderFactStars => 'النجوم';

  @override
  String get builderFactMarks => 'العلامات';

  @override
  String get builderFactWorkout => 'التمرين';

  @override
  String get builderFactPace => 'الإيقاع';

  @override
  String get builderFactBoss => 'الزعيم';

  @override
  String get builderPace_relaxed => 'هادئ';

  @override
  String get builderPace_steady => 'ثابت';

  @override
  String get builderPace_brisk => 'سريع';

  @override
  String get builderSummaryStarterNote =>
      'مرحلة بداية تطير فيها كما هي، أو تعيد مزجها لتصبح مرحلتك.';

  @override
  String get builderSummaryClearedNote =>
      'أنهيتها بنفسك: طرت فيها حتى النهاية.';

  @override
  String get builderSummaryClearNote =>
      'جرّب الطيران فيها حتى خط النهاية لتُحسب منجزة.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    return 'جرّب الطيران فيها، واهزم $boss واعبر الخط لتُحسب منجزة.';
  }

  @override
  String get builderSummaryHowTo =>
      'اختر أداة من اليسار، ثم انقر على السماء. انقر على أي شيء لتغييره، واسحبه لتحريكه.';

  @override
  String get builderFamily_garden_detail => 'ثابتة. يمكن أن تحمل بابًا حجريًا.';

  @override
  String get builderFamily_windLift_detail => 'الفتحة ترتفع وتنخفض.';

  @override
  String get builderFamily_petalGate_detail => 'الفتحة تضيق وتتسع.';

  @override
  String get builderFamily_switchback_detail => 'فتحتان تنزلقان متباعدتين.';

  @override
  String get builderFamily_lanternDrift_detail => 'فوانيس معلّقة تتمايل.';

  @override
  String get builderFamily_sunWheels_detail => 'عجلات تنغلق ثم تبتعد.';

  @override
  String get builderFamily_crystalSteps_detail => 'ثلاث درجات في موجة.';

  @override
  String get builderFamiliesCloseSemantics => 'إغلاق أنواع البوابات';

  @override
  String get builderFamiliesTitle => 'نوع البوابة';

  @override
  String get builderFamiliesSubtitle => 'شكل البوابة وطريقة حركتها.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أعطِ المرحلة اسمًا لا يزيد على $count حرف.',
      many: 'أعطِ المرحلة اسمًا لا يزيد على $count حرفًا.',
      few: 'أعطِ المرحلة اسمًا لا يزيد على $count أحرف.',
      two: 'أعطِ المرحلة اسمًا لا يزيد على حرفين.',
      one: 'أعطِ المرحلة اسمًا من حرف واحد.',
      zero: 'أعطِ المرحلة اسمًا لا يزيد على $count حرف.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort => 'أبعِد خط النهاية أكثر: المرحلة قصيرة جدًا.';

  @override
  String get reach_tooLong => 'قرّب خط النهاية: المرحلة طويلة جدًا.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أشياء كثيرة جدًا: الحد الأقصى للمرحلة $count شيء.',
      many: 'أشياء كثيرة جدًا: الحد الأقصى للمرحلة $count شيئًا.',
      few: 'أشياء كثيرة جدًا: الحد الأقصى للمرحلة $count أشياء.',
      two: 'أشياء كثيرة جدًا: الحد الأقصى للمرحلة شيئان.',
      one: 'أشياء كثيرة جدًا: الحد الأقصى للمرحلة شيء واحد.',
      zero: 'أشياء كثيرة جدًا: الحد الأقصى للمرحلة $count شيء.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap => 'مراحل «انقر وطِر» وحدها تنتهي بزعيم.';

  @override
  String get reach_noGates => 'أضف بوابات ليطير الطائر عبرها.';

  @override
  String get reach_startZone =>
      'قريب جدًا من البداية: انقله إلى ما بعد منطقة البداية.';

  @override
  String get reach_finishRoom => 'اترك مسافة قبل خط النهاية بعد هذه البوابة.';

  @override
  String get reach_overlap => 'بوابتان متداخلتان: باعد بينهما.';

  @override
  String get reach_gateHeight => 'هذه البوابة عالية جدًا أو منخفضة جدًا.';

  @override
  String get reach_gateMotion => 'هذه البوابة لا تتحرك بهذه الطريقة.';

  @override
  String get reach_gateLook => 'لهذه البوابة شكل غير معروف.';

  @override
  String get reach_gateNarrow => 'وسّع فتحة هذه البوابة: الطائر لا يمرّ منها.';

  @override
  String get reach_gateWide => 'فتحة هذه البوابة واسعة جدًا.';

  @override
  String get reach_doorNeedsShoot =>
      'الباب الحجري يحتاج «انقر وطِر» مع تفعيل «ارمِ».';

  @override
  String get reach_doorNeedsGarden => 'بوابة الحديقة وحدها تحمل بابًا حجريًا.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'انتقال ضيق: قد لا تكفي قرفصاء هادئة للوصول في الوقت.',
      'other': 'انتقال ضيق: قد لا يكفي تمرين ضغط هادئ للوصول في الوقت.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'صعود حاد: اترك مسافة أكبر للقفز إلى هذه البوابة.';

  @override
  String get reach_enemyNeedsTap =>
      'الأعداء لا يطيرون إلا في مراحل «انقر وطِر».';

  @override
  String get reach_outsideSky => 'أبقِه داخل السماء.';

  @override
  String get reach_pastFinish => 'ضعه قبل خط النهاية.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'بعيد عن مدى القرفصاء: قرّبه من المسارين.',
      'other': 'بعيد عن مدى تمرين الضغط: قرّبه من المسارين.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'داخل جدار: انقله إلى الفتحة.';

  @override
  String get reach_noStars => 'ضع نجمة واحدة على الأقل.';

  @override
  String get reach_marks => 'علامات النجوم تطلب نجومًا أكثر مما في المرحلة.';

  @override
  String reach_cannotFly(String problem) {
    return 'لا يمكن الطيران في هذه المرحلة بعد ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'لم تُحفظ المرحلة، لذا لا يمكن الطيران فيها بعد. انقر على اسمها لإعادة المحاولة.';

  @override
  String get builderShareBlockedToast =>
      'أصلح الأعلام الحمراء أولًا: بعدها يمكن مشاركة المرحلة.';

  @override
  String get builderEditorBackSemantics => 'العودة إلى الصانع';

  @override
  String get builderSettingsSemantics => 'إعدادات المرحلة';

  @override
  String get builderFly => 'طِر';

  @override
  String get builderTestFly => 'جرّب الطيران';

  @override
  String get builderFlySemantics => 'طِر في هذه المرحلة';

  @override
  String get builderTestFlySemantics => 'جرّب الطيران في المرحلة كلها';

  @override
  String get builderUndoSemantics => 'تراجع';

  @override
  String get builderRedoSemantics => 'إعادة';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice نصيحة',
      many: '$advice نصيحة',
      few: '$advice نصائح',
      two: 'نصيحتان',
      one: 'نصيحة واحدة',
      zero: 'لا نصائح',
    );
    return '$blocking للإصلاح، $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice نصيحة',
      many: '$advice نصيحة',
      few: '$advice نصائح',
      two: 'نصيحتان',
      one: 'نصيحة واحدة',
      zero: 'لا نصائح',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => 'جاهزة للطيران';

  @override
  String get builderShareSemantics => 'رمز المشاركة';

  @override
  String get builderFromHereSemantics => 'جرّب الطيران من هنا';

  @override
  String get builderFromHere => 'من هنا';

  @override
  String get builderStatusStarter => 'مرحلة بداية · شاهد، طِر أو أعد المزج';

  @override
  String get builderStatusSaveFailed => 'تعذّر الحفظ · انقر لإعادة المحاولة';

  @override
  String get builderStatusSaving => 'جارٍ الحفظ…';

  @override
  String get builderStatusSaved => 'حُفظت كل التغييرات';

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
    return '$name. $mode. $status. انقر لإعادة التسمية.';
  }

  @override
  String get builderStarterBanner => 'أعد مزجها لتصبح لك';

  @override
  String get builderRemix => 'إعادة مزج';

  @override
  String get builderRemixSemantics => 'إعادة مزج';

  @override
  String get builderIssuesCloseSemantics => 'إغلاق المشكلات والنصائح';

  @override
  String get builderIssuesReadyTitle => 'جاهزة للطيران!';

  @override
  String get builderIssuesFixTitle => 'للإصلاح قبل الطيران';

  @override
  String get builderIssuesTipsTitle => 'جاهزة، مع بعض النصائح';

  @override
  String get builderIssuesReadyDetail =>
      'لا شيء للإصلاح. جرّب الطيران فيها حتى النهاية لتُحسب منجزة.';

  @override
  String get builderIssuesDetail =>
      'انقر على أي منها للانتقال إلى موضعه على الخط.';

  @override
  String get builderSettingsCloseSemantics => 'إغلاق الإعدادات';

  @override
  String get builderSettingsTitle => 'إعدادات المرحلة';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · تُحفظ التغييرات فور إجرائها';
  }

  @override
  String get builderSettingsName => 'الاسم';

  @override
  String get builderRename => 'إعادة تسمية';

  @override
  String get builderRenameSemantics => 'إعادة تسمية';

  @override
  String get builderSettingsRegion => 'المنطقة';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان · اسحب للمزيد',
      many: '$count مكانًا · اسحب للمزيد',
      few: '$count أماكن · اسحب للمزيد',
      two: 'مكانان · اسحب للمزيد',
      one: 'مكان واحد · اسحب للمزيد',
      zero: '$count مكان · اسحب للمزيد',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'الإيقاع';

  @override
  String get builderSettingsPaceHint => 'سرعة تمرير السماء';

  @override
  String get builderSettingsMarks => 'علامات النجوم';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة موضوعة',
      many: '$count نجمة موضوعة',
      few: '$count نجوم موضوعة',
      two: 'نجمتان موضوعتان',
      one: 'نجمة واحدة موضوعة',
      zero: 'لا نجوم موضوعة',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'علامة النجمتين';

  @override
  String get builderMarkThreeSemantics => 'علامة النجوم الثلاث';

  @override
  String get builderMarksAuto => 'تلقائي: حسب النجوم';

  @override
  String get builderMarksByHand => 'تحديد يدوي';

  @override
  String get builderSettingsControls => 'التحكم';

  @override
  String get builderShootOn => '«ارمِ» مفعّل';

  @override
  String get builderShootOff => '«ارمِ» معطّل';

  @override
  String get builderSprintOn => '«انطلاقة» مفعّلة';

  @override
  String get builderSprintOff => '«انطلاقة» معطّلة';

  @override
  String get builderSettingsBoss => 'خاتمة الزعيم';

  @override
  String get builderSettingsBossHint => 'ينتظر في النهاية';

  @override
  String get builderNoBossSemantics => 'بلا زعيم: خط نهاية';

  @override
  String get builderNoBoss => 'بلا زعيم';

  @override
  String get builderBossShort_baronBat => 'البارون';

  @override
  String get builderBossShort_spitterBeetle => 'البصّاق';

  @override
  String get builderBossShort_duskMoth => 'إمبراطورة';

  @override
  String get builderBossShort_pirate => 'القبطان';

  @override
  String get builderBossShort_dragon => 'التنين';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'الطائر يطير في مسارين: أعلى كل قرفصاء وأسفلها. اللاعب الأبطأ يلقى المرحلة نفسها بسرعة ألطف. لا رمي ولا انطلاقة ولا زعماء هنا.',
      'other':
          'الطائر يطير في مسارين: أعلى كل تمرين ضغط وأسفله. اللاعب الأبطأ يلقى المرحلة نفسها بسرعة ألطف. لا رمي ولا انطلاقة ولا زعماء هنا.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'كل قفزة ترفع الطائر، وبين القفزات ينزلق. لا رمي ولا انطلاقة ولا زعماء هنا.';

  @override
  String get builderStartZoneToast =>
      'أبقِ منطقة البداية فارغة: ضع الأشياء يمين الخط المتقطع.';

  @override
  String get builderSkySemantics =>
      'سماء المرحلة. انقر للوضع، واسحب للتحريك أو التمرير.';

  @override
  String get builderSkyReadOnlySemantics =>
      'سماء المرحلة. انقر على أي شيء لتراه.';

  @override
  String get builderCoachTitle => 'اصنع مرحلتك';

  @override
  String get builderCoachPickTool => 'اختر أداة من اليسار';

  @override
  String get builderCoachTapSky => 'انقر على السماء لتضعها';

  @override
  String get builderCoachTestFly => 'جرّب الطيران فيها!';

  @override
  String get builderCoachDrag => 'اسحب أي شيء لتحريكه · اسحب السماء للتمرير';

  @override
  String get builderTipDrag => 'اسحبه لتحريكه · اسحب السماء للتمرير';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'أعلى القرفصاء',
      'other': 'أعلى تمرين الضغط',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'الأعلى';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'أسفل القرفصاء',
      'other': 'أسفل تمرين الضغط',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'الأسفل';

  @override
  String get builderCanvasStartZoneFull => 'منطقة البداية · أبقِها فارغة';

  @override
  String get builderCanvasStartZone => 'منطقة البداية';

  @override
  String get builderCanvasFinishHere => 'النهاية هنا';

  @override
  String get builderTool_select => 'تحديد';

  @override
  String get builderToolHint_select =>
      'تحديد: انقر على أي شيء لتغييره، واسحبه لتحريكه';

  @override
  String get builderTool_gate => 'بوابة';

  @override
  String get builderToolHint_gate => 'بوابة: انقر على السماء لتضع بوابة';

  @override
  String get builderTool_star => 'نجمة';

  @override
  String get builderToolHint_star => 'نجمة: انقر على السماء لتضع نجمة';

  @override
  String get builderTool_trio => 'ثلاثية';

  @override
  String get builderToolHint_trio =>
      'ثلاثية نجوم: انقر على السماء لتضع ثلاث نجوم';

  @override
  String get builderTool_heart => 'قلب';

  @override
  String get builderToolHint_heart => 'قلب: انقر على السماء لتضع قلبًا';

  @override
  String get builderTool_enemy => 'عدو';

  @override
  String get builderToolHint_enemy => 'عدو: انقر على السماء لتضع عدوًا';

  @override
  String get builderTool_finish => 'النهاية';

  @override
  String get builderToolHint_finish =>
      'النهاية: انقر على السماء لتنقل خط النهاية';

  @override
  String get builderTool_boss => 'الزعيم';

  @override
  String get builderToolHint_boss =>
      'علامة الزعيم: انقر على السماء لتنقل مكان انتظار الزعيم';

  @override
  String get builderStarterToolsToast =>
      'مراحل البداية تبقى كما هي: أعد مزجها لتغييرها.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss': 'نظرة عامة على الخط. $length حتى الزعيم. اسحب للتنقل على الخط.',
      'other': 'نظرة عامة على الخط. $length حتى النهاية. اسحب للتنقل على الخط.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'نظرة عامة على الخط. $length حتى الزعيم. $reps. اسحب للتنقل على الخط.',
      'other':
          'نظرة عامة على الخط. $length حتى النهاية. $reps. اسحب للتنقل على الخط.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '$length حتى الزعيم';
  }

  @override
  String get builtResultTestFlight => 'طيران تجريبي';

  @override
  String get builtResultCleared => 'اكتملت!';

  @override
  String get builtResultBonk => 'طُق!';

  @override
  String get builtResultLanded => 'هبوط';

  @override
  String get builtResultTestTab => 'تجربة';

  @override
  String get builtResultGoalFinish => 'النهاية';

  @override
  String get builtResultGoalBoss => 'الزعيم';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. تم.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اجمع $count نجمة.',
      many: 'اجمع $count نجمة.',
      few: 'اجمع $count نجوم.',
      two: 'اجمع نجمتين.',
      one: 'اجمع نجمة واحدة.',
      zero: 'اجمع $count نجمة.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اجمع $count نجمة. تم.',
      many: 'اجمع $count نجمة. تم.',
      few: 'اجمع $count نجوم. تم.',
      two: 'اجمع نجمتين. تم.',
      one: 'اجمع نجمة واحدة. تم.',
      zero: 'اجمع $count نجمة. تم.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'تم';

  @override
  String get builtResultNotYet => 'ليس بعد';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count نجمة',
      many: 'بقيت $count نجمة',
      few: 'بقيت $count نجوم',
      two: 'بقيت نجمتان',
      one: 'بقيت نجمة',
      zero: 'بقي $count',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'أكمل أولًا';

  @override
  String get builtResultClearedByYou => 'أنهيتها بنفسك';

  @override
  String get builtResultNewBest => 'رقم قياسي!';

  @override
  String get builtResultPractice => 'تدريب';

  @override
  String builtResultBest(int count) {
    return 'الأفضل $count';
  }

  @override
  String get builtResultFirstClear => 'أول إتمام!';

  @override
  String get builtResultStarsCollected => 'النجوم المجموعة';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count من 3 نجوم للمرحلة',
      many: '$count من 3 نجوم للمرحلة',
      few: '$count من 3 نجوم للمرحلة',
      two: 'نجمتان من 3 للمرحلة',
      one: 'نجمة واحدة من 3 للمرحلة',
      zero: 'لا نجوم من 3 للمرحلة',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'المطلوب';

  @override
  String get builtResultWorkout => 'التمرين';

  @override
  String get builtResultGotTo => 'وصلت إلى';

  @override
  String get builtResultScore => 'النقاط';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ضغطة',
      many: 'ضغطة',
      few: 'ضغطات',
      two: 'ضغطتان',
      one: 'ضغطة',
      zero: 'ضغطة',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمرين قرفصاء',
      many: 'تمرين قرفصاء',
      few: 'تمارين قرفصاء',
      two: 'تمرينا قرفصاء',
      one: 'تمرين قرفصاء',
      zero: 'تمرين قرفصاء',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قفزة',
      many: 'قفزة',
      few: 'قفزات',
      two: 'قفزتان',
      one: 'قفزة',
      zero: 'قفزة',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ضغطة أمام الكاميرا',
      many: 'ضغطة أمام الكاميرا',
      few: 'ضغطات أمام الكاميرا',
      two: 'ضغطتان أمام الكاميرا',
      one: 'ضغطة أمام الكاميرا',
      zero: 'ضغطة أمام الكاميرا',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قرفصاء أمام الكاميرا',
      many: 'قرفصاء أمام الكاميرا',
      few: 'قرفصاء أمام الكاميرا',
      two: 'قرفصاء أمام الكاميرا',
      one: 'قرفصاء أمام الكاميرا',
      zero: 'قرفصاء أمام الكاميرا',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'من $length';
  }

  @override
  String get builtResultNotKept => 'لا يُحفظ';

  @override
  String get builtResultNoBest => 'لا نتيجة سابقة';

  @override
  String get builtResultClearedStrip => 'أنهيتها بنفسك · جاهزة للمشاركة!';

  @override
  String builtResultFlownFrom(String from) {
    return 'طرت من $from. طِر فيها كلها لتُحسب منجزة.';
  }

  @override
  String get builtResultTestNothingSaved => 'طيران تجريبي · لا يُحفظ شيء';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'طيران تجريبي · وصلت إلى $reached من $length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return 'وصلت إلى $reached من $length. صِل إلى النهاية لتربح النجوم.';
  }

  @override
  String get builtResultReachFinish => 'صِل إلى خط النهاية لتربح النجوم.';

  @override
  String get builtResultSaved => 'حُفظت على هذا الهاتف';

  @override
  String get builtResultSaving => 'جارٍ حفظ رحلتك…';

  @override
  String get builtResultBuilder => 'الصانع';

  @override
  String get builtResultEditLevel => 'عدّل المرحلة';

  @override
  String get builtResultEdit => 'تعديل';

  @override
  String get builtResultFlyAgain => 'طِر مجددًا';

  @override
  String get builtResultWatchReplay => 'شاهد الإعادة';

  @override
  String get builtResultPreparing => 'جارٍ التحضير…';

  @override
  String get builtResultSessionSaving => 'جارٍ الحفظ…';

  @override
  String get builtResultSaveSession => 'احفظ الجلسة';

  @override
  String get builderShelfTitle => 'صانع المراحل';

  @override
  String get builderShelfPasteCode => 'الصق الرمز';

  @override
  String get builderShelfNewLevel => 'مرحلة جديدة';

  @override
  String get builderShelfSaveFailed => 'لم يُحفظ ذلك. حاول مجددًا من فضلك.';

  @override
  String builderShelfDeleteTitle(String name) {
    return 'أتحذف «$name»؟';
  }

  @override
  String get builderShelfDeleteBody =>
      'تذهب معها أفضل نتائجها. أما الضغط والقرفصاء والقفزات التي أديتها فيها فتبقى محسوبة.';

  @override
  String get builderShelfDelete => 'احذف';

  @override
  String builderShelfDeleted(String name) {
    return 'حُذفت «$name».';
  }

  @override
  String get builderShelfFixFirst =>
      'أصلح ما هو مُعلَّم بالأحمر قبل المشاركة: انقر على «أصلحها».';

  @override
  String get builderShelfCodeCopied => 'نُسخ الرمز! الصقه لصديقك.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'نُسخ الرمز! طِر فيها حتى النهاية أيضًا، ليعرف أصدقاؤك أنها ممكنة.';

  @override
  String get builderShelfNotReady =>
      'هذه المرحلة ليست جاهزة للطيران بعد: انقر على «أصلحها».';

  @override
  String get builderShelfPasteMissingTitle => 'لا يوجد رمز مرحلة للصقه';

  @override
  String get builderShelfPasteNewerTitle => 'مرحلة من إصدار أحدث من Beakbound';

  @override
  String get builderShelfPasteDamagedTitle => 'اختلطت حروف هذا الرمز';

  @override
  String get builderShelfPasteMissingBody =>
      'انسخ رمز مرحلة صديقك (يبدأ بـ BEAK1.‎) ثم انقر على «الصق الرمز» مجددًا.';

  @override
  String get builderShelfPasteNewerBody =>
      'حدّث Beakbound لتطير فيها، ثم الصق الرمز مجددًا.';

  @override
  String get builderShelfPasteDamagedBody =>
      'جزء منه ناقص أو مكتوب خطأً. اطلب من صديقك أن ينسخ الرمز كاملًا مرة أخرى.';

  @override
  String builderShelfImported(String name) {
    return '«$name» على رفّك الآن!';
  }

  @override
  String get builderShelfUnavailable => 'مراحلك تحتاج إلى لحظة.';

  @override
  String get builderShelfMine => 'مراحلي';

  @override
  String get builderShelfStarters => 'مراحل البداية';

  @override
  String get builderShelfStartersHint =>
      'طِر في إحداها، أو أعد مزجها لتصبح مرحلتك';

  @override
  String get builderShelfEmptyTitle => 'اصنع مرحلتك الأولى';

  @override
  String get builderShelfEmptyBody =>
      'ضع البوابات والنجوم والقلوب بيدك، وحدّد خط النهاية، ثم جرّب الطيران فيها.';

  @override
  String get builderShelfPasteFriend => 'الصق رمز صديقك';

  @override
  String get builderShelfNeedsWork => 'تحتاج إلى عمل';

  @override
  String get builderShelfClearedByYou => 'أنهيتها بنفسك';

  @override
  String get builderShelfFromFriend => 'من صديق';

  @override
  String get builderShelfFly => 'طِر';

  @override
  String builderShelfFlySemantics(String name) {
    return 'طِر في $name';
  }

  @override
  String get builderShelfFixIt => 'أصلحها';

  @override
  String builderShelfFixSemantics(String name) {
    return 'أصلح $name';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return 'عدّل $name';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return 'شارك $name';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return 'شارك $name: أنهيتها بنفسك';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'خيارات أخرى لـ $name';
  }

  @override
  String get builderShelfRemix => 'إعادة مزج';

  @override
  String builderShelfRemixSemantics(String name) {
    return 'أعد مزج $name';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شيء للإصلاح في المحرّر',
      many: '$count شيئًا للإصلاح في المحرّر',
      few: '$count أشياء للإصلاح في المحرّر',
      two: 'شيئان للإصلاح في المحرّر',
      one: 'شيء واحد للإصلاح في المحرّر',
      zero: '$count شيء للإصلاح في المحرّر',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة',
      many: '$count نجمة',
      few: '$count نجوم',
      two: 'نجمتان',
      one: 'نجمة واحدة',
      zero: '$count نجمة',
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
    return '$name. $mode في $region. $length.';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'الأفضل: $stars من 3 نجوم.',
      many: 'الأفضل: $stars من 3 نجوم.',
      few: 'الأفضل: $stars من 3 نجوم.',
      two: 'الأفضل: نجمتان من 3.',
      one: 'الأفضل: نجمة واحدة من 3.',
      zero: 'الأفضل: لا نجوم من 3.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تحتاج إلى عمل: $count شيء للإصلاح.',
      many: 'تحتاج إلى عمل: $count شيئًا للإصلاح.',
      few: 'تحتاج إلى عمل: $count أشياء للإصلاح.',
      two: 'تحتاج إلى عمل: شيئان للإصلاح.',
      one: 'تحتاج إلى عمل: شيء واحد للإصلاح.',
      zero: 'تحتاج إلى عمل: $count شيء للإصلاح.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'أنهيتها بنفسك.';

  @override
  String get builderShelfFromFriendSemantics => 'من صديق.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return 'شاهد $name. $mode، $length، $fact.';
  }

  @override
  String get builderShelfRemixSuffix => 'ريمكس';

  @override
  String get builderShelfCopySuffix => 'نسخة';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get starter_t_tap_1_name => 'قفزة في الحديقة';

  @override
  String get starter_t_push_1_name => 'عشر تمارين ضغط';

  @override
  String get starter_t_squat_1_name => 'قرفصاء الدرج';

  @override
  String get starter_t_jump_1_name => 'خليج القفز';

  @override
  String get starter_t_tap_boss_name => 'جسر البارون';

  @override
  String get builderPickCloseNewLevel => 'إغلاق المرحلة الجديدة';

  @override
  String get builderPickModeTitle => 'ماذا ستكون؟';

  @override
  String get builderPickRegionTitle => 'أين ستطير؟';

  @override
  String get builderPickModeSubtitle =>
      'اختر طريقة الطيران فيها (لا يمكنك تغييرها لاحقًا). تجرّب كل مرحلة باللمس.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · اختر أين تطير. يمكنك تغيير هذا لاحقًا.';
  }

  @override
  String get builderPickTouchLine => 'انقر لترفرف. بوابات ونجوم وأعداء وزعيم.';

  @override
  String get builderPickPushUpLine =>
      'مسار عالٍ وآخر منخفض: كل نزول تمرين ضغط.';

  @override
  String get builderPickSquatLine => 'مسار عالٍ وآخر منخفض: كل نزول قرفصاء.';

  @override
  String get builderPickJumpLine => 'اقفز لترتفع. بوابات في أي مكان من السماء.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'كاميرا';

  @override
  String get builderPickSuggested => 'مقترحة';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region، مقترحة';
  }

  @override
  String get builderPickClose => 'إغلاق';

  @override
  String get builderPickNotYet => 'ليس بعد: أصلح ما هو مُعلَّم بالأحمر أولًا.';

  @override
  String get builderPickShare => 'رمز المشاركة';

  @override
  String get builderPickShareLine =>
      'انسخ رمزًا يستطيع صديقك لصقه في Beakbound لديه.';

  @override
  String get builderPickDuplicate => 'تكرار';

  @override
  String get builderPickDuplicateLine => 'اصنع نسخة لتجرّب فكرة أخرى.';

  @override
  String get builderPickDeleteLine => 'تخلّص من المرحلة. سنسألك أولًا.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'إلغاء الاستيراد';

  @override
  String get builderPickImportTitle => 'مرحلة للطيران!';

  @override
  String get builderPickImportSubtitle => 'شاركك أحدهم هذه المرحلة.';

  @override
  String get builderPickClearedByMaker => 'أنهاها صانعها';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة للجمع',
      many: '$count نجمة للجمع',
      few: '$count نجوم للجمع',
      two: 'نجمتان للجمع',
      one: 'نجمة واحدة للجمع',
      zero: '$count نجمة للجمع',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    return 'في نهايتها $boss';
  }

  @override
  String get builderPickNotFlown => 'لم يطر صانعها فيها حتى النهاية بعد.';

  @override
  String get builderPickRoute => 'الخط';

  @override
  String builderPickAlreadyHave(String name) {
    return 'لديك هذه المرحلة من قبل: «$name».';
  }

  @override
  String get builderPickImportCopy => 'استورد نسخة';

  @override
  String get builderPickOpenYours => 'افتح نسختك';

  @override
  String get builderPickImport => 'استورد';

  @override
  String get builderShelfRenameCancelSemantics => 'إلغاء إعادة التسمية';

  @override
  String get builderShelfRenameTitle => 'سمِّ مرحلتك';

  @override
  String get builderShelfRenameEmpty => 'الاسم يحتاج إلى حرف أو اثنين';

  @override
  String get builderShelfRenameSaveSemantics => 'حفظ الاسم';

  @override
  String get builderShelfRenameSave => 'احفظ';

  @override
  String get coopMode_roped => 'بالحبل';

  @override
  String get coopMode_free => 'بلا حبل';

  @override
  String get coopMode_duel => '1 ضد 1';

  @override
  String get coopTitle => 'نطير معًا';

  @override
  String get coopPlayersTag => 'لاعبان · هاتف واحد';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode · الأفضل $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: لا نتيجة بعد';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count مبارزة',
      many: '$mode · $count مبارزة',
      few: '$mode · $count مبارزات',
      two: '$mode · مبارزتان',
      one: '$mode · مبارزة واحدة',
      zero: '$mode · $count مبارزة',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode: أول مبارزة';
  }

  @override
  String get coopRopedLead => 'طائراكما يتشاركان حبلًا واحدًا.';

  @override
  String get coopRopedBody =>
      'رفرفا معًا لتصعدا عاليًا: الطائر الذي يرفرف وحده يرفع الاثنين، لكن قليلًا فقط. انطلق لتجرّ شريكك معك.';

  @override
  String get coopFreeLead => 'بلا حبل:';

  @override
  String get coopFreeBody =>
      'كل طائر يطير وحده ولا يصطدم إلا بالآخر. القلوب والدرع والنقاط تبقى مشتركة.';

  @override
  String get duelLead => 'مبارزة!';

  @override
  String get duelBody =>
      'لكل طائر قلوبه الخاصة. التقط صناديق المفاجآت: بعضها يرسل خفافيش أو خنفساء بصّاقة أو نيازك نحو منافسك، وبعضها يمنحك قلبًا أو درعًا أو قوة النجوم. آخر طائر يبقى في الجو يفوز.';

  @override
  String get coopStart => 'نطير معًا!';

  @override
  String get duelStart => 'إلى المبارزة!';

  @override
  String get coopFlightSemantics =>
      'اللاعب 1 ينقر النصف الأيسر ليرفرف، واللاعب 2 النصف الأيمن';

  @override
  String get coopPauseSemantics => 'إيقاف الرحلة مؤقتًا';

  @override
  String coopShootSemantics(int player) {
    return 'رمي اللاعب $player';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'انطلاقة اللاعب $player';
  }

  @override
  String coopPlayerShort(int player) {
    return 'P$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'اللاعب $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'مغناطيس النجوم: بقيت $seconds ثانية',
      many: 'مغناطيس النجوم: بقيت $seconds ثانية',
      few: 'مغناطيس النجوم: بقيت $seconds ثوانٍ',
      two: 'مغناطيس النجوم: بقيت ثانيتان',
      one: 'مغناطيس النجوم: بقيت ثانية واحدة',
      zero: 'مغناطيس النجوم: انتهى الوقت',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'شحن المغناطيس: $charge من $gates بوابة مثالية',
      many: 'شحن المغناطيس: $charge من $gates بوابة مثالية',
      few: 'شحن المغناطيس: $charge من $gates بوابات مثالية',
      two: 'شحن المغناطيس: $charge من بوابتين مثاليتين',
      one: 'شحن المغناطيس: $charge من بوابة مثالية واحدة',
      zero: 'شحن المغناطيس: $charge من $gates بوابة مثالية',
    );
    return '$_temp0';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds ث',
    );
    return '$_temp0';
  }

  @override
  String get coopCountdownRoped => 'الحبل جاهز. استعدا، انتباه…';

  @override
  String get coopCountdownFree => 'استعدا، انتباه…';

  @override
  String get duelCountdown => 'استعدا للمبارزة…';

  @override
  String get coopCountdownRopedHint =>
      'رفرفا معًا لتصعدا عاليًا.\nانطلق لتجرّ شريكك معك!';

  @override
  String get coopCountdownFreeHint =>
      'كل طائر يطير وحده.\nتشاركا القلوب، واعبرا البوابات!';

  @override
  String get duelCountdownHint =>
      'التقطا صناديق المفاجآت!\nآخر طائر يبقى في الجو يفوز.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'قوة النجوم للاعب $player: بقيت $seconds ثانية',
      many: 'قوة النجوم للاعب $player: بقيت $seconds ثانية',
      few: 'قوة النجوم للاعب $player: بقيت $seconds ثوانٍ',
      two: 'قوة النجوم للاعب $player: بقيت ثانيتان',
      one: 'قوة النجوم للاعب $player: بقيت ثانية واحدة',
      zero: 'قوة النجوم للاعب $player: انتهى الوقت',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'الرئيسية';

  @override
  String get coopChangeBirds => 'تغيير الطيور';

  @override
  String get coopSaved => 'حُفظت';

  @override
  String get coopSaving => 'جارٍ الحفظ…';

  @override
  String get coopSaveSession => 'احفظ الجلسة';

  @override
  String get duelRematch => 'إعادة المباراة';

  @override
  String get coopFlyAgain => 'نطير مجددًا!';

  @override
  String duelWinner(int player) {
    return 'اللاعب $player يفوز!';
  }

  @override
  String get duelDraw => 'تعادل!';

  @override
  String get duelStopped => 'توقفت المبارزة';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first ضد $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return 'فوز $winner على $loser';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize نحو P$rival!';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize!';
  }

  @override
  String get duelPrize_batSwarm => 'سرب خفافيش';

  @override
  String get duelPrize_spitter => 'خنفساء بصّاقة';

  @override
  String get duelPrize_meteorShower => 'زخّة نيازك';

  @override
  String get duelPrize_heart => 'قلب';

  @override
  String get duelPrize_shield => 'درع';

  @override
  String get duelPrize_starPower => 'قوة النجوم';

  @override
  String get coopTapLeftHalf => 'انقر النصف الأيسر';

  @override
  String get coopTapRightHalf => 'انقر النصف الأيمن';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'اللاعب $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'اللاعب $player · انقر هذا الجانب';
  }

  @override
  String get coopKeysP1 => 'P1 · رفرف: W · ارمِ: D · انطلق: A';

  @override
  String get coopKeysP2 => 'P2 · رفرف: فوق · ارمِ: يمين · انطلق: يسار';

  @override
  String get coopRopedSemantics => 'بالحبل: الطائران يتشاركان حبلًا';

  @override
  String get coopFreeSemantics => 'بلا حبل: كل طائر يطير وحده';

  @override
  String get duelModeSemantics => '1 ضد 1: الطائران يتبارزان';

  @override
  String get duelVersus => 'ضد';

  @override
  String get coopSessionSaved => 'حُفظت الجلسة · شاهدها في السجلّات';

  @override
  String get coopNewTeamBest => 'أفضل نتيجة للفريق!';

  @override
  String get coopWhatATeam => 'يا له من فريق!';

  @override
  String coopPairCaption(String first, String second) {
    return '$first و$second';
  }

  @override
  String get coopTeamScore => 'نقاط الفريق';

  @override
  String get coopTeamBest => 'أفضل نتيجة للفريق';

  @override
  String get coopNewTeamBestRibbon => 'رقم قياسي للفريق!';

  @override
  String get coopStatFlightTime => 'مدة الطيران';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نجمة',
      many: 'نجمة',
      few: 'نجوم',
      two: 'نجمتان',
      one: 'نجمة',
      zero: 'نجمة',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بوابة',
      many: 'بوابة',
      few: 'بوابات',
      two: 'بوابتان',
      one: 'بوابة',
      zero: 'بوابة',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'حصة الرفرفة';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رفرفة P$player',
      many: 'رفرفة P$player',
      few: 'رفرفات P$player',
      two: 'رفرفتا P$player',
      one: 'رفرفة P$player',
      zero: 'رفرفة P$player',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'مدة المبارزة $time';
  }

  @override
  String get duelSeries => 'المواجهات';

  @override
  String get duelHeartsLeft => 'القلوب المتبقية';

  @override
  String get duelBoxesOpened => 'الصناديق المفتوحة';

  @override
  String get duelHitsLanded => 'الإصابات';

  @override
  String get coopPauseSubtitle =>
      'طائراكما يستريحان بانتظاركما. سنعدّ لكما قبل البدء.';

  @override
  String get coopFinishFlight => 'إنهاء الرحلة';

  @override
  String get cameraLabIntro => 'ضع هاتفك منخفضًا بالعرض، مواجهًا لك أو بجانبك.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'اقتربنا · نحتاج رؤية أوضح لـ: $parts';
  }

  @override
  String get cameraLabJointShoulder => 'الكتف';

  @override
  String get cameraLabJointElbow => 'المرفق';

  @override
  String get cameraLabJointWrist => 'الرسغ';

  @override
  String get cameraLabJointHip => 'الورك';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first، $rest';
  }

  @override
  String get cameraLabStarting => 'جارٍ تشغيل الكاميرا…';

  @override
  String get cameraLabDenied =>
      'الوصول إلى الكاميرا مطفأ. اسمح به في إعدادات التطبيق، ثم حاول مجددًا.';

  @override
  String cameraLabFailed(String error) {
    return 'تعذّر تشغيل الكاميرا: $error';
  }

  @override
  String get cameraLabStopped =>
      'توقفت الكاميرا. انقر على «شغّل الكاميرا» لإعادة المعايرة.';

  @override
  String get cameraLabBack => 'مختبر الكاميرا · العودة إلى الرئيسية';

  @override
  String get cameraLabStepShow => '1. أظهر ذراعيك ووركك';

  @override
  String get cameraLabStepPushUps => '2. أدِّ ضغطتين';

  @override
  String get cameraLabStepMove => '3. حرّك طائرك!';

  @override
  String get cameraLabStepSquat => 'اعرف مدى قرفصائك';

  @override
  String get cameraLabStepJump => 'اتخذ وضعية الوقوف';

  @override
  String get cameraLabPushUpHelp =>
      'الهاتف منخفض، مواجهًا لك أو بجانبك.\nتواجهه؟ أظهر كتفيك وذراعًا ووركًا.\nانزل واصعد مرتين على مهلك.';

  @override
  String get cameraLabSquatHelp =>
      'قِف ثابتًا، اقرفص براحة وابقَ قليلًا، ثم انهض. اقرفص لتهبط، وقِف لترتفع.';

  @override
  String get cameraLabJumpHelp =>
      'قِف أمام الهاتف بحيث يظهر جسمك كله وقدماك. اثبت قليلًا، ثم اقفز قفزات صغيرة. قفزة واحدة = اندفاعة كبيرة.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'المعايرة\nتمّت $done من $total',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'المعايرة\n$percent% مكتملة';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اختبار التحكم\n$count ضغطة',
      many: 'اختبار التحكم\n$count ضغطة',
      few: 'اختبار التحكم\n$count ضغطات',
      two: 'اختبار التحكم\nضغطتان',
      one: 'اختبار التحكم\nضغطة واحدة',
      zero: 'اختبار التحكم\n$count ضغطة',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اختبار التحكم\n$count تمرين قرفصاء',
      many: 'اختبار التحكم\n$count تمرين قرفصاء',
      few: 'اختبار التحكم\n$count تمارين قرفصاء',
      two: 'اختبار التحكم\nتمرينا قرفصاء',
      one: 'اختبار التحكم\nتمرين قرفصاء واحد',
      zero: 'اختبار التحكم\n$count تمرين قرفصاء',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اختبار التحكم\n$count قفزة',
      many: 'اختبار التحكم\n$count قفزة',
      few: 'اختبار التحكم\n$count قفزات',
      two: 'اختبار التحكم\nقفزتان',
      one: 'اختبار التحكم\nقفزة واحدة',
      zero: 'اختبار التحكم\n$count قفزة',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz هرتز · $ms مللي ثانية (p95)';
  }

  @override
  String get cameraLabStartingButton => 'جارٍ التشغيل…';

  @override
  String get cameraLabRecalibrate => 'أعد المعايرة';

  @override
  String get cameraLabStartCamera => 'شغّل الكاميرا';

  @override
  String get cameraLabTapStart => 'انقر على «شغّل الكاميرا»';

  @override
  String cameraLabTry(String mode) {
    return 'جرّب $mode';
  }

  @override
  String get cameraBadgeWaking => 'جارٍ التشغيل';

  @override
  String get cameraBadgeLive => 'مباشر';

  @override
  String get cameraBadgeLockedOn => 'تم الرصد';

  @override
  String get cameraBadgeOffline => 'متوقفة';

  @override
  String get trackingCatchingUp => 'الكاميرا تلحق بك';

  @override
  String get trackingStepIntoOutline => 'ادخل في حدود الجسم المرسومة';

  @override
  String get trackingKeepShoulders => 'أبقِ كتفيك في الصورة';

  @override
  String get trackingShowSide => 'أظهر كتفًا ومرفقًا ورسغًا ووركًا من الجانب';

  @override
  String get trackingMoveCloser => 'اقترب قليلًا';

  @override
  String get trackingGetDown => 'انزل إلى وضعية تمرين الضغط';

  @override
  String get trackingHandsOnFloor => 'ضع يديك على الأرض ومدّ جسمك خلفك';

  @override
  String get trackingExtendBody => 'مدّ جسمك خلف يديك أكثر قليلًا';

  @override
  String get trackingComfortableRange => 'ابقَ ضمن مدى مريح لتمرين الضغط';

  @override
  String get trackingPlaceHands => 'ضع يديك على الأرض وجسمك خلفهما';

  @override
  String get trackingFrontTracked => 'نتتبّعك من الأمام · أبقِ يديك في الصورة';

  @override
  String get trackingBodyInView => 'جسمك في الصورة · يمكنك النظر إلى الأسفل';

  @override
  String get trackingArmsTracked => 'نتتبّع الذراعين · فحص الساقين محدود';

  @override
  String get trackingFindTop => 'جد وضعية علوية مريحة';

  @override
  String get trackingCalibrated => 'تمت المعايرة! جرّب تحريك طائرك.';

  @override
  String get trackingFreshFrame => 'بانتظار صورة جديدة';

  @override
  String get trackingDistanceChanged =>
      'تغيّرت المسافة عن الكاميرا · أعد المعايرة';

  @override
  String get trackingKeepArm => 'أبقِ ذراعًا في الصورة';

  @override
  String get trackingSquatStepBack =>
      'ارجع للخلف لتظهر كتفاك ووركاك وركبتاك وقدماك';

  @override
  String get trackingSquatFaceCamera => 'واجه الكاميرا وقدماك على الأرض';

  @override
  String get trackingSquatControls => 'اقرفص لتهبط · قِف لترتفع';

  @override
  String get trackingStartingDistance =>
      'واجه الكاميرا من مسافتك الأولى · أعد المعايرة إن تحرّكت';

  @override
  String get trackingFeetPlanted => 'أبقِ قدميك ثابتتين في مكانك الأول';

  @override
  String get trackingSquatStandTall => 'قِف منتصبًا وثابتًا وقدماك في الصورة';

  @override
  String get trackingStandStill => 'قِف منتصبًا وثابتًا للحظة';

  @override
  String get trackingSquatDepth => 'اقرفص إلى عمق مريح وابقَ قليلًا';

  @override
  String get trackingSquatHold => 'اقرفص براحة، ثم ابقَ للحظة';

  @override
  String get trackingSquatHoldBriefly => 'ابقَ في هذه القرفصاء المريحة قليلًا';

  @override
  String get trackingSquatStandUp => 'انهض لتُنهي المعايرة';

  @override
  String get trackingSquatReady => 'هيا! اقرفص لتهبط · قِف لترتفع';

  @override
  String get trackingJumpStepBack => 'ارجع للخلف لتظهر كتفاك ووركاك وقدماك';

  @override
  String get trackingJumpFaceCamera => 'واجه الكاميرا واترك مساحة فوقك للقفز';

  @override
  String get trackingJumpSmall =>
      'القفزات الصغيرة تكفي · اهبط قبل أن تقفز مجددًا';

  @override
  String get trackingJumpStandStill => 'قِف ثابتًا وجسمك كله وقدماك في الصورة';

  @override
  String get trackingJumpReady => 'هيا! قفزة صغيرة واحدة تمنحك اندفاعة كبيرة.';

  @override
  String get trackingFindPosition => 'اتخذ وضعيتك';

  @override
  String get trackingInterrupted => 'انقطع التتبّع';

  @override
  String get trackingCameraInterrupted =>
      'انقطعت الكاميرا. تحقق من إذن الكاميرا وحاول مجددًا.';

  @override
  String get trackingCameraAway => 'توقفت الكاميرا حين غادرت التطبيق';

  @override
  String get trackingJumpBoost => 'اقفز لاندفاعة كبيرة';

  @override
  String get trackingJumpLand => 'اهبط لتستعد للقفزة التالية';

  @override
  String trackingLowerMore(int step, int total) {
    return 'انزل قليلًا بعد · $step من $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'انزل براحة · $step من $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'ادفع لتصعد · $step من $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'طابِق مداك المريح الأول · $step من $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'تعذّر حفظ هذا التغيير. حاول مجددًا من فضلك. ($error)';
  }

  @override
  String get commonDelete => 'حذف';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count نجمة',
      many: 'بقيت $count نجمة',
      few: 'بقيت $count نجوم',
      two: 'بقيت نجمتان',
      one: 'بقيت نجمة واحدة',
      zero: 'بقيت $count نجمة',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'عشّك يحتاج إلى لحظة.';

  @override
  String get homeSettings => 'الإعدادات';

  @override
  String homeGreetingFirst(String bird) {
    return 'مرحبًا، أنا $bird! هيا نطير؟';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'اكتملت المغامرة! $bird فخور بك.',
      'female': 'اكتملت المغامرة! $bird فخورة بك.',
      'other': 'اكتملت المغامرة! $bird فخور بك.',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird مستعد. وأنت؟',
      'female': '$bird مستعدة. وأنت؟',
      'other': '$bird مستعد. وأنت؟',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'بلا نهاية';

  @override
  String get homeEndlessDetail => 'طِر أبعد ما تستطيع';

  @override
  String get homeEndlessSemantics => 'بلا نهاية. طِر أبعد ما تستطيع.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: 'بلا نهاية. طِر أبعد ما تستطيع. الأفضل: $best نجمة.',
      many: 'بلا نهاية. طِر أبعد ما تستطيع. الأفضل: $best نجمة.',
      few: 'بلا نهاية. طِر أبعد ما تستطيع. الأفضل: $best نجوم.',
      two: 'بلا نهاية. طِر أبعد ما تستطيع. الأفضل: نجمتان.',
      one: 'بلا نهاية. طِر أبعد ما تستطيع. الأفضل: نجمة واحدة.',
      zero: 'بلا نهاية. طِر أبعد ما تستطيع. الأفضل: $best نجمة.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'الأفضل';

  @override
  String get homeBestNone => 'سجّل أول نتيجة لك';

  @override
  String get homeCampaignTitle => 'الحملة';

  @override
  String get homeCampaignDone => 'كل رسالة إلى صاحبها';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'الحملة. التالي: $level. $stars من $total نجمة.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'الحملة. كل رسالة إلى صاحبها. $stars من $total نجمة.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'ألعاب صغيرة';

  @override
  String get homeMiniGamesDetail => 'تمارين · لاعبان';

  @override
  String get homeMiniGamesSemantics =>
      'ألعاب صغيرة. ضغط، قرفصاء، قفز، أو لاعبان.';

  @override
  String get homeBuilderTitle => 'صانع المراحل';

  @override
  String get homeBuilderDetail => 'اصنع · طِر · شارك';

  @override
  String get homeBuilderSemantics =>
      'صانع المراحل. اصنع مراحلك، وطِر فيها، وشاركها.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يُفتح بعد $count رحلة',
      many: 'يُفتح بعد $count رحلة',
      few: 'يُفتح بعد $count رحلات',
      two: 'يُفتح بعد رحلتين',
      one: 'يُفتح بعد رحلة واحدة',
      zero: 'يُفتح بعد $count رحلة',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'صانع المراحل. مقفل. يُفتح بعد $count رحلة.',
      many: 'صانع المراحل. مقفل. يُفتح بعد $count رحلة.',
      few: 'صانع المراحل. مقفل. يُفتح بعد $count رحلات.',
      two: 'صانع المراحل. مقفل. يُفتح بعد رحلتين.',
      one: 'صانع المراحل. مقفل. يُفتح بعد رحلة واحدة.',
      zero: 'صانع المراحل. مقفل. يُفتح بعد $count رحلة.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'مغامرة';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'مغامرة اليوم. اكتمل $done من 3 أهداف.',
      many: 'مغامرة اليوم. اكتمل $done من 3 أهداف.',
      few: 'مغامرة اليوم. اكتمل $done من 3 أهداف.',
      two: 'مغامرة اليوم. اكتمل هدفان من 3.',
      one: 'مغامرة اليوم. اكتمل هدف واحد من 3.',
      zero: 'مغامرة اليوم. لم يكتمل أي هدف من 3.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'الطيور';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'الطيور. تطير مع $bird.';
  }

  @override
  String get homeDockUpgrades => 'التطويرات';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'التطويرات. $stars نجمة للإنفاق.',
      many: 'التطويرات. $stars نجمة للإنفاق.',
      few: 'التطويرات. $stars نجوم للإنفاق.',
      two: 'التطويرات. نجمتان للإنفاق.',
      one: 'التطويرات. نجمة واحدة للإنفاق.',
      zero: 'التطويرات. لا نجوم للإنفاق.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'جواز السفر';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'جواز السفر. $earned من $total ميدالية.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'السجلّات';

  @override
  String get homeMiniGamesPickerTitle => 'ألعاب صغيرة';

  @override
  String get homeMiniGamesPickerIntro => 'تحرّك لتطير، أو شارك الهاتف مع صديق.';

  @override
  String get homeMiniGamesCloseSemantics => 'إغلاق الألعاب الصغيرة';

  @override
  String get homeMiniGamesPushUpCard => 'انزل لتهبط.\nادفع لتحلّق.';

  @override
  String get homeMiniGamesSquatCard => 'اقرفص للأسفل.\nقِف لتحلّق.';

  @override
  String get homeMiniGamesJumpCard => 'اقفز لترتفع.\nانزلق نحو النجوم.';

  @override
  String get homeMiniGamesCoopCard => 'لاعبان، هاتف واحد.\nتعاونا أو تبارزا.';

  @override
  String get homeMiniGamesCamera => 'كاميرا';

  @override
  String get homeMiniGamesPlayers => 'لاعبان';

  @override
  String get homeMiniGamesCoop => 'نطير معًا';

  @override
  String get birdsTitle => 'تعرّف إلى طاقم الطيران.';

  @override
  String birdsFlownTag(int flown, int total) {
    return 'طرت مع $flown من $total';
  }

  @override
  String get birdsStatusCopilot => 'رفيق رحلتك';

  @override
  String get birdsStatusReady => 'على أهبة الطيران';

  @override
  String get birdsStatusLocked => 'مقفل';

  @override
  String get birdsNotFlown => 'لم تطر بعد';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رحلة',
      many: '$count رحلة',
      few: '$count رحلات',
      two: 'رحلتان',
      one: 'رحلة واحدة',
      zero: '$count رحلة',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return 'طِر مع $bird';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return 'طِر مع $bird بدلًا من $current';
  }

  @override
  String birdsUnlock(String bird) {
    return 'افتح $bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'افتح $bird مقابل $price نجمة',
      many: 'افتح $bird مقابل $price نجمة',
      few: 'افتح $bird مقابل $price نجوم',
      two: 'افتح $bird مقابل نجمتين',
      one: 'افتح $bird مقابل نجمة واحدة',
      zero: 'افتح $bird مقابل $price نجمة',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'افتح $bird مقابل $price نجمة، النجوم لا تكفي بعد',
      many: 'افتح $bird مقابل $price نجمة، النجوم لا تكفي بعد',
      few: 'افتح $bird مقابل $price نجوم، النجوم لا تكفي بعد',
      two: 'افتح $bird مقابل نجمتين، النجوم لا تكفي بعد',
      one: 'افتح $bird مقابل نجمة واحدة، النجوم لا تكفي بعد',
      zero: 'افتح $bird مقابل $price نجمة، النجوم لا تكفي بعد',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'معك في الرحلة';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird، معك في الرحلة';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird، معك في الرحلة، بانتظار أول رحلة';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird، يُفتح مقابل $price نجمة',
      many: '$bird، يُفتح مقابل $price نجمة',
      few: '$bird، يُفتح مقابل $price نجوم',
      two: '$bird، يُفتح مقابل نجمتين',
      one: '$bird، يُفتح مقابل نجمة واحدة',
      zero: '$bird، يُفتح مقابل $price نجمة',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird، جديد';
  }

  @override
  String get birdsTagFlying => 'في الرحلة';

  @override
  String get birdsTagNew => 'جديد';

  @override
  String get bird_0_description => 'طائر صغير، سماء كبيرة.';

  @override
  String get bird_0_trail => 'فقاعات الشمس';

  @override
  String get bird_1_description => 'خدود وردية، عُرف مجعّد، وقلب كبير.';

  @override
  String get bird_1_trail => 'قلوب خوخية';

  @override
  String get bird_2_description => 'طنّان صغير. غصن نعناع. سرعة قصوى.';

  @override
  String get bird_2_trail => 'أوراق النعناع';

  @override
  String get bird_3_description => 'بومة حالمة تطير على ضوء النجوم.';

  @override
  String get bird_3_trail => 'بريق غبار النجوم';

  @override
  String get upgradesWalletLabel => 'رصيد\nنجومك';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars نجمة للإنفاق',
      many: '$stars نجمة للإنفاق',
      few: '$stars نجوم للإنفاق',
      two: 'نجمتان للإنفاق',
      one: 'نجمة واحدة للإنفاق',
      zero: 'لا نجوم للإنفاق',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'طوّر طائرك.';

  @override
  String get upgradesIntro =>
      'انقر على ترس لترى ما يفعله. كل نجمة تلتقطها في الرحلة تستطيع إنفاقها.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power، المستوى $level من $max. المستوى التالي مقابل $cost نجمة',
      many: '$power، المستوى $level من $max. المستوى التالي مقابل $cost نجمة',
      few: '$power، المستوى $level من $max. المستوى التالي مقابل $cost نجوم',
      two: '$power، المستوى $level من $max. المستوى التالي مقابل نجمتين',
      one: '$power، المستوى $level من $max. المستوى التالي مقابل نجمة واحدة',
      zero: '$power، المستوى $level من $max. المستوى التالي مقابل $cost نجمة',
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
          '$power، المستوى $level من $max. المستوى التالي مقابل $cost نجمة، النجوم لا تكفي بعد',
      many:
          '$power، المستوى $level من $max. المستوى التالي مقابل $cost نجمة، النجوم لا تكفي بعد',
      few:
          '$power، المستوى $level من $max. المستوى التالي مقابل $cost نجوم، النجوم لا تكفي بعد',
      two:
          '$power، المستوى $level من $max. المستوى التالي مقابل نجمتين، النجوم لا تكفي بعد',
      one:
          '$power، المستوى $level من $max. المستوى التالي مقابل نجمة واحدة، النجوم لا تكفي بعد',
      zero:
          '$power، المستوى $level من $max. المستوى التالي مقابل $cost نجمة، النجوم لا تكفي بعد',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power، المستوى $level من $max. في أعلى مستوى';
  }

  @override
  String get upgradesMax => 'أقصى';

  @override
  String upgradesLevel(int level) {
    return 'المستوى $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'المستوى $level، الأعلى';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now، المستوى التالي $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value%';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value ث';
  }

  @override
  String upgradesStatTimes(String value) {
    return '‎×$value';
  }

  @override
  String upgradesStarsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ستبقى لديك $count نجمة.',
      many: 'ستبقى لديك $count نجمة.',
      few: 'ستبقى لديك $count نجوم.',
      two: 'ستبقى لديك نجمتان.',
      one: 'ستبقى لديك نجمة واحدة.',
      zero: 'لن يبقى لديك أي نجمة.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'طوّر';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'طوّر مقابل $cost نجمة',
      many: 'طوّر مقابل $cost نجمة',
      few: 'طوّر مقابل $cost نجوم',
      two: 'طوّر مقابل نجمتين',
      one: 'طوّر مقابل نجمة واحدة',
      zero: 'طوّر مقابل $cost نجمة',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'طوّر مقابل $cost نجمة، النجوم لا تكفي بعد',
      many: 'طوّر مقابل $cost نجمة، النجوم لا تكفي بعد',
      few: 'طوّر مقابل $cost نجوم، النجوم لا تكفي بعد',
      two: 'طوّر مقابل نجمتين، النجوم لا تكفي بعد',
      one: 'طوّر مقابل نجمة واحدة، النجوم لا تكفي بعد',
      zero: 'طوّر مقابل $cost نجمة، النجوم لا تكفي بعد',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'في أعلى مستوى';

  @override
  String get power_shot_name => 'قوة الرمي';

  @override
  String get power_shot_blurb =>
      'اضغط مطولًا على «ارمِ» لتشحن حجرًا أكبر وأقوى.';

  @override
  String get power_sprint_name => 'الانطلاقة';

  @override
  String get power_sprint_blurb => 'اندفاعة سرعة تحطّم الأعداء في طريقك.';

  @override
  String get power_shield_name => 'الدرع';

  @override
  String get power_shield_blurb =>
      'يصدّ عنك ضربة واحدة. اجمع النجوم في الرحلة لتعيد ملأه.';

  @override
  String get power_magnet_name => 'المغناطيس';

  @override
  String get power_magnet_blurb =>
      'اعبر البوابات عبورًا مثاليًا لتكسبه. إنه يجذب النجوم إليك.';

  @override
  String get power_stat_maxCharge => 'أقصى شحن';

  @override
  String get power_stat_burstLength => 'مدة الاندفاعة';

  @override
  String get power_stat_cooldown => 'وقت الانتظار';

  @override
  String get power_stat_starsToRefill => 'نجوم لإعادة الملء';

  @override
  String get power_stat_safeTime => 'وقت الأمان بعد انكساره';

  @override
  String get power_stat_perfectGates => 'البوابات المثالية المطلوبة';

  @override
  String get power_stat_lasts => 'المدة';

  @override
  String get power_stat_reach => 'المدى';

  @override
  String get passportTitle => 'جواز سمائك.';

  @override
  String get passportDailyCard => 'بطاقة اليوم';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total ميدالية';
  }

  @override
  String get passportIntro =>
      'مغامرات صغيرة. تذكارات تدوم. برونزية وفضية وذهبية لكل ختم.';

  @override
  String get passportNoMedal => 'لا ميدالية بعد';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'ميدالية برونزية',
      'silver': 'ميدالية فضية',
      'other': 'ميدالية ذهبية',
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
    return '$stamp. $held. التالية، $next: $goal $current من $target.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. ميدالية ذهبية. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'للبرونزية',
      'silver': 'للفضية',
      'other': 'للذهبية',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'مختوم';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: لا شيء بعد';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'برونزية';

  @override
  String get passportMedal_silver => 'فضية';

  @override
  String get passportMedal_gold => 'ذهبية';

  @override
  String get stamp_frequentFlyer_name => 'المسافر الدائم';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أنهِ $n رحلة محسوبة.',
      many: 'أنهِ $n رحلة محسوبة.',
      few: 'أنهِ $n رحلات محسوبة.',
      two: 'أنهِ رحلتين محسوبتين.',
      one: 'أنهِ رحلة محسوبة واحدة.',
      zero: 'أنهِ $n رحلة محسوبة.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'في الصميم';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اعبر عبورًا مثاليًا $n مرة على علامات التصويب.',
      many: 'اعبر عبورًا مثاليًا $n مرة على علامات التصويب.',
      few: 'اعبر عبورًا مثاليًا $n مرات على علامات التصويب.',
      two: 'اعبر عبورًا مثاليًا مرتين على علامات التصويب.',
      one: 'اعبر عبورًا مثاليًا مرة واحدة على علامات التصويب.',
      zero: 'اعبر عبورًا مثاليًا $n مرة على علامات التصويب.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'صيّاد النجوم';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اجمع $n نجمة.',
      many: 'اجمع $n نجمة.',
      few: 'اجمع $n نجوم.',
      two: 'اجمع نجمتين.',
      one: 'اجمع نجمة واحدة.',
      zero: 'اجمع $n نجمة.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => 'كوكبة';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اجمع $n نجمة في سلسلة واحدة دون انقطاع.',
      many: 'اجمع $n نجمة في سلسلة واحدة دون انقطاع.',
      few: 'اجمع $n نجوم في سلسلة واحدة دون انقطاع.',
      two: 'اجمع نجمتين في سلسلة واحدة دون انقطاع.',
      one: 'اجمع نجمة واحدة في سلسلة دون انقطاع.',
      zero: 'اجمع $n نجمة في سلسلة واحدة دون انقطاع.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'قائد السماء';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سجّل $n نقطة في رحلة واحدة بلا نهاية.',
      many: 'سجّل $n نقطة في رحلة واحدة بلا نهاية.',
      few: 'سجّل $n نقاط في رحلة واحدة بلا نهاية.',
      two: 'سجّل نقطتين في رحلة واحدة بلا نهاية.',
      one: 'سجّل نقطة واحدة في رحلة واحدة بلا نهاية.',
      zero: 'سجّل $n نقطة في رحلة واحدة بلا نهاية.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'رائد الدروب';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'طِر 60 ثانية على الأقل في $n رحلة بلا نهاية.',
      many: 'طِر 60 ثانية على الأقل في $n رحلة بلا نهاية.',
      few: 'طِر 60 ثانية على الأقل في $n رحلات بلا نهاية.',
      two: 'طِر 60 ثانية على الأقل في رحلتين بلا نهاية.',
      one: 'طِر 60 ثانية على الأقل في رحلة واحدة بلا نهاية.',
      zero: 'طِر 60 ثانية على الأقل في $n رحلة بلا نهاية.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'الطيور على أشكالها';

  @override
  String get stamp_allRounder_name => 'متعدد المواهب';

  @override
  String get stamp_flockTogether_goalBronze =>
      'خذ طائرين مختلفين في رحلات محسوبة.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'خذ الطيور الأربعة في رحلات محسوبة.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'طِر $n رحلة محسوبة مع كل طائر.',
      many: 'طِر $n رحلة محسوبة مع كل طائر.',
      few: 'طِر $n رحلات محسوبة مع كل طائر.',
      two: 'طِر رحلتين محسوبتين مع كل طائر.',
      one: 'طِر رحلة محسوبة واحدة مع كل طائر.',
      zero: 'طِر $n رحلة محسوبة مع كل طائر.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'طِر في لعبة صغيرة بالضغط أو القرفصاء أو القفز.';

  @override
  String get stamp_allRounder_goalSilver =>
      'طِر في الألعاب الصغيرة الثلاث: الضغط والقرفصاء والقفز.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'طِر $n رحلة محسوبة في كل لعبة صغيرة.',
      many: 'طِر $n رحلة محسوبة في كل لعبة صغيرة.',
      few: 'طِر $n رحلات محسوبة في كل لعبة صغيرة.',
      two: 'طِر رحلتين محسوبتين في كل لعبة صغيرة.',
      one: 'طِر رحلة محسوبة واحدة في كل لعبة صغيرة.',
      zero: 'طِر $n رحلة محسوبة في كل لعبة صغيرة.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals ميدالية · عند $level',
      many: '$stars★ · $medals ميدالية · عند $level',
      few: '$stars★ · $medals ميداليات · عند $level',
      two: '$stars★ · ميداليتان · عند $level',
      one: '$stars★ · ميدالية واحدة · عند $level',
      zero: '$stars★ · $medals ميدالية · عند $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'مغامرتك تحتاج إلى لحظة.';

  @override
  String get dailyTitle => 'مغامرة اليوم الصغيرة.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · $done/3 أهداف';
  }

  @override
  String get dailyIntro =>
      'ثلاثة أهداف. بأي طريقة تحكّم. ورحلة واحدة بلا نهاية تكفي للثلاثة.';

  @override
  String get dailyLaunchEndless => 'بلا نهاية';

  @override
  String get dailyPostcardKicker => 'بطاقة نادي السماء';

  @override
  String get dailyStamped => 'خُتمت البطاقة!';

  @override
  String dailyGoalsComplete(int done) {
    return 'اكتمل $done من 3 أهداف';
  }

  @override
  String get dailyDoneNote => 'مغامرة صغيرة، كلها لك.';

  @override
  String get dailyOpenNote => 'أنهِ الثلاثة لتختم هذه البطاقة.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal مكتمل';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current من $target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: خُتمت البطاقة';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: $done/3 أهداف';
  }

  @override
  String get dailyNoStreak => 'أهداف جديدة. لا سلسلة لتخسرها.';

  @override
  String get dailyTheme_0 => 'توصيلة الشروق';

  @override
  String get dailyTheme_1 => 'نزهة الخوخ';

  @override
  String get dailyTheme_2 => 'بريد ضوء القمر';

  @override
  String get dailyTheme_3 => 'موكب الغيوم';

  @override
  String get dailyTheme_4 => 'كنز الشفق';

  @override
  String get dailyTheme_5 => 'حفلة الحديقة';

  @override
  String get task_flights_title => 'افرد جناحيك';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أنهِ $count رحلة محسوبة اليوم.',
      many: 'أنهِ $count رحلة محسوبة اليوم.',
      few: 'أنهِ $count رحلات محسوبة اليوم.',
      two: 'أنهِ رحلتين محسوبتين اليوم.',
      one: 'أنهِ رحلة محسوبة واحدة اليوم.',
      zero: 'أنهِ $count رحلة محسوبة اليوم.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'آفاق مفتوحة';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اعبر $count بوابة في رحلات اليوم المحسوبة.',
      many: 'اعبر $count بوابة في رحلات اليوم المحسوبة.',
      few: 'اعبر $count بوابات في رحلات اليوم المحسوبة.',
      two: 'اعبر بوابتين في رحلات اليوم المحسوبة.',
      one: 'اعبر بوابة واحدة في رحلات اليوم المحسوبة.',
      zero: 'اعبر $count بوابة في رحلات اليوم المحسوبة.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'جيب مليء بالنجوم';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اجمع $count نجمة في رحلات اليوم.',
      many: 'اجمع $count نجمة في رحلات اليوم.',
      few: 'اجمع $count نجوم في رحلات اليوم.',
      two: 'اجمع نجمتين في رحلات اليوم.',
      one: 'اجمع نجمة واحدة في رحلات اليوم.',
      zero: 'اجمع $count نجمة في رحلات اليوم.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'حافظ على البريق';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اجمع $count نجمة في سلسلة واحدة دون انقطاع.',
      many: 'اجمع $count نجمة في سلسلة واحدة دون انقطاع.',
      few: 'اجمع $count نجوم في سلسلة واحدة دون انقطاع.',
      two: 'اجمع نجمتين في سلسلة واحدة دون انقطاع.',
      one: 'اجمع نجمة واحدة في سلسلة دون انقطاع.',
      zero: 'اجمع $count نجمة في سلسلة واحدة دون انقطاع.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'إصابة الهدف';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اعبر عبورًا مثاليًا $count مرة اليوم.',
      many: 'اعبر عبورًا مثاليًا $count مرة اليوم.',
      few: 'اعبر عبورًا مثاليًا $count مرات اليوم.',
      two: 'اعبر عبورًا مثاليًا مرتين اليوم.',
      one: 'اعبر عبورًا مثاليًا مرة واحدة اليوم.',
      zero: 'اعبر عبورًا مثاليًا $count مرة اليوم.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'الرحلة كلها';

  @override
  String get task_finishTrail_goal =>
      'طِر 60 ثانية على الأقل في رحلة واحدة بلا نهاية.';

  @override
  String get recordsTitle => 'انتصاراتك الصغيرة.';

  @override
  String get recordsBestsTitle => 'نقاط نجومك التي عليك تجاوزها';

  @override
  String get recordsSectionMain => 'اللعبة الرئيسية';

  @override
  String get recordsSectionMini => 'الألعاب الصغيرة';

  @override
  String get recordsEndless => 'بلا نهاية · انقر وطِر';

  @override
  String get recordsCampaignStars => 'نجوم الحملة';

  @override
  String recordsCoopName(String mode) {
    return 'نطير معًا · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رحلة محسوبة',
      many: 'رحلة محسوبة',
      few: 'رحلات محسوبة',
      two: 'رحلتان محسوبتان',
      one: 'رحلة محسوبة',
      zero: 'رحلة محسوبة',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بوابة',
      many: 'بوابة',
      few: 'بوابات',
      two: 'بوابتان',
      one: 'بوابة',
      zero: 'بوابة',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رحلة معًا',
      many: 'رحلة معًا',
      few: 'رحلات معًا',
      two: 'رحلتان معًا',
      one: 'رحلة معًا',
      zero: 'رحلة معًا',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مبارزة',
      many: 'مبارزة',
      few: 'مبارزات',
      two: 'مبارزتان',
      one: 'مبارزة',
      zero: 'مبارزة',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ضغطة',
      many: 'ضغطة',
      few: 'ضغطات',
      two: 'ضغطتان',
      one: 'ضغطة',
      zero: 'ضغطة',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قرفصاء',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'آخر الرحلات';

  @override
  String get recordsEmptyTitle => 'سماء واسعة. وصفحة بيضاء.';

  @override
  String get recordsEmptyBody => 'أول رحلة محسوبة لك تبدأ الحكاية.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds ث';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'كلاسيكي · $date · $seconds ث';
  }

  @override
  String get replaySavedSessions => 'الجلسات المحفوظة';

  @override
  String get replayBackToRecordsSemantics => 'العودة إلى السجلّات';

  @override
  String get replaySessionsLoadFailed => 'تعذّر تحميل الجلسات. أعد المحاولة';

  @override
  String get replayEmptyTitle => 'رحلاتك مكانها هنا';

  @override
  String get replayEmptyBody => 'احفظ جلسة بعد الرحلة لتشاهدها هنا.';

  @override
  String get replayEmptyButton => 'اختر رحلة';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds ث · $score نقطة نجوم',
      many: '$date · $seconds ث · $score نقطة نجوم',
      few: '$date · $seconds ث · $score نقاط نجوم',
      two: '$date · $seconds ث · نقطتا نجوم',
      one: '$date · $seconds ث · نقطة نجوم واحدة',
      zero: '$date · $seconds ث · $score نقطة نجوم',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds ث · $score بوابة',
      many: '$date · $seconds ث · $score بوابة',
      few: '$date · $seconds ث · $score بوابات',
      two: '$date · $seconds ث · بوابتان',
      one: '$date · $seconds ث · بوابة واحدة',
      zero: '$date · $seconds ث · $score بوابة',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'حذف الجلسة';

  @override
  String get replayDeleteTitle => 'أتحذف هذه الجلسة؟';

  @override
  String get replayDeleteBody =>
      'سيُحذف فيديو الكاميرا وإعادة العرض. تبقى نتائجك في السجلّات.';

  @override
  String get replayDeleteFailed => 'تعذّر حذف الجلسة. حاول مجددًا.';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return 'المرحلة $id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · بلا نهاية';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · تدريب';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · بلا نهاية · تدريب';
  }

  @override
  String get replayOpenFailed => 'تعذّر فتح هذه الجلسة.';

  @override
  String get replayBackToSessions => 'العودة إلى الجلسات';

  @override
  String get replayCameraPaused =>
      'كانت الكاميرا متوقفة في هذا الجزء من الجلسة';

  @override
  String get replayCameraUnavailable =>
      'مقطع الكاميرا غير متاح · اللعب ما زال يُعرض';

  @override
  String get replayCameraLoading => 'جارٍ تحميل الكاميرا…';

  @override
  String get replayPaused => 'استراحة قصيرة';

  @override
  String get replayHideControlsSemantics => 'إخفاء أزرار الإعادة';

  @override
  String get replayShowControlsSemantics => 'إظهار أزرار الإعادة';

  @override
  String get replayBackToSavedSemantics => 'العودة إلى الجلسات المحفوظة';

  @override
  String get replayTitle => 'إعادة العرض';

  @override
  String replayTitleSession(String session) {
    return 'إعادة العرض · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'النقاط: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts قلب · $clock',
      many: '$hearts قلبًا · $clock',
      few: '$hearts قلوب · $clock',
      two: 'قلبان · $clock',
      one: 'قلب واحد · $clock',
      zero: 'لا قلوب · $clock',
    );
    return '$_temp0';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'القلوب: P1 $p1 · P2 $p2 · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '$seconds ث';
  }

  @override
  String replayMagnet(int seconds) {
    return 'مغناطيس $seconds ث';
  }

  @override
  String get replayPauseSemantics => 'إيقاف الإعادة مؤقتًا';

  @override
  String get replayPlaySemantics => 'تشغيل الإعادة';

  @override
  String get replayRestartSemantics => 'إعادة من البداية';

  @override
  String get replayBack5Semantics => 'رجوع 5 ثوانٍ';

  @override
  String get replayForward5Semantics => 'تقدّم 5 ثوانٍ';

  @override
  String get replayHighlightsFinding => 'جارٍ البحث عن أبرز لحظات الرحلة';

  @override
  String get replayHighlightsNone => 'لا توجد لحظات بارزة';

  @override
  String get replayHighlights => 'أبرز لحظات الرحلة';

  @override
  String get replayHighlightsCloseSemantics => 'إغلاق أبرز اللحظات';

  @override
  String get replayHighlightsHint => 'اختر لحظة، وشاهد من قبيل حدوثها.';

  @override
  String get replayViewCorner => 'الكاميرا في الزاوية';

  @override
  String get replayViewBackground => 'الكاميرا في الخلفية';

  @override
  String get replayViewGameplay => 'اللعب فقط';

  @override
  String get replayMoveCornerSemantics => 'نقل زاوية الكاميرا';

  @override
  String get replayMuteRecordedSemantics => 'كتم الصوت المسجّل';

  @override
  String get replayUnmuteRecordedSemantics => 'تشغيل الصوت المسجّل';

  @override
  String get replayMuteGameSemantics => 'كتم صوت اللعبة';

  @override
  String get replayUnmuteGameSemantics => 'تشغيل صوت اللعبة';

  @override
  String get replayFullScreenSemantics => 'إخفاء الأزرار / ملء الشاشة';

  @override
  String get replayMomentTakeoff => 'الإقلاع';

  @override
  String get replayMomentTakeoffDetail => 'السماء لك.';

  @override
  String get replayMomentMagnet => 'مغناطيس النجوم';

  @override
  String get replayMomentMagnetDetail => 'ثلاث بوابات مثالية تقرّب النجوم منك.';

  @override
  String get replayMomentStarTrio => 'أول ثلاثية نجوم';

  @override
  String get replayMomentStarTrioDetail => 'ثلاث نجوم تصبح كوكبة. ‎+5 نقاط!';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'جُمعت كل نجوم المجموعة. ‎+5 نقاط!';

  @override
  String replayMomentStreak(int multiplier) {
    return 'قوة النجوم ‎×$multiplier';
  }

  @override
  String get replayMomentStreakDetail => 'سلسلة نجوم متلألئة.';

  @override
  String get replayMomentShield => 'الدرع حماك';

  @override
  String get replayMomentShieldDetail => 'نجاة بأعجوبة، وفرصة أخرى.';

  @override
  String get replayMomentPerfect => 'أول عبور مثالي';

  @override
  String get replayMomentPerfectDetail => 'في قلب علامة التصويب تمامًا.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اجتزت $count بوابة',
      many: 'اجتزت $count بوابة',
      few: 'اجتزت $count بوابات',
      two: 'اجتزت بوابتين',
      one: 'اجتزت بوابة واحدة',
      zero: 'اجتزت $count بوابة',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'أبعد قليلًا في السماء.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'بلا خدش واحد. ‎+$points نقطة!',
      many: 'بلا خدش واحد. ‎+$points نقطة!',
      few: 'بلا خدش واحد. ‎+$points نقاط!',
      two: 'بلا خدش واحد. ‎+$points نقطة!',
      one: 'بلا خدش واحد. ‎+$points نقطة!',
      zero: 'بلا خدش واحد. ‎+$points نقطة!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'حلقات الانطلاق أوصلتك إلى الأمان. ‎+$points نقطة!',
      many: 'حلقات الانطلاق أوصلتك إلى الأمان. ‎+$points نقطة!',
      few: 'حلقات الانطلاق أوصلتك إلى الأمان. ‎+$points نقاط!',
      two: 'حلقات الانطلاق أوصلتك إلى الأمان. ‎+$points نقطة!',
      one: 'حلقات الانطلاق أوصلتك إلى الأمان. ‎+$points نقطة!',
      zero: 'حلقات الانطلاق أوصلتك إلى الأمان. ‎+$points نقطة!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'صمدت أمام الريح العاتية';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'تفاديت الحطام الطائر. ‎+$points نقطة!',
      many: 'تفاديت الحطام الطائر. ‎+$points نقطة!',
      few: 'تفاديت الحطام الطائر. ‎+$points نقاط!',
      two: 'تفاديت الحطام الطائر. ‎+$points نقطة!',
      one: 'تفاديت الحطام الطائر. ‎+$points نقطة!',
      zero: 'تفاديت الحطام الطائر. ‎+$points نقطة!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'اكتمل الخط';

  @override
  String get replayMomentFinal => 'اللحظة الأخيرة';

  @override
  String get replayMomentCompleteDetail => 'وصلت إلى نهاية الخط.';

  @override
  String get replayMomentCollisionDetail => 'شاهد الاقتراب الأخير.';

  @override
  String get replayMomentEndDetail => 'نهاية هذه الرحلة.';

  @override
  String get welcomeTitle => 'اختر لغتك';

  @override
  String get welcomeContinue => 'هيا نطير!';

  @override
  String get welcomeHint => 'يمكنك تغييرها في أي وقت من الإعدادات.';

  @override
  String get welcomeDevice => 'لغة هاتفك';

  @override
  String get tutorialTitle => 'مدرسة الطيران';

  @override
  String get tutorialSkip => 'تخطّي الدرس';

  @override
  String get tutorialSkipTitle => 'أتتخطى مدرسة الطيران؟';

  @override
  String get tutorialSkipBody => 'يمكنك إعادة الدرس في أي وقت من الإعدادات.';

  @override
  String get tutorialSkipConfirm => 'تخطٍّ';

  @override
  String get tutorialSkipCancel => 'مواصلة التعلّم';

  @override
  String get tutorialRestart => 'البدء من جديد';

  @override
  String get tutorialGoalFlaps => 'رفرف';

  @override
  String get tutorialGoalStars => 'اجمع النجوم';

  @override
  String get tutorialGoalGates => 'اعبر البوابات';

  @override
  String get tutorialGoalBats => 'أسقِط الخفافيش';

  @override
  String get tutorialGoalDoor => 'حطّم الباب الحجري';

  @override
  String get tutorialGoalSprint => 'انطلاقة';

  @override
  String get tutorialGoalBoss => 'اهزم القبطان';

  @override
  String get tutorialPromptTap => 'انقر!';

  @override
  String get tutorialPromptShoot => 'انقر «ارمِ»';

  @override
  String get tutorialPromptHoldShoot => 'ثبّت على «ارمِ»';

  @override
  String get tutorialPromptSprint => 'انقر «انطلاقة»';

  @override
  String get tutorialPraiseNice => 'رائع!';

  @override
  String get tutorialPraiseGreat => 'ممتاز!';

  @override
  String get tutorialPraiseSuper => 'مذهل!';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return 'الدرس بانتظارك: $prompt';
  }

  @override
  String get licenceTitle => 'رخصة ساعي البريد';

  @override
  String get licenceIssuer => 'بريد نادي السماء';

  @override
  String get licenceHolder => 'ساعي البريد';

  @override
  String get licenceRank => 'الرتبة';

  @override
  String get licenceRankRookie => 'ساعي بريد مبتدئ';

  @override
  String get licenceSkills => 'المهارات';

  @override
  String get licenceStamp => 'معتمد';

  @override
  String licenceSignedBy(String name) {
    return 'التوقيع: $name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة',
      many: '$count نجمة',
      few: '$count نجوم',
      two: 'نجمتان',
      one: 'نجمة واحدة',
      zero: '$count نجمة',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => 'إلى خطي الأول!';

  @override
  String get licenceAgain => 'الطيران مجددًا';

  @override
  String get settingsTutorial => 'مدرسة الطيران';

  @override
  String get settingsTutorialDetail => 'إعادة الدرس الأول';
}
