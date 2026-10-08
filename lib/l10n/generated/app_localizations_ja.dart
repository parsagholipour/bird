// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get commonTryAgain => 'もう一度';

  @override
  String get languageKeyLabel => '言語';

  @override
  String languageKeySemantics(String language) {
    return '言語：$language。ゲームの言語を変えます。';
  }

  @override
  String get languageSystemDefault => '端末の言語';

  @override
  String languageSystemDetail(String language) {
    return '端末に合わせる：$language';
  }

  @override
  String get languageCurrent => '選択中の言語';

  @override
  String get languageName_en => '英語';

  @override
  String get languageName_es_419 => 'スペイン語（中南米）';

  @override
  String get languageName_pt_br => 'ポルトガル語（ブラジル）';

  @override
  String get languageName_id => 'インドネシア語';

  @override
  String get languageName_fr => 'フランス語';

  @override
  String get languageName_de => 'ドイツ語';

  @override
  String get languageName_ja => '日本語';

  @override
  String get languageName_ko => '韓国語';

  @override
  String get languageName_tr => 'トルコ語';

  @override
  String get languageName_zh_hant => '繁体字中国語';

  @override
  String get languageName_ru => 'ロシア語';

  @override
  String get languageName_ar => 'アラビア語';

  @override
  String get voicePackReady => 'ボイス準備完了';

  @override
  String get voicePackDownload => 'ボイスを入手';

  @override
  String voicePackDownloading(int percent) {
    return 'ボイス $percent%';
  }

  @override
  String get voicePackStarting => 'ボイス取得中';

  @override
  String get voicePackEnglish => '英語ボイス';

  @override
  String get voicePackFailed => 'ボイス取得失敗';

  @override
  String get settingsTitle => 'ゆっくりしていってね。';

  @override
  String get settingsSectionSound => 'サウンド';

  @override
  String get settingsSectionComfort => '快適さ';

  @override
  String get settingsMusicTitle => 'スカイクラブの音楽';

  @override
  String get settingsMusicDetail => 'メニュー、冒険、ボスのテーマ曲。';

  @override
  String get settingsEffectsTitle => '効果音';

  @override
  String get settingsEffectsDetail => '飛行、バトル、アイテム、メニューの音。';

  @override
  String get settingsVoicesTitle => 'キャラクターボイス';

  @override
  String get settingsVoicesDetail => 'ストーリー、お礼のカード、ダッシュのかけ声。';

  @override
  String get settingsReducedMotionTitle => '視差効果を減らす';

  @override
  String get settingsReducedMotionDetail => '落ち着いたメニューと、控えめな演出。';

  @override
  String get settingsSwitchOn => 'ON';

  @override
  String get settingsSwitchOff => 'OFF';

  @override
  String get settingsUnavailable => '設定をうまく読み込めなかったよ。';

  @override
  String get settingsPrivacyKicker => 'いつも端末の中だけ。';

  @override
  String get settingsPrivacyTitle => 'カメラはきみだけのもの。';

  @override
  String get settingsPrivacyBody =>
      '映像とマイク音声（使うとき）は、このスマホの中だけ。保存しない動画は消えます。アップロードなし。';

  @override
  String get settingsCameraLab => 'カメラ実験室';

  @override
  String get settingsAbout => '情報とライセンス';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return '情報とライセンス、バージョン$version';
  }

  @override
  String get settingsReset => 'セーブデータをリセット';

  @override
  String settingsResetDone(String bird) {
    return 'まっさらな再スタート。$birdが待ってるよ。';
  }

  @override
  String get settingsResetTitle => '新しい冒険をはじめる？';

  @override
  String get settingsResetBody =>
      'このスマホに保存した動画、リプレイ、スコア、フライト、作ったレベル、設定がすべて消えます。元には戻せません。';

  @override
  String get settingsResetBodyCloud =>
      'このスマホに保存した動画、リプレイ、スコア、フライト、作ったレベル、設定と、Play ゲームのクラウドセーブがすべて消えます。元には戻せません。';

  @override
  String get settingsResetConfirm => 'すべてリセット';

  @override
  String get settingsResetKeep => 'データを残す';

  @override
  String get playGamesName => 'Play ゲーム';

  @override
  String get playGamesConnected => '接続済み';

  @override
  String get playGamesNotConnected => '未接続';

  @override
  String get playGamesConnecting => '接続しています…';

  @override
  String get playGamesConnectFailed => '接続できませんでした';

  @override
  String get playGamesIdle => 'クラウドセーブと実績';

  @override
  String get playGamesSaving => 'クラウドに保存中…';

  @override
  String get playGamesOfflineUnsaved => 'オフライン・保存はまだ';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'オフライン・最終保存：$ago';
  }

  @override
  String get playGamesUpdateNeeded => '同期にはアプリの更新が必要';

  @override
  String get playGamesUnreadable => 'クラウドセーブが読めません';

  @override
  String get playGamesOn => 'クラウドセーブ有効';

  @override
  String get playGamesResetElsewhere => '別のスマホでリセット済み';

  @override
  String playGamesRestored(String ago) {
    return 'クラウドから復元・$ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'クラウドに保存・$ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Play ゲームの実績';

  @override
  String get playGamesConnectSemantics => 'Play ゲームに接続';

  @override
  String get playGamesAchievements => '実績';

  @override
  String get playGamesConnect => '接続する';

  @override
  String get timeAgoJustNow => 'たった今';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes分前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours時間前',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days日前',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '+1ライフ！';

  @override
  String calloutStarTrio(int points) {
    return '星トリオ+$points!';
  }

  @override
  String get calloutNiceShot => 'ナイス命中！';

  @override
  String calloutNiceShotPoints(int points) {
    return 'ナイス命中+$points!';
  }

  @override
  String get calloutSmash => 'ドカン！';

  @override
  String calloutSmashPoints(int points) {
    return 'ドカン+$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return 'ドカン×$count!';
  }

  @override
  String get calloutBossDown => 'ボス撃破！';

  @override
  String calloutBossDownPoints(int points) {
    return 'ボス撃破+$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier×スターパワー！';
  }

  @override
  String get calloutPerfect => '完ぺき！';

  @override
  String calloutPerfectChain(int count) {
    return '完ぺき×$count';
  }

  @override
  String get calloutShieldReady => 'シールド準備OK';

  @override
  String get calloutShieldSave => 'シールド防御！';

  @override
  String get calloutKeepFlying => 'まだ飛べる！';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countゲート！',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'あと$seconds秒！',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => '星マグネット！';

  @override
  String get calloutSprintRing => 'ダッシュリング';

  @override
  String calloutRushChain(int count) {
    return 'ラッシュ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'いん石+$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return 'コウモリ+$points!';
  }

  @override
  String get calloutScorched => 'アチチ！';

  @override
  String get region_jungle => 'ジャングル';

  @override
  String get region_antarctica => '南極';

  @override
  String get region_aztec => 'アステカ';

  @override
  String get region_paris => 'パリ';

  @override
  String get region_egypt => 'エジプト';

  @override
  String get region_cyberpunk => 'サイバーシティ';

  @override
  String get region_china => '中国';

  @override
  String get region_brazil => 'ブラジル';

  @override
  String get region_newYork => 'ニューヨーク';

  @override
  String get region_arabia => '古代アラビア';

  @override
  String get region_rome => '古代ローマ';

  @override
  String get region_mexico => 'メキシコ';

  @override
  String get region_sea => '大海原';

  @override
  String get boss_baronBat_name => 'コウモリ男爵';

  @override
  String get boss_spitterBeetle_name => 'ペッペ王';

  @override
  String get boss_duskMoth_name => 'たそがれ女帝';

  @override
  String get boss_pirate_name => '海賊船長';

  @override
  String get boss_dragon_name => '残り火ドラゴン';

  @override
  String get boss_kingCoo_name => 'キング・ポッポ';

  @override
  String get boss_searchlightGargoyle_name => 'サーチライト・ガーゴイル';

  @override
  String get boss_neferhoo_name => 'ネフェルフー';

  @override
  String get bird_0_name => 'ピップ';

  @override
  String get bird_1_name => 'ピーチズ';

  @override
  String get bird_2_name => 'ミンティ';

  @override
  String get bird_3_name => 'オービット';

  @override
  String get playMode_pushUp => '腕立てフ⁠ラ⁠イ⁠ト';

  @override
  String get playMode_jump => 'ジ⁠ャ⁠ン⁠プ＆フ⁠ラ⁠イ';

  @override
  String get playMode_touch => 'タ⁠ッ⁠プ＆フ⁠ラ⁠イ';

  @override
  String get playMode_squat => 'ス⁠ク⁠ワ⁠ッ⁠ト＆フ⁠ラ⁠イ';

  @override
  String get chapter_1_route => 'こずえルート';

  @override
  String get chapter_1_postmark => 'こずえルート';

  @override
  String get chapter_1_postcard =>
      'こずえにまた手紙が届くようになったよ！オオハシたちから（とっても大きな声で）ありがとう。コウモリ男爵の王冠は、うちの暖炉の上に飾ってあるよ。';

  @override
  String get chapter_1_postscript => 'いにしえの道から、なにか煮えてるにおいがするよ。';

  @override
  String get chapter_2_route => 'いにしえの道';

  @override
  String get chapter_2_postmark => 'いにしえの道';

  @override
  String get chapter_2_postcard =>
      'キャラバンはまた動きだして、煮えているのはミントティーだけ。ペッペ王の水筒の王冠は、花びんにしたよ。';

  @override
  String get chapter_2_postscript => 'ゆうべ、街のランプが消えちゃった。あかりを持ってきて。';

  @override
  String get chapter_3_route => '街あかり線';

  @override
  String get chapter_3_postmark => '街あかり線';

  @override
  String get chapter_3_postcard =>
      'ランプがともって、夜の郵便もぱっちり目をさましたよ！パリからはクロワッサン、ニューヨークからはプレッツェルをどうぞ。';

  @override
  String get chapter_3_postscript => '港の鐘が鳴らなくなっちゃった。';

  @override
  String get chapter_4_route => '潮のルート';

  @override
  String get chapter_4_postmark => '潮のルート';

  @override
  String get chapter_4_postcard =>
      '港の鐘がまた鳴ってるよ。大砲じゃなくて、手紙のためにね。オウムはここに残ったよ。よろしくだって。';

  @override
  String get chapter_4_postscript => '地図の果ての空が燃えてるんだって。';

  @override
  String get chapter_5_route => '地図の果て';

  @override
  String get chapter_5_postmark => '地図の果て';

  @override
  String get chapter_5_postcard =>
      '北のはしから南のはしまで空は晴れわたり、どのルートも元気に動いてるよ。スカイクラブのみんなが、きみをほこりに思ってる。';

  @override
  String get chapter_5_postscript => '果てしない空は、いつでもきみを待ってるよ。';

  @override
  String get level_1_1_name => 'はじめての配達';

  @override
  String get level_1_1_cargo => 'オオハシのふたごへ誕生日カード';

  @override
  String get level_1_1_sender => 'オオハシのふたご';

  @override
  String get level_1_1_hint => 'タップではばたこう。星を集めながら飛ぼう。';

  @override
  String get level_1_2_name => '星つなぎ';

  @override
  String get level_1_2_cargo => '星好きのナマケモノへ星図';

  @override
  String get level_1_2_sender => '星好きのナマケモノ';

  @override
  String get level_1_2_hint => '星をつなげて3倍！パーフェクト通過3回でマグネット。';

  @override
  String get level_1_3_name => 'コウモリパトロール';

  @override
  String get level_1_3_cargo => 'ホタル保育園へナイトライト';

  @override
  String get level_1_3_sender => 'ホタル保育園';

  @override
  String get level_1_3_hint => 'ショット！ショットをタップしてコウモリをやっつけよう。';

  @override
  String get level_1_4_name => 'カーニバルの空';

  @override
  String get level_1_4_cargo => 'カーニバルのパレードへ羽根のボア';

  @override
  String get level_1_4_sender => 'サンバのコンゴウインコ';

  @override
  String get level_1_4_hint => '突風だ！「！」を見て、サッカーボールをよけよう。';

  @override
  String get level_1_5_name => '速達便';

  @override
  String get level_1_5_cargo => '太鼓隊長へ大急ぎの招待状';

  @override
  String get level_1_5_sender => '太鼓隊長';

  @override
  String get level_1_5_hint => 'ダッシュでコウモリをけちらし、一気に前へ！';

  @override
  String get level_1_6_name => '神殿の階段';

  @override
  String get level_1_6_cargo => '神殿の料理人たちへカカオ豆';

  @override
  String get level_1_6_sender => '神殿の料理人たち';

  @override
  String get level_1_7_name => '日の出のねぐら';

  @override
  String get level_1_7_cargo => '夜明けの番人へ日時計';

  @override
  String get level_1_7_sender => '夜明けの番人';

  @override
  String get level_1_8_name => 'コウモリ男爵';

  @override
  String get level_1_8_cargo => 'コウモリ男爵へ最終通告';

  @override
  String get level_1_8_sender => 'コウモリ男爵';

  @override
  String get level_2_1_name => 'ペッペ虫の道';

  @override
  String get level_2_1_cargo => '馬車レーサーたちへ月桂冠';

  @override
  String get level_2_1_sender => '馬車レーサーたち';

  @override
  String get level_2_1_hint => 'ペッペ虫はタネをはくよ。ショットでタネを撃ち落とそう。';

  @override
  String get level_2_2_name => 'ふさがれた門';

  @override
  String get level_2_2_cargo => '像の彫刻家へ新しいノミ';

  @override
  String get level_2_2_sender => '像の彫刻家';

  @override
  String get level_2_2_hint => 'ショットを長押しすると、石をくだく大きな石を投げるよ。';

  @override
  String get level_2_3_name => '大火事ダッシュ';

  @override
  String get level_2_3_cargo => '消防隊へ水のバケツ';

  @override
  String get level_2_3_sender => '消防隊';

  @override
  String get level_2_3_hint => '金のリングをくぐって、火から逃げきろう！';

  @override
  String get level_2_4_name => 'ナイルのジグザグ';

  @override
  String get level_2_4_cargo => 'スフィンクスへ新しいなぞなぞの本';

  @override
  String get level_2_4_sender => 'スフィンクス';

  @override
  String get level_2_5_name => 'メテオフォール';

  @override
  String get level_2_5_cargo => 'ピラミッドの天文学者へ望遠鏡';

  @override
  String get level_2_5_sender => 'ピラミッドの天文学者';

  @override
  String get level_2_5_hint => 'リングダッシュでいん石をくだこう。';

  @override
  String get level_2_6_name => '差出人に返送';

  @override
  String get level_2_6_cargo => '管理人さんへ羽ぼうき';

  @override
  String get level_2_6_sender => 'ピラミッドの管理人さん';

  @override
  String get level_2_6_hint => 'ショットで手紙を撃ち返そう。差出人に返送！';

  @override
  String get level_2_7_name => 'ランタンのバザール';

  @override
  String get level_2_7_cargo => 'ランタン売りたちへランプの油';

  @override
  String get level_2_7_sender => 'ランタン売りたち';

  @override
  String get level_2_8_name => '長いキャラバン';

  @override
  String get level_2_8_cargo => '長いキャラバンへ水筒';

  @override
  String get level_2_8_sender => 'キャラバンのリーダー';

  @override
  String get level_2_9_name => 'ペッペ王';

  @override
  String get level_2_9_cargo => 'ペッペ王へなべ禁止令';

  @override
  String get level_2_9_sender => 'ペッペ王';

  @override
  String get level_3_1_name => 'あかりに誘われて';

  @override
  String get level_3_1_cargo => '劇場のひさしへ電球';

  @override
  String get level_3_1_sender => '舞台監督';

  @override
  String get level_3_1_hint => '蛾は扇のように3発撃つよ。すき間をすり抜けよう。';

  @override
  String get level_3_2_name => '雨と車輪';

  @override
  String get level_3_2_cargo => '新聞スタンドのハトたちへかさ';

  @override
  String get level_3_2_sender => '新聞スタンドのハトたち';

  @override
  String get level_3_2_hint => '路地裏バトが星を横取りしに来るよ。先にショット！';

  @override
  String get level_3_3_name => 'スチーム横丁';

  @override
  String get level_3_3_cargo => '夜勤のタクシー運転手へ熱々プレッツェル';

  @override
  String get level_3_3_sender => '夜のタクシー運転手たち';

  @override
  String get level_3_3_hint => '蒸気口はシューッ、そしてボン！熱いのはよけて、弱いのには乗ろう。';

  @override
  String get level_3_4_name => '暴風警報';

  @override
  String get level_3_4_cargo => 'いちばん高い塔へ風見鶏';

  @override
  String get level_3_4_sender => '塔の番人';

  @override
  String get level_3_4_hint => '光に入らないで。ランプが開いたらショット！ここではダッシュ禁止。';

  @override
  String get level_3_5_name => 'クリスタルの屋根';

  @override
  String get level_3_5_cargo => '屋根の上の画家たちへクロワッサン';

  @override
  String get level_3_5_sender => '屋根の上の画家たち';

  @override
  String get level_3_6_name => '突風のあとで';

  @override
  String get level_3_6_cargo => 'アコーディオン弾きへ楽譜';

  @override
  String get level_3_6_sender => 'アコーディオン弾き';

  @override
  String get level_3_6_hint => '突風だ！「！」を見て、あいてる側へ飛ぼう。';

  @override
  String get level_3_7_name => '真夜中の特急便';

  @override
  String get level_3_7_cargo => 'パン屋さんへ真夜中のラブレター';

  @override
  String get level_3_7_sender => 'パン屋さん';

  @override
  String get level_3_7_hint => 'ダッシュで群れをつきぬけよう。';

  @override
  String get level_3_8_name => 'たそがれ女帝';

  @override
  String get level_3_8_cargo => 'たそがれ女帝へ目覚ましコール';

  @override
  String get level_3_8_sender => 'たそがれ女帝';

  @override
  String get level_4_1_name => '港のあかり';

  @override
  String get level_4_1_cargo => '灯台守へ新しいレンズ';

  @override
  String get level_4_1_sender => '灯台守';

  @override
  String get level_4_2_name => '火山の峠';

  @override
  String get level_4_2_cargo => '火山のケーキ屋さんへオーブンミトン';

  @override
  String get level_4_2_sender => '火山のケーキ屋さん';

  @override
  String get level_4_2_hint => '溶岩の柱を飛びこえよう。';

  @override
  String get level_4_3_name => '海岸ぞいに';

  @override
  String get level_4_3_cargo => '浜辺のお祭りへたこ糸';

  @override
  String get level_4_3_sender => 'たこあげの人たち';

  @override
  String get level_4_4_name => '干潮';

  @override
  String get level_4_4_cargo => '島の仙人へお返事';

  @override
  String get level_4_4_sender => '島の仙人';

  @override
  String get level_4_4_hint => '水にさわらないでね。';

  @override
  String get level_4_5_name => '大潮';

  @override
  String get level_4_5_cargo => 'フェリーの乗組員へ潮の時刻表';

  @override
  String get level_4_5_sender => 'フェリーの乗組員';

  @override
  String get level_4_5_hint => '鐘が鳴ったら、高く飛ぼう。';

  @override
  String get level_4_6_name => '一斉砲撃の湾';

  @override
  String get level_4_6_cargo => 'カモメの群れへ魚ビスケット';

  @override
  String get level_4_6_sender => 'カモメの群れ';

  @override
  String get level_4_7_name => '嵐の海をこえて';

  @override
  String get level_4_7_cargo => '嵐の見張り番の船乗りへ乾いた靴下';

  @override
  String get level_4_7_sender => '嵐の見張り番';

  @override
  String get level_4_8_name => '海賊船長';

  @override
  String get level_4_8_cargo => '船長へ郵便返却命令';

  @override
  String get level_4_8_sender => '海賊船長';

  @override
  String get level_5_1_name => 'オーロラ郵便局';

  @override
  String get level_5_1_cargo => 'ペンギン合唱団へ毛糸の帽子';

  @override
  String get level_5_1_sender => 'ペンギン合唱団';

  @override
  String get level_5_1_hint => 'どんなラッシュも来るよ。バナーをよく見て！';

  @override
  String get level_5_2_name => '極地の夜';

  @override
  String get level_5_2_cargo => '南極基地へホットココア';

  @override
  String get level_5_2_sender => '南極基地';

  @override
  String get level_5_3_name => 'ネオン特急';

  @override
  String get level_5_3_cargo => 'ラーメン屋の看板へ予備のヒューズ';

  @override
  String get level_5_3_sender => 'ラーメン屋の店主';

  @override
  String get level_5_4_name => 'データの嵐';

  @override
  String get level_5_4_cargo => '好奇心いっぱいのロボットへ紙の手紙';

  @override
  String get level_5_4_sender => 'ユニット7';

  @override
  String get level_5_5_name => '屋上ダッシュ';

  @override
  String get level_5_5_cargo => '屋上ランナーたちへレースのチケット';

  @override
  String get level_5_5_sender => '屋上ランナーたち';

  @override
  String get level_5_6_name => 'ランタン祭り';

  @override
  String get level_5_6_cargo => 'お祭りへ紙のちょうちん';

  @override
  String get level_5_6_sender => 'ちょうちん職人たち';

  @override
  String get level_5_7_name => '最後のひと飛び';

  @override
  String get level_5_7_cargo => '山寺へ山のお茶';

  @override
  String get level_5_7_sender => '山のお坊さんたち';

  @override
  String get level_5_8_name => '残り火ドラゴン';

  @override
  String get level_5_8_cargo => 'ドラゴンへ、はじめての手紙';

  @override
  String get level_5_8_sender => '残り火ドラゴン';

  @override
  String get storyPostmasterName => 'ビル局長';

  @override
  String get storySkip => 'スキップ';

  @override
  String get storyNextLineSemantics => '次のセリフ';

  @override
  String get storyFinishSemantics => 'おわり';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name：$line';
  }

  @override
  String get campaignMotto => '手紙は必ず届く。';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand。$motto';
  }

  @override
  String get levelIntroFly => '飛ぼう！';

  @override
  String levelIntroRunUp(int seconds) {
    return 'まずは$seconds秒の助走';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'ゴールまで約$seconds秒';
  }

  @override
  String get campaignGuardian => 'ガーディアン';

  @override
  String get levelIntroBossFight => 'ボス戦';

  @override
  String get levelIntroNew => 'NEW';

  @override
  String get levelIntroTip => 'ヒント';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    return '$bossをたおす';
  }

  @override
  String get levelIntroGoalFinish => 'ゴールまで飛ぶ';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星を$count個集める',
      one: '星を1個集める',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': '星1つ：$goal。',
      'two': '星2つ：$goal。',
      'other': '星3つ：$goal。',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': '星1つ：$goal。達成ずみ。',
      'two': '星2つ：$goal。達成ずみ。',
      'other': '星3つ：$goal。達成ずみ。',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ベスト：星$count個',
      one: 'ベスト：星1個',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'まだ届けていない';

  @override
  String get levelIntroFirstFlight => 'はじめてのフライト';

  @override
  String get levelIntroControlFlap => 'はばたく';

  @override
  String get levelIntroControlShoot => 'ショット';

  @override
  String get levelIntroControlSprint => 'ダッシュ';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': '操作：はばたく。',
      'shoot': '操作：はばたく、ショット。',
      'sprint': '操作：はばたく、ダッシュ。',
      'other': '操作：はばたく、ショット、ダッシュ。',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => '特別便';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return '特別便：$cargo。';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return 'レベル$level、$name。$region。';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return 'レベル$level、$name。$region。ガーディアンのレベル：$boss。';
  }

  @override
  String get levelIntroStory => 'ストーリー';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonContinue => 'つづける';

  @override
  String get commonHome => 'ホーム';

  @override
  String get commonBackHome => 'ホームにもどる';

  @override
  String get campaignComingSoon => '近日公開';

  @override
  String campaignStopComingSoon(String region) {
    return '$regionは近日公開';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    return '$bossをたおすと解放';
  }

  @override
  String campaignLockedFinish(String level) {
    return '$levelをクリアすると解放';
  }

  @override
  String get campaignMapUnavailable => 'マップを読み込めなかったよ。';

  @override
  String campaignCloseLevelSemantics(String name) {
    return '$nameを閉じる';
  }

  @override
  String get campaignMapPreviousStop => '前の行き先';

  @override
  String get campaignMapNextStop => '次の行き先';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region。第$chapter章、$route。近日公開。',
      'locked': '$region。第$chapter章、$route。ロック中。',
      'other': '$region。第$chapter章、$route。',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return '第$chapter章・$route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level、$name、ボス',
      'guardian': 'レベル$level、$name、ガーディアン$boss',
      'other': 'レベル$level、$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node。ロック中。';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node。ロック中。$note。';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '星3個中$stars個',
    );
    return '$node。次はここ。$_temp0。';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '星3個中$stars個',
    );
    return '$node。$_temp0。';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'ガーゴイル',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return '第$chapter章の絵はがき';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'キャンペーンの星、$total個中$stars個',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => '配達人さんへ';

  @override
  String get campaignPostcardPs => 'P.S.';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return '$routeからの絵はがき。配達人さんへ。$body P.S. $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => '旅だより';

  @override
  String get campaignPostcardHeader => 'スカイクラブの絵はがき';

  @override
  String campaignPostcardSignature(String route) {
    return '$routeより';
  }

  @override
  String get campaignPostcardAddressName => '配達人さま';

  @override
  String get campaignPostcardAddressStreet => 'スカイクラブ郵便';

  @override
  String get campaignPostcardAddressCity => '空のずっと上';

  @override
  String get campaignPostmarkDelivered => '配達済み';

  @override
  String get campaignPostmarkClub => 'スカイクラブ郵便';

  @override
  String get campaignStampSkyClub => 'SKY CLUB';

  @override
  String campaignThanksQuoted(String thanks) {
    return '「$thanks」';
  }

  @override
  String campaignThanksSignature(String sender) {
    return '$senderより';
  }

  @override
  String campaignThanksSemantics(String sender, String thanks) {
    return '$senderからのお礼のカード：$thanks';
  }

  @override
  String get flightSetupTitlePushUp => '準備はちょっと。空はたっぷり。';

  @override
  String get flightSetupTitleSquat => '足はしっかり。翼はひろげて。';

  @override
  String get flightSetupTitleJump => '小さくジャンプ。大きな翼。';

  @override
  String flightSetupBuiltTag(String name) {
    return 'レベル・$name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course・記録に残る';
  }

  @override
  String get flightSetupRoomPushUp => '動ける場所を少しあけよう。';

  @override
  String get flightSetupRoomBody => '全身をうつそう。';

  @override
  String get flightSetupTipsPushUp => 'スマホは低く。腕と腰をうつそう。\n正面から？両肩が見えるようにね。';

  @override
  String get flightSetupTipsSquat => 'しゃがむと下がる。立つと上がる。\n両足は床につけたままで。';

  @override
  String get flightSetupTipsJump => 'ジャンプでブースト＋3秒グライド。\n着地してから次のジャンプ。';

  @override
  String get flightSetupHowToFly => '飛びかた';

  @override
  String get flightSetupStep1PushUp => '腕と腰をうつそう';

  @override
  String get flightSetupStep1Squat => 'しゃがむ場所をあけよう';

  @override
  String get flightSetupStep1Jump => 'ジャンプする場所をあけよう';

  @override
  String get flightSetupStep1DetailPushUp => 'スマホに向かってる？両肩と片腕、腰をうつそう。';

  @override
  String get flightSetupStep1DetailBody => 'スマホは横向き。体と両足をうつそう。';

  @override
  String get flightSetupStep2PushUp => '動く範囲をはかろう';

  @override
  String get flightSetupStep2Squat => '楽なしゃがみ方を見つけよう';

  @override
  String get flightSetupStep2Jump => 'まっすぐ立って、じっとして';

  @override
  String get flightSetupStep2DetailPushUp => '楽な上の位置を決めて、2回下がって上がろう。';

  @override
  String get flightSetupStep2DetailSquat => 'じっと立ち、しゃがんで少し止まり、また立ち上がろう。';

  @override
  String get flightSetupStep2DetailJump => '少しのあいだじっとして。それからジャンプで大きくブースト！';

  @override
  String get flightSetupStep3Stars => '星を集めよう';

  @override
  String get flightSetupStep3DetailJump => '星1個でグライド0.75秒、最大5秒。星トリオで+5点。';

  @override
  String get flightSetupLivesEndless => 'ハート3つ＋シールド。いつでも一時停止できるよ。';

  @override
  String get flightSetupLivesClassic =>
      'ぶつかったり位置がずれたりすると、記録に残るフライトは終わり。いつでも一時停止できるよ。';

  @override
  String get flightSetupCameraButton => 'カメラを準備する';

  @override
  String get flightMicTitle => 'マイクで録音';

  @override
  String get flightMicOn => 'ON';

  @override
  String get flightMicOptional => 'お好みで';

  @override
  String get flightMicDetail =>
      'リプレイにきみの声や部屋の音を入れられるよ。マイクを使うのはフライト中だけ。保存先はこのスマホ。';

  @override
  String get flightMicSemantics => 'リプレイ用にマイクで録音';

  @override
  String get flightMicSettings => 'マイクの設定';

  @override
  String get flightCalibrationTitleReady => 'きみの翼が見つかった！';

  @override
  String get flightCalibrationTitleWaking => 'カメラを起こしているよ…';

  @override
  String get flightCalibrationTitleError => 'カメラをもう一度つなごう。';

  @override
  String get flightCalibrationTitleRange => '動く範囲をはかろう。';

  @override
  String get flightCalibrationTitleStill => 'まっすぐ立って、じっとして。';

  @override
  String get flightCalibrationStepTry => '鳥を動かしてみよう。';

  @override
  String get flightCalibrationStepTop => '楽な上の位置を見つけよう。';

  @override
  String get flightCalibrationStepLower => 'ゆっくり体を下げよう。';

  @override
  String get flightCalibrationStepPushBack => '押し上げてもどろう。';

  @override
  String get flightCalibrationStepStill => 'まっすぐ立って、じっとして。';

  @override
  String get flightCalibrationStepSquat => '楽にしゃがもう。';

  @override
  String get flightCalibrationStepStandUp => 'また立ち上がろう。';

  @override
  String get flightCalibrationStepDone => 'きみの翼が見つかった！';

  @override
  String get flightCalibrationReadyPushUp => '体を押し上げると上昇。下げるとグライド。';

  @override
  String get flightCalibrationReadySquat => 'しゃがむと下がる。立つと上がる。';

  @override
  String get flightCalibrationReadyJump => 'ジャンプしたら、鳥がグライドするあいだ休もう。';

  @override
  String get flightCalibrationKeepPushUp => '両肩と片腕、腰がうつるようにして、楽に動こう。';

  @override
  String get flightCalibrationKeepBody => '両肩と腰、両足がうつるようにしよう。';

  @override
  String get flightCalibrationLearning => '動きながら範囲をおぼえているよ。';

  @override
  String get flightCalibrationAfter => '調整が終わると鳥が動くよ。';

  @override
  String get flightCalibrationJump => 'ジャンプ！';

  @override
  String get flightCalibrationTagCheck => '操作チェック';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '腕立て$count/2回';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '調整$percent%完了';
  }

  @override
  String get flightCalibrationTakeoff => '離陸の準備OK';

  @override
  String get flightCalibrationStarting => '起動中…';

  @override
  String get flightCalibrationRestart => '調整をやり直す';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate回/秒 · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate回/秒 · $p95 ms p95（処理のみ）';
  }

  @override
  String get flightCalibrationStatusReady => '準備OK';

  @override
  String get flightCalibrationStatusStarting => '起動中';

  @override
  String get flightCalibrationStatusCameraOff => 'カメラOFF';

  @override
  String get flightCalibrationStatusCalibrating => '調整中';

  @override
  String get flightSwitchCameraSemantics => 'カメラを切りかえる';

  @override
  String get flightCalibrationStepIntoView => 'カメラの前に立とう';

  @override
  String get flightCameraTroubleTitle => 'もう一度やればたいてい直るよ。';

  @override
  String get flightCameraTroubleAllow => '設定でカメラへのアクセスを許可してね。';

  @override
  String get flightCameraTroubleClose => 'ほかのカメラアプリを閉じてから、もう一度試してね。';

  @override
  String get flightCameraPermissionSemantics => 'カメラの許可の設定';

  @override
  String get flightNoteRememberFailed => 'このフライトだけ変更しました。設定は保存できませんでした。';

  @override
  String get flightNoteMicUnavailable => 'マイクが使えません。映像とゲームはそのまま使えます。';

  @override
  String get flightNoteMicBlocked => 'マイクがブロックされています。設定で許可できます。映像は使えます。';

  @override
  String get flightNoteMicOff => 'マイクはOFFです。プレイも動画の保存もできます。';

  @override
  String get flightNoteVideoUnavailable => 'カメラ映像が使えません。プレイ内容は保存できます。';

  @override
  String get flightNoteMicAudioLost => 'マイク音声がとれませんでした。映像とプレイ内容は保存できます。';

  @override
  String get flightNoteVideoInterrupted => 'カメラ映像がとぎれました。撮れた部分とプレイ内容は保存できます。';

  @override
  String get flightNoteSessionSaveFailed =>
      'フライトを保存できませんでした。「フライトを保存」をタップしてもう一度。';

  @override
  String get flightNoteWakingCamera => 'カメラを起こしているよ…';

  @override
  String get flightNoteCameraOff =>
      'カメラへのアクセスがOFFです。Androidの設定で許可してから、もどってもう一度試してね。';

  @override
  String get flightNoteCameraFailed => 'カメラを起動できませんでした。もう一度試すか、カメラを切りかえてね。';

  @override
  String get flightNotePreparing => 'フライトを準備しているよ…';

  @override
  String get flightNoteSaveFailed => 'フライトを保存できませんでした。タップしてもう一度。';

  @override
  String get flightNoteWelcomeBack => 'おかえり。もう一度、位置をチェックしよう。';

  @override
  String get flightNoteCameraInterrupted => 'カメラが止まりました。カメラの許可を確認して、もう一度試してね。';

  @override
  String get flightNoteTrackingInterrupted => 'トラッキングがとぎれました';

  @override
  String get flightFindPosition => '位置につこう';

  @override
  String get flightTapSemantics => 'タップではばたく';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'タップではばたく。$groupがボスより先に飛んでくる';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'タップではばたく。$boss：体力$maxHp中$hp';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'タップではばたく。$boss：体力$maxHp中$hp。$hint';
  }

  @override
  String get flightSkipToResultsSemantics => '結果へスキップ';

  @override
  String get hudPauseSemantics => 'フライトを一時停止';

  @override
  String get flightHintTestSteerKeys => 'テスト飛行：上下キーで操作。';

  @override
  String get flightHintTestSteerDrag => 'テスト飛行：上下にドラッグして操作。';

  @override
  String get flightHintTestJumpKeys => 'テスト飛行：Spaceキーでジャンプ。';

  @override
  String get flightHintTestJumpTap => 'テスト飛行：タップでジャンプ。';

  @override
  String get flightHintKeysStars => 'Spaceではばたこう。星を集めながら飛ぼう。';

  @override
  String get flightHintKeysShoot => 'Spaceではばたこう。Dを長押しでショットをためる。';

  @override
  String get flightHintKeysCombat => 'Spaceではばたこう。D長押しでショットをためる。Aでダッシュ！';

  @override
  String get flightHintKeysPause => 'Spaceではばたこう。Escで一時停止。';

  @override
  String get flightHintTapStars => '空をタップしてはばたこう。星を集めながら飛ぼう。';

  @override
  String get flightHintTapShoot => '空をタップしてはばたこう。ショットを長押しでためる。';

  @override
  String get flightHintTapCombat => '空をタップしてはばたこう。ショット長押しでためる。ダッシュでドカン！';

  @override
  String get flightHintTapRelease => 'タップではばたく。タップの合間は指をはなそう。';

  @override
  String get flightHintTrail => '星をたどろう。シールドは準備OK。';

  @override
  String get flightHintSky => '空はきみのもの。';

  @override
  String hudClockSemantics(String time) {
    return '残り$time';
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
      other: '星マグネット：残り$seconds秒',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'マグネットをチャージ中：パーフェクト通過$gates回中$charge回',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'さがしてるよ…';

  @override
  String get hudShoot => 'ショット';

  @override
  String get hudSprint => 'ダッシュ';

  @override
  String get flightTestNothingSaved => '保存されません';

  @override
  String get flightCountdownReady => '位置について、よーい…';

  @override
  String get flightPauseTitle => 'ひと休みしよう。';

  @override
  String get flightPauseKeepFlying => '飛びつづける';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id・$name。きみの鳥は枝にとまって待ってるよ。';
  }

  @override
  String flightPausedTest(String name) {
    return '$nameのテスト飛行。保存はされません。';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name。きみの鳥は枝にとまって待ってるよ。';
  }

  @override
  String get flightPausedTouch => 'きみの鳥は枝にとまって待ってるよ。再開のときはカウントダウンするね。';

  @override
  String get flightPausedCamera => '体をほぐしたら、また位置についてね。カウントダウンするよ。';

  @override
  String get flightPauseEdit => '編集';

  @override
  String get flightPauseBuilder => 'ビルダー';

  @override
  String get flightPauseFinish => 'フライト終了';

  @override
  String get hudShieldRecovering => '回復中';

  @override
  String get hudShieldReady => 'シールド準備OK';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'シールドをチャージ中：星$stars個中$charge個',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ハート残り$count個',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'ダッシュ中';

  @override
  String get hudSprintReady => '準備OK';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'チャージ中、あと$seconds秒',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint => '前へ突進してコウモリや石の板をくだく';

  @override
  String get hudShotReloading => 'リロード中…';

  @override
  String hudShotFullCharge(int ms) {
    return 'フルチャージ、残り$msミリ秒';
  }

  @override
  String hudShotCharging(int percent) {
    return 'チャージ中 $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return '石の残り $percent%';
  }

  @override
  String get hudShotHint => '長押しで大きな石をためる';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星$count個に到達',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$at個集めると星$countつ',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '集めた星$stars個',
    );
    return '$_temp0。$two。$three。';
  }

  @override
  String get hudMax => 'MAX';

  @override
  String hudRouteSemantics(int percent) {
    return 'ルートの$percent%を飛行';
  }

  @override
  String hudGlideCompact(String time) {
    return 'グライド$time';
  }

  @override
  String get hudJumpToGlide => '跳んでグライド';

  @override
  String get hudJump => 'ジャンプ';

  @override
  String hudGlideSemantics(String time) {
    return 'グライド、残り$time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'グライドもうすぐ終了、残り$time';
  }

  @override
  String get hudJumpChargeSemantics => 'ジャンプで3秒のグライドをチャージ';

  @override
  String get hudRecordNewBest => 'ベスト更新！';

  @override
  String get hudRecordMatched => 'ベストと同点！';

  @override
  String hudRecordBest(int best) {
    return 'ベスト$best';
  }

  @override
  String hudRecordBeyond(int points) {
    return 'ベストより+$points';
  }

  @override
  String get hudRecordOneMore => 'あと1点で新記録';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと$count点で新記録',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title。$detail。';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'スコア$score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'スコア$score、倍率$multiplier倍';
  }

  @override
  String get commonBusySemantics => '処理中';

  @override
  String get flightResultBumpClouds => '雲の中でちょっとゴツン。';

  @override
  String get flightResultPersonalBest => '自己ベスト';

  @override
  String get flightResultNewPersonalBest => '自己ベスト更新！';

  @override
  String get flightResultStarsCollected => '集めた星';

  @override
  String get flightResultDailyStamped => '今日の絵はがきにスタンプ！';

  @override
  String flightResultNextStamp(String stamp) {
    return '次：$stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'このスマホに保存しました';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'このスマホに保存・通過ゲート合計$total',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'フライトを保存中…';

  @override
  String get flightResultSessionSaved => 'フライトを保存・「記録」で見られるよ';

  @override
  String get flightResultWatchReplay => 'リプレイを見る';

  @override
  String get flightResultPreparing => '準備中…';

  @override
  String get flightResultSavingShort => '保存中…';

  @override
  String get flightResultSaveSession => 'フライトを保存';

  @override
  String get flightResultFlyAgain => 'もう一度飛ぶ';

  @override
  String get commonRetry => 'リトライ';

  @override
  String get commonMap => 'マップ';

  @override
  String get commonNext => '次へ';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回の腕立て',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回のスクワット',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回のジャンプ',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回のはばたき',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => '飛行時間';

  @override
  String get flightStatPerfect => 'パーフェクト';

  @override
  String get flightStatBestStreak => '最長星つなぎ';

  @override
  String get flightStatRank => 'ランク';

  @override
  String get flightRankSkyCaptain => '空のキャプテン';

  @override
  String get flightRankCloudExplorer => '雲の探検家';

  @override
  String get flightRankFirstWings => 'はじめての翼';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => 'ゴツン、でも自己ベスト更新！';

  @override
  String get gameOverCaptionSea => '海にちょっとザブン。';

  @override
  String get gameOverSplash => 'ザブン！';

  @override
  String get gameOverBonk => 'ゴツン！';

  @override
  String get gameOverEveryMarkSemantics => '星の目盛りにすべて到達';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星$markつまで、あと星$count個',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss：体力$maxHp中、残り$hp';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return 'ルートの$percentパーセントを飛行';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss：残りHP $hp';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$bossの残りHP';
  }

  @override
  String get gameOverRouteFlown => '飛んだルート';

  @override
  String gameOverHp(int hp) {
    return '$hp HP';
  }

  @override
  String gameOverMoreFor(int count) {
    return 'あと$countで';
  }

  @override
  String get gameOverBothMarks => '目盛りは両方クリア';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    return '目盛りは両方クリア。あとは$boss！';
  }

  @override
  String get miniResultTitle => 'どのフライトも無駄じゃない。';

  @override
  String get miniResultComplete => 'フライト完了';

  @override
  String get miniResultCheerBest => 'すごい飛びっぷり！';

  @override
  String get miniResultCheerComplete => 'フライト完了！';

  @override
  String get miniResultCheerNice => 'ナイスフライト。';

  @override
  String get miniResultNew => 'NEW';

  @override
  String get flightEndTrackingLost => 'ちょっとのあいだ、きみを見失っちゃった。';

  @override
  String get flightEndPostureLost => '体の位置が範囲の外に出たよ。';

  @override
  String get flightEndBackgrounded => '空からちょっと離れたね。';

  @override
  String get flightEndBreak => 'しっかりひと休み。';

  @override
  String get flightEndQuit => 'また次の冒険で。';

  @override
  String get flightEndStalled => 'ゲームが中断されました。';

  @override
  String get flightEndCompleted => '空いっぱいの星。ぜんぶきみのもの。';

  @override
  String get levelResultTryAgain => 'もう一回！';

  @override
  String get levelResultVictory => '勝利！';

  @override
  String get levelResultGuardianDown => 'ガーディアン撃破';

  @override
  String get levelResultDelivered => 'お届け完了！';

  @override
  String levelResultComingSoon(String region) {
    return '$regionは近日公開！';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '星3つ中$earnedつ';
  }

  @override
  String levelResultBest(int best) {
    return 'ベスト$best';
  }

  @override
  String get levelResultNoBest => 'まだベストなし';

  @override
  String get levelResultFirstClear => '初クリア！';

  @override
  String get levelResultNewBest => 'ベスト更新！';

  @override
  String get levelResultScore => 'スコア';

  @override
  String get levelResultGoalBoss => 'ボス';

  @override
  String get levelResultGoalGuardian => '中ボス';

  @override
  String get levelResultGoalFinish => 'ゴール';

  @override
  String get levelResultGoalDone => 'クリア';

  @override
  String get levelResultGoalNotYet => 'まだ';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと$count個',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'まずはゴール';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal。';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal。クリア。';
  }

  @override
  String get levelResultPostcardWaiting => 'マップで絵はがきが待ってるよ！';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '$id「$name」が解放されたよ！';
  }

  @override
  String get levelResultReachFinish => 'ゴールすると星がもらえるよ。';

  @override
  String get course_classic_title => 'クラシック';

  @override
  String get course_starTrail_title => 'エンドレス';

  @override
  String get course_classic_instructions => 'すき間を見つけよう。ねらいマークに合わせてパーフェクト通過！';

  @override
  String get course_starTrail_instructions =>
      'グループの星を3つ全部集めると+5。星をつなげて最大3×。星でシールドが回復し、パーフェクト通過で星マグネット。どちらも星でアップグレードしよう！';

  @override
  String get course_classic_scoreLabel => '障害物';

  @override
  String get course_starTrail_scoreLabel => '星ポイント';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ゲート',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星ポイント',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics => 'クラシック：すき間をくぐって飛ぶ。';

  @override
  String get course_starTrail_previewSemantics => 'エンドレス：ハート3つとシールドで星を集める。';

  @override
  String get obstacle_garden_name => '庭のゲ⁠ー⁠ト';

  @override
  String get obstacle_windLift_name => '風のリ⁠フ⁠ト';

  @override
  String get obstacle_petalGate_name => '花びらシ⁠ャ⁠ッ⁠タ⁠ー';

  @override
  String get obstacle_switchback_name => 'ジ⁠グ⁠ザ⁠グ⁠ゲ⁠ー⁠ト';

  @override
  String get obstacle_lanternDrift_name => 'ゆらゆらラ⁠ン⁠タ⁠ン';

  @override
  String get obstacle_sunWheels_name => 'お日さま車輪';

  @override
  String get obstacle_crystalSteps_name => 'ク⁠リ⁠ス⁠タ⁠ルの階⁠段';

  @override
  String get rush_wildfire_name => '大火事';

  @override
  String get rush_wildfire_escape => '大火事から逃げきった';

  @override
  String get rush_skyfall_name => 'メテオフォール';

  @override
  String get rush_skyfall_escape => 'メテオフォールを生きのびた';

  @override
  String get rush_eruption_name => '噴火';

  @override
  String get rush_eruption_escape => '噴火をふりきった';

  @override
  String get rush_swarm_name => '大群';

  @override
  String get rush_swarm_escape => '大群をつきぬけた';

  @override
  String get boss_baronBat_title => '嵐の君主';

  @override
  String get boss_spitterBeetle_title => '群れの醸造王';

  @override
  String get boss_duskMoth_title => 'たそがれのベールの守り手';

  @override
  String get boss_pirate_title => '満潮の恐怖';

  @override
  String get boss_dragon_title => '燃える空の支配者';

  @override
  String get boss_kingCoo_title => '道ばた署長';

  @override
  String get boss_searchlightGargoyle_title => 'いちばん高い塔の見張り番';

  @override
  String get boss_neferhoo_title => '迷子の一通の番人';

  @override
  String get boss_baronBat_returnTitle => '嵐、ふたたび';

  @override
  String get boss_baronBat_barName => 'コウモリ男爵';

  @override
  String get boss_spitterBeetle_barName => 'ペッペ王';

  @override
  String get boss_duskMoth_barName => 'たそがれ女帝';

  @override
  String get boss_pirate_barName => '海賊船長';

  @override
  String get boss_dragon_barName => '残り火ドラゴン';

  @override
  String get boss_kingCoo_barName => 'キング・ポッポ';

  @override
  String get boss_searchlightGargoyle_barName => 'ガーゴイル';

  @override
  String get boss_neferhoo_barName => 'ネフェルフー';

  @override
  String get vanguard_baronBat_title => 'コウモリ男爵のコウモリたち';

  @override
  String get vanguard_baronBat_call => '来たぞ！すぐ後ろに男爵がいる！';

  @override
  String get vanguard_spitterBeetle_title => 'ペッペ王の子分たち';

  @override
  String get vanguard_spitterBeetle_call => '来たぞ！すぐ後ろにペッペ王がいる！';

  @override
  String get vanguard_duskMoth_title => '女帝の蛾たち';

  @override
  String get vanguard_duskMoth_call => '来たぞ！すぐ後ろに女帝がいる！';

  @override
  String get vanguard_kingCoo_title => 'キング・ポッポのポッポ隊';

  @override
  String get vanguard_kingCoo_call => '来たぞ！すぐ後ろにキング・ポッポがいる！';

  @override
  String get vanguard_kingCoo_callCrusts => '来たぞ！かたいパンの耳をよけて！';

  @override
  String get vanguard_kingCoo_callReturns => 'パンの耳をよけて！逃がしたハトはまた来るよ！';

  @override
  String get bossVanguardClear => 'クリア！';

  @override
  String get bossVanguardLeft => '体残り';

  @override
  String get bossStragglersCaught => '全員つかまえた！';

  @override
  String get bossHint_strongerBaronBat => 'パワーアップ · 3連ショット、コウモリたちも参戦！';

  @override
  String get bossHint_strongerSpitterBeetle => 'パワーアップ · 全開の扇撃ち、ペッペ虫も参戦！';

  @override
  String get bossHint_strongerDuskMoth => 'パワーアップ · 7発の扇撃ち、蛾たちも参戦！';

  @override
  String get bossHint_strongerPirate => 'パワーアップ · 潮目が変わるぞ！';

  @override
  String get bossHint_strongerDragon => 'パワーアップ · 火の息と群れに注意！';

  @override
  String get bossHint_strongerKingCoo => 'パワーアップ · 笛でポッポ隊を呼ぶぞ！';

  @override
  String get bossHint_strongerGargoyleFierce => 'パワーアップ · ランプが開くと石の羽根が降る！';

  @override
  String get bossHint_strongerGargoyle => 'パワーアップ · 石の羽根が降ってくる！';

  @override
  String get bossHint_strongerNeferhooTougher => 'パワーアップ · アンクと、ミイラコウモリ！';

  @override
  String get bossHint_strongerNeferhoo => 'パワーアップ · 金のアンクがもどってくる！';

  @override
  String get bossHint_tideRising => '潮が満ちてくる · 高く飛ぼう！';

  @override
  String get bossHint_highTide => '満潮 · 水の上をキープ';

  @override
  String get bossHint_tideFury => '激怒 · 波のあいまに一斉砲撃';

  @override
  String get bossHint_tideCalm => '砲弾をよけよう · 水に入らないで';

  @override
  String get bossHint_dragonSwarm => '大群 · コウモリをよけるか、ダッシュでつきぬけよう';

  @override
  String get bossHint_dragonFuryDebut => '激怒 · 火の玉が速くなる';

  @override
  String get bossHint_dragonFury => '激怒 · 火の玉がはじけて残り火に';

  @override
  String get bossHint_dragonCalm => '火の玉をよけよう · 火の息に注意';

  @override
  String get bossHint_screechFury => '激怒 · 火の玉が速く、コウモリも増える';

  @override
  String get bossHint_screechCalm => '火の玉とコウモリをよけよう · 超音波に注意';

  @override
  String get bossHint_cooPopped => 'パーン！ · ポッポ隊は来ない';

  @override
  String get bossHint_cooSquadron => 'ポッポ隊 · あいてるレーンを進もう！';

  @override
  String get bossHint_cooPuffed => '胸ふくらまし · 胸をショット（2倍）！';

  @override
  String get bossHint_cooCrumbBomb => 'パンくず爆弾 · 輪から出よう！';

  @override
  String get bossHint_cooFury => '激怒 · 輪と輪のあいだにいよう';

  @override
  String get bossHint_cooCalm => 'パンくず爆弾をよけよう · 胸がふくらんだらショット';

  @override
  String get bossHint_beamOn => 'サーチライト · 暗がりにいよう';

  @override
  String get bossHint_beamFury => '激怒 · 光と光のすき間をぬけよう';

  @override
  String get bossHint_beamIncomingHigh => '光が来る · 低く飛ぼう！';

  @override
  String get bossHint_beamIncomingLow => '光が来る · 高く飛ぼう！';

  @override
  String get bossHint_lampOpen => 'ランプが開いた · ランプをショット！';

  @override
  String get bossHint_shuttersClosed => 'シャッターが閉じた · ショットは温存';

  @override
  String get bossHint_mothFuryNoVeil => '激怒 · 7発の扇撃ち。まだベールはない！';

  @override
  String get bossHint_mothNoVeil => 'まだベールはない · 扇のすき間に撃ちこもう！';

  @override
  String get bossHint_mothShielded => 'ベールで防御中 · ベールが落ちるまでよけよう';

  @override
  String get bossHint_mothShieldForming => 'ベールを作り中 · よける準備を';

  @override
  String get bossHint_mothFury => '激怒 · 7発の扇撃ち。ベールが落ちた！';

  @override
  String get bossHint_mothCalm => 'ベールが落ちた · 扇のすき間に撃ちこもう！';

  @override
  String get bossHint_neferhooMailCall => '郵便ですぞ！ · 撃ち返そう！';

  @override
  String get bossHint_neferhooReturn => '差出人に返送！ · −25';

  @override
  String get bossHint_neferhooReturnFaster => '差出人に返送！ · −18';

  @override
  String get bossHint_neferhooAnkh => 'アンク · もどってくるよ！';

  @override
  String get bossHint_neferhooExpress => '速達便 · 5通、もっと速く';

  @override
  String get bossHint_neferhooTwoAnkhs => 'アンク2つ · どちらのレーンもさけよう';

  @override
  String get bossHint_neferhooBats => 'ミイラコウモリ · 撃ち落とそう！';

  @override
  String get bossHint_neferhooScuff => '石では包帯がすれるだけ。「手紙」を撃ち返そう！';

  @override
  String get bossHint_neferhooWarmUp => '手紙を撃ち返そう · 差出人に返送';

  @override
  String get bossHint_neferhooCalm => '手紙を撃ち返そう · 金のアンクをよけよう';

  @override
  String get bossHint_neferhooFury => '激怒 · 速達便とアンク2つ';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'ドラゴンの火の息 · 低く飛ぼう！心臓が開いてる',
      'middle': 'ドラゴンの火の息 · 上か下へ！心臓が開いてる',
      'other': 'ドラゴンの火の息 · 高く飛ぼう！心臓が開いてる',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': '火の息 · 低く飛ぼう！光る心臓をねらえ',
      'middle': '火の息 · 上か下へ！光る心臓をねらえ',
      'other': '火の息 · 高く飛ぼう！光る心臓をねらえ',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': '超音波 · 上のすき間へ！',
      'middle': '超音波 · まん中のすき間へ！',
      'other': '超音波 · 下のすき間へ！',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': '超音波 · 上のすき間をキープ',
      'middle': '超音波 · まん中のすき間をキープ',
      'other': '超音波 · 下のすき間をキープ',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth => '扇撃ちをよけて  ·  ベールが落ちたらショット';

  @override
  String get encounterCaption_pirate => '大砲をよけて  ·  水に入らないで';

  @override
  String get encounterCaption_dragon => '火の玉をよけて  ·  火の息から逃げて';

  @override
  String get encounterCaption_kingCoo => '輪から出て  ·  胸がふくらんだらショット';

  @override
  String get encounterCaption_searchlightGargoyle => '光に入らないで  ·  ランプが開いたらショット';

  @override
  String get encounterCaption_neferhoo => '準備して  ·  手紙を撃ち返そう';

  @override
  String get encounterCaption_screech => '超音波が来たら  ·  すき間へ飛ぼう';

  @override
  String get encounterCaption_default => '準備して  ·  はばたいて、よけて、撃とう';

  @override
  String get encounterCoasting => 'きみの鳥は安全に飛んでいるよ';

  @override
  String get encounterOpenSky => 'ひろい空へもどろう';

  @override
  String get encounterOmenTitle_duskMoth => 'たそがれが羽ばたく';

  @override
  String get encounterOmenLine_duskMoth => 'たそがれに、絹のベールが集まっていく…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'なにかが煮えている';

  @override
  String get encounterOmenLine_spitterBeetle => '空気がシュワシュワしはじめた…';

  @override
  String get encounterOmenTitle_dragon => '空が燃えあがる';

  @override
  String get encounterOmenLine_dragon => '雲の上で、大きな翼がはばたいている…';

  @override
  String get encounterOmenTitle_kingCoo => '道ばた、通行止め';

  @override
  String get encounterOmenLine_kingCoo => 'だれかさんが、パンの屋台のことでカンカンだ…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => '暴風警報';

  @override
  String get encounterOmenLine_searchlightGargoyle => 'ビルのでっぱりで、なにかが見張っている…';

  @override
  String get encounterOmenTitle_neferhoo => 'ピラミッドが目覚める';

  @override
  String get encounterOmenLine_neferhoo => 'ピラミッドのほこりが舞いはじめた…';

  @override
  String get encounterOmenTitle_baronReturns => '男爵、ふたたび';

  @override
  String get encounterOmenLine_baronReturns => 'あいつが帰ってきた。しかも、ずっとうるさく…';

  @override
  String get encounterOmenTitle_default => '影が近づく';

  @override
  String get encounterOmenLine_default => 'この空は、だれかのものになっている…';

  @override
  String get encounterOmenTitle_pirate => '帆が見えたぞ！';

  @override
  String get encounterOmenLine_pirate => '満ちる潮にのって、船がやってくる…';

  @override
  String get bossGuardianEyebrow => 'ガーディアン';

  @override
  String bossEncounterEyebrow(String number) {
    return '遭遇 $number';
  }

  @override
  String get bossGuardianDown => 'ガーディアン撃破';

  @override
  String get bossSkyReclaimed => '空をとりもどした';

  @override
  String bossVictoryPoints(int points) {
    return '+$pointsポイント   ·   シールド回復';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'コウモリ男爵をたおした',
      'spitterBeetle': 'ペッペ王をたおした',
      'duskMoth': 'たそがれ女帝をたおした',
      'pirate': '海賊船長をたおした',
      'dragon': '残り火ドラゴンをたおした',
      'kingCoo': 'キング・ポッポをたおした',
      'searchlightGargoyle': 'サーチライト・ガーゴイルをたおした',
      'other': 'ネフェルフーをたおした',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '「$line」';
  }

  @override
  String get bossPirateRoar => 'ヨホー!';

  @override
  String get bossGargoyleCardSmall => 'サーチライト';

  @override
  String get bossGargoyleCardBig => 'ガーゴイル';

  @override
  String get bossGargoyleCardOrder => 'small-big';

  @override
  String get bossDodgeFlyLow => '低く飛ぼう';

  @override
  String get bossDodgeFlyHigh => '高く飛ぼう';

  @override
  String get bossDodgeClimbOrDive => '上か下へ';

  @override
  String get bossDodgeSlipBetween => '光のすき間を\nすりぬけよう';

  @override
  String get bossSpotted => 'バレた！';

  @override
  String get bossShieldLost => 'シールド消失';

  @override
  String get bossHeartLost => '-1ハート';

  @override
  String get bossGargoyleLampOpen => 'ランプ開いた';

  @override
  String get bossGargoyleShoot => 'ショット';

  @override
  String get bossScreechFlyToGap => 'すき間へ飛ぼう';

  @override
  String get bossScreechHoldGap => 'すき間をキープ';

  @override
  String get bossPirateHighTide => '満潮';

  @override
  String get bossBarDefeated => '撃破';

  @override
  String get bossBarIncoming => '接近中';

  @override
  String get bossBarFury => '激怒';

  @override
  String get bossBarHeartDouble => '心臓×2';

  @override
  String get bossStronger => 'パワーアップ！';

  @override
  String get bossKingCooPuffed => 'ふくらみ';

  @override
  String get bossKingCooShout => 'ポッポー';

  @override
  String get bossKingCooPop => 'パーン！';

  @override
  String get bossKingCooPoof => 'ボフン！';

  @override
  String get bossSquadOpenLane => 'あいてるレーンへ';

  @override
  String get bossSquadUseGap => 'すき間をぬけよう';

  @override
  String get bossSquadThenV => '次：V字';

  @override
  String get bossSquadThenGap => '次：すき間';

  @override
  String get bossSquadCancelled => 'ポッポ隊は中止';

  @override
  String get bossNeferhooFound => '迷子の手紙が見つかった';

  @override
  String get bossNeferhooHoo => 'ホー';

  @override
  String get bossNeferhooPoo => 'ポー';

  @override
  String get bossNeferhooMailCall => '郵便ですぞ！';

  @override
  String get bossNeferhooExpressPost => '速達便';

  @override
  String get bossNeferhooShootBack => '撃ち返そう！';

  @override
  String get bossNeferhooAnkh => 'アンク';

  @override
  String get bossNeferhooTwoAnkhs => 'アンク2つ';

  @override
  String get bossNeferhooComesBack => 'もどってくるよ！';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '大火事だ！',
      'skyfall': 'メテオフォール！',
      'eruption': '噴火だ！',
      'other': '大群だ！',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'ダッシュリングを取って逃げきろう！',
      'skyfall': 'ダッシュリングを取って、いん石と競争だ！',
      'eruption': 'ダッシュリングを取って、噴火をかわそう！',
      'other': 'ダッシュリングを取って、つきぬけよう！',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return '逃げきった！+$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'ノーミス！+$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '大火事から逃げきった',
      'skyfall': 'メテオフォールを生きのびた',
      'eruption': '噴火をふりきった',
      'other': '大群をつきぬけた',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => '突風！';

  @override
  String encounterGaleDetail(String mark) {
    return '$markが光ったところのがらくたをよけよう！';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'のりきった！+$points';
  }

  @override
  String get encounterGaleWeatheredDetail => '突風をのりきった';

  @override
  String get encounterAllRings => 'リング全部！';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'ターボブースト+$seconds秒';
  }

  @override
  String get encounterFinish => 'ゴール';

  @override
  String get builderMode_pushUp => '腕立て';

  @override
  String get builderMode_squat => 'スクワット';

  @override
  String get builderMode_jump => 'ジャンプ';

  @override
  String builderSeconds(String seconds) {
    return '$seconds秒';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '腕立て$count回',
      one: '腕立て1回',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'スクワット$count回',
      one: 'スクワット1回',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'マイタップレベル';

  @override
  String get builderNewLevel_pushUp => 'マイ腕立てレベル';

  @override
  String get builderNewLevel_squat => 'マイスクワットレベル';

  @override
  String get builderNewLevel_jump => 'マイジャンプレベル';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'マイレベル';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Beakboundで作ったレベル「$name」（$mode）を飛んでみて！$code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '星$total個中$earned個';
  }

  @override
  String get builderBackSemantics => 'もどる';

  @override
  String get builderKeepIt => '残しておく';

  @override
  String builderLessSemantics(String name) {
    return '$nameを減らす';
  }

  @override
  String builderMoreSemantics(String name) {
    return '$nameを増やす';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => '複製';

  @override
  String get builderCopy => 'コピー';

  @override
  String get builderDeleteSemantics => '削除';

  @override
  String get builderDelete => '削除';

  @override
  String get builderMoreBelow => '下にもあるよ';

  @override
  String builderStepSemantics(String caption, String value) {
    return '$caption $value';
  }

  @override
  String builderStepHintSemantics(String caption, String value, String hint) {
    return '$caption $value、$hint';
  }

  @override
  String builderPercent(int percent) {
    return '$percent%';
  }

  @override
  String get builderLane => 'レーン';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'スクワットの上か下',
      'other': '腕立ての上か下',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => '上';

  @override
  String get builderLaneBottom => '下';

  @override
  String get builderHeight => '高さ';

  @override
  String get builderHeightHint => '空の高さに対して';

  @override
  String get builderLowerSemantics => '下げる';

  @override
  String get builderHigherSemantics => '上げる';

  @override
  String get builderOpening => 'すき間';

  @override
  String builderOpeningHint(int percent) {
    return '$percent%以上';
  }

  @override
  String get builderNarrowerSemantics => 'せまくする';

  @override
  String get builderWiderSemantics => 'ひろくする';

  @override
  String get builderMotion => '動き';

  @override
  String get builderMotionGardenHint => '庭のゲートは動かない';

  @override
  String get builderMotionStill => '静止';

  @override
  String get builderMotionGentle => '小さく';

  @override
  String get builderMotionLively => '大きく';

  @override
  String get builderMotionGardenToast => '庭のゲートは動きません。動かすにはほかの種類を選んでね。';

  @override
  String get builderSway => 'ゆれ';

  @override
  String builderSwayHint(String seconds) {
    return '1回のゆれ：$seconds';
  }

  @override
  String get builderSwayFast => '速い';

  @override
  String get builderSwayMedium => 'ふつう';

  @override
  String get builderSwaySlow => 'ゆっくり';

  @override
  String get builderPhase => '到着したとき';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position/$count';
  }

  @override
  String get builderPhaseHint => 'ゆれのどの位置にいるか';

  @override
  String get builderPhaseEarlierSemantics => 'ゆれの前のほうへ';

  @override
  String get builderPhaseLaterSemantics => 'ゆれの後のほうへ';

  @override
  String get builderLook => '見た目';

  @override
  String builderLookSemantics(int number) {
    return '見た目$number';
  }

  @override
  String get builderDoor => '石の扉';

  @override
  String get builderDoorHint => 'ショットでこわせる';

  @override
  String get builderDoorNone => '扉なし';

  @override
  String get builderDoorNeedsShootToast => '扉を使うには、レベル設定でショットをONにしてね。';

  @override
  String get builderPlace => '位置';

  @override
  String get builderPlaceHint => 'スタートから';

  @override
  String get builderEarlierSemantics => '前へ';

  @override
  String get builderLaterSemantics => '後ろへ';

  @override
  String builderFamilySemantics(String family) {
    return 'ゲートの種類：$family。変更';
  }

  @override
  String get builderChangeFamily => '種類を変える';

  @override
  String get builderItemStar => '星';

  @override
  String get builderItemTrio => '星トリオ';

  @override
  String get builderItemHeart => 'ハート';

  @override
  String get builderItemEnemy => '敵';

  @override
  String get builderItemGate => 'ゲート';

  @override
  String get builderItemStarDetail => '集める星が1個';

  @override
  String get builderItemTrioDetail => '3つそろえてボーナス';

  @override
  String get builderItemHeartDetail => 'ハートが1つもどる';

  @override
  String get builderEnemyKind => '種類';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '鳥はスクワットの上と下を飛ぶよ。アイテムは黄色い線の上か、線のあいだに置こう。',
      'other': '鳥は腕立ての上と下を飛ぶよ。アイテムは黄色い線の上か、線のあいだに置こう。',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'ムラサキコウモリ';

  @override
  String get builderEnemy_caveBat => 'ホラアナコウモリ';

  @override
  String get builderEnemy_spitterBeetle => 'ペッペ虫';

  @override
  String get builderEnemy_duskMoth => 'たそがれ蛾';

  @override
  String get builderEnemy_alleyPigeon => '路地裏バト';

  @override
  String get builderEnemy_mummyBat => 'ミイラコウモリ';

  @override
  String get builderSummaryTitle => 'このレベル';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode・$region';
  }

  @override
  String get builderFactLength => '長さ';

  @override
  String get builderFactStars => '星';

  @override
  String get builderFactMarks => '目盛り';

  @override
  String get builderFactWorkout => '運動';

  @override
  String get builderFactPace => 'ペース';

  @override
  String get builderFactBoss => 'ボス';

  @override
  String get builderPace_relaxed => 'のんびり';

  @override
  String get builderPace_steady => 'ふつう';

  @override
  String get builderPace_brisk => 'きびきび';

  @override
  String get builderSummaryStarterNote => 'そのまま飛べるお手本レベル。リミックスして自分のレベルにもできるよ。';

  @override
  String get builderSummaryClearedNote => '自分でクリア済み：最後まで飛びきったよ。';

  @override
  String get builderSummaryClearNote => 'テスト飛行でゴールまで飛ぶと、クリア済みになるよ。';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    return 'テスト飛行で$bossをたおしてゴールすると、クリア済みになるよ。';
  }

  @override
  String get builderSummaryHowTo =>
      '左の道具を選んで、空をタップ。置いたものをタップすると変更、ドラッグで移動できるよ。';

  @override
  String get builderFamily_garden_detail => '動かない。石の扉をつけられる。';

  @override
  String get builderFamily_windLift_detail => 'すき間が上がったり下がったりする。';

  @override
  String get builderFamily_petalGate_detail => 'すき間がせまくなったり、ひろくなったりする。';

  @override
  String get builderFamily_switchback_detail => '2つのすき間がずれて離れる。';

  @override
  String get builderFamily_lanternDrift_detail => 'ぶら下がったラ⁠ン⁠タ⁠ンがゆらゆらゆれる。';

  @override
  String get builderFamily_sunWheels_detail => '車輪が近づいたり離れたりする。';

  @override
  String get builderFamily_crystalSteps_detail => '3段の階⁠段が波のように動く。';

  @override
  String get builderFamiliesCloseSemantics => 'ゲートの種類を閉じる';

  @override
  String get builderFamiliesTitle => 'ゲートの種類';

  @override
  String get builderFamiliesSubtitle => 'ゲートの見た目と動き方。';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family。$detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'レベルに$count文字までの名前をつけよう。',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort => 'ゴールをもっと先へ。レベルが短すぎるよ。';

  @override
  String get reach_tooLong => 'ゴールをもっと手前へ。レベルが長すぎるよ。';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '置きすぎ！1つのレベルには$count個までだよ。',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap => 'ボスで終わるのはタップ＆フライのレベルだけ。';

  @override
  String get reach_noGates => '鳥がくぐるゲートを置こう。';

  @override
  String get reach_startZone => 'スタートに近すぎるよ。スタート地点の外へ動かそう。';

  @override
  String get reach_finishRoom => 'このゲートのあと、ゴールまでに余裕をあけよう。';

  @override
  String get reach_overlap => 'ゲートが重なってるよ。離して置こう。';

  @override
  String get reach_gateHeight => 'このゲートは高すぎるか、低すぎるよ。';

  @override
  String get reach_gateMotion => 'このゲートはその動き方ができないよ。';

  @override
  String get reach_gateLook => 'このゲートの見た目が不明です。';

  @override
  String get reach_gateNarrow => 'このゲートをもっとひろげて。鳥が通れないよ。';

  @override
  String get reach_gateWide => 'このゲートはひろすぎるよ。';

  @override
  String get reach_doorNeedsShoot => '石の扉には、ショットONのタップ＆フライが必要だよ。';

  @override
  String get reach_doorNeedsGarden => '石の扉をつけられるのは庭のゲートだけ。';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '切りかえがギリギリ：ふつうのスクワットだと間に合わないかも。',
      'other': '切りかえがギリギリ：ふつうの腕立てだと間に合わないかも。',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb => '急な上り：このゲートまでジャンプできるよう、もっと間をあけよう。';

  @override
  String get reach_enemyNeedsTap => '敵が飛ぶのはタップ＆フライのレベルだけ。';

  @override
  String get reach_outsideSky => '空の中に置こう。';

  @override
  String get reach_pastFinish => 'ゴールより前に置こう。';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'スクワットでは届かないよ。レーンの近くへ動かそう。',
      'other': '腕立てでは届かないよ。レーンの近くへ動かそう。',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => '壁の中だよ。すき間に動かそう。';

  @override
  String get reach_noStars => '星を1個以上置こう。';

  @override
  String get reach_marks => '星の目盛りが、置いた星の数より多いよ。';

  @override
  String reach_cannotFly(String problem) {
    return 'このレベルはまだ飛べません（$problem）。';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'レベルを保存できなかったので、まだ飛べないよ。名前をタップしてもう一度。';

  @override
  String get builderShareBlockedToast => 'まず赤い旗を直そう。そうすれば共有できるよ。';

  @override
  String get builderEditorBackSemantics => 'ビルダーにもどる';

  @override
  String get builderSettingsSemantics => 'レベル設定';

  @override
  String get builderFly => '飛ぶ';

  @override
  String get builderTestFly => 'テスト飛行';

  @override
  String get builderFlySemantics => 'このレベルを飛ぶ';

  @override
  String get builderTestFlySemantics => 'レベル全体をテスト飛行';

  @override
  String get builderUndoSemantics => '元に戻す';

  @override
  String get builderRedoSemantics => 'やり直し';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: 'ヒント$advice個',
    );
    return '直すところ$blocking個、$_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: 'ヒント$advice個',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => '飛ぶ準備OK';

  @override
  String get builderShareSemantics => '共有コード';

  @override
  String get builderFromHereSemantics => 'ここからテスト飛行';

  @override
  String get builderFromHere => 'ここから';

  @override
  String get builderStatusStarter => 'お手本レベル・見る、飛ぶ、リミックス';

  @override
  String get builderStatusSaveFailed => '保存できなかった・タップでもう一度';

  @override
  String get builderStatusSaving => '保存中…';

  @override
  String get builderStatusSaved => 'すべて保存しました';

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
    return '$name。$mode。$status。タップで名前を変更。';
  }

  @override
  String get builderStarterBanner => 'リミックスして自分のものに';

  @override
  String get builderRemix => 'リミックス';

  @override
  String get builderRemixSemantics => 'リミックス';

  @override
  String get builderIssuesCloseSemantics => '直すところとヒントを閉じる';

  @override
  String get builderIssuesReadyTitle => '飛ぶ準備OK！';

  @override
  String get builderIssuesFixTitle => '飛ぶ前に直すところ';

  @override
  String get builderIssuesTipsTitle => '準備OK、ヒントつき';

  @override
  String get builderIssuesReadyDetail => '直すところはなし。ゴールまでテスト飛行してクリアしよう。';

  @override
  String get builderIssuesDetail => 'タップすると、ルート上のその場所へ行けるよ。';

  @override
  String get builderSettingsCloseSemantics => '設定を閉じる';

  @override
  String get builderSettingsTitle => 'レベル設定';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode・変更はすぐに保存されます';
  }

  @override
  String get builderSettingsName => '名前';

  @override
  String get builderRename => '名前を変える';

  @override
  String get builderRenameSemantics => '名前を変える';

  @override
  String get builderSettingsRegion => '地域';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countか所・スワイプでもっと',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'ペース';

  @override
  String get builderSettingsPaceHint => '空が流れる速さ';

  @override
  String get builderSettingsMarks => '星の目盛り';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星を$count個配置',
      one: '星を1個配置',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => '星2つの目盛り';

  @override
  String get builderMarkThreeSemantics => '星3つの目盛り';

  @override
  String get builderMarksAuto => '自動：星の数に合わせる';

  @override
  String get builderMarksByHand => '手動で決める';

  @override
  String get builderSettingsControls => '操作';

  @override
  String get builderShootOn => 'ショットON';

  @override
  String get builderShootOff => 'ショットOFF';

  @override
  String get builderSprintOn => 'ダッシュON';

  @override
  String get builderSprintOff => 'ダッシュOFF';

  @override
  String get builderSettingsBoss => 'ボスで締める';

  @override
  String get builderSettingsBossHint => '最後に待ちかまえる';

  @override
  String get builderNoBossSemantics => 'ボスなし：ゴールで終わる';

  @override
  String get builderNoBoss => 'なし';

  @override
  String get builderBossShort_baronBat => '男爵';

  @override
  String get builderBossShort_spitterBeetle => 'ペッペ王';

  @override
  String get builderBossShort_duskMoth => '女帝';

  @override
  String get builderBossShort_pirate => '船長';

  @override
  String get builderBossShort_dragon => 'ドラゴン';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          '鳥は2つのレーンを飛ぶよ：スクワットの上と下。ゆっくりな人には、同じレベルがやさしい速さになるよ。ここではショット、ダッシュ、ボスはなし。',
      'other':
          '鳥は2つのレーンを飛ぶよ：腕立ての上と下。ゆっくりな人には、同じレベルがやさしい速さになるよ。ここではショット、ダッシュ、ボスはなし。',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'ジャンプするたびに鳥が上がり、そのあいだはグライドするよ。ここではショット、ダッシュ、ボスはなし。';

  @override
  String get builderStartZoneToast => 'スタート地点はあけておこう。点線より右に置いてね。';

  @override
  String get builderSkySemantics => 'レベルの空。タップで配置、ドラッグで移動やスクロール。';

  @override
  String get builderSkyReadOnlySemantics => 'レベルの空。タップするとよく見られるよ。';

  @override
  String get builderCoachTitle => 'レベルを作ろう';

  @override
  String get builderCoachPickTool => '左の道具を選ぶ';

  @override
  String get builderCoachTapSky => '空をタップして置く';

  @override
  String get builderCoachTestFly => 'テスト飛行しよう！';

  @override
  String get builderCoachDrag => '置いたものはドラッグで移動・空はドラッグでスクロール';

  @override
  String get builderTipDrag => 'ドラッグで移動・空をドラッグでスクロール';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'スクワットの上',
      'other': '腕立ての上',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => '上';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'スクワットの下',
      'other': '腕立ての下',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => '下';

  @override
  String get builderCanvasStartZoneFull => 'スタート地点・空けておく';

  @override
  String get builderCanvasStartZone => 'スタート地点';

  @override
  String get builderCanvasFinishHere => 'ここがゴール';

  @override
  String get builderTool_select => '選択';

  @override
  String get builderToolHint_select => '選択：タップで変更、ドラッグで移動';

  @override
  String get builderTool_gate => 'ゲート';

  @override
  String get builderToolHint_gate => 'ゲート：空をタップしてゲートを置く';

  @override
  String get builderTool_star => '星';

  @override
  String get builderToolHint_star => '星：空をタップして星を置く';

  @override
  String get builderTool_trio => 'トリオ';

  @override
  String get builderToolHint_trio => '星トリオ：空をタップして星を3つ置く';

  @override
  String get builderTool_heart => 'ハート';

  @override
  String get builderToolHint_heart => 'ハート：空をタップしてハートを置く';

  @override
  String get builderTool_enemy => '敵';

  @override
  String get builderToolHint_enemy => '敵：空をタップして敵を置く';

  @override
  String get builderTool_finish => 'ゴール';

  @override
  String get builderToolHint_finish => 'ゴール：空をタップしてゴールを動かす';

  @override
  String get builderTool_boss => 'ボス';

  @override
  String get builderToolHint_boss => 'ボスの位置：空をタップしてボスの待つ場所を動かす';

  @override
  String get builderStarterToolsToast => 'お手本レベルはそのまま。変えるならリミックスしてね。';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss': 'ルートの全体図。ボスまで$length。ドラッグでルートを移動。',
      'other': 'ルートの全体図。ゴールまで$length。ドラッグでルートを移動。',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss': 'ルートの全体図。ボスまで$length。$reps。ドラッグでルートを移動。',
      'other': 'ルートの全体図。ゴールまで$length。$reps。ドラッグでルートを移動。',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return 'ボスまで$length';
  }

  @override
  String get builtResultTestFlight => 'テスト飛行';

  @override
  String get builtResultCleared => 'クリア！';

  @override
  String get builtResultBonk => 'ゴツン！';

  @override
  String get builtResultLanded => '着地';

  @override
  String get builtResultTestTab => 'テスト';

  @override
  String get builtResultGoalFinish => 'ゴール';

  @override
  String get builtResultGoalBoss => 'ボス';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal。';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal。クリア。';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星を$count個集める。',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星を$count個集める。クリア。',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'クリア';

  @override
  String get builtResultNotYet => 'まだ';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと$count個',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'まずはゴール';

  @override
  String get builtResultClearedByYou => '自分でクリア済み';

  @override
  String get builtResultNewBest => 'ベスト更新！';

  @override
  String get builtResultPractice => '練習';

  @override
  String builtResultBest(int count) {
    return 'ベスト$count';
  }

  @override
  String get builtResultFirstClear => '初クリア！';

  @override
  String get builtResultStarsCollected => '集めた星';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'レベルの星3つ中$countつ',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => '必要な回数';

  @override
  String get builtResultWorkout => '運動';

  @override
  String get builtResultGotTo => '到達';

  @override
  String get builtResultScore => 'スコア';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回の腕立て',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回のスクワット',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回のジャンプ',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回の腕立て（カメラ）',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回スクワット（カメラ）',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return '全$length中';
  }

  @override
  String get builtResultNotKept => '記録されない';

  @override
  String get builtResultNoBest => 'まだベストなし';

  @override
  String get builtResultClearedStrip => '自分でクリア済み・共有できるよ！';

  @override
  String builtResultFlownFrom(String from) {
    return '$fromから飛んだよ。クリアするには最初から全部飛ぼう。';
  }

  @override
  String get builtResultTestNothingSaved => 'テスト飛行・保存されません';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'テスト飛行・$length中$reachedまで到達';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return '$length中$reachedまで到達。ゴールして星をゲット。';
  }

  @override
  String get builtResultReachFinish => 'ゴールすると星がもらえるよ。';

  @override
  String get builtResultSaved => 'このスマホに保存しました';

  @override
  String get builtResultSaving => 'フライトを保存中…';

  @override
  String get builtResultBuilder => 'ビルダー';

  @override
  String get builtResultEditLevel => 'レベルを編集';

  @override
  String get builtResultEdit => '編集';

  @override
  String get builtResultFlyAgain => 'もう一度飛ぶ';

  @override
  String get builtResultWatchReplay => 'リプレイを見る';

  @override
  String get builtResultPreparing => '準備中…';

  @override
  String get builtResultSessionSaving => '保存中…';

  @override
  String get builtResultSaveSession => 'フライトを保存';

  @override
  String get builderShelfTitle => 'レベルビルダー';

  @override
  String get builderShelfPasteCode => 'コードを貼りつけ';

  @override
  String get builderShelfNewLevel => '新しいレベル';

  @override
  String get builderShelfSaveFailed => '保存できなかったよ。もう一度試してね。';

  @override
  String builderShelfDeleteTitle(String name) {
    return '「$name」を削除する？';
  }

  @override
  String get builderShelfDeleteBody =>
      'ベスト記録もいっしょに消えるよ。このレベルで飛んだ腕立て、スクワット、ジャンプの回数はそのまま残るよ。';

  @override
  String get builderShelfDelete => '削除';

  @override
  String builderShelfDeleted(String name) {
    return '「$name」を削除しました。';
  }

  @override
  String get builderShelfFixFirst => '共有する前に赤いところを直そう：「直す」をタップ。';

  @override
  String get builderShelfCodeCopied => 'コードをコピーしたよ！友だちに貼りつけて送ろう。';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'コードをコピーしたよ！自分でもゴールまで飛んでおくと、クリアできるって友だちにわかるよ。';

  @override
  String get builderShelfNotReady => 'このレベルはまだ飛べないよ：「直す」をタップ。';

  @override
  String get builderShelfPasteMissingTitle => '貼りつけるレベルコードがないよ';

  @override
  String get builderShelfPasteNewerTitle => 'もっと新しいBeakboundで作られたレベル';

  @override
  String get builderShelfPasteDamagedTitle => 'コードがごちゃまぜになってる';

  @override
  String get builderShelfPasteMissingBody =>
      '友だちのレベルコード（BEAK1.ではじまるよ）をコピーして、もう一度「コードを貼りつけ」をタップしてね。';

  @override
  String get builderShelfPasteNewerBody => 'Beakboundを更新してから、もう一度コードを貼りつけてね。';

  @override
  String get builderShelfPasteDamagedBody =>
      '一部が欠けているか、まちがっているみたい。友だちにコード全体をもう一度コピーしてもらおう。';

  @override
  String builderShelfImported(String name) {
    return '「$name」をたなに追加したよ！';
  }

  @override
  String get builderShelfUnavailable => 'レベルを読み込めなかったよ。';

  @override
  String get builderShelfMine => '自分のレベル';

  @override
  String get builderShelfStarters => 'お手本レベル';

  @override
  String get builderShelfStartersHint => 'そのまま飛ぶか、リミックスして自分のレベルにしよう';

  @override
  String get builderShelfEmptyTitle => 'はじめてのレベルを作ろう';

  @override
  String get builderShelfEmptyBody => 'ゲートや星、ハートを自分で置いて、ゴールを決めたらテスト飛行しよう。';

  @override
  String get builderShelfPasteFriend => '友だちのコードを貼りつけ';

  @override
  String get builderShelfNeedsWork => '直しが必要';

  @override
  String get builderShelfClearedByYou => '自分でクリア済み';

  @override
  String get builderShelfFromFriend => '友だちから';

  @override
  String get builderShelfFly => '飛ぶ';

  @override
  String builderShelfFlySemantics(String name) {
    return '$nameを飛ぶ';
  }

  @override
  String get builderShelfFixIt => '直す';

  @override
  String builderShelfFixSemantics(String name) {
    return '$nameを直す';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return '$nameを編集';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return '$nameを共有';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return '$nameを共有：クリア済み';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return '$nameのその他の操作';
  }

  @override
  String get builderShelfRemix => 'リミックス';

  @override
  String builderShelfRemixSemantics(String name) {
    return '$nameをリミックス';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'エディターで直すところが$countつ',
      one: 'エディターで直すところが1つ',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星$count個',
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
    return '$name。$regionで$mode。$length。';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'ベストは星3つ中$starsつ。',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '直しが必要：直すところが$countつ。',
      one: '直しが必要：直すところが1つ。',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => '自分でクリア済み。';

  @override
  String get builderShelfFromFriendSemantics => '友だちから。';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return '$nameを見る。$mode、$length、$fact。';
  }

  @override
  String get builderShelfRemixSuffix => 'リミックス';

  @override
  String get builderShelfCopySuffix => 'コピー';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get starter_t_tap_1_name => 'お庭ぴょんぴょん';

  @override
  String get starter_t_push_1_name => '腕立て10回';

  @override
  String get starter_t_squat_1_name => '階段スクワット';

  @override
  String get starter_t_jump_1_name => 'ぴょんぴょん湾';

  @override
  String get starter_t_tap_boss_name => '男爵の橋';

  @override
  String get builderPickCloseNewLevel => '新しいレベルを閉じる';

  @override
  String get builderPickModeTitle => 'どんなレベルにする？';

  @override
  String get builderPickRegionTitle => 'どこを飛ぶ？';

  @override
  String get builderPickModeSubtitle =>
      '飛び方を選ぼう（あとから変えられないよ）。テスト飛行はどのレベルもタッチで飛ぶよ。';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode・飛ぶ場所を選ぼう。あとから変えられるよ。';
  }

  @override
  String get builderPickTouchLine => 'タップではばたく。ゲート、星、敵、ボスも。';

  @override
  String get builderPickPushUpLine => '高いレーンと低いレーン：下がるたびに腕立て1回。';

  @override
  String get builderPickSquatLine => '高いレーンと低いレーン：下がるたびにスクワット1回。';

  @override
  String get builderPickJumpLine => 'ジャンプで上昇。ゲートは空のどこにでも。';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode。$line';
  }

  @override
  String get builderPickCamera => 'カメラ';

  @override
  String get builderPickSuggested => 'おすすめ';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region、おすすめ';
  }

  @override
  String get builderPickClose => '閉じる';

  @override
  String get builderPickNotYet => 'まだだよ：先に赤いところを直そう。';

  @override
  String get builderPickShare => '共有コード';

  @override
  String get builderPickShareLine => '友だちが自分のBeakboundに貼りつけられるコードをコピー。';

  @override
  String get builderPickDuplicate => '複製';

  @override
  String get builderPickDuplicateLine => 'コピーを作って、ほかのアイデアを試そう。';

  @override
  String get builderPickDeleteLine => 'レベルをすてる。先に確認するよ。';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode・$region';
  }

  @override
  String get builderPickCancelImport => '読み込みをやめる';

  @override
  String get builderPickImportTitle => '飛べるレベルが届いたよ！';

  @override
  String get builderPickImportSubtitle => 'だれかがこのレベルをシェアしてくれたよ。';

  @override
  String get builderPickClearedByMaker => '作者がクリア済み';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '集める星$count個',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    return '$bossで終わる';
  }

  @override
  String get builderPickNotFlown => '作者はまだ最後まで飛んでいないよ。';

  @override
  String get builderPickRoute => 'ルート';

  @override
  String builderPickAlreadyHave(String name) {
    return 'このレベルはもう持ってるよ：「$name」。';
  }

  @override
  String get builderPickImportCopy => 'コピーを追加';

  @override
  String get builderPickOpenYours => '自分のを開く';

  @override
  String get builderPickImport => '追加する';

  @override
  String get builderShelfRenameCancelSemantics => '名前の変更をやめる';

  @override
  String get builderShelfRenameTitle => 'レベルに名前をつけよう';

  @override
  String get builderShelfRenameEmpty => '名前には1文字以上必要だよ';

  @override
  String get builderShelfRenameSaveSemantics => '名前を保存';

  @override
  String get builderShelfRenameSave => '保存';

  @override
  String get coopMode_roped => 'ロープあり';

  @override
  String get coopMode_free => 'ロープなし';

  @override
  String get coopMode_duel => '1対1';

  @override
  String get coopTitle => 'いっしょに飛ぼう';

  @override
  String get coopPlayersTag => '2人プレイ・スマホ1台';

  @override
  String coopBestTag(String mode, int best) {
    return '$modeベスト$best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode：まだベストなし';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode・$count回対戦',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode：はじめての対戦';
  }

  @override
  String get coopRopedLead => '2羽の鳥は1本のロープでつながってるよ。';

  @override
  String get coopRopedBody =>
      'いっしょにはばたいて高く上がろう。1羽だけでも2羽とも上がるけど、ちょっとだけ。ダッシュで相棒を引っぱろう。';

  @override
  String get coopFreeLead => 'ロープなし：';

  @override
  String get coopFreeBody => 'それぞれ自由に飛んで、相手とはぶつかるだけ。ハート、シールド、スコアは共有だよ。';

  @override
  String get duelLead => '勝負！';

  @override
  String get duelBody =>
      'ハートはそれぞれ別。ふしぎボックスを取ろう：ライバルにコウモリやペッペ虫、いん石を送るものもあれば、ハートやシールド、スターパワーがもらえるものも。最後まで飛んでいた鳥の勝ち！';

  @override
  String get coopStart => 'いっしょに飛ぶ';

  @override
  String get duelStart => '勝負！';

  @override
  String get coopFlightSemantics => 'プレイヤー1は左半分、プレイヤー2は右半分をタップしてはばたく';

  @override
  String get coopPauseSemantics => 'フライトを一時停止';

  @override
  String coopShootSemantics(int player) {
    return 'プレイヤー$playerのショット';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'プレイヤー$playerのダッシュ';
  }

  @override
  String coopPlayerShort(int player) {
    return '${player}P';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'プレイヤー$player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '星マグネット：残り$seconds秒',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'マグネットをチャージ中：パーフェクト通過$gates回中$charge回',
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
  String get coopCountdownRoped => 'ロープよし。位置について、よーい…';

  @override
  String get coopCountdownFree => '位置について、よーい…';

  @override
  String get duelCountdown => 'いざ、勝負…';

  @override
  String get coopCountdownRopedHint => 'いっしょにはばたいて高く上がろう。\nダッシュで相棒を引っぱろう！';

  @override
  String get coopCountdownFreeHint => 'それぞれ自由に飛ぶよ。\nハートを分け合って、ゲートをクリア！';

  @override
  String get duelCountdownHint => 'ふしぎボックスを取ろう！\n最後まで飛んでいた鳥の勝ち。';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'プレイヤー$playerのスターパワー：残り$seconds秒',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'ホーム';

  @override
  String get coopChangeBirds => '鳥を変える';

  @override
  String get coopSaved => '保存済み';

  @override
  String get coopSaving => '保存中…';

  @override
  String get coopSaveSession => 'フライトを保存';

  @override
  String get duelRematch => '再戦';

  @override
  String get coopFlyAgain => 'もう一度飛ぶ';

  @override
  String duelWinner(int player) {
    return 'プレイヤー$playerの勝ち！';
  }

  @override
  String get duelDraw => '引き分け！';

  @override
  String get duelStopped => '対戦中止';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first 対 $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winnerが$loserに勝った';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '${rival}Pに$prize！';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize！';
  }

  @override
  String get duelPrize_batSwarm => 'コウモリの大群';

  @override
  String get duelPrize_spitter => 'ペッペ虫';

  @override
  String get duelPrize_meteorShower => 'いん石の雨';

  @override
  String get duelPrize_heart => 'ハート';

  @override
  String get duelPrize_shield => 'シールド';

  @override
  String get duelPrize_starPower => 'スターパワー';

  @override
  String get coopTapLeftHalf => '左半分をタップ';

  @override
  String get coopTapRightHalf => '右半分をタップ';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'プレイヤー$player：$bird';
  }

  @override
  String coopSideHint(int player) {
    return '${player}P・こっちをタップ';
  }

  @override
  String get coopKeysP1 => '1P・W はばたく・D ショット・A ダッシュ';

  @override
  String get coopKeysP2 => '2P・↑ はばたく・→ ショット・← ダッシュ';

  @override
  String get coopRopedSemantics => 'ロープあり：2羽はロープでつながっている';

  @override
  String get coopFreeSemantics => 'ロープなし：それぞれ自由に飛ぶ';

  @override
  String get duelModeSemantics => '1対1：鳥どうしで対戦する';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'フライトを保存・「記録」で見られるよ';

  @override
  String get coopNewTeamBest => 'チームベスト更新！';

  @override
  String get coopWhatATeam => '最高のチームだね。';

  @override
  String coopPairCaption(String first, String second) {
    return '$first＆$second';
  }

  @override
  String get coopTeamScore => 'チームスコア';

  @override
  String get coopTeamBest => 'チームベスト';

  @override
  String get coopNewTeamBestRibbon => 'チームベスト更新！';

  @override
  String get coopStatFlightTime => '飛行時間';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ゲート',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'はばたきの割合';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${player}Pのはばたき',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return '対戦時間 $time';
  }

  @override
  String get duelSeries => '通算';

  @override
  String get duelHeartsLeft => '残りハート';

  @override
  String get duelBoxesOpened => '開けたボックス';

  @override
  String get duelHitsLanded => '当てた回数';

  @override
  String get coopPauseSubtitle => '2羽とも枝にとまって待ってるよ。再開のときはカウントダウンするね。';

  @override
  String get coopFinishFlight => 'フライト終了';

  @override
  String get cameraLabIntro => 'スマホを横向きにして低く立てかけよう。正面でも横でもOK。';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'あと少し・もっとはっきり見せて：$parts';
  }

  @override
  String get cameraLabJointShoulder => '肩';

  @override
  String get cameraLabJointElbow => 'ひじ';

  @override
  String get cameraLabJointWrist => '手首';

  @override
  String get cameraLabJointHip => '腰';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first、$rest';
  }

  @override
  String get cameraLabStarting => 'カメラを起動中…';

  @override
  String get cameraLabDenied => 'カメラへのアクセスがOFFです。アプリの設定で許可して、もう一度試してね。';

  @override
  String cameraLabFailed(String error) {
    return 'カメラを起動できませんでした：$error';
  }

  @override
  String get cameraLabStopped => 'カメラが止まりました。「カメラを起動」をタップして調整し直そう。';

  @override
  String get cameraLabBack => 'カメラ実験室・ホームにもどる';

  @override
  String get cameraLabStepShow => '1. 腕と腰をうつそう';

  @override
  String get cameraLabStepPushUps => '2. 腕立てを2回しよう';

  @override
  String get cameraLabStepMove => '3. 鳥を動かそう！';

  @override
  String get cameraLabStepSquat => 'スクワットの範囲をはかろう';

  @override
  String get cameraLabStepJump => '立つ位置を決めよう';

  @override
  String get cameraLabPushUpHelp =>
      'スマホは低く、正面か横に置こう。\n正面なら、両肩と腕、腰をうつそう。\n自分のペースで2回、下がって上がろう。';

  @override
  String get cameraLabSquatHelp =>
      'じっと立ち、楽にしゃがんで少し止まり、また立ち上がろう。しゃがむと下がる、立つと上がる。';

  @override
  String get cameraLabJumpHelp =>
      '全身と足が見えるように、スマホに向かって立とう。じっとしてから、小さくジャンプ。1回のジャンプで大きくブースト。';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '調整\n$total回中$done回',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return '調整\n$percent%完了';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '操作テスト\n腕立て$count回',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '操作テスト\nスクワット$count回',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '操作テスト\nジャンプ$count回',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Hz · p95 $msミリ秒';
  }

  @override
  String get cameraLabStartingButton => '起動中…';

  @override
  String get cameraLabRecalibrate => '調整し直す';

  @override
  String get cameraLabStartCamera => 'カメラを起動';

  @override
  String get cameraLabTapStart => '「カメラを起動」を押そう';

  @override
  String cameraLabTry(String mode) {
    return '$modeを試す';
  }

  @override
  String get cameraBadgeWaking => '起動中';

  @override
  String get cameraBadgeLive => 'ライブ';

  @override
  String get cameraBadgeLockedOn => 'ロックオン';

  @override
  String get cameraBadgeOffline => 'オフライン';

  @override
  String get trackingCatchingUp => 'カメラが追いついてくるよ';

  @override
  String get trackingStepIntoOutline => '体の輪かくの中に入ろう';

  @override
  String get trackingKeepShoulders => '両肩が見えるようにしよう';

  @override
  String get trackingShowSide => '横から、片方の肩・ひじ・手首・腰を見せよう';

  @override
  String get trackingMoveCloser => 'もう少し近づこう';

  @override
  String get trackingGetDown => '腕立ての姿勢になろう';

  @override
  String get trackingHandsOnFloor => '手を床について、体を後ろへのばそう';

  @override
  String get trackingExtendBody => '体を手より少し後ろまでのばそう';

  @override
  String get trackingComfortableRange => '腕立ては無理のない範囲で';

  @override
  String get trackingPlaceHands => '手を床について、体はその後ろへ';

  @override
  String get trackingFrontTracked => '正面からトラッキング中・手が見えるようにしよう';

  @override
  String get trackingBodyInView => '体が見えてるよ・顔は下を向いてもOK';

  @override
  String get trackingArmsTracked => '腕をトラッキング中・足のチェックは一部だけ';

  @override
  String get trackingFindTop => '楽な上の位置を見つけよう';

  @override
  String get trackingCalibrated => '調整完了！鳥を動かしてみよう。';

  @override
  String get trackingFreshFrame => '新しい映像を待っているよ';

  @override
  String get trackingDistanceChanged => 'カメラとの距離が変わったよ・調整し直そう';

  @override
  String get trackingKeepArm => '片腕が見えるようにしよう';

  @override
  String get trackingSquatStepBack => '肩、腰、ひざ、足が見えるように下がろう';

  @override
  String get trackingSquatFaceCamera => '両足を床につけて、カメラのほうを向こう';

  @override
  String get trackingSquatControls => 'しゃがむと下がる・立つと上がる';

  @override
  String get trackingStartingDistance => '最初の距離でカメラに向かおう・動いたら調整し直そう';

  @override
  String get trackingFeetPlanted => '両足を最初の場所につけたままにしよう';

  @override
  String get trackingSquatStandTall => '両足が見えるように、まっすぐじっと立とう';

  @override
  String get trackingStandStill => '少しのあいだ、まっすぐじっと立とう';

  @override
  String get trackingSquatDepth => '楽な深さまでしゃがんで、少し止まろう';

  @override
  String get trackingSquatHold => '楽にしゃがんで、少し止まろう';

  @override
  String get trackingSquatHoldBriefly => 'そのまま少し止まろう';

  @override
  String get trackingSquatStandUp => '立ち上がったら調整完了';

  @override
  String get trackingSquatReady => '準備OK！しゃがむと下がる・立つと上がる';

  @override
  String get trackingJumpStepBack => '肩、腰、両足が見えるように下がろう';

  @override
  String get trackingJumpFaceCamera => '上にジャンプできる空間をあけて、カメラに向かって立とう';

  @override
  String get trackingJumpSmall => '小さなジャンプでOK・着地してから次のジャンプ';

  @override
  String get trackingJumpStandStill => '全身と両足が見えるように、じっと立とう';

  @override
  String get trackingJumpReady => '準備OK！小さなジャンプ1回で大きくブースト。';

  @override
  String get trackingFindPosition => '位置につこう';

  @override
  String get trackingInterrupted => 'トラッキングがとぎれました';

  @override
  String get trackingCameraInterrupted => 'カメラが止まりました。カメラの許可を確認して、もう一度試してね。';

  @override
  String get trackingCameraAway => 'アプリを離れているあいだにカメラが止まりました';

  @override
  String get trackingJumpBoost => 'ジャンプで大きくブースト';

  @override
  String get trackingJumpLand => '着地して次のジャンプに備えよう';

  @override
  String trackingLowerMore(int step, int total) {
    return 'もう少し下げて・$step/$total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return '楽に下げて・$step/$total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return '押し上げて・$step/$total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return '最初の楽な範囲に合わせて・$step/$total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'この変更を保存できませんでした。もう一度試してね。（$error）';
  }

  @override
  String get commonDelete => '削除';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと星$count個',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => '巣のデータを読み込めなかったよ。';

  @override
  String get homeSettings => '設定';

  @override
  String homeGreetingFirst(String bird) {
    return 'やあ、$birdだよ！飛ぶ準備はいい？';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'アドベンチャー達成！$birdも鼻高々。',
      'female': 'アドベンチャー達成！$birdも鼻高々。',
      'other': 'アドベンチャー達成！$birdも鼻高々。',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$birdは準備OK。きみは？',
      'female': '$birdは準備OK。きみは？',
      'other': '$birdは準備OK。きみは？',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'エンドレス';

  @override
  String get homeEndlessDetail => 'どこまでも飛ぼう';

  @override
  String get homeEndlessSemantics => 'エンドレス。どこまでも飛ぼう。';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: 'エンドレス。どこまでも飛ぼう。ベスト：星$best個。',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'ベスト';

  @override
  String get homeBestNone => '初ベストをめざそう';

  @override
  String get homeCampaignTitle => 'キャンペーン';

  @override
  String get homeCampaignDone => 'すべての手紙をお届け';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'キャンペーン。次：$level。星$total個中$stars個。',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'キャンペーン。すべての手紙をお届け。星$total個中$stars個。',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id・$name';
  }

  @override
  String get homeMiniGamesTitle => 'ミニゲーム';

  @override
  String get homeMiniGamesDetail => '運動・2人プレイ';

  @override
  String get homeMiniGamesSemantics => 'ミニゲーム。腕立て、スクワット、ジャンプ、または2人プレイ。';

  @override
  String get homeBuilderTitle => 'レベルビルダー';

  @override
  String get homeBuilderDetail => '作る・飛ぶ・シェア';

  @override
  String get homeBuilderSemantics => 'レベルビルダー。自分のレベルを作って、飛んで、シェアしよう。';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと$countフライトで解放',
      one: 'あと1フライトで解放',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'レベルビルダー。ロック中。あと$countフライトで解放。',
      one: 'レベルビルダー。ロック中。あと1フライトで解放。',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'アドベンチャー';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '今日のアドベンチャー。目標3つ中$doneつ達成。',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => '鳥たち';

  @override
  String homeDockBirdsSemantics(String bird) {
    return '鳥たち。$birdといっしょに飛行中。';
  }

  @override
  String get homeDockUpgrades => 'アップグレード';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'アップグレード。使える星$stars個。',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'パスポート';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'パスポート。メダル$total個中$earned個。',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => '記録';

  @override
  String get homeMiniGamesPickerTitle => 'ミニゲーム';

  @override
  String get homeMiniGamesPickerIntro => '体を動かして飛ぶか、友だちとスマホをいっしょに使おう。';

  @override
  String get homeMiniGamesCloseSemantics => 'ミニゲームを閉じる';

  @override
  String get homeMiniGamesPushUpCard => '下がると急降下。\n押し上げて急上昇。';

  @override
  String get homeMiniGamesSquatCard => '低くしゃがんで。\n立って急上昇。';

  @override
  String get homeMiniGamesJumpCard => 'ジャンプで上昇。\nグライドで星を。';

  @override
  String get homeMiniGamesCoopCard => '2人でスマホ1台。\n協力か、対戦か。';

  @override
  String get homeMiniGamesCamera => 'カメラ';

  @override
  String get homeMiniGamesPlayers => '2人プレイ';

  @override
  String get homeMiniGamesCoop => 'いっしょに飛⁠ぼ⁠う';

  @override
  String get birdsTitle => 'きみのフライト仲間たち。';

  @override
  String birdsFlownTag(int flown, int total) {
    return '$total羽中$flown羽と飛んだ';
  }

  @override
  String get birdsStatusCopilot => 'きみの相棒';

  @override
  String get birdsStatusReady => 'いつでも飛べる';

  @override
  String get birdsStatusLocked => 'ロック中';

  @override
  String get birdsNotFlown => 'まだ飛んでない';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countフライト',
      one: '1フライト',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return '$birdと飛ぶ';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return '$currentのかわりに$birdと飛ぶ';
  }

  @override
  String birdsUnlock(String bird) {
    return '$birdを解放';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '星$price個で$birdを解放',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '星$price個で$birdを解放、星がまだ足りません',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'いっしょに飛行中';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird、いっしょに飛行中';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird、いっしょに飛行中、新入り';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird、ロック中、星$price個',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird、新入り';
  }

  @override
  String get birdsTagFlying => '飛行中';

  @override
  String get birdsTagNew => 'NEW';

  @override
  String get bird_0_description => '小さな鳥、大きな空。';

  @override
  String get bird_0_trail => 'おひさまのあわ';

  @override
  String get bird_1_description => 'バラ色ほっぺ、くるくるトサカ、ハートいっぱい。';

  @override
  String get bird_1_trail => 'ピーチハート';

  @override
  String get bird_2_description => 'ちびハチドリ。ミントの若葉。全速力。';

  @override
  String get bird_2_trail => 'ミントの葉っぱ';

  @override
  String get bird_3_description => '星あかりで飛ぶ、夢見るフクロウ。';

  @override
  String get bird_3_trail => '星くずのきらめき';

  @override
  String get upgradesWalletLabel => '使える\n星';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '使える星$stars個',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => '鳥をパワーアップしよう。';

  @override
  String get upgradesIntro => '歯車をタップすると効果がわかるよ。飛んで拾った星は、1個ずつ使えるよ。';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power、レベル$level/$max。次のレベルは星$cost個',
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
      other: '$power、レベル$level/$max。次のレベルは星$cost個、まだ足りません',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power、レベル$level/$max。最大';
  }

  @override
  String get upgradesMax => 'MAX';

  @override
  String upgradesLevel(int level) {
    return 'レベル$level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'レベル$level、最大';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now、次のレベルは$next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value%';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value秒';
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
      other: '残りの星は$count個になるよ。',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => '強化する';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '星$cost個でアップグレード',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '星$cost個でアップグレード、星がまだ足りません',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => '最大レベル';

  @override
  String get power_shot_name => 'ショットパワー';

  @override
  String get power_shot_blurb => 'ショットを長押しすると、もっと大きくて強い石をためられる。';

  @override
  String get power_sprint_name => 'ダッシュ';

  @override
  String get power_sprint_blurb => '一気に加速して、じゃまな敵をけちらす。';

  @override
  String get power_shield_name => 'シールド';

  @override
  String get power_shield_blurb => '1回だけ攻撃を防ぐよ。飛びながら星を集めると回復。';

  @override
  String get power_magnet_name => 'マグネット';

  @override
  String get power_magnet_blurb => 'ゲートをパーフェクト通過するともらえる。星を引きよせるよ。';

  @override
  String get power_stat_maxCharge => '最大チャージ';

  @override
  String get power_stat_burstLength => 'ダッシュの長さ';

  @override
  String get power_stat_cooldown => '待ち時間';

  @override
  String get power_stat_starsToRefill => '回復に必要な星';

  @override
  String get power_stat_safeTime => '割れたあとの無敵時間';

  @override
  String get power_stat_perfectGates => '必要なパーフェクト通過';

  @override
  String get power_stat_lasts => '効果時間';

  @override
  String get power_stat_reach => 'とどく範囲';

  @override
  String get passportTitle => 'きみの空のパスポート。';

  @override
  String get passportDailyCard => '今日のカード';

  @override
  String passportMedalsTag(int earned, int total) {
    return 'メダル $earned/$total';
  }

  @override
  String get passportIntro => '小さな冒険と、ずっと残る思い出。どのスタンプにも銅・銀・金。';

  @override
  String get passportNoMedal => 'メダルはまだなし';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': '銅メダル',
      'silver': '銀メダル',
      'other': '金メダル',
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
    return '$stamp。$held。次は$next：$goal $target中$current。';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp。金メダル。$goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': '銅まで',
      'silver': '銀まで',
      'other': '金まで',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'スタンプ済';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp：$medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp：まだなし';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => '銅';

  @override
  String get passportMedal_silver => '銀';

  @override
  String get passportMedal_gold => '金';

  @override
  String get stamp_frequentFlyer_name => '常連フライヤー';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '記録に残るフライトを$n回終える。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'ど真ん中';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ねらいマークにそって$n回パーフェクト通過する。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => '星を追う者';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星を$n個集める。',
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
      other: '1回の星つなぎで星を$n個集める。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => '空のキャプテン';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '1回のエンドレスフライトで$n点取る。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => '道を切りひらく者';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n回のエンドレスフライトで、60秒以上飛ぶ。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => '類は友を呼ぶ';

  @override
  String get stamp_allRounder_name => 'なんでも屋';

  @override
  String get stamp_flockTogether_goalBronze => 'ちがう鳥2羽で、記録に残るフライトをする。';

  @override
  String get stamp_flockTogether_goalSilver => '4羽すべてで、記録に残るフライトをする。';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'どの鳥とも、記録に残るフライトを$n回する。',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze => '腕立て・スクワット・ジャンプのどれかのミニゲームで飛ぶ。';

  @override
  String get stamp_allRounder_goalSilver => '3つのミニゲームをすべて飛ぶ：腕立て、スクワット、ジャンプ。';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'どのミニゲームでも、記録に残るフライトを$n回する。',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★・メダル$medals個・現在$level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => '今日の冒険を読み込めなかったよ。';

  @override
  String get dailyTitle => '今日の小さなアドベンチャー。';

  @override
  String dailyDateTag(String date, int done) {
    return '$date・目標$done/3';
  }

  @override
  String get dailyIntro => '目標は3つ。操作はなんでもOK。エンドレス1回で3つ全部にカウントされるよ。';

  @override
  String get dailyLaunchEndless => 'エンドレス';

  @override
  String get dailyPostcardKicker => 'スカイクラブ絵はがき';

  @override
  String get dailyStamped => 'スタンプ完了！';

  @override
  String dailyGoalsComplete(int done) {
    return '目標$done/3達成';
  }

  @override
  String get dailyDoneNote => '小さな冒険、ぜんぶきみのもの。';

  @override
  String get dailyOpenNote => '3つともクリアしてスタンプを押そう。';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal 達成';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $target中$current';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date：スタンプ済み';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date：目標$done/3';
  }

  @override
  String get dailyNoStreak => '毎日新しい目標。休んでもへっちゃら。';

  @override
  String get dailyTheme_0 => '朝焼けの配達';

  @override
  String get dailyTheme_1 => 'ピーチのピクニック';

  @override
  String get dailyTheme_2 => '月あかりの郵便';

  @override
  String get dailyTheme_3 => '雲のパレード';

  @override
  String get dailyTheme_4 => 'たそがれの宝物';

  @override
  String get dailyTheme_5 => 'ガーデンパーティー';

  @override
  String get task_flights_title => '翼を広げて';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日、記録に残るフライトを$count回終える。',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'ひろがる地平線';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日の記録に残るフライトで、ゲートを合計$count個くぐる。',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'ポケットいっぱいの星';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日のフライトで、星を合計$count個集める。',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'きらきらつなげて';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '1回の星つなぎで星を$count個集める。',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'ねらいどおり';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日、パーフェクト通過を$count回する。',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => '旅をまるごと';

  @override
  String get task_finishTrail_goal => '1回のエンドレスフライトで、60秒以上飛ぶ。';

  @override
  String get recordsTitle => 'きみの小さな勝利たち。';

  @override
  String get recordsBestsTitle => '超えたい星ポイント';

  @override
  String get recordsSectionMain => 'メインゲーム';

  @override
  String get recordsSectionMini => 'ミニゲーム';

  @override
  String get recordsEndless => 'エンドレス・タップ＆フライ';

  @override
  String get recordsCampaignStars => 'キャンペーンの星';

  @override
  String recordsCoopName(String mode) {
    return 'いっしょに飛ぼう・$mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回の記録フライト',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '個のゲート',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回いっしょに',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回の対戦',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回の腕立て',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回スクワット',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => '最近のフライト';

  @override
  String get recordsEmptyTitle => '大きな空。まっさらなページ。';

  @override
  String get recordsEmptyBody => '記録に残る最初のフライトで物語がはじまる。';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date・$seconds秒';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'クラシック・$date・$seconds秒';
  }

  @override
  String get replaySavedSessions => '保存したフライト';

  @override
  String get replayBackToRecordsSemantics => '記録にもどる';

  @override
  String get replaySessionsLoadFailed => '読み込めなかった。タップでもう一度';

  @override
  String get replayEmptyTitle => 'フライトはここに集まるよ';

  @override
  String get replayEmptyBody => 'フライトのあとで保存すると、ここで見られるよ。';

  @override
  String get replayEmptyButton => 'フライトを選ぶ';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date・$seconds秒・$score星ポイント',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date・$seconds秒・$scoreゲート',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'フライトを削除';

  @override
  String get replayDeleteTitle => 'このフライトを削除する？';

  @override
  String get replayDeleteBody => 'カメラ映像とリプレイが消えます。スコアは「記録」に残ります。';

  @override
  String get replayDeleteFailed => 'フライトを削除できませんでした。もう一度試してね。';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name・$mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return 'レベル$id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode・エンドレス';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode・練習';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode・エンドレス・練習';
  }

  @override
  String get replayOpenFailed => 'このフライトは開けませんでした。';

  @override
  String get replayBackToSessions => 'フライト一覧へ';

  @override
  String get replayCameraPaused => 'この部分ではカメラが止まっていました';

  @override
  String get replayCameraUnavailable => 'カメラ映像は見られません・ゲーム画面は再生できます';

  @override
  String get replayCameraLoading => 'カメラを読み込み中…';

  @override
  String get replayPaused => 'ひと休み中';

  @override
  String get replayHideControlsSemantics => 'リプレイの操作をかくす';

  @override
  String get replayShowControlsSemantics => 'リプレイの操作を表示';

  @override
  String get replayBackToSavedSemantics => '保存したフライトにもどる';

  @override
  String get replayTitle => 'リプレイ';

  @override
  String replayTitleSession(String session) {
    return 'リプレイ・$session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'スコア：$score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: 'ハート$hearts',
    );
    return '$_temp0・$clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'ハート 1P $p1・2P $p2・$clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String replayMagnet(int seconds) {
    return 'じしゃく$seconds秒';
  }

  @override
  String get replayPauseSemantics => 'リプレイを一時停止';

  @override
  String get replayPlaySemantics => 'リプレイを再生';

  @override
  String get replayRestartSemantics => 'リプレイを最初から';

  @override
  String get replayBack5Semantics => '5秒もどる';

  @override
  String get replayForward5Semantics => '5秒進む';

  @override
  String get replayHighlightsFinding => 'フライトのハイライトをさがし中';

  @override
  String get replayHighlightsNone => 'フライトのハイライトはありません';

  @override
  String get replayHighlights => 'フライトのハイライト';

  @override
  String get replayHighlightsCloseSemantics => 'ハイライトを閉じる';

  @override
  String get replayHighlightsHint => '場面を選ぼう。その少し前から再生するよ。';

  @override
  String get replayViewCorner => 'すみにカメラ';

  @override
  String get replayViewBackground => '背景にカメラ';

  @override
  String get replayViewGameplay => 'ゲーム画面だけ';

  @override
  String get replayMoveCornerSemantics => 'カメラの位置を動かす';

  @override
  String get replayMuteRecordedSemantics => '録音した音を消す';

  @override
  String get replayUnmuteRecordedSemantics => '録音した音を出す';

  @override
  String get replayMuteGameSemantics => 'ゲームの音を消す';

  @override
  String get replayUnmuteGameSemantics => 'ゲームの音を出す';

  @override
  String get replayFullScreenSemantics => '操作をかくす／全画面';

  @override
  String get replayMomentTakeoff => '離陸';

  @override
  String get replayMomentTakeoffDetail => '空はきみのもの。';

  @override
  String get replayMomentMagnet => '星マグネット';

  @override
  String get replayMomentMagnetDetail => 'パーフェクト通過3回で、星が近づいてくる。';

  @override
  String get replayMomentStarTrio => 'はじめての星トリオ';

  @override
  String get replayMomentStarTrioDetail => '3つの星が星座になった。+5点！';

  @override
  String get replayMomentStarTrioSubtleDetail => 'グループの星をぜんぶ集めた。+5点！';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier×スターパワー';
  }

  @override
  String get replayMomentStreakDetail => 'きらきら光る星つなぎ。';

  @override
  String get replayMomentShield => 'シールド防御';

  @override
  String get replayMomentShieldDetail => 'あぶなかった！でも、もう一度チャンス。';

  @override
  String get replayMomentPerfect => 'はじめてのパーフェクト通過';

  @override
  String get replayMomentPerfectDetail => 'ねらいマークのど真ん中。';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ゲート$count個クリア',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => '空のもう少し先へ。';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'かすり傷ひとつなし。+$points点！',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'ダッシュリングで安全地帯へ。+$points点！',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => '突風をのりきった';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '飛んでくるがらくたをよけた。+$points点！',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'ルート完走';

  @override
  String get replayMomentFinal => '最後の瞬間';

  @override
  String get replayMomentCompleteDetail => 'ルートの最後までたどり着いた。';

  @override
  String get replayMomentCollisionDetail => '最後の場面を見てみよう。';

  @override
  String get replayMomentEndDetail => 'このフライトのおわり。';

  @override
  String get welcomeTitle => '言語を選んでね';

  @override
  String get welcomeContinue => 'さあ、飛ぼう！';

  @override
  String get welcomeHint => '設定からいつでも変えられます。';

  @override
  String get welcomeDevice => 'スマホの言語';

  @override
  String get tutorialTitle => 'フライト教室';

  @override
  String get tutorialSkip => 'レッスンをとばす';

  @override
  String get tutorialSkipTitle => 'フライト教室をとばす？';

  @override
  String get tutorialSkipBody => 'レッスンは設定からいつでも受け直せます。';

  @override
  String get tutorialSkipConfirm => 'とばす';

  @override
  String get tutorialSkipCancel => '練習を続ける';

  @override
  String get tutorialRestart => '最初から';

  @override
  String get tutorialGoalFlaps => 'はばたく';

  @override
  String get tutorialGoalStars => '星を集める';

  @override
  String get tutorialGoalGates => 'ゲートを通る';

  @override
  String get tutorialGoalBats => 'コウモリをやっつける';

  @override
  String get tutorialGoalDoor => '石の扉をこわす';

  @override
  String get tutorialGoalSprint => 'ダッシュ';

  @override
  String get tutorialGoalBoss => '船長をやっつける';

  @override
  String get tutorialPromptTap => 'タップ！';

  @override
  String get tutorialPromptShoot => 'ショットをタップ';

  @override
  String get tutorialPromptHoldShoot => 'ショットを長押し';

  @override
  String get tutorialPromptSprint => 'ダッシュをタップ';

  @override
  String get tutorialPraiseNice => 'いいね！';

  @override
  String get tutorialPraiseGreat => 'すごい！';

  @override
  String get tutorialPraiseSuper => 'おみごと！';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return 'レッスンが待っています：$prompt';
  }

  @override
  String get licenceTitle => '配達人免許証';

  @override
  String get licenceIssuer => 'スカイクラブ郵便';

  @override
  String get licenceHolder => '配達人';

  @override
  String get licenceRank => 'ランク';

  @override
  String get licenceRankRookie => '新米配達人';

  @override
  String get licenceSkills => 'スキル';

  @override
  String get licenceStamp => '認定';

  @override
  String licenceSignedBy(String name) {
    return '署名：$name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '星$count個',
      one: '星1個',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => 'はじめてのルートへ！';

  @override
  String get licenceAgain => 'もう一度飛ぶ';

  @override
  String get settingsTutorial => 'フライト教室';

  @override
  String get settingsTutorialDetail => '最初のレッスンをもう一度';
}
