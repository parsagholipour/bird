// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get commonTryAgain => 'Повторить';

  @override
  String get languageKeyLabel => 'Язык';

  @override
  String languageKeySemantics(String language) {
    return 'Язык: $language. Сменить язык игры.';
  }

  @override
  String get languageSystemDefault => 'Как на телефоне';

  @override
  String languageSystemDetail(String language) {
    return 'Язык телефона: $language';
  }

  @override
  String get languageCurrent => 'Текущий язык';

  @override
  String get languageName_en => 'Английский';

  @override
  String get languageName_es_419 => 'Испанский (Лат. Америка)';

  @override
  String get languageName_pt_br => 'Португальский (Бразилия)';

  @override
  String get languageName_id => 'Индонезийский';

  @override
  String get languageName_fr => 'Французский';

  @override
  String get languageName_de => 'Немецкий';

  @override
  String get languageName_ja => 'Японский';

  @override
  String get languageName_ko => 'Корейский';

  @override
  String get languageName_tr => 'Турецкий';

  @override
  String get languageName_zh_hant => 'Традиционный китайский';

  @override
  String get languageName_ru => 'Русский';

  @override
  String get languageName_ar => 'Арабский';

  @override
  String get voicePackReady => 'Голоса готовы';

  @override
  String get voicePackDownload => 'Скачать голоса';

  @override
  String voicePackDownloading(int percent) {
    return 'Голоса $percent%';
  }

  @override
  String get voicePackStarting => 'Загрузка голосов';

  @override
  String get voicePackEnglish => 'Английские голоса';

  @override
  String get voicePackFailed => 'Ошибка загрузки';

  @override
  String get settingsTitle => 'Располагайся как дома.';

  @override
  String get settingsSectionSound => 'Звук';

  @override
  String get settingsSectionComfort => 'Удобство';

  @override
  String get settingsMusicTitle => 'Музыка Небесного клуба';

  @override
  String get settingsMusicDetail => 'Темы меню, приключений и боссов.';

  @override
  String get settingsEffectsTitle => 'Звуковые эффекты';

  @override
  String get settingsEffectsDetail => 'Полёт, бой, бонусы и звуки меню.';

  @override
  String get settingsVoicesTitle => 'Голоса персонажей';

  @override
  String get settingsVoicesDetail =>
      'Сцены, благодарственные записки и кличи рывка.';

  @override
  String get settingsReducedMotionTitle => 'Меньше анимации';

  @override
  String get settingsReducedMotionDetail =>
      'Спокойные меню и меньше украшений.';

  @override
  String get settingsSwitchOn => 'ВКЛ';

  @override
  String get settingsSwitchOff => 'ВЫКЛ';

  @override
  String get settingsUnavailable => 'Настройкам нужна минутка.';

  @override
  String get settingsPrivacyKicker => 'ТОЛЬКО НА ТЕЛЕФОНЕ.';

  @override
  String get settingsPrivacyTitle => 'Твоя камера — только твоя.';

  @override
  String get settingsPrivacyBody =>
      'Видео и звук с микрофона (если включён) остаются на телефоне. Несохранённое удаляется. Ничего не выгружается.';

  @override
  String get settingsCameraLab => 'Лаборатория камеры';

  @override
  String get settingsAbout => 'Об игре и лицензии';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'Об игре и лицензии, версия $version';
  }

  @override
  String get settingsReset => 'Сбросить прогресс';

  @override
  String settingsResetDone(String bird) {
    return 'Всё с чистого листа. $bird уже ждёт тебя.';
  }

  @override
  String get settingsResetTitle => 'Начать приключение заново?';

  @override
  String get settingsResetBody =>
      'С этого телефона будут удалены сохранённые видео, повторы, очки, полёты, созданные уровни и настройки. Отменить это нельзя.';

  @override
  String get settingsResetBodyCloud =>
      'С этого телефона будут удалены сохранённые видео, повторы, очки, полёты, созданные уровни и настройки, а также облачное сохранение Play Игр. Отменить это нельзя.';

  @override
  String get settingsResetConfirm => 'Сбросить всё';

  @override
  String get settingsResetKeep => 'Оставить прогресс';

  @override
  String get playGamesName => 'Play Игры';

  @override
  String get playGamesConnected => 'Подключено';

  @override
  String get playGamesNotConnected => 'Не подключено';

  @override
  String get playGamesConnecting => 'Подключение…';

  @override
  String get playGamesConnectFailed => 'Не удалось подключиться';

  @override
  String get playGamesIdle => 'Облако и достижения';

  @override
  String get playGamesSaving => 'Сохранение в облако…';

  @override
  String get playGamesOfflineUnsaved => 'Офлайн · ещё не сохранено';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'Офлайн · сохранено $ago';
  }

  @override
  String get playGamesUpdateNeeded => 'Обнови игру для синхронизации';

  @override
  String get playGamesUnreadable => 'Облачное сохранение повреждено';

  @override
  String get playGamesOn => 'Облачное сохранение включено';

  @override
  String get playGamesResetElsewhere => 'Сброшено на другом телефоне';

  @override
  String playGamesRestored(String ago) {
    return 'Восстановлено · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'Сохранено в облаке · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Достижения Play Игр';

  @override
  String get playGamesConnectSemantics => 'Подключить Play Игры';

  @override
  String get playGamesAchievements => 'Достижения';

  @override
  String get playGamesConnect => 'Подключить';

  @override
  String get timeAgoJustNow => 'только что';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes мин назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ч назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days д назад',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '+1 ЖИЗНЬ!';

  @override
  String calloutStarTrio(int points) {
    return 'ТРИО ЗВЁЗД +$points!';
  }

  @override
  String get calloutNiceShot => 'МЕТКО!';

  @override
  String calloutNiceShotPoints(int points) {
    return 'МЕТКО +$points!';
  }

  @override
  String get calloutSmash => 'БАБАХ!';

  @override
  String calloutSmashPoints(int points) {
    return 'БАБАХ +$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return 'БАБАХ ×$count!';
  }

  @override
  String get calloutBossDown => 'БОСС ПОВЕРЖЕН!';

  @override
  String calloutBossDownPoints(int points) {
    return 'ПОБЕДА +$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier× ЗВЁЗДНАЯ СИЛА!';
  }

  @override
  String get calloutPerfect => 'ИДЕАЛЬНО!';

  @override
  String calloutPerfectChain(int count) {
    return 'ИДЕАЛЬНО ×$count';
  }

  @override
  String get calloutShieldReady => 'ЩИТ ГОТОВ';

  @override
  String get calloutShieldSave => 'ЩИТ СПАС!';

  @override
  String get calloutKeepFlying => 'ЛЕТИМ ДАЛЬШЕ!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ВОРОТ!',
      many: '$count ВОРОТ!',
      few: '$count ВОРОТ!',
      one: '$count ВОРОТА!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'ЕЩЁ $seconds СЕКУНДЫ',
      many: 'ЕЩЁ $seconds СЕКУНД',
      few: 'ЕЩЁ $seconds СЕКУНДЫ',
      one: 'ЕЩЁ $seconds СЕКУНДА',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => 'МАГНИТ!';

  @override
  String get calloutSprintRing => 'КОЛЬЦО РЫВКА!';

  @override
  String calloutRushChain(int count) {
    return 'КОЛЬЦА ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'МЕТЕОР +$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return 'МЫШЬ +$points!';
  }

  @override
  String get calloutScorched => 'ОПАЛИЛО!';

  @override
  String get region_jungle => 'Джунгли';

  @override
  String get region_antarctica => 'Антарктида';

  @override
  String get region_aztec => 'Земли ацтеков';

  @override
  String get region_paris => 'Париж';

  @override
  String get region_egypt => 'Египет';

  @override
  String get region_cyberpunk => 'Киберпанк-сити';

  @override
  String get region_china => 'Китай';

  @override
  String get region_brazil => 'Бразилия';

  @override
  String get region_newYork => 'Нью-Йорк';

  @override
  String get region_arabia => 'Древняя Аравия';

  @override
  String get region_rome => 'Древний Рим';

  @override
  String get region_mexico => 'Мексика';

  @override
  String get region_sea => 'Открытое море';

  @override
  String get boss_baronBat_name => 'Барон Нетопырь';

  @override
  String get boss_spitterBeetle_name => 'Король Плевунов';

  @override
  String get boss_duskMoth_name => 'Сумеречная Императрица';

  @override
  String get boss_pirate_name => 'Пиратский Капитан';

  @override
  String get boss_dragon_name => 'Тлеющий Дракон';

  @override
  String get boss_kingCoo_name => 'Король Курлык';

  @override
  String get boss_searchlightGargoyle_name => 'Прожекторная Горгулья';

  @override
  String get boss_neferhoo_name => 'Неферху';

  @override
  String get bird_0_name => 'Пип';

  @override
  String get bird_1_name => 'Пичес';

  @override
  String get bird_2_name => 'Минти';

  @override
  String get bird_3_name => 'Орбит';

  @override
  String get playMode_pushUp => 'Отжимайся и лети';

  @override
  String get playMode_jump => 'Прыгай и лети';

  @override
  String get playMode_touch => 'Жми и лети';

  @override
  String get playMode_squat => 'Присядь и лети';

  @override
  String get chapter_1_route => 'Маршрут над кронами';

  @override
  String get chapter_1_postmark => 'МАРШРУТ НАД КРОНАМИ';

  @override
  String get chapter_1_postcard =>
      'Письма снова долетают до верхушек деревьев! Туканы говорят спасибо (очень громко). Корона Барона Нетопыря теперь стоит у нас на камине.';

  @override
  String get chapter_1_postscript =>
      'На древней дороге пахнет так, будто там что-то варится.';

  @override
  String get chapter_2_route => 'Древняя дорога';

  @override
  String get chapter_2_postmark => 'ДРЕВНЯЯ ДОРОГА';

  @override
  String get chapter_2_postcard =>
      'Караваны снова в пути, а варится тут только мятный чай. Корону-колбу Короля мы оставили себе как вазу.';

  @override
  String get chapter_2_postscript =>
      'Вчера ночью погасли городские фонари. Захвати с собой свет.';

  @override
  String get chapter_3_route => 'Фонарная линия';

  @override
  String get chapter_3_postmark => 'ФОНАРНАЯ ЛИНИЯ';

  @override
  String get chapter_3_postcard =>
      'Фонари горят, а ночная почта бодра как никогда! Париж шлёт тебе круассан. Нью-Йорк — крендель.';

  @override
  String get chapter_3_postscript => 'Колокола гавани перестали звонить.';

  @override
  String get chapter_4_route => 'Приливный маршрут';

  @override
  String get chapter_4_postmark => 'ПРИЛИВНЫЙ МАРШРУТ';

  @override
  String get chapter_4_postcard =>
      'Колокола гавани снова звонят о письмах, а не о пушках. Попугай остался с нами. Передаёт привет.';

  @override
  String get chapter_4_postscript => 'Говорят, на краю карты горит небо.';

  @override
  String get chapter_5_route => 'Край карты';

  @override
  String get chapter_5_postmark => 'КРАЙ КАРТЫ';

  @override
  String get chapter_5_postcard =>
      'Небо чистое от полюса до полюса, и все маршруты снова работают. Весь Небесный клуб гордится тобой.';

  @override
  String get chapter_5_postscript =>
      'Бесконечное небо всё ещё ждёт тебя — когда захочешь.';

  @override
  String get level_1_1_name => 'Первая доставка';

  @override
  String get level_1_1_cargo => 'Именинная открытка туканам-близнецам';

  @override
  String get level_1_1_sender => 'Туканы-близнецы';

  @override
  String get level_1_1_hint =>
      'Жми, чтобы взмахнуть крыльями. Лети сквозь звёзды.';

  @override
  String get level_1_2_name => 'Звёздная серия';

  @override
  String get level_1_2_cargo => 'Звёздные карты ленивцу-звездочёту';

  @override
  String get level_1_2_sender => 'Ленивец-звездочёт';

  @override
  String get level_1_2_hint =>
      'Звёзды подряд дают 3×, а три идеальных пролёта — магнит.';

  @override
  String get level_1_3_name => 'Патруль летучих мышей';

  @override
  String get level_1_3_cargo => 'Ночники для яслей светлячков';

  @override
  String get level_1_3_sender => 'Ясли светлячков';

  @override
  String get level_1_3_hint =>
      'Выстрел. Жми «Выстрел», чтобы сбивать летучих мышей.';

  @override
  String get level_1_4_name => 'Карнавальное небо';

  @override
  String get level_1_4_cargo => 'Боа из перьев для карнавала';

  @override
  String get level_1_4_sender => 'Ара из школы самбы';

  @override
  String get level_1_4_hint =>
      'Шквал! Следи за знаком ! и уворачивайся от мячей.';

  @override
  String get level_1_5_name => 'Экспресс-почта';

  @override
  String get level_1_5_cargo => 'Срочное приглашение барабанщику';

  @override
  String get level_1_5_sender => 'Главный барабанщик';

  @override
  String get level_1_5_hint =>
      'Рывок сносит летучих мышей и бросает тебя вперёд.';

  @override
  String get level_1_6_name => 'Ступени храма';

  @override
  String get level_1_6_cargo => 'Какао-бобы для храмовых поваров';

  @override
  String get level_1_6_sender => 'Храмовые повара';

  @override
  String get level_1_7_name => 'Насест на рассвете';

  @override
  String get level_1_7_cargo => 'Солнечные часы хранителю рассвета';

  @override
  String get level_1_7_sender => 'Хранитель рассвета';

  @override
  String get level_1_8_name => 'Барон Нетопырь';

  @override
  String get level_1_8_cargo => 'Последнее предупреждение Барону';

  @override
  String get level_1_8_sender => 'Барон Нетопырь';

  @override
  String get level_2_1_name => 'Жучиная дорога';

  @override
  String get level_2_1_cargo => 'Лавровые венки гонщикам колесниц';

  @override
  String get level_2_1_sender => 'Гонщики на колесницах';

  @override
  String get level_2_1_hint =>
      'Жуки плюются семечками. Сбивай семечки выстрелами.';

  @override
  String get level_2_2_name => 'Запертые ворота';

  @override
  String get level_2_2_cargo => 'Новое долото для скульптора';

  @override
  String get level_2_2_sender => 'Скульптор';

  @override
  String get level_2_2_hint =>
      'Удерживай «Выстрел» — большой камень разбивает каменные плиты.';

  @override
  String get level_2_3_name => 'Бегство от пожара';

  @override
  String get level_2_3_cargo => 'Вёдра воды для пожарной команды';

  @override
  String get level_2_3_sender => 'Пожарная команда';

  @override
  String get level_2_3_hint =>
      'Пролетай сквозь золотые кольца, чтобы удрать от огня!';

  @override
  String get level_2_4_name => 'Нильский серпантин';

  @override
  String get level_2_4_cargo => 'Книга новых загадок для Сфинкса';

  @override
  String get level_2_4_sender => 'Сфинкс';

  @override
  String get level_2_5_name => 'Небопад';

  @override
  String get level_2_5_cargo => 'Телескоп для астронома с пирамиды';

  @override
  String get level_2_5_sender => 'Астроном с пирамиды';

  @override
  String get level_2_5_hint => 'Рывок из кольца разбивает метеоры.';

  @override
  String get level_2_6_name => 'Вернуть отправителю';

  @override
  String get level_2_6_cargo => 'Метёлка из перьев смотрительнице';

  @override
  String get level_2_6_sender => 'Смотрительница пирамиды';

  @override
  String get level_2_6_hint =>
      'Стреляй по его письмам, чтобы отбить их. Вернуть отправителю!';

  @override
  String get level_2_7_name => 'Базар фонарей';

  @override
  String get level_2_7_cargo => 'Масло для ламп продавцам фонарей';

  @override
  String get level_2_7_sender => 'Продавцы фонарей';

  @override
  String get level_2_8_name => 'Долгий караван';

  @override
  String get level_2_8_cargo => 'Фляги с водой для долгого каравана';

  @override
  String get level_2_8_sender => 'Глава каравана';

  @override
  String get level_2_9_name => 'Король Плевунов';

  @override
  String get level_2_9_cargo => 'Приказ «Не варить!» Королю Плевунов';

  @override
  String get level_2_9_sender => 'Король Плевунов';

  @override
  String get level_3_1_name => 'Мотыльки на свет';

  @override
  String get level_3_1_cargo => 'Лампочки для козырька театра';

  @override
  String get level_3_1_sender => 'Директор театра';

  @override
  String get level_3_1_hint =>
      'Мотыльки стреляют веером по три. Проскользни между ними.';

  @override
  String get level_3_2_name => 'Колёса под дождём';

  @override
  String get level_3_2_cargo => 'Зонтики для голубей из киоска';

  @override
  String get level_3_2_sender => 'Голуби из газетного киоска';

  @override
  String get level_3_2_hint =>
      'Дворовые голуби пикируют за звёздами. Сбивай их раньше!';

  @override
  String get level_3_3_name => 'Паровой переулок';

  @override
  String get level_3_3_cargo => 'Горячие крендели ночным таксистам';

  @override
  String get level_3_3_sender => 'Ночные таксисты';

  @override
  String get level_3_3_hint =>
      'Люки шипят, потом бьют паром. Горячие облетай, на мягких взлетай!';

  @override
  String get level_3_4_name => 'Штормовое предупреждение';

  @override
  String get level_3_4_cargo => 'Флюгер для самой высокой башни';

  @override
  String get level_3_4_sender => 'Смотритель башни';

  @override
  String get level_3_4_hint =>
      'Не попадай в луч. Стреляй в лампу, когда она откроется! Рывка тут нет.';

  @override
  String get level_3_5_name => 'Хрустальные крыши';

  @override
  String get level_3_5_cargo => 'Круассаны художникам на крышах';

  @override
  String get level_3_5_sender => 'Художники на крышах';

  @override
  String get level_3_6_name => 'После шквала';

  @override
  String get level_3_6_cargo => 'Ноты для аккордеониста';

  @override
  String get level_3_6_sender => 'Аккордеонист';

  @override
  String get level_3_6_hint =>
      'Шквал! Следи за знаком ! и держись открытой стороны.';

  @override
  String get level_3_7_name => 'Полуночный экспресс';

  @override
  String get level_3_7_cargo => 'Полуночное любовное письмо булочнице';

  @override
  String get level_3_7_sender => 'Булочница';

  @override
  String get level_3_7_hint => 'Пролетай сквозь стаи рывком.';

  @override
  String get level_3_8_name => 'Сумеречная Императрица';

  @override
  String get level_3_8_cargo => 'Побудка для Сумеречной Императрицы';

  @override
  String get level_3_8_sender => 'Сумеречная Императрица';

  @override
  String get level_4_1_name => 'Огни гавани';

  @override
  String get level_4_1_cargo => 'Новая линза смотрителю маяка';

  @override
  String get level_4_1_sender => 'Смотритель маяка';

  @override
  String get level_4_2_name => 'Перевал вулканов';

  @override
  String get level_4_2_cargo => 'Прихватки для пекарши с вулкана';

  @override
  String get level_4_2_sender => 'Пекарша с вулкана';

  @override
  String get level_4_2_hint => 'Перепрыгивай фонтаны лавы.';

  @override
  String get level_4_3_name => 'Вдоль побережья';

  @override
  String get level_4_3_cargo => 'Нить для змеев на пляжный праздник';

  @override
  String get level_4_3_sender => 'Любители воздушных змеев';

  @override
  String get level_4_4_name => 'Отлив';

  @override
  String get level_4_4_cargo => 'Ответ отшельнику с острова';

  @override
  String get level_4_4_sender => 'Отшельник с острова';

  @override
  String get level_4_4_hint => 'Не касайся воды.';

  @override
  String get level_4_5_name => 'Большой прилив';

  @override
  String get level_4_5_cargo => 'Таблица приливов для команды парома';

  @override
  String get level_4_5_sender => 'Команда парома';

  @override
  String get level_4_5_hint => 'Звонит колокол — лети повыше.';

  @override
  String get level_4_6_name => 'Бухта бортового залпа';

  @override
  String get level_4_6_cargo => 'Рыбное печенье для колонии чаек';

  @override
  String get level_4_6_sender => 'Колония чаек';

  @override
  String get level_4_7_name => 'Штормовая переправа';

  @override
  String get level_4_7_cargo => 'Сухие носки штормовому дозору';

  @override
  String get level_4_7_sender => 'Штормовой дозор';

  @override
  String get level_4_8_name => 'Пиратский Капитан';

  @override
  String get level_4_8_cargo => 'Приказ вернуть почту для Капитана';

  @override
  String get level_4_8_sender => 'Пиратский Капитан';

  @override
  String get level_5_1_name => 'Почта полярного сияния';

  @override
  String get level_5_1_cargo => 'Шерстяные шапки пингвиньему хору';

  @override
  String get level_5_1_sender => 'Пингвиний хор';

  @override
  String get level_5_1_hint =>
      'Теперь может начаться любая погоня. Читай табличку!';

  @override
  String get level_5_2_name => 'Полярная ночь';

  @override
  String get level_5_2_cargo => 'Горячее какао для полярной станции';

  @override
  String get level_5_2_sender => 'Полярная станция';

  @override
  String get level_5_3_name => 'Неоновый экспресс';

  @override
  String get level_5_3_cargo => 'Предохранители для вывески лапшичной';

  @override
  String get level_5_3_sender => 'Повар лапшичной';

  @override
  String get level_5_4_name => 'Буря данных';

  @override
  String get level_5_4_cargo => 'Бумажное письмо любопытному роботу';

  @override
  String get level_5_4_sender => 'Блок-7';

  @override
  String get level_5_5_name => 'Рывок над крышами';

  @override
  String get level_5_5_cargo => 'Билеты на забег бегунам по крышам';

  @override
  String get level_5_5_sender => 'Бегуны по крышам';

  @override
  String get level_5_6_name => 'Праздник фонарей';

  @override
  String get level_5_6_cargo => 'Бумажные фонарики для праздника';

  @override
  String get level_5_6_sender => 'Мастера фонариков';

  @override
  String get level_5_7_name => 'Финишная прямая';

  @override
  String get level_5_7_cargo => 'Горный чай для монастыря';

  @override
  String get level_5_7_sender => 'Горные монахи';

  @override
  String get level_5_8_name => 'Тлеющий Дракон';

  @override
  String get level_5_8_cargo => 'Первое в жизни письмо Дракону';

  @override
  String get level_5_8_sender => 'Тлеющий Дракон';

  @override
  String get storyPostmasterName => 'Почтмейстер Билл';

  @override
  String get storySkip => 'Пропустить';

  @override
  String get storyNextLineSemantics => 'Дальше';

  @override
  String get storyFinishSemantics => 'Завершить';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => 'Каждое письмо долетит.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => 'Летим!';

  @override
  String levelIntroRunUp(int seconds) {
    return 'Сначала разбег $seconds с';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'Около $seconds с до финиша';
  }

  @override
  String get campaignGuardian => 'СТРАЖ';

  @override
  String get levelIntroBossFight => 'БОЙ С БОССОМ';

  @override
  String get levelIntroNew => 'НОВОЕ';

  @override
  String get levelIntroTip => 'СОВЕТ';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Победи Барона Нетопыря',
      'spitterBeetle': 'Победи Короля Плевунов',
      'duskMoth': 'Победи Сумеречную Императрицу',
      'pirate': 'Победи Пиратского Капитана',
      'dragon': 'Победи Тлеющего Дракона',
      'kingCoo': 'Победи Короля Курлыка',
      'searchlightGargoyle': 'Победи Прожекторную Горгулью',
      'other': 'Победи $boss',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroGoalFinish => 'Долети до финиша';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Собери $count звезды',
      many: 'Собери $count звёзд',
      few: 'Собери $count звезды',
      one: 'Собери $count звезду',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Одна звезда: $goal.',
      'two': 'Две звезды: $goal.',
      'other': 'Три звезды: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Одна звезда: $goal. Получена.',
      'two': 'Две звезды: $goal. Получены.',
      'other': 'Три звезды: $goal. Получены.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Рекорд: $count звезды',
      many: 'Рекорд: $count звёзд',
      few: 'Рекорд: $count звезды',
      one: 'Рекорд: $count звезда',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'Ещё не доставлено';

  @override
  String get levelIntroFirstFlight => 'Первый полёт';

  @override
  String get levelIntroControlFlap => 'Взмах';

  @override
  String get levelIntroControlShoot => 'Выстрел';

  @override
  String get levelIntroControlSprint => 'Рывок';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Управление: Взмах.',
      'shoot': 'Управление: Взмах, Выстрел.',
      'sprint': 'Управление: Взмах, Рывок.',
      'other': 'Управление: Взмах, Выстрел, Рывок.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => 'ОСОБАЯ ДОСТАВКА';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return 'Особая доставка: $cargo.';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return 'Уровень $level, $name. $region.';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return 'Уровень $level, $name. $region. Уровень стража: $boss.';
  }

  @override
  String get levelIntroStory => 'История';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonContinue => 'Дальше';

  @override
  String get commonHome => 'Домой';

  @override
  String get commonBackHome => 'Назад домой';

  @override
  String get campaignComingSoon => 'Скоро';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — скоро';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat': 'Сначала победи Барона Нетопыря',
      'spitterBeetle': 'Сначала победи Короля Плевунов',
      'duskMoth': 'Сначала победи Сумеречную Императрицу',
      'pirate': 'Сначала победи Пиратского Капитана',
      'dragon': 'Сначала победи Тлеющего Дракона',
      'kingCoo': 'Сначала победи Короля Курлыка',
      'searchlightGargoyle': 'Сначала победи Прожекторную Горгулью',
      'other': 'Сначала победи $boss',
    });
    return '$_temp0';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'Сначала пройди уровень $level';
  }

  @override
  String get campaignMapUnavailable => 'Карте нужна минутка.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return 'Закрыть: $name';
  }

  @override
  String get campaignMapPreviousStop => 'Предыдущая остановка';

  @override
  String get campaignMapNextStop => 'Следующая остановка';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. Глава $chapter, $route. Скоро.',
      'locked': '$region. Глава $chapter, $route. Закрыто.',
      'other': '$region. Глава $chapter, $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return 'ГЛАВА $chapter · $route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level, $name, босс',
      'guardian': 'Уровень $level, $name, страж: $boss',
      'other': 'Уровень $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. Закрыто.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. Закрыто. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars из 3 звёзд',
    );
    return '$node. Следующий на очереди. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars из 3 звёзд',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'Горгулья',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return 'Открытка главы $chapter';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars из $total звезды кампании',
      many: '$stars из $total звёзд кампании',
      few: '$stars из $total звёзд кампании',
      one: '$stars из $total звезды кампании',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'Дорогой курьер,';

  @override
  String get campaignPostcardPs => 'P.S.';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'Открытка. $route. Дорогой курьер, $body P.S. $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'Привет! Мы тут:';

  @override
  String get campaignPostcardHeader => 'ОТКРЫТКА НЕБЕСНОГО КЛУБА';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'Курьеру';

  @override
  String get campaignPostcardAddressStreet => 'Небесный клуб';

  @override
  String get campaignPostcardAddressCity => 'Высоко в небе';

  @override
  String get campaignPostmarkDelivered => 'ДОСТАВЛЕНО';

  @override
  String get campaignPostmarkClub => 'НЕБЕСНАЯ ПОЧТА';

  @override
  String get campaignStampSkyClub => 'НЕБ. КЛУБ';

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
    return 'Благодарственная записка. $sender: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'Чуть-чуть подготовки. Много неба.';

  @override
  String get flightSetupTitleSquat => 'Ноги на полу. Крылья расправлены.';

  @override
  String get flightSetupTitleJump => 'Маленькие прыжки. Большие крылья.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'УРОВЕНЬ · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · В ЗАЧЁТ';
  }

  @override
  String get flightSetupRoomPushUp => 'Освободи немного места.';

  @override
  String get flightSetupRoomBody => 'Покажись в полный рост.';

  @override
  String get flightSetupTipsPushUp =>
      'Телефон пониже. Покажи руку и бедро.\nЛицом к нему? Держи в кадре оба плеча.';

  @override
  String get flightSetupTipsSquat =>
      'Присядь — снижаешься. Встань — взлетаешь.\nДержи обе ноги на полу.';

  @override
  String get flightSetupTipsJump =>
      'Прыжок — ускорение и 3 с парения.\nПриземлись перед новым прыжком.';

  @override
  String get flightSetupHowToFly => 'КАК ЛЕТАТЬ';

  @override
  String get flightSetupStep1PushUp => 'Покажи руку и бедро';

  @override
  String get flightSetupStep1Squat => 'Освободи место для приседаний';

  @override
  String get flightSetupStep1Jump => 'Освободи место для прыжков';

  @override
  String get flightSetupStep1DetailPushUp =>
      'Лицом к телефону? Покажи оба плеча, руку и бедро.';

  @override
  String get flightSetupStep1DetailBody =>
      'Телефон горизонтально. Покажи себя целиком и обе ступни.';

  @override
  String get flightSetupStep2PushUp => 'Найди свою амплитуду';

  @override
  String get flightSetupStep2Squat => 'Найди удобный присед';

  @override
  String get flightSetupStep2Jump => 'Встань прямо и замри';

  @override
  String get flightSetupStep2DetailPushUp =>
      'Найди удобную верхнюю точку, потом дважды опустись и поднимись.';

  @override
  String get flightSetupStep2DetailSquat =>
      'Постой спокойно, присядь, чуть задержись и встань.';

  @override
  String get flightSetupStep2DetailJump =>
      'Чуть-чуть замри. Потом прыгни — будет мощное ускорение.';

  @override
  String get flightSetupStep3Stars => 'Собирай звёзды';

  @override
  String get flightSetupStep3DetailJump =>
      'Звезда даёт 0,75 с парения, максимум 5 с. Трио звёзд — +5 очков.';

  @override
  String get flightSetupLivesEndless =>
      'Три сердечка + щит. Пауза — в любой момент.';

  @override
  String get flightSetupLivesClassic =>
      'Столкновение или потеря позиции завершают зачётный полёт. Пауза — в любой момент.';

  @override
  String get flightSetupCameraButton => 'Настроить камеру';

  @override
  String get flightMicTitle => 'Запись микрофона';

  @override
  String get flightMicOn => 'Вкл';

  @override
  String get flightMicOptional => 'По желанию';

  @override
  String get flightMicDetail =>
      'Добавь в повторы свой голос и звуки комнаты. Микрофон работает только в полёте. Всё хранится на этом телефоне.';

  @override
  String get flightMicSemantics => 'Записывать микрофон для повторов';

  @override
  String get flightMicSettings => 'Настройки микрофона';

  @override
  String get flightCalibrationTitleReady => 'Твои крылья на месте!';

  @override
  String get flightCalibrationTitleWaking => 'Будим твою камеру…';

  @override
  String get flightCalibrationTitleError => 'Давай переподключим камеру.';

  @override
  String get flightCalibrationTitleRange => 'Найди свою амплитуду.';

  @override
  String get flightCalibrationTitleStill => 'Встань прямо и замри.';

  @override
  String get flightCalibrationStepTry => 'Попробуй управлять птицей.';

  @override
  String get flightCalibrationStepTop => 'Найди удобную верхнюю точку.';

  @override
  String get flightCalibrationStepLower => 'Медленно опустись.';

  @override
  String get flightCalibrationStepPushBack => 'Поднимись обратно.';

  @override
  String get flightCalibrationStepStill => 'Встань прямо и замри.';

  @override
  String get flightCalibrationStepSquat => 'Присядь, как удобно.';

  @override
  String get flightCalibrationStepStandUp => 'Встань обратно.';

  @override
  String get flightCalibrationStepDone => 'Твои крылья на месте!';

  @override
  String get flightCalibrationReadyPushUp =>
      'Поднимайся — птица взлетает. Опускайся — парит.';

  @override
  String get flightCalibrationReadySquat =>
      'Присядь — птица снижается. Встань — взлетает.';

  @override
  String get flightCalibrationReadyJump =>
      'Прыгни и отдыхай, пока птица парит.';

  @override
  String get flightCalibrationKeepPushUp =>
      'Держи в кадре плечи, руку и бедро. Двигайся, как удобно.';

  @override
  String get flightCalibrationKeepBody =>
      'Держи в кадре плечи, бёдра и обе ступни.';

  @override
  String get flightCalibrationLearning => 'Запоминаем, как ты двигаешься.';

  @override
  String get flightCalibrationAfter => 'Птица полетит после калибровки.';

  @override
  String get flightCalibrationJump => 'Прыжок!';

  @override
  String get flightCalibrationTagCheck => 'ТЕСТ УПРАВЛЕНИЯ';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '$count / 2 ОТЖИМАНИЯ';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return 'КАЛИБРОВКА $percent%';
  }

  @override
  String get flightCalibrationTakeoff => 'Готовы к взлёту';

  @override
  String get flightCalibrationStarting => 'Запуск…';

  @override
  String get flightCalibrationRestart => 'Калибровать заново';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate обн./с · $p95 мс p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate обн./с · $p95 мс p95 (только обработка)';
  }

  @override
  String get flightCalibrationStatusReady => 'ГОТОВО';

  @override
  String get flightCalibrationStatusStarting => 'ЗАПУСК';

  @override
  String get flightCalibrationStatusCameraOff => 'КАМЕРА ВЫКЛ.';

  @override
  String get flightCalibrationStatusCalibrating => 'КАЛИБРОВКА';

  @override
  String get flightSwitchCameraSemantics => 'Сменить камеру';

  @override
  String get flightCalibrationStepIntoView => 'Встань в кадр';

  @override
  String get flightCameraTroubleTitle => 'Обычно помогает перезапуск.';

  @override
  String get flightCameraTroubleAllow =>
      'Разреши доступ к камере в настройках.';

  @override
  String get flightCameraTroubleClose =>
      'Закрой другие приложения с камерой и попробуй снова.';

  @override
  String get flightCameraPermissionSemantics => 'Настройки доступа к камере';

  @override
  String get flightNoteRememberFailed =>
      'Изменено для этого полёта. Не удалось запомнить выбор.';

  @override
  String get flightNoteMicUnavailable =>
      'Микрофон недоступен. Видео и игра работают.';

  @override
  String get flightNoteMicBlocked =>
      'Микрофон заблокирован. Его можно разрешить в настройках; видео работает.';

  @override
  String get flightNoteMicOff =>
      'Микрофон выключен. Играть и сохранять видео всё равно можно.';

  @override
  String get flightNoteVideoUnavailable =>
      'Видео с камеры недоступно. Игру всё равно можно сохранить.';

  @override
  String get flightNoteMicAudioLost =>
      'Звук с микрофона был недоступен. Видео и игру всё равно можно сохранить.';

  @override
  String get flightNoteVideoInterrupted =>
      'Видео с камеры прервалось. Записанное и игру всё равно можно сохранить.';

  @override
  String get flightNoteSessionSaveFailed =>
      'Не удалось сохранить полёт. Нажми «Сохранить полёт», чтобы повторить.';

  @override
  String get flightNoteWakingCamera => 'Будим твою камеру…';

  @override
  String get flightNoteCameraOff =>
      'Доступ к камере выключен. Разреши его в настройках Android, вернись и попробуй снова.';

  @override
  String get flightNoteCameraFailed =>
      'Камера не запустилась. Попробуй снова или смени камеру.';

  @override
  String get flightNotePreparing => 'Готовим полёт…';

  @override
  String get flightNoteSaveFailed =>
      'Не удалось сохранить полёт. Нажми, чтобы повторить.';

  @override
  String get flightNoteWelcomeBack =>
      'С возвращением! Давай снова проверим позицию.';

  @override
  String get flightNoteCameraInterrupted =>
      'Камера прервалась. Проверь доступ к камере и попробуй снова.';

  @override
  String get flightNoteTrackingInterrupted => 'Трекинг прервался';

  @override
  String get flightFindPosition => 'Займи позицию';

  @override
  String get flightTapSemantics => 'Жми для взмаха';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'Жми для взмаха. $group летят впереди своего босса';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'Жми для взмаха. $boss: здоровье $hp из $maxHp';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'Жми для взмаха. $boss: здоровье $hp из $maxHp. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'К результатам';

  @override
  String get hudPauseSemantics => 'Пауза';

  @override
  String get flightHintTestSteerKeys =>
      'Пробный полёт: управляй стрелками вверх и вниз.';

  @override
  String get flightHintTestSteerDrag =>
      'Пробный полёт: веди пальцем вверх и вниз.';

  @override
  String get flightHintTestJumpKeys => 'Пробный полёт: пробел — прыжок.';

  @override
  String get flightHintTestJumpTap => 'Пробный полёт: жми, чтобы прыгнуть.';

  @override
  String get flightHintKeysStars => 'Пробел — взмах. Лети сквозь звёзды.';

  @override
  String get flightHintKeysShoot =>
      'Пробел — взмах. Держи D, чтобы зарядить выстрел.';

  @override
  String get flightHintKeysCombat =>
      'Пробел — взмах. Держи D — заряд выстрела. A — рывок!';

  @override
  String get flightHintKeysPause => 'Пробел — взмах. Esc — пауза.';

  @override
  String get flightHintTapStars =>
      'Жми на небо, чтобы взмахнуть. Лети сквозь звёзды.';

  @override
  String get flightHintTapShoot =>
      'Жми на небо — взмах. Держи «Выстрел» для заряда.';

  @override
  String get flightHintTapCombat =>
      'Жми на небо — взмах. Держи «Выстрел» для заряда. «Рывок» всё сносит!';

  @override
  String get flightHintTapRelease =>
      'Жми для взмаха. Отпускай между нажатиями.';

  @override
  String get flightHintTrail => 'Следуй за звёздами. Щит готов.';

  @override
  String get flightHintSky => 'Небо твоё.';

  @override
  String hudClockSemantics(String time) {
    return 'Осталось $time';
  }

  @override
  String flightSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Звёздный магнит: осталось $seconds секунды',
      many: 'Звёздный магнит: осталось $seconds секунд',
      few: 'Звёздный магнит: осталось $seconds секунды',
      one: 'Звёздный магнит: осталась $seconds секунда',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Магнит заряжается: $charge из $gates идеального пролёта',
      many: 'Магнит заряжается: $charge из $gates идеальных пролётов',
      few: 'Магнит заряжается: $charge из $gates идеальных пролётов',
      one: 'Магнит заряжается: $charge из $gates идеального пролёта',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'Ищем тебя…';

  @override
  String get hudShoot => 'Выстрел';

  @override
  String get hudSprint => 'Рывок';

  @override
  String get flightTestNothingSaved => 'без сохранения';

  @override
  String get flightCountdownReady => 'На старт, внимание…';

  @override
  String get flightPauseTitle => 'Передохни.';

  @override
  String get flightPauseKeepFlying => 'Летим дальше';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. Птица присела отдохнуть и ждёт тебя.';
  }

  @override
  String flightPausedTest(String name) {
    return 'Пробный полёт: $name. Ничего не сохраняется.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. Птица присела отдохнуть и ждёт тебя.';
  }

  @override
  String get flightPausedTouch =>
      'Птица присела отдохнуть и ждёт. Перед стартом будет отсчёт.';

  @override
  String get flightPausedCamera =>
      'Разомнись и вернись на позицию. Перед стартом будет отсчёт.';

  @override
  String get flightPauseEdit => 'Изменить';

  @override
  String get flightPauseBuilder => 'Конструктор';

  @override
  String get flightPauseFinish => 'Завершить полёт';

  @override
  String get hudShieldRecovering => 'Восстановление';

  @override
  String get hudShieldReady => 'Щит готов';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Щит заряжается: $charge из $stars звезды',
      many: 'Щит заряжается: $charge из $stars звёзд',
      few: 'Щит заряжается: $charge из $stars звёзд',
      one: 'Щит заряжается: $charge из $stars звезды',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count сердечка',
      many: 'Осталось $count сердечек',
      few: 'Осталось $count сердечка',
      one: 'Осталось $count сердечко',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'Рывок идёт';

  @override
  String get hudSprintReady => 'Готово';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Перезарядка, $seconds секунды',
      many: 'Перезарядка, $seconds секунд',
      few: 'Перезарядка, $seconds секунды',
      one: 'Перезарядка, $seconds секунда',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint =>
      'Рвани вперёд, сметая летучих мышей и каменные плиты';

  @override
  String get hudShotReloading => 'Перезарядка…';

  @override
  String hudShotFullCharge(int ms) {
    return 'Полный заряд, осталось $ms мс';
  }

  @override
  String hudShotCharging(int percent) {
    return 'Заряд $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'Камни $percent%';
  }

  @override
  String get hudShotHint => 'Удерживай, чтобы зарядить камень побольше';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды получено',
      many: '$count звёзд получено',
      few: '$count звезды получены',
      one: '$count звезда получена',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды — при $at',
      many: '$count звёзд — при $at',
      few: '$count звезды — при $at',
      one: '$count звезда — при $at',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Собрано $stars звезды',
      many: 'Собрано $stars звёзд',
      few: 'Собрано $stars звезды',
      one: 'Собрана $stars звезда',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'МАКС';

  @override
  String hudRouteSemantics(int percent) {
    return 'Пройдено $percent% маршрута';
  }

  @override
  String hudGlideCompact(String time) {
    return 'Парение · $time';
  }

  @override
  String get hudJumpToGlide => 'Прыгай и пари';

  @override
  String get hudJump => 'Прыжок';

  @override
  String hudGlideSemantics(String time) {
    return 'Парение, осталось $time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'Парение заканчивается, осталось $time';
  }

  @override
  String get hudJumpChargeSemantics =>
      'Прыгни, чтобы зарядить 3 секунды парения';

  @override
  String get hudRecordNewBest => 'Новый рекорд!';

  @override
  String get hudRecordMatched => 'Ровно рекорд!';

  @override
  String hudRecordBest(int best) {
    return 'Рекорд $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '+$points сверх рекорда';
  }

  @override
  String get hudRecordOneMore => 'Ещё очко — и рекорд';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count до рекорда',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'Очки: $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'Очки: $score, множитель ×$multiplier';
  }

  @override
  String get commonBusySemantics => 'Обработка';

  @override
  String get flightResultBumpClouds => 'Небольшая заминка в облаках.';

  @override
  String get flightResultPersonalBest => 'ЛИЧНЫЙ РЕКОРД';

  @override
  String get flightResultNewPersonalBest => 'НОВЫЙ ЛИЧНЫЙ РЕКОРД!';

  @override
  String get flightResultStarsCollected => 'СОБРАНО ЗВЁЗД';

  @override
  String get flightResultDailyStamped => 'Открытка дня проштампована!';

  @override
  String flightResultNextStamp(String stamp) {
    return 'Далее: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'Сохранено на этом телефоне';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Сохранено на телефоне · ворот всего: $total',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'Сохраняем полёт…';

  @override
  String get flightResultSessionSaved => 'Полёт сохранён · Смотри в «Рекордах»';

  @override
  String get flightResultWatchReplay => 'Смотреть повтор';

  @override
  String get flightResultPreparing => 'Готовим…';

  @override
  String get flightResultSavingShort => 'Сохранение…';

  @override
  String get flightResultSaveSession => 'Сохранить полёт';

  @override
  String get flightResultFlyAgain => 'Лететь снова';

  @override
  String get commonRetry => 'Заново';

  @override
  String get commonMap => 'Карта';

  @override
  String get commonNext => 'Дальше';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'отжимания',
      many: 'отжиманий',
      few: 'отжимания',
      one: 'отжимание',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'приседания',
      many: 'приседаний',
      few: 'приседания',
      one: 'приседание',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'прыжка',
      many: 'прыжков',
      few: 'прыжка',
      one: 'прыжок',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'взмаха',
      many: 'взмахов',
      few: 'взмаха',
      one: 'взмах',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'время полёта';

  @override
  String get flightStatPerfect => 'идеальных';

  @override
  String get flightStatBestStreak => 'лучшая серия';

  @override
  String get flightStatRank => 'звание';

  @override
  String get flightRankSkyCaptain => 'Капитан неба';

  @override
  String get flightRankCloudExplorer => 'Облакопроходец';

  @override
  String get flightRankFirstWings => 'Первые крылья';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => 'Столкновение — зато новый рекорд!';

  @override
  String get gameOverCaptionSea => 'Маленький плюх в море.';

  @override
  String get gameOverSplash => 'Плюх!';

  @override
  String get gameOverBonk => 'Бамс!';

  @override
  String get gameOverEveryMarkSemantics => 'Все отметки достигнуты';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count звезды до $mark звёзд',
      many: 'Ещё $count звёзд до $mark звёзд',
      few: 'Ещё $count звезды до $mark звёзд',
      one: 'Ещё $count звезда до $mark звёзд',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: осталось $hp из $maxHp здоровья';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return 'Пройдено $percent% маршрута';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: ЗДОРОВЬЕ $hp';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$boss: ОСТАЛОСЬ';
  }

  @override
  String get gameOverRouteFlown => 'ПРОЙДЕНО МАРШРУТА';

  @override
  String gameOverHp(int hp) {
    return '$hp ОЗ';
  }

  @override
  String gameOverMoreFor(int count) {
    return 'Ещё $count до';
  }

  @override
  String get gameOverBothMarks => 'Обе отметки есть';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    return 'Обе отметки есть. Теперь — $boss!';
  }

  @override
  String get miniResultTitle => 'Каждый полёт на счету.';

  @override
  String get miniResultComplete => 'ПОЛЁТ ЗАВЕРШЁН';

  @override
  String get miniResultCheerBest => 'Вот это полёт!';

  @override
  String get miniResultCheerComplete => 'Полёт завершён!';

  @override
  String get miniResultCheerNice => 'Отлично летаешь.';

  @override
  String get miniResultNew => 'НОВОЕ';

  @override
  String get flightEndTrackingLost => 'Мы ненадолго потеряли тебя из виду.';

  @override
  String get flightEndPostureLost => 'Твоя позиция вышла за пределы кадра.';

  @override
  String get flightEndBackgrounded => 'Небо пришлось ненадолго оставить.';

  @override
  String get flightEndBreak => 'Заслуженная передышка.';

  @override
  String get flightEndQuit => 'До следующего приключения.';

  @override
  String get flightEndStalled => 'Игра прервалась.';

  @override
  String get flightEndCompleted => 'Целое небо звёзд. Всё твоё.';

  @override
  String get levelResultTryAgain => 'Ещё разок!';

  @override
  String get levelResultVictory => 'Победа!';

  @override
  String get levelResultGuardianDown => 'Страж повержен!';

  @override
  String get levelResultDelivered => 'Доставлено!';

  @override
  String levelResultComingSoon(String region) {
    return '$region — уже скоро!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned из 3 звёзд';
  }

  @override
  String levelResultBest(int best) {
    return 'Рекорд $best';
  }

  @override
  String get levelResultNoBest => 'Рекорда пока нет';

  @override
  String get levelResultFirstClear => 'Первый финиш!';

  @override
  String get levelResultNewBest => 'НОВЫЙ РЕКОРД!';

  @override
  String get levelResultScore => 'ОЧКИ';

  @override
  String get levelResultGoalBoss => 'Босс';

  @override
  String get levelResultGoalGuardian => 'Страж';

  @override
  String get levelResultGoalFinish => 'Финиш';

  @override
  String get levelResultGoalDone => 'Готово';

  @override
  String get levelResultGoalNotYet => 'Пока нет';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'Нужен финиш';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. Готово.';
  }

  @override
  String get levelResultPostcardWaiting => 'На карте тебя ждёт открытка!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return 'Уровень $id «$name» открыт!';
  }

  @override
  String get levelResultReachFinish => 'Долети до финиша — получишь звёзды.';

  @override
  String get course_classic_title => 'Классика';

  @override
  String get course_starTrail_title => 'Бесконечный';

  @override
  String get course_classic_instructions =>
      'Находи проходы. Следуй прицельным меткам для идеального пролёта.';

  @override
  String get course_starTrail_instructions =>
      'Собери все 3 звезды группы — +5. Звёзды подряд дают до 3×. Звёзды чинят щит, идеальные пролёты дают звёздный магнит. Улучшай и то и другое за звёзды!';

  @override
  String get course_classic_scoreLabel => 'ПРЕПЯТСТВИЯ';

  @override
  String get course_starTrail_scoreLabel => 'ЗВЁЗДНЫЕ ОЧКИ';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'препятствия',
      many: 'препятствий',
      few: 'препятствия',
      one: 'препятствие',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'звёздного очка',
      many: 'звёздных очков',
      few: 'звёздных очка',
      one: 'звёздное очко',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics =>
      'Классика: пролетай сквозь проходы.';

  @override
  String get course_starTrail_previewSemantics =>
      'Бесконечный полёт: собирай звёзды; три сердечка и щит.';

  @override
  String get obstacle_garden_name => 'Садовая калитка';

  @override
  String get obstacle_windLift_name => 'Ветряной лифт';

  @override
  String get obstacle_petalGate_name => 'Лепестковые ставни';

  @override
  String get obstacle_switchback_name => 'Серпантин';

  @override
  String get obstacle_lanternDrift_name => 'Плавучие фонарики';

  @override
  String get obstacle_sunWheels_name => 'Солнечные колёса';

  @override
  String get obstacle_crystalSteps_name => 'Ступени хрусталя';

  @override
  String get rush_wildfire_name => 'Пожар';

  @override
  String get rush_wildfire_escape => 'Удрали от пожара';

  @override
  String get rush_skyfall_name => 'Небопад';

  @override
  String get rush_skyfall_escape => 'Пережили небопад';

  @override
  String get rush_eruption_name => 'Извержение';

  @override
  String get rush_eruption_escape => 'Обогнали извержение';

  @override
  String get rush_swarm_name => 'Стая';

  @override
  String get rush_swarm_escape => 'Прорвались сквозь стаю';

  @override
  String get boss_baronBat_title => 'ПОВЕЛИТЕЛЬ БУРИ';

  @override
  String get boss_spitterBeetle_title => 'ЗЕЛЬЕВАР РОЯ';

  @override
  String get boss_duskMoth_title => 'ХРАНИТЕЛЬНИЦА СУМЕРЕЧНОЙ ВУАЛИ';

  @override
  String get boss_pirate_title => 'ГРОЗА ВЫСОКОГО ПРИЛИВА';

  @override
  String get boss_dragon_title => 'ВЛАДЫКА ПЫЛАЮЩЕГО НЕБА';

  @override
  String get boss_kingCoo_title => 'БЛЮСТИТЕЛЬ БОРДЮРА';

  @override
  String get boss_searchlightGargoyle_title => 'СТРАЖ САМОЙ ВЫСОКОЙ БАШНИ';

  @override
  String get boss_neferhoo_title => 'ХРАНИТЕЛЬ ПОТЕРЯННОГО ПИСЬМА';

  @override
  String get boss_baronBat_returnTitle => 'БУРЯ ВОЗВРАЩАЕТСЯ';

  @override
  String get boss_baronBat_barName => 'БАРОН НЕТОПЫРЬ';

  @override
  String get boss_spitterBeetle_barName => 'КОРОЛЬ ПЛЕВУНОВ';

  @override
  String get boss_duskMoth_barName => 'ИМПЕРАТРИЦА';

  @override
  String get boss_pirate_barName => 'КАПИТАН';

  @override
  String get boss_dragon_barName => 'ТЛЕЮЩИЙ ДРАКОН';

  @override
  String get boss_kingCoo_barName => 'КОРОЛЬ КУРЛЫК';

  @override
  String get boss_searchlightGargoyle_barName => 'ГОРГУЛЬЯ';

  @override
  String get boss_neferhoo_barName => 'НЕФЕРХУ';

  @override
  String get vanguard_baronBat_title => 'ЛЕТУЧИЕ МЫШИ БАРОНА';

  @override
  String get vanguard_baronBat_call => 'Летят! А за ними сам Барон.';

  @override
  String get vanguard_spitterBeetle_title => 'ВЫВОДОК КОРОЛЯ ПЛЕВУНОВ';

  @override
  String get vanguard_spitterBeetle_call =>
      'Летят! А за ними сам Король Плевунов.';

  @override
  String get vanguard_duskMoth_title => 'МОТЫЛЬКИ ИМПЕРАТРИЦЫ';

  @override
  String get vanguard_duskMoth_call => 'Летят! А за ними сама Императрица.';

  @override
  String get vanguard_kingCoo_title => 'ЭСКАДРИЛЬЯ КОРОЛЯ КУРЛЫКА';

  @override
  String get vanguard_kingCoo_call => 'Летят! А за ними сам Король Курлык.';

  @override
  String get vanguard_kingCoo_callCrusts => 'Летят! Уворачивайся от корок!';

  @override
  String get vanguard_kingCoo_callReturns =>
      'Уворачивайся от корок! Упустишь голубя — он вернётся!';

  @override
  String get bossVanguardClear => 'ЧИСТО!';

  @override
  String get bossVanguardLeft => 'ОСТАЛОСЬ';

  @override
  String get bossStragglersCaught => 'ВСЕ ПОЙМАНЫ!';

  @override
  String get bossHint_strongerBaronBat =>
      'СИЛЬНЕЕ · Тройные выстрелы, и летучие мыши тоже в деле!';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'СИЛЬНЕЕ · Полные веера, и жуки тоже в деле!';

  @override
  String get bossHint_strongerDuskMoth =>
      'СИЛЬНЕЕ · Веера по семь, и мотыльки тоже в деле!';

  @override
  String get bossHint_strongerPirate => 'СИЛЬНЕЕ · Прилив поднимается!';

  @override
  String get bossHint_strongerDragon => 'СИЛЬНЕЕ · Берегись дыхания и стай!';

  @override
  String get bossHint_strongerKingCoo =>
      'СИЛЬНЕЕ · Он свистом зовёт эскадрилью!';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'СИЛЬНЕЕ · Перья падают, пока лампа открыта!';

  @override
  String get bossHint_strongerGargoyle => 'СИЛЬНЕЕ · Падают каменные перья!';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'СИЛЬНЕЕ · Анх и летучие мыши-мумии!';

  @override
  String get bossHint_strongerNeferhoo => 'СИЛЬНЕЕ · Золотой анх возвращается!';

  @override
  String get bossHint_tideRising => 'ПРИЛИВ ИДЁТ · Лети выше!';

  @override
  String get bossHint_highTide => 'ВЫСОКИЙ ПРИЛИВ · Держись над водой';

  @override
  String get bossHint_tideFury => 'ЯРОСТЬ · Бортовые залпы между волнами';

  @override
  String get bossHint_tideCalm =>
      'Уворачивайся от ядер · Держись подальше от воды';

  @override
  String get bossHint_dragonSwarm =>
      'СТАЯ · Уворачивайся от мышей или пролети рывком';

  @override
  String get bossHint_dragonFuryDebut => 'ЯРОСТЬ · Огненные шары быстрее';

  @override
  String get bossHint_dragonFury =>
      'ЯРОСТЬ · Огненные шары рассыпаются тлеющими углями';

  @override
  String get bossHint_dragonCalm =>
      'Уворачивайся от огненных шаров · Берегись дыхания';

  @override
  String get bossHint_screechFury =>
      'ЯРОСТЬ · Огненные шары быстрее, мышей больше';

  @override
  String get bossHint_screechCalm =>
      'Уворачивайся от огненных шаров и мышей · Берегись визга';

  @override
  String get bossHint_cooPopped => 'ХЛОП! · Эскадрильи не будет';

  @override
  String get bossHint_cooSquadron => 'ЭСКАДРИЛЬЯ · Лети по свободной полосе!';

  @override
  String get bossHint_cooPuffed => 'НАДУЛСЯ · Стреляй в грудь (x2)!';

  @override
  String get bossHint_cooCrumbBomb => 'БОМБА ИЗ КРОШЕК · Покинь кольцо!';

  @override
  String get bossHint_cooFury => 'ЯРОСТЬ · Держись между кольцами';

  @override
  String get bossHint_cooCalm =>
      'Уворачивайся от бомб из крошек · Стреляй в грудь, когда он надувается';

  @override
  String get bossHint_beamOn => 'ЛУЧ · Держись в темноте';

  @override
  String get bossHint_beamFury => 'ЯРОСТЬ · Проскользни между лучами';

  @override
  String get bossHint_beamIncomingHigh => 'ЛУЧ БЛИЗКО · Лети ниже!';

  @override
  String get bossHint_beamIncomingLow => 'ЛУЧ БЛИЗКО · Лети выше!';

  @override
  String get bossHint_lampOpen => 'ЛАМПА ОТКРЫТА · Стреляй в лампу!';

  @override
  String get bossHint_shuttersClosed => 'СТАВНИ ЗАКРЫТЫ · Береги камни';

  @override
  String get bossHint_mothFuryNoVeil =>
      'ЯРОСТЬ · Веера по семь. Вуали пока нет!';

  @override
  String get bossHint_mothNoVeil => 'Вуали пока нет · Стреляй между веерами!';

  @override
  String get bossHint_mothShielded =>
      'ЩИТ · Уворачивайся, пока вуаль не спадёт';

  @override
  String get bossHint_mothShieldForming =>
      'ЩИТ ПОЯВЛЯЕТСЯ · Готовься уворачиваться';

  @override
  String get bossHint_mothFury => 'ЯРОСТЬ · Веера по семь. Вуаль спала!';

  @override
  String get bossHint_mothCalm => 'Вуаль спала · Стреляй между веерами!';

  @override
  String get bossHint_neferhooMailCall => 'ВАМ ПОЧТА! · Отбей письма!';

  @override
  String get bossHint_neferhooReturn => 'ВЕРНУТЬ ОТПРАВИТЕЛЮ! · −25';

  @override
  String get bossHint_neferhooReturnFaster => 'ВЕРНУТЬ ОТПРАВИТЕЛЮ! · −18';

  @override
  String get bossHint_neferhooAnkh => 'АНХ · Он возвращается!';

  @override
  String get bossHint_neferhooExpress => 'ЭКСПРЕСС-ПОЧТА · Пять писем, быстрее';

  @override
  String get bossHint_neferhooTwoAnkhs =>
      'ДВА АНХА · Держись подальше от обеих полос';

  @override
  String get bossHint_neferhooBats => 'ЛЕТУЧИЕ МЫШИ-МУМИИ · Сбей их!';

  @override
  String get bossHint_neferhooScuff =>
      'Камни только царапают его бинты. Отбивай его ПИСЬМА!';

  @override
  String get bossHint_neferhooWarmUp =>
      'Отбивай его письма · Вернуть отправителю';

  @override
  String get bossHint_neferhooCalm =>
      'Отбивай его письма · Уворачивайся от золотого анха';

  @override
  String get bossHint_neferhooFury => 'ЯРОСТЬ · Экспресс-почта и два анха';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'ДРАКОНЬЕ ДЫХАНИЕ · Лети ниже! Сердце открыто',
      'middle': 'ДРАКОНЬЕ ДЫХАНИЕ · Вверх или вниз! Сердце открыто',
      'other': 'ДРАКОНЬЕ ДЫХАНИЕ · Лети выше! Сердце открыто',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'ОГОНЬ · Лети ниже! Бей в светящееся сердце',
      'middle': 'ОГОНЬ · Вверх или вниз! Бей в светящееся сердце',
      'other': 'ОГОНЬ · Лети выше! Бей в светящееся сердце',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'ЗВУКОВОЙ ВИЗГ · Лети к верхнему просвету!',
      'middle': 'ЗВУКОВОЙ ВИЗГ · Лети к среднему просвету!',
      'other': 'ЗВУКОВОЙ ВИЗГ · Лети к нижнему просвету!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'ВИЗГ · Держись в верхнем просвете',
      'middle': 'ВИЗГ · Держись в среднем просвете',
      'other': 'ВИЗГ · Держись в нижнем просвете',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'УВОРАЧИВАЙСЯ ОТ ВЕЕРОВ  ·  СТРЕЛЯЙ, КОГДА СПАДЁТ ВУАЛЬ';

  @override
  String get encounterCaption_pirate =>
      'УВОРАЧИВАЙСЯ ОТ ПУШКИ  ·  ДЕРЖИСЬ ПОДАЛЬШЕ ОТ ВОДЫ';

  @override
  String get encounterCaption_dragon =>
      'УВОРАЧИВАЙСЯ ОТ ОГНЕННЫХ ШАРОВ  ·  СПАСАЙСЯ ОТ ДЫХАНИЯ';

  @override
  String get encounterCaption_kingCoo =>
      'ПОКИДАЙ КОЛЬЦА  ·  СТРЕЛЯЙ В ГРУДЬ, КОГДА ОН НАДУВАЕТСЯ';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'НЕ ПОПАДАЙ В ЛУЧ  ·  СТРЕЛЯЙ В ЛАМПУ, КОГДА ОНА ОТКРЫТА';

  @override
  String get encounterCaption_neferhoo => 'ПРИГОТОВЬСЯ  ·  ОТБИВАЙ ЕГО ПИСЬМА';

  @override
  String get encounterCaption_screech => 'КОГДА ОН ВИЗЖИТ  ·  ЛЕТИ К ПРОСВЕТУ';

  @override
  String get encounterCaption_default =>
      'ПРИГОТОВЬСЯ  ·  МАШИ, УВОРАЧИВАЙСЯ, СТРЕЛЯЙ';

  @override
  String get encounterCoasting => 'Птица летит сама и в безопасности';

  @override
  String get encounterOpenSky => 'Снова в открытое небо';

  @override
  String get encounterOmenTitle_duskMoth => 'СУМЕРКИ РАСПРАВЛЯЮТ КРЫЛЬЯ';

  @override
  String get encounterOmenLine_duskMoth =>
      'В сумерках сгущается шёлковая вуаль…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'ЧТО-ТО ЗАВАРИВАЕТСЯ';

  @override
  String get encounterOmenLine_spitterBeetle =>
      'Воздух начинает шипеть и пузыриться…';

  @override
  String get encounterOmenTitle_dragon => 'НЕБО ВСПЫХИВАЕТ';

  @override
  String get encounterOmenLine_dragon => 'Над облаками бьют огромные крылья…';

  @override
  String get encounterOmenTitle_kingCoo => 'БОРДЮР ПЕРЕКРЫТ';

  @override
  String get encounterOmenLine_kingCoo =>
      'Кто-то очень сердит из-за хлебной тележки…';

  @override
  String get encounterOmenTitle_searchlightGargoyle =>
      'ШТОРМОВОЕ ПРЕДУПРЕЖДЕНИЕ';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      'Кто-то на карнизе за тобой следит…';

  @override
  String get encounterOmenTitle_neferhoo => 'ПИРАМИДА ПРОСЫПАЕТСЯ';

  @override
  String get encounterOmenLine_neferhoo => 'Пыль пирамиды приходит в движение…';

  @override
  String get encounterOmenTitle_baronReturns => 'БАРОН ВЕРНУЛСЯ';

  @override
  String get encounterOmenLine_baronReturns =>
      'Он вернулся, и теперь он гораздо громче…';

  @override
  String get encounterOmenTitle_default => 'НАДВИГАЕТСЯ ТЕНЬ';

  @override
  String get encounterOmenLine_default =>
      'Небо теперь принадлежит кому-то другому…';

  @override
  String get encounterOmenTitle_pirate => 'ПАРУС НА ГОРИЗОНТЕ!';

  @override
  String get encounterOmenLine_pirate => 'С приливом приближается корабль…';

  @override
  String get bossGuardianEyebrow => 'СТРАЖ';

  @override
  String bossEncounterEyebrow(String number) {
    return 'ВСТРЕЧА $number';
  }

  @override
  String get bossGuardianDown => 'СТРАЖ ПОВЕРЖЕН!';

  @override
  String get bossSkyReclaimed => 'НЕБО ОСВОБОЖДЕНО';

  @override
  String bossVictoryPoints(int points) {
    return '+$points К СЧЁТУ   ·   ЩИТ ВОССТАНОВЛЕН';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'БАРОН НЕТОПЫРЬ ПОВЕРЖЕН',
      'spitterBeetle': 'КОРОЛЬ ПЛЕВУНОВ ПОВЕРЖЕН',
      'duskMoth': 'СУМЕРЕЧНАЯ ИМПЕРАТРИЦА ПОВЕРЖЕНА',
      'pirate': 'ПИРАТСКИЙ КАПИТАН ПОВЕРЖЕН',
      'dragon': 'ТЛЕЮЩИЙ ДРАКОН ПОВЕРЖЕН',
      'kingCoo': 'КОРОЛЬ КУРЛЫК ПОВЕРЖЕН',
      'searchlightGargoyle': 'ПРОЖЕКТОРНАЯ ГОРГУЛЬЯ ПОВЕРЖЕНА',
      'other': 'НЕФЕРХУ ПОВЕРЖЕН',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '«$line»';
  }

  @override
  String get bossPirateRoar => 'АРРР!';

  @override
  String get bossGargoyleCardSmall => 'ПРОЖЕКТОРНАЯ';

  @override
  String get bossGargoyleCardBig => 'ГОРГУЛЬЯ';

  @override
  String get bossGargoyleCardOrder => 'small-big';

  @override
  String get bossDodgeFlyLow => 'ЛЕТИ НИЖЕ';

  @override
  String get bossDodgeFlyHigh => 'ЛЕТИ ВЫШЕ';

  @override
  String get bossDodgeClimbOrDive => 'ВВЕРХ ИЛИ ВНИЗ';

  @override
  String get bossDodgeSlipBetween => 'ПРОСКОЛЬЗНИ\nМЕЖДУ ЛУЧАМИ';

  @override
  String get bossSpotted => 'ЗАСЕКЛИ!';

  @override
  String get bossShieldLost => 'ЩИТ ПОТЕРЯН';

  @override
  String get bossHeartLost => '-1 СЕРДЕЧКО';

  @override
  String get bossGargoyleLampOpen => 'ЛАМПА ВИДНА';

  @override
  String get bossGargoyleShoot => 'СТРЕЛЯЙ!';

  @override
  String get bossScreechFlyToGap => 'ЛЕТИ В ПРОСВЕТ';

  @override
  String get bossScreechHoldGap => 'ДЕРЖИСЬ ПРОСВЕТА';

  @override
  String get bossPirateHighTide => 'ВЫСОКИЙ ПРИЛИВ';

  @override
  String get bossBarDefeated => 'ПОБЕДА';

  @override
  String get bossBarIncoming => 'ПРИБЛИЖАЕТСЯ';

  @override
  String get bossBarFury => 'ЯРОСТЬ';

  @override
  String get bossBarHeartDouble => 'СЕРДЦЕ ×2';

  @override
  String get bossStronger => 'СИЛЬНЕЕ!';

  @override
  String get bossKingCooPuffed => 'НАДУЛСЯ';

  @override
  String get bossKingCooShout => 'КУРЛЫК!';

  @override
  String get bossKingCooPop => 'ХЛОП!';

  @override
  String get bossKingCooPoof => 'ПУФ!';

  @override
  String get bossSquadOpenLane => 'ЛЕТИ, ГДЕ ПУСТО';

  @override
  String get bossSquadUseGap => 'ЛЕТИ В ПРОСВЕТ';

  @override
  String get bossSquadThenV => 'ПОТОМ: V';

  @override
  String get bossSquadThenGap => 'ПОТОМ: ЩЕЛЬ';

  @override
  String get bossSquadCancelled => 'ОТБОЙ ЭСКАДРИЛЬЕ';

  @override
  String get bossNeferhooFound => 'ПОТЕРЯННОЕ ПИСЬМО НАЙДЕНО';

  @override
  String get bossNeferhooHoo => 'УУП';

  @override
  String get bossNeferhooPoo => 'УП';

  @override
  String get bossNeferhooMailCall => 'ВАМ ПОЧТА!';

  @override
  String get bossNeferhooExpressPost => 'ЭКСПРЕСС-ПОЧТА';

  @override
  String get bossNeferhooShootBack => 'Отбей их выстрелами!';

  @override
  String get bossNeferhooAnkh => 'АНХ';

  @override
  String get bossNeferhooTwoAnkhs => 'ДВА АНХА';

  @override
  String get bossNeferhooComesBack => 'Он возвращается!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'ПОЖАР!',
      'skyfall': 'НЕБОПАД!',
      'eruption': 'ИЗВЕРЖЕНИЕ!',
      'other': 'СТАЯ!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Хватай золотые кольца и удирай от огня!',
      'skyfall': 'Хватай золотые кольца и обгоняй метеоры!',
      'eruption': 'Хватай золотые кольца и обгоняй взрывы!',
      'other': 'Хватай золотые кольца и прорывайся!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return 'УДРАЛИ! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'ЧИСТАЯ РАБОТА! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Пожар остался позади',
      'skyfall': 'Небопад остался позади',
      'eruption': 'Извержение осталось позади',
      'other': 'Стая осталась позади',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => 'ШКВАЛ!';

  @override
  String encounterGaleDetail(String mark) {
    return 'Уворачивайся от хлама там, где мигает $mark!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'ВЫСТОЯЛИ! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail => 'Шквал остался позади';

  @override
  String get encounterAllRings => 'ВСЕ КОЛЬЦА!';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'Турбо-рывок +$seconds с';
  }

  @override
  String get encounterFinish => 'ФИНИШ';

  @override
  String get builderMode_pushUp => 'Отжимания';

  @override
  String get builderMode_squat => 'Приседания';

  @override
  String get builderMode_jump => 'Прыжки';

  @override
  String builderSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes мин $seconds с';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count отжимания',
      many: '$count отжиманий',
      few: '$count отжимания',
      one: '$count отжимание',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count приседания',
      many: '$count приседаний',
      few: '$count приседания',
      one: '$count приседание',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'Мой полёт';

  @override
  String get builderNewLevel_pushUp => 'Мои отжимания';

  @override
  String get builderNewLevel_squat => 'Мои приседания';

  @override
  String get builderNewLevel_jump => 'Мои прыжки';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'Мой уровень';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Пролети мой уровень Beakbound «$name» ($mode): $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$earned из $total звёзд';
  }

  @override
  String get builderBackSemantics => 'Назад';

  @override
  String get builderKeepIt => 'Оставить';

  @override
  String builderLessSemantics(String name) {
    return 'Меньше: $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'Больше: $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name: $value';
  }

  @override
  String get builderDuplicateSemantics => 'Дублировать';

  @override
  String get builderCopy => 'Копия';

  @override
  String get builderDeleteSemantics => 'Удалить';

  @override
  String get builderDelete => 'Удалить';

  @override
  String get builderMoreBelow => 'Ниже ещё';

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
  String get builderLane => 'Полоса';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'верх или низ приседания',
      'other': 'верх или низ отжимания',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'Верх';

  @override
  String get builderLaneBottom => 'Низ';

  @override
  String get builderHeight => 'Высота';

  @override
  String get builderHeightHint => 'от высоты неба';

  @override
  String get builderLowerSemantics => 'Ниже';

  @override
  String get builderHigherSemantics => 'Выше';

  @override
  String get builderOpening => 'Проход';

  @override
  String builderOpeningHint(int percent) {
    return 'не меньше $percent%';
  }

  @override
  String get builderNarrowerSemantics => 'Уже';

  @override
  String get builderWiderSemantics => 'Шире';

  @override
  String get builderMotion => 'Движение';

  @override
  String get builderMotionGardenHint => 'садовые калитки стоят на месте';

  @override
  String get builderMotionStill => 'Стоит';

  @override
  String get builderMotionGentle => 'Плавно';

  @override
  String get builderMotionLively => 'Бодро';

  @override
  String get builderMotionGardenToast =>
      'Садовые калитки стоят на месте: выбери другой вид ворот, чтобы они двигались.';

  @override
  String get builderSway => 'Качание';

  @override
  String builderSwayHint(String seconds) {
    return 'одно качание: $seconds';
  }

  @override
  String get builderSwayFast => 'Быстро';

  @override
  String get builderSwayMedium => 'Средне';

  @override
  String get builderSwaySlow => 'Медленно';

  @override
  String get builderPhase => 'Когда подлетаешь';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position из $count';
  }

  @override
  String get builderPhaseHint => 'в какой точке качания';

  @override
  String get builderPhaseEarlierSemantics => 'Раньше в качании';

  @override
  String get builderPhaseLaterSemantics => 'Позже в качании';

  @override
  String get builderLook => 'Облик';

  @override
  String builderLookSemantics(int number) {
    return 'Облик $number';
  }

  @override
  String get builderDoor => 'Каменная дверь';

  @override
  String get builderDoorHint => 'открой выстрелом';

  @override
  String get builderDoorNone => 'Без двери';

  @override
  String get builderDoorNeedsShootToast =>
      'Включи «Выстрел» в настройках уровня, чтобы ставить двери.';

  @override
  String get builderPlace => 'Место';

  @override
  String get builderPlaceHint => 'от старта';

  @override
  String get builderEarlierSemantics => 'Раньше';

  @override
  String get builderLaterSemantics => 'Позже';

  @override
  String builderFamilySemantics(String family) {
    return 'Вид ворот: $family. Изменить';
  }

  @override
  String get builderChangeFamily => 'Сменить вид';

  @override
  String get builderItemStar => 'Звезда';

  @override
  String get builderItemTrio => 'Звёздное трио';

  @override
  String get builderItemHeart => 'Сердечко';

  @override
  String get builderItemEnemy => 'Враг';

  @override
  String get builderItemGate => 'Ворота';

  @override
  String get builderItemStarDetail => 'Одна звезда для сбора';

  @override
  String get builderItemTrioDetail => 'Все три дают бонус';

  @override
  String get builderItemHeartDetail => 'Возвращает одно сердечко';

  @override
  String get builderEnemyKind => 'Тип';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Птица летает по верху и низу каждого приседания: ставь звёзды и сердечки на жёлтые линии или между ними.',
      'other':
          'Птица летает по верху и низу каждого отжимания: ставь звёзды и сердечки на жёлтые линии или между ними.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'Летучая мышь';

  @override
  String get builderEnemy_caveBat => 'Пещерная летучая мышь';

  @override
  String get builderEnemy_spitterBeetle => 'Жук-плевун';

  @override
  String get builderEnemy_duskMoth => 'Сумеречный мотылёк';

  @override
  String get builderEnemy_alleyPigeon => 'Дворовый голубь';

  @override
  String get builderEnemy_mummyBat => 'Летучая мышь-мумия';

  @override
  String get builderSummaryTitle => 'Этот уровень';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'Длина';

  @override
  String get builderFactStars => 'Звёзды';

  @override
  String get builderFactMarks => 'Отметки';

  @override
  String get builderFactWorkout => 'Зарядка';

  @override
  String get builderFactPace => 'Темп';

  @override
  String get builderFactBoss => 'Босс';

  @override
  String get builderPace_relaxed => 'Спокойный';

  @override
  String get builderPace_steady => 'Ровный';

  @override
  String get builderPace_brisk => 'Бодрый';

  @override
  String get builderSummaryStarterNote =>
      'Стартовый уровень: лети как есть или сделай из него свой ремикс.';

  @override
  String get builderSummaryClearedNote => 'Пройден тобой — до самого финиша.';

  @override
  String get builderSummaryClearNote =>
      'Испытай уровень до самого финиша, чтобы он считался пройденным.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'baronBat':
          'Испытай уровень: победи Барона Нетопыря и пересеки финиш, чтобы он считался пройденным.',
      'spitterBeetle':
          'Испытай уровень: победи Короля Плевунов и пересеки финиш, чтобы он считался пройденным.',
      'duskMoth':
          'Испытай уровень: победи Сумеречную Императрицу и пересеки финиш, чтобы он считался пройденным.',
      'pirate':
          'Испытай уровень: победи Пиратского Капитана и пересеки финиш, чтобы он считался пройденным.',
      'dragon':
          'Испытай уровень: победи Тлеющего Дракона и пересеки финиш, чтобы он считался пройденным.',
      'kingCoo':
          'Испытай уровень: победи Короля Курлыка и пересеки финиш, чтобы он считался пройденным.',
      'searchlightGargoyle':
          'Испытай уровень: победи Прожекторную Горгулью и пересеки финиш, чтобы он считался пройденным.',
      'other':
          'Испытай уровень: победи $boss и пересеки финиш, чтобы он считался пройденным.',
    });
    return '$_temp0';
  }

  @override
  String get builderSummaryHowTo =>
      'Выбери инструмент слева и жми на небо. Нажми на предмет, чтобы изменить его; тяни, чтобы передвинуть.';

  @override
  String get builderFamily_garden_detail =>
      'Стоит на месте. Может держать каменную дверь.';

  @override
  String get builderFamily_windLift_detail =>
      'Проход поднимается и опускается.';

  @override
  String get builderFamily_petalGate_detail => 'Проход сужается и расширяется.';

  @override
  String get builderFamily_switchback_detail =>
      'Два прохода разъезжаются в стороны.';

  @override
  String get builderFamily_lanternDrift_detail =>
      'Висячие фонарики покачиваются.';

  @override
  String get builderFamily_sunWheels_detail => 'Колёса сходятся и расходятся.';

  @override
  String get builderFamily_crystalSteps_detail => 'Три ступени волной.';

  @override
  String get builderFamiliesCloseSemantics => 'Закрыть виды ворот';

  @override
  String get builderFamiliesTitle => 'Вид ворот';

  @override
  String get builderFamiliesSubtitle => 'Как ворота выглядят и двигаются.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Дай уровню название до $count буквы.',
      many: 'Дай уровню название до $count букв.',
      few: 'Дай уровню название до $count букв.',
      one: 'Дай уровню название до $count буквы.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort =>
      'Отодвинь финиш дальше: уровень слишком короткий.';

  @override
  String get reach_tooLong => 'Придвинь финиш ближе: уровень слишком длинный.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Слишком много всего: в уровне помещается не больше $count.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap =>
      'Босс бывает только в конце уровней «Жми и лети».';

  @override
  String get reach_noGates => 'Добавь ворота, сквозь которые полетит птица.';

  @override
  String get reach_startZone =>
      'Слишком близко к старту: передвинь за стартовую зону.';

  @override
  String get reach_finishRoom => 'Оставь место перед финишем после этих ворот.';

  @override
  String get reach_overlap => 'Двое ворот наложились: раздвинь их.';

  @override
  String get reach_gateHeight => 'Эти ворота слишком высоко или слишком низко.';

  @override
  String get reach_gateMotion => 'Эти ворота не могут так двигаться.';

  @override
  String get reach_gateLook => 'У этих ворот неизвестный облик.';

  @override
  String get reach_gateNarrow => 'Открой эти ворота шире: птица не пролезет.';

  @override
  String get reach_gateWide => 'Эти ворота открыты слишком широко.';

  @override
  String get reach_doorNeedsShoot =>
      'Каменной двери нужен режим «Жми и лети» с включённым «Выстрелом».';

  @override
  String get reach_doorNeedsGarden =>
      'Каменную дверь можно поставить только в садовую калитку.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Резкая смена: при ровном темпе приседаний можно не успеть.',
      'other': 'Резкая смена: при ровном темпе отжиманий можно не успеть.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'Крутой подъём: оставь больше места для прыжков к этим воротам.';

  @override
  String get reach_enemyNeedsTap =>
      'Враги летают только в уровнях «Жми и лети».';

  @override
  String get reach_outsideSky => 'Держи это в пределах неба.';

  @override
  String get reach_pastFinish => 'Поставь это перед финишем.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Приседанием не достать: придвинь ближе к полосам.',
      'other': 'Отжиманием не достать: придвинь ближе к полосам.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'Внутри стены: передвинь в проход.';

  @override
  String get reach_noStars => 'Поставь хотя бы одну звезду.';

  @override
  String get reach_marks =>
      'Звёздные отметки требуют больше звёзд, чем есть в уровне.';

  @override
  String reach_cannotFly(String problem) {
    return 'Этот уровень пока нельзя пролететь ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'Уровень не сохранился, поэтому лететь пока нельзя. Нажми на название, чтобы повторить.';

  @override
  String get builderShareBlockedToast =>
      'Сначала исправь красные флажки: потом уровнем можно будет поделиться.';

  @override
  String get builderEditorBackSemantics => 'Назад в конструктор';

  @override
  String get builderSettingsSemantics => 'Настройки уровня';

  @override
  String get builderFly => 'ЛЕТИМ';

  @override
  String get builderTestFly => 'ИСПЫТАТЬ';

  @override
  String get builderFlySemantics => 'Пролететь этот уровень';

  @override
  String get builderTestFlySemantics => 'Испытать весь уровень';

  @override
  String get builderUndoSemantics => 'Отменить';

  @override
  String get builderRedoSemantics => 'Повторить';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice совета',
      many: '$advice советов',
      few: '$advice совета',
      one: '$advice совет',
    );
    return 'Исправить: $blocking, $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice совета',
      many: '$advice советов',
      few: '$advice совета',
      one: '$advice совет',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => 'Можно лететь';

  @override
  String get builderShareSemantics => 'Код уровня';

  @override
  String get builderFromHereSemantics => 'Испытать отсюда';

  @override
  String get builderFromHere => 'Отсюда';

  @override
  String get builderStatusStarter => 'Стартовый уровень · лети или ремикс';

  @override
  String get builderStatusSaveFailed => 'Не сохранилось · нажми ещё раз';

  @override
  String get builderStatusSaving => 'Сохранение…';

  @override
  String get builderStatusSaved => 'Все изменения сохранены';

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
    return '$name. $mode. $status. Нажми, чтобы переименовать.';
  }

  @override
  String get builderStarterBanner => 'Сделай ремикс — и он твой';

  @override
  String get builderRemix => 'Ремикс';

  @override
  String get builderRemixSemantics => 'Ремикс';

  @override
  String get builderIssuesCloseSemantics => 'Закрыть проблемы и советы';

  @override
  String get builderIssuesReadyTitle => 'Можно лететь!';

  @override
  String get builderIssuesFixTitle => 'Исправь перед полётом';

  @override
  String get builderIssuesTipsTitle => 'Готово, но есть советы';

  @override
  String get builderIssuesReadyDetail =>
      'Всё в порядке. Долети на испытании до финиша — и уровень пройден.';

  @override
  String get builderIssuesDetail =>
      'Нажми на пункт, чтобы перейти к его месту на маршруте.';

  @override
  String get builderSettingsCloseSemantics => 'Закрыть настройки';

  @override
  String get builderSettingsTitle => 'Настройки уровня';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · изменения сохраняются сразу';
  }

  @override
  String get builderSettingsName => 'Название';

  @override
  String get builderRename => 'Сменить';

  @override
  String get builderRenameSemantics => 'Переименовать';

  @override
  String get builderSettingsRegion => 'Регион';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count места · листай дальше',
      many: '$count мест · листай дальше',
      few: '$count места · листай дальше',
      one: '$count место · листай дальше',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'Темп';

  @override
  String get builderSettingsPaceHint => 'как быстро движется небо';

  @override
  String get builderSettingsMarks => 'Отметки звёзд';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Поставлено $count звезды',
      many: 'Поставлено $count звёзд',
      few: 'Поставлено $count звезды',
      one: 'Поставлена $count звезда',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'отметка двух звёзд';

  @override
  String get builderMarkThreeSemantics => 'отметка трёх звёзд';

  @override
  String get builderMarksAuto => 'Авто: по числу звёзд';

  @override
  String get builderMarksByHand => 'Вручную';

  @override
  String get builderSettingsControls => 'Управление';

  @override
  String get builderShootOn => 'Выстрел вкл.';

  @override
  String get builderShootOff => 'Выстрел выкл.';

  @override
  String get builderSprintOn => 'Рывок вкл.';

  @override
  String get builderSprintOff => 'Рывок выкл.';

  @override
  String get builderSettingsBoss => 'Финал с боссом';

  @override
  String get builderSettingsBossHint => 'ждёт в конце';

  @override
  String get builderNoBossSemantics => 'Без босса: только финиш';

  @override
  String get builderNoBoss => 'Без босса';

  @override
  String get builderBossShort_baronBat => 'Барон';

  @override
  String get builderBossShort_spitterBeetle => 'Король';

  @override
  String get builderBossShort_duskMoth => 'Сумеречная';

  @override
  String get builderBossShort_pirate => 'Капитан';

  @override
  String get builderBossShort_dragon => 'Дракон';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Птица летает по двум полосам: верх и низ каждого приседания. Кто приседает медленнее, проходит тот же уровень на спокойной скорости. Без стрельбы, рывков и боссов.',
      'other':
          'Птица летает по двум полосам: верх и низ каждого отжимания. Кто отжимается медленнее, проходит тот же уровень на спокойной скорости. Без стрельбы, рывков и боссов.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'Каждый прыжок поднимает птицу, а между прыжками она парит. Без стрельбы, рывков и боссов.';

  @override
  String get builderStartZoneToast =>
      'Стартовая зона должна быть свободной: ставь всё правее пунктирной линии.';

  @override
  String get builderSkySemantics =>
      'Небо уровня. Жми, чтобы поставить; тяни, чтобы передвинуть или прокрутить.';

  @override
  String get builderSkyReadOnlySemantics =>
      'Небо уровня. Нажми на предмет, чтобы рассмотреть его.';

  @override
  String get builderCoachTitle => 'Построй свой уровень';

  @override
  String get builderCoachPickTool => 'Выбери инструмент слева';

  @override
  String get builderCoachTapSky => 'Нажми на небо, чтобы поставить';

  @override
  String get builderCoachTestFly => 'Испытай его!';

  @override
  String get builderCoachDrag =>
      'Тяни предмет, чтобы передвинуть · тяни небо для прокрутки';

  @override
  String get builderTipDrag =>
      'Тяни, чтобы передвинуть · тяни небо для прокрутки';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'ВЕРХ ПРИСЕДАНИЯ',
      'other': 'ВЕРХ ОТЖИМАНИЯ',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'ВЕРХ';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'НИЗ ПРИСЕДАНИЯ',
      'other': 'НИЗ ОТЖИМАНИЯ',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'НИЗ';

  @override
  String get builderCanvasStartZoneFull => 'СТАРТОВАЯ ЗОНА · НЕ ЗАНИМАТЬ';

  @override
  String get builderCanvasStartZone => 'СТАРТОВАЯ ЗОНА';

  @override
  String get builderCanvasFinishHere => 'ФИНИШ ЗДЕСЬ';

  @override
  String get builderTool_select => 'Выбор';

  @override
  String get builderToolHint_select =>
      'Выбор: нажми на предмет, чтобы изменить; тяни, чтобы передвинуть';

  @override
  String get builderTool_gate => 'Ворота';

  @override
  String get builderToolHint_gate =>
      'Ворота: нажми на небо, чтобы поставить ворота';

  @override
  String get builderTool_star => 'Звезда';

  @override
  String get builderToolHint_star =>
      'Звезда: нажми на небо, чтобы поставить звезду';

  @override
  String get builderTool_trio => 'Трио';

  @override
  String get builderToolHint_trio =>
      'Звёздное трио: нажми на небо, чтобы поставить три звезды';

  @override
  String get builderTool_heart => 'Сердечко';

  @override
  String get builderToolHint_heart =>
      'Сердечко: нажми на небо, чтобы поставить сердечко';

  @override
  String get builderTool_enemy => 'Враг';

  @override
  String get builderToolHint_enemy =>
      'Враг: нажми на небо, чтобы поставить врага';

  @override
  String get builderTool_finish => 'Финиш';

  @override
  String get builderToolHint_finish =>
      'Финиш: нажми на небо, чтобы передвинуть финиш';

  @override
  String get builderTool_boss => 'Босс';

  @override
  String get builderToolHint_boss =>
      'Метка босса: нажми на небо, чтобы передвинуть место босса';

  @override
  String get builderStarterToolsToast =>
      'Стартовые уровни не меняются: сделай ремикс, чтобы что-то изменить.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Обзор маршрута. $length до босса. Тяни, чтобы двигаться по маршруту.',
      'other':
          'Обзор маршрута. $length до финиша. Тяни, чтобы двигаться по маршруту.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Обзор маршрута. $length до босса. $reps. Тяни, чтобы двигаться по маршруту.',
      'other':
          'Обзор маршрута. $length до финиша. $reps. Тяни, чтобы двигаться по маршруту.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '$length до босса';
  }

  @override
  String get builtResultTestFlight => 'ПРОБНЫЙ ПОЛЁТ';

  @override
  String get builtResultCleared => 'Пройдено!';

  @override
  String get builtResultBonk => 'Бамс!';

  @override
  String get builtResultLanded => 'Приземление';

  @override
  String get builtResultTestTab => 'ТЕСТ';

  @override
  String get builtResultGoalFinish => 'Финиш';

  @override
  String get builtResultGoalBoss => 'Босс';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. Готово.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Собери $count звезды.',
      many: 'Собери $count звёзд.',
      few: 'Собери $count звезды.',
      one: 'Собери $count звезду.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Собери $count звезды. Готово.',
      many: 'Собери $count звёзд. Готово.',
      few: 'Собери $count звезды. Готово.',
      one: 'Собери $count звезду. Готово.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'Готово';

  @override
  String get builtResultNotYet => 'Пока нет';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'Нужен финиш';

  @override
  String get builtResultClearedByYou => 'ПРОЙДЕН ТОБОЙ';

  @override
  String get builtResultNewBest => 'НОВЫЙ РЕКОРД!';

  @override
  String get builtResultPractice => 'Тренировка';

  @override
  String builtResultBest(int count) {
    return 'Рекорд $count';
  }

  @override
  String get builtResultFirstClear => 'Первый финиш!';

  @override
  String get builtResultStarsCollected => 'СОБРАНО ЗВЁЗД';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count из 3 звёзд уровня',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'НУЖНО';

  @override
  String get builtResultWorkout => 'ЗАРЯДКА';

  @override
  String get builtResultGotTo => 'ДОЛЕТЕЛИ ДО';

  @override
  String get builtResultScore => 'ОЧКИ';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'отжимания',
      many: 'отжиманий',
      few: 'отжимания',
      one: 'отжимание',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'приседания',
      many: 'приседаний',
      few: 'приседания',
      one: 'приседание',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'прыжка',
      many: 'прыжков',
      few: 'прыжка',
      one: 'прыжок',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'отжимания на камеру',
      many: 'отжиманий на камеру',
      few: 'отжимания на камеру',
      one: 'отжимание на камеру',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'приседания на камеру',
      many: 'приседаний на камеру',
      few: 'приседания на камеру',
      one: 'приседание на камеру',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'из $length';
  }

  @override
  String get builtResultNotKept => 'Не в зачёт';

  @override
  String get builtResultNoBest => 'Рекорда нет';

  @override
  String get builtResultClearedStrip => 'Пройден тобой · можно делиться!';

  @override
  String builtResultFlownFrom(String from) {
    return 'Полёт с отметки $from. Пролети целиком, чтобы пройти.';
  }

  @override
  String get builtResultTestNothingSaved =>
      'Пробный полёт · ничего не сохраняется';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'Пробный полёт · $reached из $length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return 'Пройдено $reached из $length. Звёзды — за финиш.';
  }

  @override
  String get builtResultReachFinish => 'Долети до финиша — получишь звёзды.';

  @override
  String get builtResultSaved => 'Сохранено на этом телефоне';

  @override
  String get builtResultSaving => 'Сохраняем полёт…';

  @override
  String get builtResultBuilder => 'Конструктор';

  @override
  String get builtResultEditLevel => 'Изменить уровень';

  @override
  String get builtResultEdit => 'Изменить';

  @override
  String get builtResultFlyAgain => 'Лететь снова';

  @override
  String get builtResultWatchReplay => 'Смотреть повтор';

  @override
  String get builtResultPreparing => 'Готовим…';

  @override
  String get builtResultSessionSaving => 'Сохранение…';

  @override
  String get builtResultSaveSession => 'Сохранить полёт';

  @override
  String get builderShelfTitle => 'Конструктор уровней';

  @override
  String get builderShelfPasteCode => 'Вставить код';

  @override
  String get builderShelfNewLevel => 'Новый уровень';

  @override
  String get builderShelfSaveFailed => 'Не сохранилось. Попробуй ещё раз.';

  @override
  String builderShelfDeleteTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get builderShelfDeleteBody =>
      'Его рекорды удалятся вместе с ним. Отжимания, приседания и прыжки, сделанные в нём, останутся в зачёте.';

  @override
  String get builderShelfDelete => 'Удалить';

  @override
  String builderShelfDeleted(String name) {
    return 'Уровень «$name» удалён.';
  }

  @override
  String get builderShelfFixFirst =>
      'Прежде чем делиться, исправь отмеченное красным: нажми «Исправить».';

  @override
  String get builderShelfCodeCopied => 'Код скопирован! Отправь его другу.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'Код скопирован! Пролети уровень до финиша, чтобы друзья знали: он проходим.';

  @override
  String get builderShelfNotReady =>
      'Этот уровень пока не готов к полёту: нажми «Исправить».';

  @override
  String get builderShelfPasteMissingTitle => 'Нет кода уровня для вставки';

  @override
  String get builderShelfPasteNewerTitle => 'Уровень из новой версии Beakbound';

  @override
  String get builderShelfPasteDamagedTitle => 'Этот код перепутался';

  @override
  String get builderShelfPasteMissingBody =>
      'Скопируй код уровня друга (он начинается с BEAK1.) и снова нажми «Вставить код».';

  @override
  String get builderShelfPasteNewerBody =>
      'Обнови Beakbound, чтобы пролететь его, и снова вставь код.';

  @override
  String get builderShelfPasteDamagedBody =>
      'Часть кода пропала или набрана с ошибкой. Попроси друга скопировать весь код ещё раз.';

  @override
  String builderShelfImported(String name) {
    return '«$name» теперь на твоей полке!';
  }

  @override
  String get builderShelfUnavailable => 'Твоим уровням нужна минутка.';

  @override
  String get builderShelfMine => 'Мои уровни';

  @override
  String get builderShelfStarters => 'Стартовые уровни';

  @override
  String get builderShelfStartersHint =>
      'Пролети любой или сделай из него ремикс — свой уровень';

  @override
  String get builderShelfEmptyTitle => 'Построй свой первый уровень';

  @override
  String get builderShelfEmptyBody =>
      'Расставь ворота, звёзды и сердечки, поставь финиш и испытай уровень.';

  @override
  String get builderShelfPasteFriend => 'Вставить код друга';

  @override
  String get builderShelfNeedsWork => 'Нужно доделать';

  @override
  String get builderShelfClearedByYou => 'Пройден тобой';

  @override
  String get builderShelfFromFriend => 'От друга';

  @override
  String get builderShelfFly => 'Летим';

  @override
  String builderShelfFlySemantics(String name) {
    return 'Лететь: $name';
  }

  @override
  String get builderShelfFixIt => 'Исправить';

  @override
  String builderShelfFixSemantics(String name) {
    return 'Исправить: $name';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return 'Изменить: $name';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return 'Поделиться: $name';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return 'Поделиться: $name. Пройден тобой';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'Ещё: $name';
  }

  @override
  String get builderShelfRemix => 'Ремикс';

  @override
  String builderShelfRemixSemantics(String name) {
    return 'Ремикс: $name';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недочёта — исправь в редакторе',
      many: '$count недочётов — исправь в редакторе',
      few: '$count недочёта — исправь в редакторе',
      one: '$count недочёт — исправь в редакторе',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды',
      many: '$count звёзд',
      few: '$count звезды',
      one: '$count звезда',
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
      other: 'Рекорд: $stars из 3 звёзд.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Нужно доделать: $count недочёта.',
      many: 'Нужно доделать: $count недочётов.',
      few: 'Нужно доделать: $count недочёта.',
      one: 'Нужно доделать: $count недочёт.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'Пройден тобой.';

  @override
  String get builderShelfFromFriendSemantics => 'От друга.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return 'Посмотреть «$name». $mode, $length, $fact.';
  }

  @override
  String get builderShelfRemixSuffix => 'ремикс';

  @override
  String get builderShelfCopySuffix => 'копия';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get starter_t_tap_1_name => 'Прыжки по саду';

  @override
  String get starter_t_push_1_name => 'Десять отжиманий';

  @override
  String get starter_t_squat_1_name => 'Лесенка-присядка';

  @override
  String get starter_t_jump_1_name => 'Бухта прыг-скок';

  @override
  String get starter_t_tap_boss_name => 'Мост Барона';

  @override
  String get builderPickCloseNewLevel => 'Закрыть новый уровень';

  @override
  String get builderPickModeTitle => 'Каким он будет?';

  @override
  String get builderPickRegionTitle => 'Где будем летать?';

  @override
  String get builderPickModeSubtitle =>
      'Выбери, как в нём летать (потом не поменять). Испытывать любой уровень можно касаниями.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · выбери, где летать. Это можно изменить позже.';
  }

  @override
  String get builderPickTouchLine =>
      'Жми, чтобы взмахнуть. Ворота, звёзды, враги и босс.';

  @override
  String get builderPickPushUpLine =>
      'Верхняя полоса и нижняя: каждый нырок вниз — отжимание.';

  @override
  String get builderPickSquatLine =>
      'Верхняя полоса и нижняя: каждый нырок вниз — приседание.';

  @override
  String get builderPickJumpLine =>
      'Прыгай, чтобы взлететь. Ворота — где угодно в небе.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'Камера';

  @override
  String get builderPickSuggested => 'Советуем';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, советуем';
  }

  @override
  String get builderPickClose => 'Закрыть';

  @override
  String get builderPickNotYet =>
      'Пока нельзя: сначала исправь отмеченное красным.';

  @override
  String get builderPickShare => 'Код уровня';

  @override
  String get builderPickShareLine =>
      'Скопируй код, который друг вставит в свой Beakbound.';

  @override
  String get builderPickDuplicate => 'Дублировать';

  @override
  String get builderPickDuplicateLine =>
      'Сделай копию, чтобы попробовать другую идею.';

  @override
  String get builderPickDeleteLine => 'Выбросить уровень. Сначала мы спросим.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'Отменить импорт';

  @override
  String get builderPickImportTitle => 'Уровень для полёта!';

  @override
  String get builderPickImportSubtitle =>
      'Кто-то поделился с тобой этим уровнем.';

  @override
  String get builderPickClearedByMaker => 'Пройден автором';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды для сбора',
      many: '$count звёзд для сбора',
      few: '$count звезды для сбора',
      one: '$count звезда для сбора',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    return 'В конце — $boss';
  }

  @override
  String get builderPickNotFlown => 'Автор ещё не проходил его до конца.';

  @override
  String get builderPickRoute => 'Маршрут';

  @override
  String builderPickAlreadyHave(String name) {
    return 'У тебя уже есть этот уровень: «$name».';
  }

  @override
  String get builderPickImportCopy => 'Добавить копию';

  @override
  String get builderPickOpenYours => 'Открыть свой';

  @override
  String get builderPickImport => 'Добавить к себе';

  @override
  String get builderShelfRenameCancelSemantics => 'Не переименовывать';

  @override
  String get builderShelfRenameTitle => 'Назови свой уровень';

  @override
  String get builderShelfRenameEmpty => 'В названии нужна хотя бы буква';

  @override
  String get builderShelfRenameSaveSemantics => 'Сохранить имя';

  @override
  String get builderShelfRenameSave => 'Сохранить';

  @override
  String get coopMode_roped => 'На верёвке';

  @override
  String get coopMode_free => 'Без верёвки';

  @override
  String get coopMode_duel => '1 на 1';

  @override
  String get coopTitle => 'Летим вместе';

  @override
  String get coopPlayersTag => 'ДВА ИГРОКА · ОДИН ТЕЛЕФОН';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode: РЕКОРД $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: РЕКОРДА НЕТ';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count ДУЭЛИ',
      many: '$mode · $count ДУЭЛЕЙ',
      few: '$mode · $count ДУЭЛИ',
      one: '$mode · $count ДУЭЛЬ',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode: ПЕРВАЯ ДУЭЛЬ';
  }

  @override
  String get coopRopedLead => 'Ваши птицы связаны одной верёвкой.';

  @override
  String get coopRopedBody =>
      'Машите вместе, чтобы подняться высоко: одна птица тянет обеих, но совсем чуть-чуть. Рывок тащит напарника за собой.';

  @override
  String get coopFreeLead => 'Без верёвки:';

  @override
  String get coopFreeBody =>
      'каждая птица летит сама и только толкается с другой. Сердечки, щит и очки всё равно общие.';

  @override
  String get duelLead => 'В бой!';

  @override
  String get duelBody =>
      'У каждой птицы свои сердечки. Хватайте коробки-сюрпризы: одни шлют на соперника летучих мышей, жука-плевуна или метеоры, другие дают сердечко, щит или звёздную силу. Побеждает птица, которая продержится дольше.';

  @override
  String get coopStart => 'Летим вместе';

  @override
  String get duelStart => 'В бой!';

  @override
  String get coopFlightSemantics =>
      'Игрок 1 жмёт на левую половину для взмаха, игрок 2 — на правую';

  @override
  String get coopPauseSemantics => 'Пауза';

  @override
  String coopShootSemantics(int player) {
    return 'Выстрел игрока $player';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'Рывок игрока $player';
  }

  @override
  String coopPlayerShort(int player) {
    return 'И$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'ИГРОК $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Звёздный магнит: осталось $seconds секунды',
      many: 'Звёздный магнит: осталось $seconds секунд',
      few: 'Звёздный магнит: осталось $seconds секунды',
      one: 'Звёздный магнит: осталась $seconds секунда',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Магнит заряжается: $charge из $gates идеального пролёта',
      many: 'Магнит заряжается: $charge из $gates идеальных пролётов',
      few: 'Магнит заряжается: $charge из $gates идеальных пролётов',
      one: 'Магнит заряжается: $charge из $gates идеального пролёта',
    );
    return '$_temp0';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds с',
    );
    return '$_temp0';
  }

  @override
  String get coopCountdownRoped => 'Верёвка на месте. На старт, внимание…';

  @override
  String get coopCountdownFree => 'На старт, внимание…';

  @override
  String get duelCountdown => 'Готовы к дуэли…';

  @override
  String get coopCountdownRopedHint =>
      'Машите вместе, чтобы подняться.\nРывок тащит напарника за собой!';

  @override
  String get coopCountdownFreeHint =>
      'Каждая птица летит сама.\nСердечки общие — проходите ворота!';

  @override
  String get duelCountdownHint =>
      'Хватайте коробки-сюрпризы!\nПобеждает последняя птица в небе.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Звёздная сила игрока $player: осталось $seconds секунды',
      many: 'Звёздная сила игрока $player: осталось $seconds секунд',
      few: 'Звёздная сила игрока $player: осталось $seconds секунды',
      one: 'Звёздная сила игрока $player: осталась $seconds секунда',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'Домой';

  @override
  String get coopChangeBirds => 'Сменить птиц';

  @override
  String get coopSaved => 'Сохранено';

  @override
  String get coopSaving => 'Сохранение…';

  @override
  String get coopSaveSession => 'Сохранить полёт';

  @override
  String get duelRematch => 'Реванш';

  @override
  String get coopFlyAgain => 'Лететь снова';

  @override
  String duelWinner(int player) {
    return 'Победа игрока $player!';
  }

  @override
  String get duelDraw => 'Ничья!';

  @override
  String get duelStopped => 'Дуэль остановлена';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first — $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner 1:0 $loser';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize летит к И$rival!';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize!';
  }

  @override
  String get duelPrize_batSwarm => 'Стая мышей';

  @override
  String get duelPrize_spitter => 'Жук-плевун';

  @override
  String get duelPrize_meteorShower => 'Дождь метеоров';

  @override
  String get duelPrize_heart => 'Сердечко';

  @override
  String get duelPrize_shield => 'Щит';

  @override
  String get duelPrize_starPower => 'Звёздная сила';

  @override
  String get coopTapLeftHalf => 'Жми на левую половину';

  @override
  String get coopTapRightHalf => 'Жми на правую половину';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'Игрок $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'И$player · жми на эту сторону';
  }

  @override
  String get coopKeysP1 => 'И1 · W взмах · D выстрел · A рывок';

  @override
  String get coopKeysP2 => 'И2 · ↑ взмах · → выстрел · ← рывок';

  @override
  String get coopRopedSemantics => 'На верёвке: птицы связаны одной верёвкой';

  @override
  String get coopFreeSemantics => 'Без верёвки: каждая птица летит сама';

  @override
  String get duelModeSemantics => '1 на 1: птицы сражаются друг с другом';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'Полёт сохранён · Смотри в «Рекордах»';

  @override
  String get coopNewTeamBest => 'Новый рекорд команды!';

  @override
  String get coopWhatATeam => 'Вот это команда!';

  @override
  String coopPairCaption(String first, String second) {
    return '$first и $second';
  }

  @override
  String get coopTeamScore => 'СЧЁТ КОМАНДЫ';

  @override
  String get coopTeamBest => 'РЕКОРД КОМАНДЫ';

  @override
  String get coopNewTeamBestRibbon => 'НОВЫЙ РЕКОРД КОМАНДЫ!';

  @override
  String get coopStatFlightTime => 'время полёта';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'звезды',
      many: 'звёзд',
      few: 'звезды',
      one: 'звезда',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ворот',
      many: 'ворот',
      few: 'ворот',
      one: 'ворота',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'ДОЛЯ ВЗМАХОВ';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'взмаха И$player',
      many: 'взмахов И$player',
      few: 'взмаха И$player',
      one: 'взмах И$player',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'Время дуэли $time';
  }

  @override
  String get duelSeries => 'СЕРИЯ';

  @override
  String get duelHeartsLeft => 'осталось сердечек';

  @override
  String get duelBoxesOpened => 'открыто коробок';

  @override
  String get duelHitsLanded => 'точных попаданий';

  @override
  String get coopPauseSubtitle =>
      'Обе птицы присели отдохнуть и ждут. Перед стартом будет отсчёт.';

  @override
  String get coopFinishFlight => 'Завершить полёт';

  @override
  String get cameraLabIntro =>
      'Поставь телефон пониже горизонтально, лицом к себе или сбоку.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'Почти готово · нужно лучше видеть: $parts';
  }

  @override
  String get cameraLabJointShoulder => 'плечо';

  @override
  String get cameraLabJointElbow => 'локоть';

  @override
  String get cameraLabJointWrist => 'запястье';

  @override
  String get cameraLabJointHip => 'бедро';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => 'Запуск камеры…';

  @override
  String get cameraLabDenied =>
      'Доступ к камере выключен. Разреши его в настройках приложения и попробуй снова.';

  @override
  String cameraLabFailed(String error) {
    return 'Камера не запустилась: $error';
  }

  @override
  String get cameraLabStopped =>
      'Камера остановлена. Нажми «Включить камеру» для калибровки.';

  @override
  String get cameraLabBack => 'ЛАБОРАТОРИЯ КАМЕРЫ · Домой';

  @override
  String get cameraLabStepShow => '1. Покажи руки и бедро';

  @override
  String get cameraLabStepPushUps => '2. Сделай два отжимания';

  @override
  String get cameraLabStepMove => '3. Управляй птицей!';

  @override
  String get cameraLabStepSquat => 'Найди свою амплитуду приседа';

  @override
  String get cameraLabStepJump => 'Найди стартовую позицию';

  @override
  String get cameraLabPushUpHelp =>
      'Телефон пониже, лицом к тебе или сбоку.\nЛицом к нему? Покажи оба плеча, руку и бедро.\nДважды опустись и поднимись в своём темпе.';

  @override
  String get cameraLabSquatHelp =>
      'Постой спокойно, удобно присядь, чуть задержись и встань. Присядь — птица снижается; встань — взлетает.';

  @override
  String get cameraLabJumpHelp =>
      'Встань лицом к телефону, чтобы было видно всё тело и ступни. Замри, потом делай маленькие прыжки. Один прыжок = одно мощное ускорение.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'КАЛИБРОВКА\nготово $done из $total',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'КАЛИБРОВКА\nготово $percent%';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ТЕСТ УПРАВЛЕНИЯ\n$count отжимания',
      many: 'ТЕСТ УПРАВЛЕНИЯ\n$count отжиманий',
      few: 'ТЕСТ УПРАВЛЕНИЯ\n$count отжимания',
      one: 'ТЕСТ УПРАВЛЕНИЯ\n$count отжимание',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ТЕСТ УПРАВЛЕНИЯ\n$count приседания',
      many: 'ТЕСТ УПРАВЛЕНИЯ\n$count приседаний',
      few: 'ТЕСТ УПРАВЛЕНИЯ\n$count приседания',
      one: 'ТЕСТ УПРАВЛЕНИЯ\n$count приседание',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ТЕСТ УПРАВЛЕНИЯ\n$count прыжка',
      many: 'ТЕСТ УПРАВЛЕНИЯ\n$count прыжков',
      few: 'ТЕСТ УПРАВЛЕНИЯ\n$count прыжка',
      one: 'ТЕСТ УПРАВЛЕНИЯ\n$count прыжок',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Гц · $ms мс p95';
  }

  @override
  String get cameraLabStartingButton => 'Запуск…';

  @override
  String get cameraLabRecalibrate => 'Калибровать заново';

  @override
  String get cameraLabStartCamera => 'Включить камеру';

  @override
  String get cameraLabTapStart => 'Нажми «Включить камеру»';

  @override
  String cameraLabTry(String mode) {
    return 'Попробовать: $mode';
  }

  @override
  String get cameraBadgeWaking => 'ПРОСЫПАЕТСЯ';

  @override
  String get cameraBadgeLive => 'В ЭФИРЕ';

  @override
  String get cameraBadgeLockedOn => 'ВИЖУ ТЕБЯ';

  @override
  String get cameraBadgeOffline => 'ОФЛАЙН';

  @override
  String get trackingCatchingUp => 'Камера догоняет';

  @override
  String get trackingStepIntoOutline => 'Встань в контур тела';

  @override
  String get trackingKeepShoulders => 'Держи оба плеча в кадре';

  @override
  String get trackingShowSide => 'Покажи сбоку плечо, локоть, запястье и бедро';

  @override
  String get trackingMoveCloser => 'Подвинься чуть ближе';

  @override
  String get trackingGetDown => 'Прими упор лёжа';

  @override
  String get trackingHandsOnFloor => 'Поставь руки на пол и вытяни тело назад';

  @override
  String get trackingExtendBody => 'Вытяни тело чуть дальше за руки';

  @override
  String get trackingComfortableRange => 'Отжимайся в удобной амплитуде';

  @override
  String get trackingPlaceHands => 'Поставь руки на пол, тело — за ними';

  @override
  String get trackingFrontTracked =>
      'Вид спереди распознан · держи руки в кадре';

  @override
  String get trackingBodyInView => 'Тело в кадре · можно смотреть в пол';

  @override
  String get trackingArmsTracked => 'Руки распознаны · ноги видно не полностью';

  @override
  String get trackingFindTop => 'Найди удобную верхнюю позицию';

  @override
  String get trackingCalibrated => 'Готово! Попробуй управлять птицей.';

  @override
  String get trackingFreshFrame => 'Ждём свежий кадр';

  @override
  String get trackingDistanceChanged =>
      'Расстояние до камеры изменилось · откалибруй заново';

  @override
  String get trackingKeepArm => 'Держи руку в кадре';

  @override
  String get trackingSquatStepBack =>
      'Отойди, чтобы в кадре были плечи, бёдра, колени и ступни';

  @override
  String get trackingSquatFaceCamera =>
      'Встань лицом к камере, обе ноги на полу';

  @override
  String get trackingSquatControls => 'Присядь — вниз · встань — вверх';

  @override
  String get trackingStartingDistance =>
      'Встань лицом к камере на прежнем расстоянии · если позиция сменилась, откалибруй заново';

  @override
  String get trackingFeetPlanted => 'Держи обе ноги на исходном месте';

  @override
  String get trackingSquatStandTall =>
      'Встань прямо и замри, обе ступни в кадре';

  @override
  String get trackingStandStill => 'Встань прямо и замри на мгновение';

  @override
  String get trackingSquatDepth =>
      'Присядь на удобную глубину и чуть задержись';

  @override
  String get trackingSquatHold =>
      'Присядь, как удобно, и задержись на мгновение';

  @override
  String get trackingSquatHoldBriefly => 'Чуть задержись в этом приседе';

  @override
  String get trackingSquatStandUp => 'Встань, чтобы закончить калибровку';

  @override
  String get trackingSquatReady => 'Готово! Присядь — вниз · встань — вверх';

  @override
  String get trackingJumpStepBack =>
      'Отойди, чтобы в кадре были плечи, бёдра и обе ступни';

  @override
  String get trackingJumpFaceCamera =>
      'Встань лицом к камере, чтобы над головой было место для прыжка';

  @override
  String get trackingJumpSmall =>
      'Хватит маленьких прыжков · приземлись перед новым';

  @override
  String get trackingJumpStandStill =>
      'Замри, чтобы всё тело и обе ступни были в кадре';

  @override
  String get trackingJumpReady =>
      'Готово! Один маленький прыжок — одно мощное ускорение.';

  @override
  String get trackingFindPosition => 'Займи позицию';

  @override
  String get trackingInterrupted => 'Трекинг прервался';

  @override
  String get trackingCameraInterrupted =>
      'Камера прервалась. Проверь доступ к камере и попробуй снова.';

  @override
  String get trackingCameraAway =>
      'Камера остановилась, пока игра была свёрнута';

  @override
  String get trackingJumpBoost => 'Прыгни для мощного ускорения';

  @override
  String get trackingJumpLand => 'Приземлись перед следующим прыжком';

  @override
  String trackingLowerMore(int step, int total) {
    return 'Опустись чуть ниже · $step из $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'Опустись, как удобно · $step из $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'Поднимись обратно · $step из $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'Повтори свою первую удобную амплитуду · $step из $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Не удалось сохранить изменение. Попробуй ещё раз. ($error)';
  }

  @override
  String get commonDelete => 'Удалить';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count звезды',
      many: 'Ещё $count звёзд',
      few: 'Ещё $count звезды',
      one: 'Ещё $count звезда',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'Твоему гнезду нужна минутка.';

  @override
  String get homeSettings => 'Настройки';

  @override
  String homeGreetingFirst(String bird) {
    return 'Привет, я $bird! Летим?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Приключение пройдено! $bird горд тобой!',
      'female': 'Приключение пройдено! $bird горда тобой!',
      'other': 'Приключение пройдено! $bird гордится тобой!',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird готов. А ты?',
      'female': '$bird готова. А ты?',
      'other': '$bird на старте. А ты?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'БЕСКОНЕЧНЫЙ';

  @override
  String get homeEndlessDetail => 'Лети как можно дальше';

  @override
  String get homeEndlessSemantics =>
      'Бесконечный полёт. Лети как можно дальше.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other:
          'Бесконечный полёт. Лети как можно дальше. Рекорд: $best звёздного очка.',
      many:
          'Бесконечный полёт. Лети как можно дальше. Рекорд: $best звёздных очков.',
      few:
          'Бесконечный полёт. Лети как можно дальше. Рекорд: $best звёздных очка.',
      one:
          'Бесконечный полёт. Лети как можно дальше. Рекорд: $best звёздное очко.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'Рекорд';

  @override
  String get homeBestNone => 'Поставь первый рекорд';

  @override
  String get homeCampaignTitle => 'КАМПАНИЯ';

  @override
  String get homeCampaignDone => 'Каждое письмо доставлено';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Кампания. Далее: $level. Звёзд: $stars из $total.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Кампания. Каждое письмо доставлено. Звёзд: $stars из $total.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'МИНИ-ИГРЫ';

  @override
  String get homeMiniGamesDetail => 'Зарядка · 2 игрока';

  @override
  String get homeMiniGamesSemantics =>
      'Мини-игры. Отжимания, приседания, прыжки или игра вдвоём.';

  @override
  String get homeBuilderTitle => 'КОНСТРУКТОР';

  @override
  String get homeBuilderDetail => 'Строй · летай · делись';

  @override
  String get homeBuilderSemantics =>
      'Конструктор уровней. Строй свои уровни, летай по ним и делись ими.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count полёта',
      many: 'Ещё $count полётов',
      few: 'Ещё $count полёта',
      one: 'Ещё $count полёт',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Конструктор уровней. Закрыт. Откроется через $count полёта.',
      many: 'Конструктор уровней. Закрыт. Откроется через $count полётов.',
      few: 'Конструктор уровней. Закрыт. Откроется через $count полёта.',
      one: 'Конструктор уровней. Закрыт. Откроется через $count полёт.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'Приключение';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Приключение дня. Выполнено целей: $done из 3.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'Птицы';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'Птицы. Сейчас летит: $bird.';
  }

  @override
  String get homeDockUpgrades => 'Улучшения';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Улучшения. $stars звезды на трату.',
      many: 'Улучшения. $stars звёзд на трату.',
      few: 'Улучшения. $stars звезды на трату.',
      one: 'Улучшения. $stars звезда на трату.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'Паспорт';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Паспорт. Медалей: $earned из $total.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'Рекорды';

  @override
  String get homeMiniGamesPickerTitle => 'Мини-игры';

  @override
  String get homeMiniGamesPickerIntro =>
      'Двигайся, чтобы лететь, или играй на одном телефоне с другом.';

  @override
  String get homeMiniGamesCloseSemantics => 'Закрыть мини-игры';

  @override
  String get homeMiniGamesPushUpCard => 'Опустись — нырок.\nОтожмись — взлёт.';

  @override
  String get homeMiniGamesSquatCard => 'Присядь — вниз.\nВстань — взлёт.';

  @override
  String get homeMiniGamesJumpCard => 'Прыгай — взлёт.\nПари за звёздами.';

  @override
  String get homeMiniGamesCoopCard =>
      'Два игрока, один телефон.\nВместе или дуэль.';

  @override
  String get homeMiniGamesCamera => 'Камера';

  @override
  String get homeMiniGamesPlayers => '2 игрока';

  @override
  String get homeMiniGamesCoop => 'Летим вместе';

  @override
  String get birdsTitle => 'Знакомься: твой лётный экипаж.';

  @override
  String birdsFlownTag(int flown, int total) {
    return 'ЛЕТАЛИ: $flown ИЗ $total';
  }

  @override
  String get birdsStatusCopilot => 'ТВОЙ НАПАРНИК';

  @override
  String get birdsStatusReady => 'МОЖНО ЛЕТЕТЬ';

  @override
  String get birdsStatusLocked => 'ЗАКРЫТО';

  @override
  String get birdsNotFlown => 'Ещё не летали';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count полёта',
      many: '$count полётов',
      few: '$count полёта',
      one: '$count полёт',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return '$bird, летим!';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return 'Выбрать птицу $bird. Сейчас выбрана: $current';
  }

  @override
  String birdsUnlock(String bird) {
    return 'Открыть: $bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Открыть птицу $bird за $price звезды',
      many: 'Открыть птицу $bird за $price звёзд',
      few: 'Открыть птицу $bird за $price звезды',
      one: 'Открыть птицу $bird за $price звезду',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Открыть птицу $bird за $price звезды, звёзд пока не хватает',
      many: 'Открыть птицу $bird за $price звёзд, звёзд пока не хватает',
      few: 'Открыть птицу $bird за $price звезды, звёзд пока не хватает',
      one: 'Открыть птицу $bird за $price звезду, звёзд пока не хватает',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'Летит с тобой';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, летит с тобой';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, летит с тобой, новичок';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, закрыто, $price звезды',
      many: '$bird, закрыто, $price звёзд',
      few: '$bird, закрыто, $price звезды',
      one: '$bird, закрыто, $price звезда',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird, новичок';
  }

  @override
  String get birdsTagFlying => 'ЛЕТИТ';

  @override
  String get birdsTagNew => 'НОВОЕ';

  @override
  String get bird_0_description => 'Птичка мала. Небо велико.';

  @override
  String get bird_0_trail => 'Солнечные пузырьки';

  @override
  String get bird_1_description =>
      'Румяные щёчки, кудрявый хохолок, большое сердце.';

  @override
  String get bird_1_trail => 'Персиковые сердечки';

  @override
  String get bird_2_description =>
      'Крошка-колибри. Свежая мята. Полный вперёд.';

  @override
  String get bird_2_trail => 'Мятные листики';

  @override
  String get bird_3_description =>
      'Мечтательная сова, что летает при свете звёзд.';

  @override
  String get bird_3_trail => 'Звёздная пыльца';

  @override
  String get upgradesWalletLabel => 'ТВОИ\nЗВЁЗДЫ';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars звезды на трату',
      many: '$stars звёзд на трату',
      few: '$stars звезды на трату',
      one: '$stars звезда на трату',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'Прокачай свою птицу.';

  @override
  String get upgradesIntro =>
      'Нажми на шестерёнку, чтобы узнать, что она даёт. Каждая звезда из полёта идёт в копилку.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, уровень $level из $max. Следующий уровень: $cost звезды',
      many: '$power, уровень $level из $max. Следующий уровень: $cost звёзд',
      few: '$power, уровень $level из $max. Следующий уровень: $cost звезды',
      one: '$power, уровень $level из $max. Следующий уровень: $cost звезда',
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
          '$power, уровень $level из $max. Следующий уровень: $cost звезды, пока не хватает',
      many:
          '$power, уровень $level из $max. Следующий уровень: $cost звёзд, пока не хватает',
      few:
          '$power, уровень $level из $max. Следующий уровень: $cost звезды, пока не хватает',
      one:
          '$power, уровень $level из $max. Следующий уровень: $cost звезда, пока не хватает',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, уровень $level из $max. Максимум';
  }

  @override
  String get upgradesMax => 'МАКС';

  @override
  String upgradesLevel(int level) {
    return 'Уровень $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'Уровень $level, высший';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label: $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label: $now, на следующем уровне $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value%';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value с';
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
      other: 'У тебя останется $count звезды.',
      many: 'У тебя останется $count звёзд.',
      few: 'У тебя останется $count звезды.',
      one: 'У тебя останется $count звезда.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'Улучшить';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Улучшить за $cost звезды',
      many: 'Улучшить за $cost звёзд',
      few: 'Улучшить за $cost звезды',
      one: 'Улучшить за $cost звезду',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Улучшить за $cost звезды, звёзд пока не хватает',
      many: 'Улучшить за $cost звёзд, звёзд пока не хватает',
      few: 'Улучшить за $cost звезды, звёзд пока не хватает',
      one: 'Улучшить за $cost звезду, звёзд пока не хватает',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'Максимум';

  @override
  String get power_shot_name => 'Сила броска';

  @override
  String get power_shot_blurb =>
      'Держи «Выстрел», чтобы зарядить камень побольше и потяжелее.';

  @override
  String get power_sprint_name => 'Рывок';

  @override
  String get power_sprint_blurb =>
      'Рывок скорости, который сносит врагов на пути.';

  @override
  String get power_shield_name => 'Щит';

  @override
  String get power_shield_blurb =>
      'Блокирует один удар. Звёзды в полёте восстанавливают его.';

  @override
  String get power_magnet_name => 'Магнит';

  @override
  String get power_magnet_blurb =>
      'Заслужи его идеальными пролётами. Он притягивает к тебе звёзды.';

  @override
  String get power_stat_maxCharge => 'Максимальный заряд';

  @override
  String get power_stat_burstLength => 'Длительность рывка';

  @override
  String get power_stat_cooldown => 'Перезарядка';

  @override
  String get power_stat_starsToRefill => 'Звёзд для восстановления';

  @override
  String get power_stat_safeTime => 'Неуязвимость после удара';

  @override
  String get power_stat_perfectGates => 'Нужно идеальных пролётов';

  @override
  String get power_stat_lasts => 'Длится';

  @override
  String get power_stat_reach => 'Дальность';

  @override
  String get passportTitle => 'Твой небесный паспорт.';

  @override
  String get passportDailyCard => 'Открытка дня';

  @override
  String passportMedalsTag(int earned, int total) {
    return 'МЕДАЛИ: $earned / $total';
  }

  @override
  String get passportIntro =>
      'Маленькие приключения. Долгая память. Бронза, серебро и золото за каждый штамп.';

  @override
  String get passportNoMedal => 'Медали пока нет';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Бронзовая медаль',
      'silver': 'Серебряная медаль',
      'other': 'Золотая медаль',
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
    return '$stamp. $held. Далее — $next: $goal $current из $target.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. Золотая медаль. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'ДО БРОНЗЫ',
      'silver': 'ДО СЕРЕБРА',
      'other': 'ДО ЗОЛОТА',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'ЗАВЕРЕНО';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: пока нет';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'Бронза';

  @override
  String get passportMedal_silver => 'Серебро';

  @override
  String get passportMedal_gold => 'Золото';

  @override
  String get stamp_frequentFlyer_name => 'Частый летун';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Заверши $n зачётного полёта.',
      many: 'Заверши $n зачётных полётов.',
      few: 'Заверши $n зачётных полёта.',
      one: 'Заверши $n зачётный полёт.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'В яблочко';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сделай $n идеального пролёта по прицельным меткам.',
      many: 'Сделай $n идеальных пролётов по прицельным меткам.',
      few: 'Сделай $n идеальных пролёта по прицельным меткам.',
      one: 'Сделай $n идеальный пролёт по прицельным меткам.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'Ловец звёзд';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Собери $n звезды.',
      many: 'Собери $n звёзд.',
      few: 'Собери $n звезды.',
      one: 'Собери $n звезду.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => 'Созвездие';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Собери $n звезды одной непрерывной серией.',
      many: 'Собери $n звёзд одной непрерывной серией.',
      few: 'Собери $n звезды одной непрерывной серией.',
      one: 'Собери $n звезду одной непрерывной серией.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'Капитан неба';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Набери $n очка за один бесконечный полёт.',
      many: 'Набери $n очков за один бесконечный полёт.',
      few: 'Набери $n очка за один бесконечный полёт.',
      one: 'Набери $n очко за один бесконечный полёт.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'Первопроходец';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Продержись не меньше 60 секунд в $n бесконечных полётах.',
      many: 'Продержись не меньше 60 секунд в $n бесконечных полётах.',
      few: 'Продержись не меньше 60 секунд в $n бесконечных полётах.',
      one: 'Продержись не меньше 60 секунд в $n бесконечном полёте.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'Одной стаей';

  @override
  String get stamp_allRounder_name => 'Мастер на все крылья';

  @override
  String get stamp_flockTogether_goalBronze =>
      'Слетай в зачётные полёты с двумя разными птицами.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'Слетай в зачётные полёты со всеми четырьмя птицами.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Соверши $n зачётного полёта с каждой птицей.',
      many: 'Соверши $n зачётных полётов с каждой птицей.',
      few: 'Соверши $n зачётных полёта с каждой птицей.',
      one: 'Соверши $n зачётный полёт с каждой птицей.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'Сыграй в мини-игру с отжиманиями, приседаниями или прыжками.';

  @override
  String get stamp_allRounder_goalSilver =>
      'Сыграй во все три мини-игры: отжимания, приседания, прыжки.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Соверши $n зачётного полёта в каждой мини-игре.',
      many: 'Соверши $n зачётных полётов в каждой мини-игре.',
      few: 'Соверши $n зачётных полёта в каждой мини-игре.',
      one: 'Соверши $n зачётный полёт в каждой мини-игре.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals медали · уровень $level',
      many: '$stars★ · $medals медалей · уровень $level',
      few: '$stars★ · $medals медали · уровень $level',
      one: '$stars★ · $medals медаль · уровень $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'Твоему приключению нужна минутка.';

  @override
  String get dailyTitle => 'Маленькое приключение дня.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · ЦЕЛИ $done/3';
  }

  @override
  String get dailyIntro =>
      'Три цели. Любое управление. Один бесконечный полёт может выполнить все три.';

  @override
  String get dailyLaunchEndless => 'Бесконечный';

  @override
  String get dailyPostcardKicker => 'ОТКРЫТКА КЛУБА';

  @override
  String get dailyStamped => 'ШТАМП ПОСТАВЛЕН!';

  @override
  String dailyGoalsComplete(int done) {
    return 'ВЫПОЛНЕНО: $done / 3';
  }

  @override
  String get dailyDoneNote => 'Маленькое приключение — всё твоё.';

  @override
  String get dailyOpenNote => 'Выполни все три, чтобы получить штамп.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal Выполнено';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current из $target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: штамп поставлен';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: целей $done/3';
  }

  @override
  String get dailyNoStreak => 'Новые цели. Серию не потеряешь.';

  @override
  String get dailyTheme_0 => 'Рассветная доставка';

  @override
  String get dailyTheme_1 => 'Персиковый пикник';

  @override
  String get dailyTheme_2 => 'Лунная почта';

  @override
  String get dailyTheme_3 => 'Парад облаков';

  @override
  String get dailyTheme_4 => 'Сумеречный клад';

  @override
  String get dailyTheme_5 => 'Праздник в саду';

  @override
  String get task_flights_title => 'Расправь крылья';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Заверши сегодня $count зачётного полёта.',
      many: 'Заверши сегодня $count зачётных полётов.',
      few: 'Заверши сегодня $count зачётных полёта.',
      one: 'Заверши сегодня $count зачётный полёт.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'Новые горизонты';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Пролети сквозь ворота $count раза за сегодняшние зачётные полёты.',
      many: 'Пролети сквозь ворота $count раз за сегодняшние зачётные полёты.',
      few: 'Пролети сквозь ворота $count раза за сегодняшние зачётные полёты.',
      one: 'Пролети сквозь ворота $count раз за сегодняшние зачётные полёты.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'Полный карман звёзд';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Собери $count звезды за сегодняшние полёты.',
      many: 'Собери $count звёзд за сегодняшние полёты.',
      few: 'Собери $count звезды за сегодняшние полёты.',
      one: 'Собери $count звезду за сегодняшние полёты.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'Сияй без перерыва';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Собери $count звезды одной непрерывной серией.',
      many: 'Собери $count звёзд одной непрерывной серией.',
      few: 'Собери $count звезды одной непрерывной серией.',
      one: 'Собери $count звезду одной непрерывной серией.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'Точно в цель';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сделай сегодня $count идеального пролёта.',
      many: 'Сделай сегодня $count идеальных пролётов.',
      few: 'Сделай сегодня $count идеальных пролёта.',
      one: 'Сделай сегодня $count идеальный пролёт.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'Весь путь';

  @override
  String get task_finishTrail_goal =>
      'Продержись не меньше 60 секунд в одном бесконечном полёте.';

  @override
  String get recordsTitle => 'Твои маленькие победы.';

  @override
  String get recordsBestsTitle => 'Твои рекорды — побей их!';

  @override
  String get recordsSectionMain => 'ОСНОВНАЯ ИГРА';

  @override
  String get recordsSectionMini => 'МИНИ-ИГРЫ';

  @override
  String get recordsEndless => 'Бесконечный · Жми и лети';

  @override
  String get recordsCampaignStars => 'Звёзды кампании';

  @override
  String recordsCoopName(String mode) {
    return 'Летим вместе · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'зачётного полёта',
      many: 'зачётных полётов',
      few: 'зачётных полёта',
      one: 'зачётный полёт',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ворот',
      many: 'ворот',
      few: 'ворот',
      one: 'ворота',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'вдвоём',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дуэли',
      many: 'дуэлей',
      few: 'дуэли',
      one: 'дуэль',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'отжимания',
      many: 'отжиманий',
      few: 'отжимания',
      one: 'отжимание',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'приседания',
      many: 'приседаний',
      few: 'приседания',
      one: 'приседание',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'Последние полёты';

  @override
  String get recordsEmptyTitle => 'Большое небо. Чистый лист.';

  @override
  String get recordsEmptyBody => 'Первый зачётный полёт начнёт историю.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds с';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'Классика · $date · $seconds с';
  }

  @override
  String get replaySavedSessions => 'Сохранённые полёты';

  @override
  String get replayBackToRecordsSemantics => 'Назад к рекордам';

  @override
  String get replaySessionsLoadFailed => 'Не удалось загрузить. Повторить';

  @override
  String get replayEmptyTitle => 'Здесь будут твои полёты';

  @override
  String get replayEmptyBody =>
      'Сохрани полёт после приземления, чтобы посмотреть его здесь.';

  @override
  String get replayEmptyButton => 'Выбрать полёт';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds с · $score звёздного очка',
      many: '$date · $seconds с · $score звёздных очков',
      few: '$date · $seconds с · $score звёздных очка',
      one: '$date · $seconds с · $score звёздное очко',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds с · $score препятствия',
      many: '$date · $seconds с · $score препятствий',
      few: '$date · $seconds с · $score препятствия',
      one: '$date · $seconds с · $score препятствие',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'Удалить полёт';

  @override
  String get replayDeleteTitle => 'Удалить этот полёт?';

  @override
  String get replayDeleteBody =>
      'Видео с камеры и повтор будут удалены. Очки останутся в «Рекордах».';

  @override
  String get replayDeleteFailed =>
      'Не удалось удалить полёт. Попробуй ещё раз.';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return 'Уровень $id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · Бесконечный';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · Тренировка';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · Бесконечный · Тренировка';
  }

  @override
  String get replayOpenFailed => 'Этот полёт не удалось открыть.';

  @override
  String get replayBackToSessions => 'Назад к полётам';

  @override
  String get replayCameraPaused => 'В этой части полёта камера была на паузе';

  @override
  String get replayCameraUnavailable =>
      'Видео с камеры недоступно · Игра всё равно идёт';

  @override
  String get replayCameraLoading => 'Загрузка камеры…';

  @override
  String get replayPaused => 'Передышка';

  @override
  String get replayHideControlsSemantics => 'Скрыть управление повтором';

  @override
  String get replayShowControlsSemantics => 'Показать управление повтором';

  @override
  String get replayBackToSavedSemantics => 'Назад к сохранённым полётам';

  @override
  String get replayTitle => 'ПОВТОР';

  @override
  String replayTitleSession(String session) {
    return 'ПОВТОР · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'Очки: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts сердечка',
      many: '$hearts сердечек',
      few: '$hearts сердечка',
      one: '$hearts сердечко',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'Сердечки: И1 $p1 · И2 $p2 · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String replayMagnet(int seconds) {
    return 'Магнит $seconds с';
  }

  @override
  String get replayPauseSemantics => 'Пауза';

  @override
  String get replayPlaySemantics => 'Смотреть';

  @override
  String get replayRestartSemantics => 'Сначала';

  @override
  String get replayBack5Semantics => 'Назад на 5 секунд';

  @override
  String get replayForward5Semantics => 'Вперёд на 5 секунд';

  @override
  String get replayHighlightsFinding => 'Ищем лучшие моменты полёта';

  @override
  String get replayHighlightsNone => 'Лучших моментов нет';

  @override
  String get replayHighlights => 'Лучшие моменты полёта';

  @override
  String get replayHighlightsCloseSemantics => 'Закрыть лучшие моменты';

  @override
  String get replayHighlightsHint =>
      'Выбери момент. Смотри с секунды перед ним.';

  @override
  String get replayViewCorner => 'Камера в углу';

  @override
  String get replayViewBackground => 'Камера на фоне';

  @override
  String get replayViewGameplay => 'Только игра';

  @override
  String get replayMoveCornerSemantics => 'Переместить окно камеры';

  @override
  String get replayMuteRecordedSemantics => 'Выключить записанный звук';

  @override
  String get replayUnmuteRecordedSemantics => 'Включить записанный звук';

  @override
  String get replayMuteGameSemantics => 'Выключить звук игры';

  @override
  String get replayUnmuteGameSemantics => 'Включить звук игры';

  @override
  String get replayFullScreenSemantics => 'Скрыть управление / полный экран';

  @override
  String get replayMomentTakeoff => 'Взлёт';

  @override
  String get replayMomentTakeoffDetail => 'Небо твоё.';

  @override
  String get replayMomentMagnet => 'Звёздный магнит';

  @override
  String get replayMomentMagnetDetail =>
      'Три идеальных пролёта притягивают звёзды поближе.';

  @override
  String get replayMomentStarTrio => 'Первое звёздное трио';

  @override
  String get replayMomentStarTrioDetail =>
      'Три звезды — уже созвездие. +5 очков!';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'Все звёзды группы собраны. +5 очков!';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier× звёздная сила';
  }

  @override
  String get replayMomentStreakDetail => 'Сверкающая серия звёзд.';

  @override
  String get replayMomentShield => 'Щит спас';

  @override
  String get replayMomentShieldDetail => 'Было близко — но есть ещё шанс.';

  @override
  String get replayMomentPerfect => 'Первый идеальный пролёт';

  @override
  String get replayMomentPerfectDetail => 'Точно через прицельную метку.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пройдено ворот: $count',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'Ещё немного дальше в небо.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Ни царапины. +$points очка!',
      many: 'Ни царапины. +$points очков!',
      few: 'Ни царапины. +$points очка!',
      one: 'Ни царапины. +$points очко!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Золотые кольца унесли от беды. +$points очка!',
      many: 'Золотые кольца унесли от беды. +$points очков!',
      few: 'Золотые кольца унесли от беды. +$points очка!',
      one: 'Золотые кольца унесли от беды. +$points очко!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'Пережили шквал';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Увернулись от летящего хлама. +$points очка!',
      many: 'Увернулись от летящего хлама. +$points очков!',
      few: 'Увернулись от летящего хлама. +$points очка!',
      one: 'Увернулись от летящего хлама. +$points очко!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'Маршрут пройден';

  @override
  String get replayMomentFinal => 'Финальный момент';

  @override
  String get replayMomentCompleteDetail => 'Конец маршрута достигнут.';

  @override
  String get replayMomentCollisionDetail => 'Посмотри на последний заход.';

  @override
  String get replayMomentEndDetail => 'Конец этого полёта.';
}
