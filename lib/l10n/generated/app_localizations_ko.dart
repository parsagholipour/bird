// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get commonTryAgain => '다시 시도';

  @override
  String get languageKeyLabel => '언어';

  @override
  String languageKeySemantics(String language) {
    return '언어: $language. 게임 언어를 바꿔요.';
  }

  @override
  String get languageSystemDefault => '시스템 기본값';

  @override
  String languageSystemDetail(String language) {
    return '휴대폰 언어를 따라요: $language';
  }

  @override
  String get languageCurrent => '현재 언어';

  @override
  String get languageName_en => '영어';

  @override
  String get languageName_es_419 => '스페인어(중남미)';

  @override
  String get languageName_pt_br => '포르투갈어(브라질)';

  @override
  String get languageName_id => '인도네시아어';

  @override
  String get languageName_fr => '프랑스어';

  @override
  String get languageName_de => '독일어';

  @override
  String get languageName_ja => '일본어';

  @override
  String get languageName_ko => '한국어';

  @override
  String get languageName_tr => '튀르키예어';

  @override
  String get languageName_zh_hant => '중국어 번체';

  @override
  String get languageName_ru => '러시아어';

  @override
  String get languageName_ar => '아랍어';

  @override
  String get voicePackReady => '음성 준비 완료';

  @override
  String get voicePackDownload => '음성 받기';

  @override
  String voicePackDownloading(int percent) {
    return '음성 $percent%';
  }

  @override
  String get voicePackStarting => '음성 받는 중';

  @override
  String get voicePackEnglish => '영어 음성';

  @override
  String get voicePackFailed => '음성 받기 실패';

  @override
  String get settingsTitle => '내 집처럼 편하게.';

  @override
  String get settingsSectionSound => '소리';

  @override
  String get settingsSectionComfort => '편안함';

  @override
  String get settingsMusicTitle => '하늘 클럽 사운드트랙';

  @override
  String get settingsMusicDetail => '메뉴, 모험, 보스 테마곡.';

  @override
  String get settingsEffectsTitle => '효과음';

  @override
  String get settingsEffectsDetail => '비행, 전투, 아이템 줍기, 메뉴 소리.';

  @override
  String get settingsVoicesTitle => '캐릭터 음성';

  @override
  String get settingsVoicesDetail => '이야기 장면, 감사 쪽지, 대시 외침.';

  @override
  String get settingsReducedMotionTitle => '동작 줄이기';

  @override
  String get settingsReducedMotionDetail => '메뉴는 차분하게, 장식 효과는 적게.';

  @override
  String get settingsSwitchOn => '켜짐';

  @override
  String get settingsSwitchOff => '꺼짐';

  @override
  String get settingsUnavailable => '설정을 잠깐 못 불러왔어요.';

  @override
  String get settingsPrivacyKicker => '언제나 기기 안에서만';

  @override
  String get settingsPrivacyTitle => '내 카메라는 나만의 것.';

  @override
  String get settingsPrivacyBody =>
      '영상과 마이크 소리(선택)는 이 휴대폰에만 남아요. 저장 안 한 영상은 지워져요. 업로드 없음.';

  @override
  String get settingsCameraLab => '카메라·동작 인식 실험실';

  @override
  String get settingsAbout => '정보 및 라이선스';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return '정보 및 라이선스, 버전 $version';
  }

  @override
  String get settingsReset => '기기 진행 상황 초기화';

  @override
  String settingsResetDone(String bird) {
    return '새 출발이에요. $bird 준비 완료!';
  }

  @override
  String get settingsResetTitle => '새 모험을 시작할까요?';

  @override
  String get settingsResetBody =>
      '저장된 영상, 다시 보기, 점수, 비행 기록, 만든 레벨, 설정이 이 휴대폰에서 지워져요. 되돌릴 수 없어요.';

  @override
  String get settingsResetBodyCloud =>
      '저장된 영상, 다시 보기, 점수, 비행 기록, 만든 레벨, 설정이 이 휴대폰에서 지워지고 Play 게임즈 클라우드 저장도 지워져요. 되돌릴 수 없어요.';

  @override
  String get settingsResetConfirm => '모두 초기화';

  @override
  String get settingsResetKeep => '진행 상황 유지';

  @override
  String get playGamesName => 'Play 게임즈';

  @override
  String get playGamesConnected => '연결됨';

  @override
  String get playGamesNotConnected => '연결 안 됨';

  @override
  String get playGamesConnecting => '연결 중…';

  @override
  String get playGamesConnectFailed => '연결하지 못했어요';

  @override
  String get playGamesIdle => '클라우드 저장 & 업적';

  @override
  String get playGamesSaving => '클라우드에 저장 중…';

  @override
  String get playGamesOfflineUnsaved => '오프라인 · 아직 저장 안 됨';

  @override
  String playGamesOfflineSaved(String ago) {
    return '오프라인 · $ago 저장됨';
  }

  @override
  String get playGamesUpdateNeeded => '업데이트하면 동기화돼요';

  @override
  String get playGamesUnreadable => '클라우드 저장 읽기 실패';

  @override
  String get playGamesOn => '클라우드 저장 켜짐';

  @override
  String get playGamesResetElsewhere => '다른 휴대폰에서 초기화됨';

  @override
  String playGamesRestored(String ago) {
    return '클라우드 복원 · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return '클라우드 저장 · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Play 게임즈 업적';

  @override
  String get playGamesConnectSemantics => 'Play 게임즈 연결';

  @override
  String get playGamesAchievements => '업적';

  @override
  String get playGamesConnect => '연결';

  @override
  String get timeAgoJustNow => '방금';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes분 전',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours시간 전',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 전',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '하트 +1!';

  @override
  String calloutStarTrio(int points) {
    return '별 삼총사 +$points!';
  }

  @override
  String get calloutNiceShot => '명중!';

  @override
  String calloutNiceShotPoints(int points) {
    return '명중 +$points!';
  }

  @override
  String get calloutSmash => '박살!';

  @override
  String calloutSmashPoints(int points) {
    return '박살 +$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return '박살 ×$count!';
  }

  @override
  String get calloutBossDown => '보스 격파!';

  @override
  String calloutBossDownPoints(int points) {
    return '보스 격파 +$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier× 별의 힘!';
  }

  @override
  String get calloutPerfect => '퍼펙트!';

  @override
  String calloutPerfectChain(int count) {
    return '퍼펙트 ×$count';
  }

  @override
  String get calloutShieldReady => '보호막 준비';

  @override
  String get calloutShieldSave => '보호막 방어!';

  @override
  String get calloutKeepFlying => '계속 날자!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '관문 $count개!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds초 남음',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => '별 자석!';

  @override
  String get calloutSprintRing => '대시 링!';

  @override
  String calloutRushChain(int count) {
    return '러시 ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return '운석 +$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return '박쥐 +$points!';
  }

  @override
  String get calloutScorched => '앗 뜨거!';

  @override
  String get region_jungle => '정글';

  @override
  String get region_antarctica => '남극';

  @override
  String get region_aztec => '아즈텍';

  @override
  String get region_paris => '파리';

  @override
  String get region_egypt => '이집트';

  @override
  String get region_cyberpunk => '사이버펑크 시티';

  @override
  String get region_china => '중국';

  @override
  String get region_brazil => '브라질';

  @override
  String get region_newYork => '뉴욕';

  @override
  String get region_arabia => '고대 아라비아';

  @override
  String get region_rome => '고대 로마';

  @override
  String get region_mexico => '멕시코';

  @override
  String get region_sea => '먼바다';

  @override
  String get boss_baronBat_name => '박쥐 남작';

  @override
  String get boss_spitterBeetle_name => '퉤퉤 왕';

  @override
  String get boss_duskMoth_name => '황혼 여제';

  @override
  String get boss_pirate_name => '해적 선장';

  @override
  String get boss_dragon_name => '불씨 드래곤';

  @override
  String get boss_kingCoo_name => '킹구구';

  @override
  String get boss_searchlightGargoyle_name => '탐조등 가고일';

  @override
  String get boss_neferhoo_name => '네페르후';

  @override
  String get bird_0_name => '핍';

  @override
  String get bird_1_name => '피치스';

  @override
  String get bird_2_name => '민티';

  @override
  String get bird_3_name => '오빗';

  @override
  String get playMode_pushUp => '팔굽혀펴기 비행';

  @override
  String get playMode_jump => '점프 & 비행';

  @override
  String get playMode_touch => '탭 & 비행';

  @override
  String get playMode_squat => '스쿼트 & 비행';

  @override
  String get chapter_1_route => '숲 지붕 항로';

  @override
  String get chapter_1_postmark => '숲 지붕 항로';

  @override
  String get chapter_1_postcard =>
      '숲 지붕에 다시 편지가 닿고 있어요! 큰부리새 쌍둥이가 고맙대요(아주 큰 소리로). 박쥐 남작의 왕관은 우리 벽난로 위에 있어요.';

  @override
  String get chapter_1_postscript => '고대의 길에서 뭔가 보글보글 끓는 냄새가 나요.';

  @override
  String get chapter_2_route => '고대의 길';

  @override
  String get chapter_2_postmark => '고대의 길';

  @override
  String get chapter_2_postcard =>
      '카라반은 다시 길을 떠났고, 끓는 거라곤 민트차뿐이에요. 왕의 플라스크 왕관은 꽃병으로 쓰고 있어요.';

  @override
  String get chapter_2_postscript => '어젯밤 도시의 가로등이 꺼졌어요. 불빛을 챙겨 와요.';

  @override
  String get chapter_3_route => '등불 노선';

  @override
  String get chapter_3_postmark => '등불 노선';

  @override
  String get chapter_3_postcard =>
      '가로등이 켜지고 야간 우편도 말똥말똥 깨어 있어요! 파리는 크루아상을, 뉴욕은 프레첼을 보냈어요.';

  @override
  String get chapter_3_postscript => '항구의 종이 더는 울리지 않아요.';

  @override
  String get chapter_4_route => '밀물 항로';

  @override
  String get chapter_4_postmark => '밀물 항로';

  @override
  String get chapter_4_postcard =>
      '항구의 종이 다시 대포 말고 편지를 위해 울려요. 앵무새는 여기 남았어요. 안부 전해 달래요.';

  @override
  String get chapter_4_postscript => '지도의 끝에서 하늘이 불타고 있대요.';

  @override
  String get chapter_5_route => '지도의 끝';

  @override
  String get chapter_5_postmark => '지도의 끝';

  @override
  String get chapter_5_postcard =>
      '남극부터 북극까지 하늘이 맑고, 모든 항로가 다시 움직여요. 하늘 클럽 모두가 자랑스러워해요.';

  @override
  String get chapter_5_postscript => '끝없는 하늘은 언제든 그대로 기다리고 있어요.';

  @override
  String get level_1_1_name => '첫 배달';

  @override
  String get level_1_1_cargo => '큰부리새 쌍둥이에게 생일 카드';

  @override
  String get level_1_1_sender => '큰부리새 쌍둥이';

  @override
  String get level_1_1_hint => '탭하면 날갯짓해요. 별을 지나며 날아요.';

  @override
  String get level_1_2_name => '별 콤보';

  @override
  String get level_1_2_cargo => '별 보는 나무늘보에게 별자리 지도';

  @override
  String get level_1_2_sender => '별 보는 나무늘보';

  @override
  String get level_1_2_hint => '별 콤보로 3×! 퍼펙트 관문 세 번이면 자석이 생겨요.';

  @override
  String get level_1_3_name => '박쥐 순찰대';

  @override
  String get level_1_3_cargo => '반딧불이 어린이집에 수면등';

  @override
  String get level_1_3_sender => '반딧불이 어린이집';

  @override
  String get level_1_3_hint => '발사! 발사를 탭해서 박쥐를 쓰러뜨려요.';

  @override
  String get level_1_4_name => '카니발 하늘';

  @override
  String get level_1_4_cargo => '카니발 행진용 깃털 목도리';

  @override
  String get level_1_4_sender => '삼바 앵무새들';

  @override
  String get level_1_4_hint => '강풍! ‘!’를 잘 보고 축구공을 피해요.';

  @override
  String get level_1_5_name => '빠른우편';

  @override
  String get level_1_5_cargo => '드럼 대장에게 급한 초대장';

  @override
  String get level_1_5_sender => '드럼 대장';

  @override
  String get level_1_5_hint => '대시하면 박쥐를 박살 내고 앞으로 쭉 나가요.';

  @override
  String get level_1_6_name => '신전 계단';

  @override
  String get level_1_6_cargo => '신전 요리사들에게 카카오 콩';

  @override
  String get level_1_6_sender => '신전 요리사들';

  @override
  String get level_1_7_name => '해돋이 횃대';

  @override
  String get level_1_7_cargo => '새벽지기에게 해시계';

  @override
  String get level_1_7_sender => '새벽지기';

  @override
  String get level_1_8_name => '박쥐 남작';

  @override
  String get level_1_8_cargo => '박쥐 남작에게 최종 통지서';

  @override
  String get level_1_8_sender => '박쥐 남작';

  @override
  String get level_2_1_name => '딱정벌레 길';

  @override
  String get level_2_1_cargo => '마차 경주 선수들에게 월계관';

  @override
  String get level_2_1_sender => '마차 경주 선수들';

  @override
  String get level_2_1_hint => '딱정벌레는 씨앗을 뱉어요. 씨앗을 쏴서 떨어뜨려요.';

  @override
  String get level_2_2_name => '막힌 관문';

  @override
  String get level_2_2_cargo => '석상 조각가에게 새 끌';

  @override
  String get level_2_2_sender => '석상 조각가';

  @override
  String get level_2_2_hint => '발사를 꾹 누르면 큰 돌멩이로 돌을 부숴요.';

  @override
  String get level_2_3_name => '산불 질주';

  @override
  String get level_2_3_cargo => '소방대에 물 양동이';

  @override
  String get level_2_3_sender => '소방대';

  @override
  String get level_2_3_hint => '황금 링을 지나 불길보다 빨리 날아요!';

  @override
  String get level_2_4_name => '나일 지그재그';

  @override
  String get level_2_4_cargo => '스핑크스에게 새 수수께끼 책';

  @override
  String get level_2_4_sender => '스핑크스';

  @override
  String get level_2_5_name => '하늘사태';

  @override
  String get level_2_5_cargo => '피라미드 천문학자에게 망원경';

  @override
  String get level_2_5_sender => '피라미드 천문학자';

  @override
  String get level_2_5_hint => '링 대시로 운석을 박살 내요.';

  @override
  String get level_2_6_name => '보낸 이에게 반송';

  @override
  String get level_2_6_cargo => '관리인에게 깃털 먼지떨이';

  @override
  String get level_2_6_sender => '피라미드 관리인';

  @override
  String get level_2_6_hint => '그의 편지를 쏴서 돌려보내요. 보낸 이에게 반송!';

  @override
  String get level_2_7_name => '등불 시장';

  @override
  String get level_2_7_cargo => '등불 장수들에게 등잔 기름';

  @override
  String get level_2_7_sender => '등불 장수들';

  @override
  String get level_2_8_name => '기나긴 카라반';

  @override
  String get level_2_8_cargo => '기나긴 카라반에 물통';

  @override
  String get level_2_8_sender => '카라반 대장';

  @override
  String get level_2_9_name => '퉤퉤 왕';

  @override
  String get level_2_9_cargo => '퉤퉤 왕에게 끓이기 금지 명령';

  @override
  String get level_2_9_sender => '퉤퉤 왕';

  @override
  String get level_3_1_name => '나방과 불빛';

  @override
  String get level_3_1_cargo => '극장 차양에 전구';

  @override
  String get level_3_1_sender => '무대 감독';

  @override
  String get level_3_1_hint => '나방은 세 발짜리 부채꼴을 쏴요. 그 사이로 빠져나가요.';

  @override
  String get level_3_2_name => '빗속의 바퀴';

  @override
  String get level_3_2_cargo => '가판대 비둘기들에게 우산';

  @override
  String get level_3_2_sender => '가판대 비둘기들';

  @override
  String get level_3_2_hint => '골목 비둘기가 날아들어 별을 채 가요. 먼저 쏴요!';

  @override
  String get level_3_3_name => '증기 골목';

  @override
  String get level_3_3_cargo => '야간 택시 기사들에게 따끈한 프레첼';

  @override
  String get level_3_3_sender => '야간 택시 기사들';

  @override
  String get level_3_3_hint => '증기 구멍은 쉭쉭대다 펑! 뜨거운 건 뛰어넘고, 부드러운 건 타고 올라요.';

  @override
  String get level_3_4_name => '폭풍 경보';

  @override
  String get level_3_4_cargo => '가장 높은 탑에 풍향계';

  @override
  String get level_3_4_sender => '탑지기';

  @override
  String get level_3_4_hint => '빛을 피해요. 가슴 등이 열리면 쏴요! 여기선 대시 금지.';

  @override
  String get level_3_5_name => '수정 지붕';

  @override
  String get level_3_5_cargo => '지붕 위 화가들에게 크루아상';

  @override
  String get level_3_5_sender => '지붕 위 화가들';

  @override
  String get level_3_6_name => '강풍이 지나고';

  @override
  String get level_3_6_cargo => '아코디언 연주자에게 악보';

  @override
  String get level_3_6_sender => '아코디언 연주자';

  @override
  String get level_3_6_hint => '강풍! ‘!’를 잘 보고 열린 쪽으로 가요.';

  @override
  String get level_3_7_name => '한밤의 특급';

  @override
  String get level_3_7_cargo => '제빵사에게 한밤의 연애편지';

  @override
  String get level_3_7_sender => '제빵사';

  @override
  String get level_3_7_hint => '대시로 떼를 뚫고 지나가요.';

  @override
  String get level_3_8_name => '황혼 여제';

  @override
  String get level_3_8_cargo => '황혼 여제에게 모닝콜';

  @override
  String get level_3_8_sender => '황혼 여제';

  @override
  String get level_4_1_name => '항구의 불빛';

  @override
  String get level_4_1_cargo => '등대지기에게 새 렌즈';

  @override
  String get level_4_1_sender => '등대지기';

  @override
  String get level_4_2_name => '화산 고개';

  @override
  String get level_4_2_cargo => '화산 제빵사에게 오븐 장갑';

  @override
  String get level_4_2_sender => '화산 제빵사';

  @override
  String get level_4_2_hint => '용암 기둥을 뛰어넘어요.';

  @override
  String get level_4_3_name => '해안을 따라';

  @override
  String get level_4_3_cargo => '해변 축제에 연줄';

  @override
  String get level_4_3_sender => '연 날리는 친구들';

  @override
  String get level_4_4_name => '썰물';

  @override
  String get level_4_4_cargo => '외딴섬 은둔자에게 답장';

  @override
  String get level_4_4_sender => '외딴섬 은둔자';

  @override
  String get level_4_4_hint => '물에 닿으면 안 돼요.';

  @override
  String get level_4_5_name => '큰 밀물';

  @override
  String get level_4_5_cargo => '여객선 선원들에게 물때표';

  @override
  String get level_4_5_sender => '여객선 선원들';

  @override
  String get level_4_5_hint => '종이 울리면 높이 날아요.';

  @override
  String get level_4_6_name => '포격의 만';

  @override
  String get level_4_6_cargo => '갈매기 마을에 생선 비스킷';

  @override
  String get level_4_6_sender => '갈매기 마을';

  @override
  String get level_4_7_name => '폭풍 속 항해';

  @override
  String get level_4_7_cargo => '폭풍 감시 선원들에게 마른 양말';

  @override
  String get level_4_7_sender => '폭풍 감시대';

  @override
  String get level_4_8_name => '해적 선장';

  @override
  String get level_4_8_cargo => '선장에게 우편물 반환 명령';

  @override
  String get level_4_8_sender => '해적 선장';

  @override
  String get level_5_1_name => '오로라 우체국';

  @override
  String get level_5_1_cargo => '펭귄 합창단에게 털모자';

  @override
  String get level_5_1_sender => '펭귄 합창단';

  @override
  String get level_5_1_hint => '이제 어떤 러시든 올 수 있어요. 배너를 잘 봐요!';

  @override
  String get level_5_2_name => '극지의 밤';

  @override
  String get level_5_2_cargo => '극지 기지에 따뜻한 코코아';

  @override
  String get level_5_2_sender => '극지 기지';

  @override
  String get level_5_3_name => '네온 특급';

  @override
  String get level_5_3_cargo => '국숫집 간판에 예비 퓨즈';

  @override
  String get level_5_3_sender => '국숫집 주방장';

  @override
  String get level_5_4_name => '데이터 폭풍';

  @override
  String get level_5_4_cargo => '호기심 많은 로봇에게 종이 편지';

  @override
  String get level_5_4_sender => '7호기';

  @override
  String get level_5_5_name => '스카이라인 대시';

  @override
  String get level_5_5_cargo => '옥상 달리기 팀에게 경주 티켓';

  @override
  String get level_5_5_sender => '옥상 달리기 팀';

  @override
  String get level_5_6_name => '등불 축제';

  @override
  String get level_5_6_cargo => '축제에 종이 등불';

  @override
  String get level_5_6_sender => '등불 장인들';

  @override
  String get level_5_7_name => '마지막 고비';

  @override
  String get level_5_7_cargo => '산사에 고산차';

  @override
  String get level_5_7_sender => '산사 스님들';

  @override
  String get level_5_8_name => '불씨 드래곤';

  @override
  String get level_5_8_cargo => '드래곤이 처음 받는 편지';

  @override
  String get level_5_8_sender => '불씨 드래곤';

  @override
  String get storyPostmasterName => '우체국장 빌';

  @override
  String get storySkip => '건너뛰기';

  @override
  String get storyNextLineSemantics => '다음 대사';

  @override
  String get storyFinishSemantics => '끝내기';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => '모든 편지는 꼭 닿는다.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => '날자!';

  @override
  String levelIntroRunUp(int seconds) {
    return '먼저 $seconds초 진입 비행';
  }

  @override
  String levelIntroLength(int seconds) {
    return '결승선까지 약 $seconds초';
  }

  @override
  String get campaignGuardian => '수호자';

  @override
  String get levelIntroBossFight => '보스전';

  @override
  String get levelIntroNew => '신규';

  @override
  String get levelIntroTip => '팁';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    return '$boss 격파';
  }

  @override
  String get levelIntroGoalFinish => '결승선 도착';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개 모으기',
      one: '별 1개 모으기',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': '별 하나: $goal.',
      'two': '별 둘: $goal.',
      'other': '별 셋: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': '별 하나: $goal. 획득함.',
      'two': '별 둘: $goal. 획득함.',
      'other': '별 셋: $goal. 획득함.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '최고: 별 $count개',
      one: '최고: 별 1개',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => '아직 배달 전';

  @override
  String get levelIntroFirstFlight => '첫 비행';

  @override
  String get levelIntroControlFlap => '날갯짓';

  @override
  String get levelIntroControlShoot => '발사';

  @override
  String get levelIntroControlSprint => '대시';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': '조작: 날갯짓.',
      'shoot': '조작: 날갯짓, 발사.',
      'sprint': '조작: 날갯짓, 대시.',
      'other': '조작: 날갯짓, 발사, 대시.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => '특별 배달';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return '특별 배달: $cargo.';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return '레벨 $level, $name. $region.';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return '레벨 $level, $name. $region. 수호자 레벨: $boss.';
  }

  @override
  String get levelIntroStory => '이야기';

  @override
  String get commonClose => '닫기';

  @override
  String get commonContinue => '계속';

  @override
  String get commonHome => '홈';

  @override
  String get commonBackHome => '홈으로 가기';

  @override
  String get campaignComingSoon => '곧 공개';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — 곧 공개';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    return '$boss 격파하면 열려요';
  }

  @override
  String campaignLockedFinish(String level) {
    return '$level 클리어하면 열려요';
  }

  @override
  String get campaignMapUnavailable => '지도를 잠깐 못 불러왔어요.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return '$name 닫기';
  }

  @override
  String get campaignMapPreviousStop => '이전 목적지';

  @override
  String get campaignMapNextStop => '다음 목적지';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. 제$chapter장, $route. 곧 공개.',
      'locked': '$region. 제$chapter장, $route. 잠김.',
      'other': '$region. 제$chapter장, $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return '제$chapter장 · $route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level, $name, 보스',
      'guardian': '레벨 $level, $name, 수호자 $boss',
      'other': '레벨 $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. 잠김.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. 잠김. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '별 3개 중 $stars개',
    );
    return '$node. 다음 차례. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '별 3개 중 $stars개',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': '가고일',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return '제$chapter장 엽서';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '캠페인 별 $total개 중 $stars개',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => '배달부에게,';

  @override
  String get campaignPostcardPs => '추신';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return '$route에서 온 엽서. 배달부에게, $body 추신: $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => '안녕! 여기는';

  @override
  String get campaignPostcardHeader => '하늘 클럽 엽서';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => '배달부님께';

  @override
  String get campaignPostcardAddressStreet => '하늘 클럽 우체국';

  @override
  String get campaignPostcardAddressCity => '저 높은 하늘 위';

  @override
  String get campaignPostmarkDelivered => '배달 완료';

  @override
  String get campaignPostmarkClub => '하늘 클럽 우체국';

  @override
  String get campaignStampSkyClub => '하늘 클럽';

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
    return '$sender의 감사 쪽지: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => '준비는 조금, 하늘은 가득.';

  @override
  String get flightSetupTitleSquat => '발은 단단히. 날개는 활짝.';

  @override
  String get flightSetupTitleJump => '작은 점프. 큰 날개.';

  @override
  String flightSetupBuiltTag(String name) {
    return '레벨 · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · 기록 비행';
  }

  @override
  String get flightSetupRoomPushUp => '움직일 공간을 조금 만들어요.';

  @override
  String get flightSetupRoomBody => '온몸이 다 보이게 해요.';

  @override
  String get flightSetupTipsPushUp =>
      '휴대폰은 낮게. 팔 하나와 엉덩이가 보이게.\n정면이라면? 양어깨가 다 보이게.';

  @override
  String get flightSetupTipsSquat => '앉으면 내려가고, 서면 올라가요.\n두 발은 바닥에 붙여요.';

  @override
  String get flightSetupTipsJump => '점프하면 부스트 + 3초 활공.\n착지한 뒤에 다시 뛰어요.';

  @override
  String get flightSetupHowToFly => '나는 방법';

  @override
  String get flightSetupStep1PushUp => '팔과 엉덩이가 보이게';

  @override
  String get flightSetupStep1Squat => '스쿼트할 공간 만들기';

  @override
  String get flightSetupStep1Jump => '점프할 공간 만들기';

  @override
  String get flightSetupStep1DetailPushUp =>
      '휴대폰을 마주 보나요? 양어깨, 팔 하나, 엉덩이가 보이게 해요.';

  @override
  String get flightSetupStep1DetailBody => '휴대폰은 가로로. 몸과 두 발이 다 보이게 해요.';

  @override
  String get flightSetupStep2PushUp => '움직이는 범위 찾기';

  @override
  String get flightSetupStep2Squat => '편한 스쿼트 자세 찾기';

  @override
  String get flightSetupStep2Jump => '똑바로 가만히 서기';

  @override
  String get flightSetupStep2DetailPushUp => '편한 윗자세를 찾고, 내려갔다 올라오기를 두 번 해요.';

  @override
  String get flightSetupStep2DetailSquat => '가만히 섰다가 앉아서 잠깐 버틴 뒤 다시 일어나요.';

  @override
  String get flightSetupStep2DetailJump => '잠깐 가만히 있다가 점프하면 크게 부스트!';

  @override
  String get flightSetupStep3Stars => '별 모으기';

  @override
  String get flightSetupStep3DetailJump =>
      '별 하나에 활공 0.75초, 최대 5초. 별 삼총사를 모으면 +5점.';

  @override
  String get flightSetupLivesEndless => '하트 셋 + 보호막 하나. 언제든 멈출 수 있어요.';

  @override
  String get flightSetupLivesClassic =>
      '부딪히거나 자세를 놓치면 기록 비행이 끝나요. 언제든 멈출 수 있어요.';

  @override
  String get flightSetupCameraButton => '카메라 준비하기';

  @override
  String get flightMicTitle => '마이크 녹음';

  @override
  String get flightMicOn => '켜짐';

  @override
  String get flightMicOptional => '선택';

  @override
  String get flightMicDetail =>
      '다시 보기에 내 목소리와 주변 소리를 넣어요. 마이크는 비행 중에만 쓰고, 이 휴대폰에 저장돼요.';

  @override
  String get flightMicSemantics => '다시 보기용 마이크 녹음';

  @override
  String get flightMicSettings => '마이크 설정';

  @override
  String get flightCalibrationTitleReady => '날개를 찾았어요!';

  @override
  String get flightCalibrationTitleWaking => '카메라를 깨우는 중…';

  @override
  String get flightCalibrationTitleError => '카메라를 다시 연결해 봐요.';

  @override
  String get flightCalibrationTitleRange => '움직이는 범위를 찾아요.';

  @override
  String get flightCalibrationTitleStill => '똑바로 가만히 서요.';

  @override
  String get flightCalibrationStepTry => '새를 움직여 봐요.';

  @override
  String get flightCalibrationStepTop => '편한 윗자세를 찾아요.';

  @override
  String get flightCalibrationStepLower => '천천히 내려가요.';

  @override
  String get flightCalibrationStepPushBack => '다시 밀어 올라와요.';

  @override
  String get flightCalibrationStepStill => '똑바로 가만히 서요.';

  @override
  String get flightCalibrationStepSquat => '편하게 스쿼트해요.';

  @override
  String get flightCalibrationStepStandUp => '다시 일어나요.';

  @override
  String get flightCalibrationStepDone => '날개를 찾았어요!';

  @override
  String get flightCalibrationReadyPushUp => '밀어 올리면 상승, 내려가면 활공.';

  @override
  String get flightCalibrationReadySquat => '앉으면 내려가고, 서면 올라가요.';

  @override
  String get flightCalibrationReadyJump => '점프하고, 새가 활공하는 동안 쉬어요.';

  @override
  String get flightCalibrationKeepPushUp => '양어깨, 팔 하나, 엉덩이가 보이게 해요. 편하게 움직여요.';

  @override
  String get flightCalibrationKeepBody => '어깨, 엉덩이, 두 발이 다 보이게 해요.';

  @override
  String get flightCalibrationLearning => '움직이는 동안 범위를 익히는 중.';

  @override
  String get flightCalibrationAfter => '보정이 끝나면 새가 움직여요.';

  @override
  String get flightCalibrationJump => '점프!';

  @override
  String get flightCalibrationTagCheck => '조작 확인';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '팔굽혀펴기 $count/2';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '$percent% 보정됨';
  }

  @override
  String get flightCalibrationTakeoff => '이륙 준비 완료';

  @override
  String get flightCalibrationStarting => '시작 중…';

  @override
  String get flightCalibrationRestart => '보정 다시 시작';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate회/초 · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate회/초 · $p95 ms p95 (처리 시간만)';
  }

  @override
  String get flightCalibrationStatusReady => '준비 완료';

  @override
  String get flightCalibrationStatusStarting => '시작 중';

  @override
  String get flightCalibrationStatusCameraOff => '카메라 꺼짐';

  @override
  String get flightCalibrationStatusCalibrating => '보정 중';

  @override
  String get flightSwitchCameraSemantics => '카메라 전환';

  @override
  String get flightCalibrationStepIntoView => '화면 안으로 들어와요';

  @override
  String get flightCameraTroubleTitle => '새로 시작하면 보통 괜찮아져요.';

  @override
  String get flightCameraTroubleAllow => '설정에서 카메라 접근을 허용해요.';

  @override
  String get flightCameraTroubleClose => '다른 카메라 앱을 닫고 다시 시도해요.';

  @override
  String get flightCameraPermissionSemantics => '카메라 권한 설정';

  @override
  String get flightNoteRememberFailed => '이번 비행에만 바뀌었어요. 설정을 기억하지 못했어요.';

  @override
  String get flightNoteMicUnavailable => '마이크를 쓸 수 없어요. 영상과 게임은 그대로 돼요.';

  @override
  String get flightNoteMicBlocked => '마이크가 막혀 있어요. 설정에서 허용할 수 있어요. 영상은 그대로 돼요.';

  @override
  String get flightNoteMicOff => '마이크 꺼짐. 그래도 플레이하고 영상을 저장할 수 있어요.';

  @override
  String get flightNoteVideoUnavailable => '카메라 영상을 쓸 수 없어요. 게임 기록은 저장할 수 있어요.';

  @override
  String get flightNoteMicAudioLost =>
      '마이크 소리를 쓸 수 없었어요. 영상과 게임 기록은 저장할 수 있어요.';

  @override
  String get flightNoteVideoInterrupted =>
      '카메라 영상이 끊겼어요. 남은 영상과 게임 기록은 저장할 수 있어요.';

  @override
  String get flightNoteSessionSaveFailed =>
      '다시 보기를 저장하지 못했어요. ‘다시 보기 저장’을 탭해 다시 시도해요.';

  @override
  String get flightNoteWakingCamera => '카메라를 깨우는 중…';

  @override
  String get flightNoteCameraOff =>
      '카메라 접근이 꺼져 있어요. 안드로이드 설정에서 허용한 뒤 돌아와 다시 시도해요.';

  @override
  String get flightNoteCameraFailed => '카메라를 켜지 못했어요. 다시 시도하거나 카메라를 바꿔요.';

  @override
  String get flightNotePreparing => '비행 준비 중…';

  @override
  String get flightNoteSaveFailed => '비행을 저장하지 못했어요. 탭해서 다시 시도해요.';

  @override
  String get flightNoteWelcomeBack => '다시 왔네요. 자세를 한 번 더 확인해요.';

  @override
  String get flightNoteCameraInterrupted => '카메라가 끊겼어요. 카메라 권한을 확인하고 다시 시도해요.';

  @override
  String get flightNoteTrackingInterrupted => '동작 인식이 끊겼어요';

  @override
  String get flightFindPosition => '자리를 잡아요';

  @override
  String get flightTapSemantics => '탭해서 날갯짓';

  @override
  String flightTapVanguardSemantics(String group) {
    return '탭해서 날갯짓. 보스보다 먼저 $group 등장';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return '탭해서 날갯짓. $boss: 체력 $maxHp 중 $hp';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return '탭해서 날갯짓. $boss: 체력 $maxHp 중 $hp. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => '결과로 건너뛰기';

  @override
  String get hudPauseSemantics => '비행 일시 정지';

  @override
  String get flightHintTestSteerKeys => '시험 비행: 위·아래 방향키로 조종.';

  @override
  String get flightHintTestSteerDrag => '시험 비행: 위아래로 드래그해 조종.';

  @override
  String get flightHintTestJumpKeys => '시험 비행: Space 키로 점프.';

  @override
  String get flightHintTestJumpTap => '시험 비행: 탭하면 점프.';

  @override
  String get flightHintKeysStars => 'Space로 날갯짓. 별을 지나며 날아요.';

  @override
  String get flightHintKeysShoot => 'Space로 날갯짓. D를 꾹 눌러 충전 발사.';

  @override
  String get flightHintKeysCombat => 'Space로 날갯짓. D를 꾹 눌러 충전 발사. A로 대시!';

  @override
  String get flightHintKeysPause => 'Space로 날갯짓. Esc로 일시 정지.';

  @override
  String get flightHintTapStars => '하늘을 탭해 날갯짓. 별을 지나며 날아요.';

  @override
  String get flightHintTapShoot => '하늘을 탭해 날갯짓. 발사를 꾹 눌러 충전해요.';

  @override
  String get flightHintTapCombat => '하늘을 탭해 날갯짓. 발사를 꾹 눌러 충전. 대시로 박살!';

  @override
  String get flightHintTapRelease => '탭해서 날갯짓. 탭 사이엔 손을 떼요.';

  @override
  String get flightHintTrail => '별을 따라가요. 보호막 준비 완료.';

  @override
  String get flightHintSky => '하늘이 활짝 열렸어요.';

  @override
  String hudClockSemantics(String time) {
    return '$time 남음';
  }

  @override
  String flightSeconds(String seconds) {
    return '$seconds초';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '별 자석: $seconds초 남음',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: '자석 충전 중: 퍼펙트 관문 $gates개 중 $charge개',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => '찾는 중…';

  @override
  String get hudShoot => '발사';

  @override
  String get hudSprint => '대시';

  @override
  String get flightTestNothingSaved => '저장 안 됨';

  @override
  String get flightCountdownReady => '제자리에, 준비…';

  @override
  String get flightPauseTitle => '잠깐 숨 돌리자.';

  @override
  String get flightPauseKeepFlying => '계속 날기';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. 새가 횃대에 앉아 기다려요.';
  }

  @override
  String flightPausedTest(String name) {
    return '$name 시험 비행. 아무것도 저장되지 않아요.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. 새가 횃대에 앉아 기다려요.';
  }

  @override
  String get flightPausedTouch => '새가 횃대에 앉아 기다려요. 카운트다운 후에 다시 출발해요.';

  @override
  String get flightPausedCamera => '몸을 한번 털고 다시 자세를 잡아요. 카운트다운 후에 출발해요.';

  @override
  String get flightPauseEdit => '편집';

  @override
  String get flightPauseBuilder => '만들기';

  @override
  String get flightPauseFinish => '비행 끝내기';

  @override
  String get hudShieldRecovering => '회복 중';

  @override
  String get hudShieldReady => '보호막 준비됨';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '보호막 충전 중: 별 $stars개 중 $charge개',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '하트 $count개 남음',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => '대시 중';

  @override
  String get hudSprintReady => '준비됨';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '충전 중, $seconds초',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint => '앞으로 돌진해 박쥐와 돌판을 박살 내요';

  @override
  String get hudShotReloading => '장전 중…';

  @override
  String hudShotFullCharge(int ms) {
    return '완전 충전, ${ms}ms 남음';
  }

  @override
  String hudShotCharging(int percent) {
    return '충전 $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return '탄약 $percent%';
  }

  @override
  String get hudShotHint => '꾹 누르면 더 큰 돌멩이를 충전해요';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개 달성',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$at개 모으면 별 $count개',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '별 $stars개 모음',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => '최대';

  @override
  String hudRouteSemantics(int percent) {
    return '항로 $percent% 비행';
  }

  @override
  String hudGlideCompact(String time) {
    return '활공 · $time';
  }

  @override
  String get hudJumpToGlide => '점프해서 활공';

  @override
  String get hudJump => '점프';

  @override
  String hudGlideSemantics(String time) {
    return '활공, $time 남음';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return '활공 곧 끝남, $time 남음';
  }

  @override
  String get hudJumpChargeSemantics => '점프하면 3초 활공이 충전돼요';

  @override
  String get hudRecordNewBest => '새 최고 기록!';

  @override
  String get hudRecordMatched => '최고와 동점!';

  @override
  String hudRecordBest(int best) {
    return '최고 $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '최고보다 +$points';
  }

  @override
  String get hudRecordOneMore => '신기록까지 1점!';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '신기록까지 $count점',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return '점수 $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return '점수 $score, 배율 $multiplier배';
  }

  @override
  String get commonBusySemantics => '처리 중';

  @override
  String get flightResultBumpClouds => '구름 속에서 살짝 콩!';

  @override
  String get flightResultPersonalBest => '개인 최고 기록';

  @override
  String get flightResultNewPersonalBest => '새 개인 최고 기록!';

  @override
  String get flightResultStarsCollected => '모은 별';

  @override
  String get flightResultDailyStamped => '오늘의 엽서에 도장 쾅!';

  @override
  String flightResultNextStamp(String stamp) {
    return '다음: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => '이 휴대폰에 저장됨';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '이 휴대폰에 저장됨 · 총 관문 $total개',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => '비행 저장 중…';

  @override
  String get flightResultSessionSaved => '다시 보기 저장됨 · 기록실에서 보기';

  @override
  String get flightResultWatchReplay => '다시 보기';

  @override
  String get flightResultPreparing => '준비 중…';

  @override
  String get flightResultSavingShort => '저장 중…';

  @override
  String get flightResultSaveSession => '다시 보기 저장';

  @override
  String get flightResultFlyAgain => '다시 날기';

  @override
  String get commonRetry => '다시 하기';

  @override
  String get commonMap => '지도';

  @override
  String get commonNext => '다음';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '팔굽혀펴기',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '스쿼트',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '점프',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '날갯짓',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => '비행 시간';

  @override
  String get flightStatPerfect => '퍼펙트';

  @override
  String get flightStatBestStreak => '최고 콤보';

  @override
  String get flightStatRank => '등급';

  @override
  String get flightRankSkyCaptain => '하늘의 기장';

  @override
  String get flightRankCloudExplorer => '구름 탐험가';

  @override
  String get flightRankFirstWings => '첫 날개';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => '콩! 그래도 새 최고 기록!';

  @override
  String get gameOverCaptionSea => '바다에 살짝 풍덩.';

  @override
  String get gameOverSplash => '풍덩!';

  @override
  String get gameOverBonk => '콩!';

  @override
  String get gameOverEveryMarkSemantics => '모든 별 눈금 달성';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $mark개까지 별 $count개 더',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: 체력 $maxHp 중 $hp 남음';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '항로의 $percent퍼센트 비행';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: 체력 $hp 남음';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$boss 남은 체력';
  }

  @override
  String get gameOverRouteFlown => '비행한 항로';

  @override
  String gameOverHp(int hp) {
    return '$hp HP';
  }

  @override
  String gameOverMoreFor(int count) {
    return '$count개 더 모으면';
  }

  @override
  String get gameOverBothMarks => '별 눈금 둘 다 달성';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    return '눈금 달성! 이제 $boss 격파!';
  }

  @override
  String get miniResultTitle => '모든 비행이 소중해요.';

  @override
  String get miniResultComplete => '비행 완료';

  @override
  String get miniResultCheerBest => '정말 대단해요!';

  @override
  String get miniResultCheerComplete => '비행 완료!';

  @override
  String get miniResultCheerNice => '멋진 비행이었어요.';

  @override
  String get miniResultNew => '신규';

  @override
  String get flightEndTrackingLost => '잠깐 모습을 놓쳤어요.';

  @override
  String get flightEndPostureLost => '자세가 범위를 벗어났어요.';

  @override
  String get flightEndBackgrounded => '하늘을 잠깐 떠났어요.';

  @override
  String get flightEndBreak => '충분히 쉴 자격이 있어요.';

  @override
  String get flightEndQuit => '다음 모험에서 만나요.';

  @override
  String get flightEndStalled => '게임이 중단됐어요.';

  @override
  String get flightEndCompleted => '하늘 가득한 별을 다 모았어요!';

  @override
  String get levelResultTryAgain => '다시 해 보자!';

  @override
  String get levelResultVictory => '승리!';

  @override
  String get levelResultGuardianDown => '수호자 격파!';

  @override
  String get levelResultDelivered => '배달 완료!';

  @override
  String levelResultComingSoon(String region) {
    return '$region, 곧 공개!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '별 3개 중 $earned개';
  }

  @override
  String levelResultBest(int best) {
    return '최고 $best';
  }

  @override
  String get levelResultNoBest => '최고 기록 없음';

  @override
  String get levelResultFirstClear => '첫 클리어!';

  @override
  String get levelResultNewBest => '신기록!';

  @override
  String get levelResultScore => '점수';

  @override
  String get levelResultGoalBoss => '보스';

  @override
  String get levelResultGoalGuardian => '수호자';

  @override
  String get levelResultGoalFinish => '결승선';

  @override
  String get levelResultGoalDone => '완료';

  @override
  String get levelResultGoalNotYet => '아직';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 남음',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => '결승선부터';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. 완료.';
  }

  @override
  String get levelResultPostcardWaiting => '지도에서 엽서가 기다려요!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '$id $name, 이제 열렸어요!';
  }

  @override
  String get levelResultReachFinish => '결승선에 도착해야 별을 받아요.';

  @override
  String get course_classic_title => '클래식';

  @override
  String get course_starTrail_title => '무한 비행';

  @override
  String get course_classic_instructions => '틈을 찾아요. 조준점을 따라가면 퍼펙트 통과.';

  @override
  String get course_starTrail_instructions =>
      '한 무리의 별 3개를 모두 모으면 +5. 별 콤보로 최대 3×. 별은 보호막을 채우고, 퍼펙트 관문은 별 자석을 줘요. 둘 다 별로 업그레이드해요!';

  @override
  String get course_classic_scoreLabel => '장애물';

  @override
  String get course_starTrail_scoreLabel => '별 점수';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '관문',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '점',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics => '클래식: 틈 사이로 날아요.';

  @override
  String get course_starTrail_previewSemantics => '무한 비행: 하트 셋과 보호막으로 별을 모아요.';

  @override
  String get obstacle_garden_name => '정원 관문';

  @override
  String get obstacle_windLift_name => '바람 관문';

  @override
  String get obstacle_petalGate_name => '꽃잎 덧문';

  @override
  String get obstacle_switchback_name => '지그재그';

  @override
  String get obstacle_lanternDrift_name => '떠도는 등불';

  @override
  String get obstacle_sunWheels_name => '태양 바퀴';

  @override
  String get obstacle_crystalSteps_name => '수정 계단';

  @override
  String get rush_wildfire_name => '산불';

  @override
  String get rush_wildfire_escape => '산불을 따돌렸다';

  @override
  String get rush_skyfall_name => '하늘사태';

  @override
  String get rush_skyfall_escape => '하늘사태를 버텨 냈다';

  @override
  String get rush_eruption_name => '분화';

  @override
  String get rush_eruption_escape => '분화를 이겨 냈다';

  @override
  String get rush_swarm_name => '박쥐 떼';

  @override
  String get rush_swarm_escape => '박쥐 떼를 뚫고 나왔다';

  @override
  String get boss_baronBat_title => '폭풍의 군주';

  @override
  String get boss_spitterBeetle_title => '벌레 떼의 양조가';

  @override
  String get boss_duskMoth_title => '황혼 베일의 수호자';

  @override
  String get boss_pirate_title => '밀물의 공포';

  @override
  String get boss_dragon_title => '불타는 하늘의 제왕';

  @override
  String get boss_kingCoo_title => '길모퉁이 서장';

  @override
  String get boss_searchlightGargoyle_title => '가장 높은 탑의 파수꾼';

  @override
  String get boss_neferhoo_title => '잃어버린 편지의 지킴이';

  @override
  String get boss_baronBat_returnTitle => '폭풍의 귀환';

  @override
  String get boss_baronBat_barName => '박쥐 남작';

  @override
  String get boss_spitterBeetle_barName => '퉤퉤 왕';

  @override
  String get boss_duskMoth_barName => '황혼 여제';

  @override
  String get boss_pirate_barName => '해적 선장';

  @override
  String get boss_dragon_barName => '불씨 드래곤';

  @override
  String get boss_kingCoo_barName => '킹구구';

  @override
  String get boss_searchlightGargoyle_barName => '가고일';

  @override
  String get boss_neferhoo_barName => '네페르후';

  @override
  String get vanguard_baronBat_title => '박쥐 남작의 박쥐들';

  @override
  String get vanguard_baronBat_call => '몰려와요! 남작이 바로 뒤에 있어요.';

  @override
  String get vanguard_spitterBeetle_title => '퉤퉤 왕의 새끼들';

  @override
  String get vanguard_spitterBeetle_call => '몰려와요! 퉤퉤 왕이 바로 뒤에 있어요.';

  @override
  String get vanguard_duskMoth_title => '황혼 여제의 나방들';

  @override
  String get vanguard_duskMoth_call => '몰려와요! 여제가 바로 뒤에 있어요.';

  @override
  String get vanguard_kingCoo_title => '킹구구 비행대';

  @override
  String get vanguard_kingCoo_call => '몰려와요! 킹구구가 바로 뒤에 있어요.';

  @override
  String get vanguard_kingCoo_callCrusts => '몰려와요! 빵 껍질을 피해요!';

  @override
  String get vanguard_kingCoo_callReturns => '빵 껍질을 피해요! 하나라도 놓치면 다시 와요!';

  @override
  String get bossVanguardClear => '클리어!';

  @override
  String get bossVanguardLeft => '남음';

  @override
  String get bossStragglersCaught => '모두 잡았다!';

  @override
  String get bossHint_strongerBaronBat => '강화 · 세 발씩 쏘고, 박쥐들도 합류해요!';

  @override
  String get bossHint_strongerSpitterBeetle => '강화 · 꽉 찬 부채꼴, 딱정벌레들도 합류해요!';

  @override
  String get bossHint_strongerDuskMoth => '강화 · 일곱 발 부채꼴, 나방들도 합류해요!';

  @override
  String get bossHint_strongerPirate => '강화 · 밀물이 차올라요!';

  @override
  String get bossHint_strongerDragon => '강화 · 숨결과 박쥐 떼를 조심해요!';

  @override
  String get bossHint_strongerKingCoo => '강화 · 휘파람으로 비행대를 불러요!';

  @override
  String get bossHint_strongerGargoyleFierce => '강화 · 가슴 등이 열리면 깃털이 떨어져요!';

  @override
  String get bossHint_strongerGargoyle => '강화 · 돌 깃털이 떨어져요!';

  @override
  String get bossHint_strongerNeferhooTougher => '강화 · 앙크, 그리고 미라 박쥐들!';

  @override
  String get bossHint_strongerNeferhoo => '강화 · 황금 앙크가 돌아와요!';

  @override
  String get bossHint_tideRising => '밀물 상승 · 높이 날아요!';

  @override
  String get bossHint_highTide => '만조 · 물 위에 머물러요';

  @override
  String get bossHint_tideFury => '분노 · 밀물 사이사이 일제 포격';

  @override
  String get bossHint_tideCalm => '대포알을 피해요 · 물에 닿지 마요';

  @override
  String get bossHint_dragonSwarm => '박쥐 떼 · 피하거나 대시로 뚫어요';

  @override
  String get bossHint_dragonFuryDebut => '분노 · 더 빨라진 불덩이';

  @override
  String get bossHint_dragonFury => '분노 · 불덩이가 불씨로 터져요';

  @override
  String get bossHint_dragonCalm => '불덩이를 피해요 · 숨결을 조심해요';

  @override
  String get bossHint_screechFury => '분노 · 더 빠른 불덩이, 더 많은 박쥐';

  @override
  String get bossHint_screechCalm => '불덩이와 박쥐를 피해요 · 괴성을 조심해요';

  @override
  String get bossHint_cooPopped => '펑! · 비행대 없음';

  @override
  String get bossHint_cooSquadron => '비행대 · 열린 길로 가요!';

  @override
  String get bossHint_cooPuffed => '가슴 부풀리기 · 가슴을 쏴요 (x2)!';

  @override
  String get bossHint_cooCrumbBomb => '빵가루 폭탄 · 원 밖으로!';

  @override
  String get bossHint_cooFury => '분노 · 원과 원 사이에 있어요';

  @override
  String get bossHint_cooCalm => '빵가루 폭탄을 피해요 · 가슴이 부풀면 쏴요';

  @override
  String get bossHint_beamOn => '빛줄기 · 어둠 속에 있어요';

  @override
  String get bossHint_beamFury => '분노 · 빛줄기 사이로 빠져나가요';

  @override
  String get bossHint_beamIncomingHigh => '빛줄기 접근 · 낮게 날아요!';

  @override
  String get bossHint_beamIncomingLow => '빛줄기 접근 · 높이 날아요!';

  @override
  String get bossHint_lampOpen => '가슴 등 열림 · 등을 쏴요!';

  @override
  String get bossHint_shuttersClosed => '덧문 닫힘 · 돌멩이를 아껴요';

  @override
  String get bossHint_mothFuryNoVeil => '분노 · 일곱 발 부채꼴. 아직 베일 없음!';

  @override
  String get bossHint_mothNoVeil => '아직 베일 없음 · 부채꼴 사이로 쏴요!';

  @override
  String get bossHint_mothShielded => '베일 보호 중 · 베일이 걷힐 때까지 피해요';

  @override
  String get bossHint_mothShieldForming => '베일 생성 중 · 피할 준비!';

  @override
  String get bossHint_mothFury => '분노 · 일곱 발 부채꼴. 베일이 걷혔어요!';

  @override
  String get bossHint_mothCalm => '베일이 걷혔어요 · 부채꼴 사이로 쏴요!';

  @override
  String get bossHint_neferhooMailCall => '편지 왔소 · 쏴서 돌려보내요!';

  @override
  String get bossHint_neferhooReturn => '보낸 이에게 반송! · −25';

  @override
  String get bossHint_neferhooReturnFaster => '보낸 이에게 반송! · −18';

  @override
  String get bossHint_neferhooAnkh => '앙크 · 다시 돌아와요!';

  @override
  String get bossHint_neferhooExpress => '빠른우편 · 편지 다섯 통, 더 빠르게';

  @override
  String get bossHint_neferhooTwoAnkhs => '앙크 두 개 · 두 길 모두 피해요';

  @override
  String get bossHint_neferhooBats => '미라 박쥐 · 쏴서 떨어뜨려요!';

  @override
  String get bossHint_neferhooScuff => '돌멩이는 붕대만 살짝 긁어요. ‘편지’를 쏴서 돌려보내요!';

  @override
  String get bossHint_neferhooWarmUp => '편지를 쏴서 돌려보내요 · 보낸 이에게 반송';

  @override
  String get bossHint_neferhooCalm => '편지를 쏴서 돌려보내요 · 황금 앙크를 피해요';

  @override
  String get bossHint_neferhooFury => '분노 · 빠른우편과 앙크 두 개';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': '드래곤의 숨결 · 낮게 날아요! 심장이 열렸어요',
      'middle': '드래곤의 숨결 · 위나 아래로! 심장이 열렸어요',
      'other': '드래곤의 숨결 · 높이 날아요! 심장이 열렸어요',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': '불길 · 낮게 날아요! 빛나는 심장을 쏴요',
      'middle': '불길 · 위나 아래로! 빛나는 심장을 쏴요',
      'other': '불길 · 높이 날아요! 빛나는 심장을 쏴요',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': '초음파 괴성 · 위쪽 틈으로!',
      'middle': '초음파 괴성 · 가운데 틈으로!',
      'other': '초음파 괴성 · 아래쪽 틈으로!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': '괴성 · 위쪽 틈에 머물러요',
      'middle': '괴성 · 가운데 틈에 머물러요',
      'other': '괴성 · 아래쪽 틈에 머물러요',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth => '부채꼴을 피해요  ·  베일이 걷히면 쏴요';

  @override
  String get encounterCaption_pirate => '대포를 피해요  ·  물에 닿지 마요';

  @override
  String get encounterCaption_dragon => '불덩이를 피해요  ·  숨결에서 벗어나요';

  @override
  String get encounterCaption_kingCoo => '원 밖으로  ·  가슴이 부풀면 쏴요';

  @override
  String get encounterCaption_searchlightGargoyle => '빛을 피해요  ·  가슴 등이 열리면 쏴요';

  @override
  String get encounterCaption_neferhoo => '준비해요  ·  편지를 쏴서 돌려보내요';

  @override
  String get encounterCaption_screech => '괴성이 울리면  ·  틈으로 날아가요';

  @override
  String get encounterCaption_default => '준비해요  ·  날갯짓, 피하기, 발사';

  @override
  String get encounterCoasting => '새가 안전하게 날고 있어요';

  @override
  String get encounterOpenSky => '다시 탁 트인 하늘로';

  @override
  String get encounterOmenTitle_duskMoth => '황혼이 날개를 편다';

  @override
  String get encounterOmenLine_duskMoth => '비단 베일이 황혼 속에 드리운다…';

  @override
  String get encounterOmenTitle_spitterBeetle => '뭔가 끓고 있다';

  @override
  String get encounterOmenLine_spitterBeetle => '공기가 부글부글 끓어오른다…';

  @override
  String get encounterOmenTitle_dragon => '하늘에 불이 붙는다';

  @override
  String get encounterOmenLine_dragon => '구름 위에서 거대한 날개가 퍼덕인다…';

  @override
  String get encounterOmenTitle_kingCoo => '길모퉁이 봉쇄';

  @override
  String get encounterOmenLine_kingCoo => '누군가 빵 수레 때문에 단단히 화가 났다…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => '폭풍 경보';

  @override
  String get encounterOmenLine_searchlightGargoyle => '난간 위의 무언가가 지켜보고 있다…';

  @override
  String get encounterOmenTitle_neferhoo => '피라미드가 꿈틀댄다';

  @override
  String get encounterOmenLine_neferhoo => '피라미드의 먼지가 일렁인다…';

  @override
  String get encounterOmenTitle_baronReturns => '남작의 귀환';

  @override
  String get encounterOmenLine_baronReturns => '그가 돌아왔다, 훨씬 더 시끄럽게…';

  @override
  String get encounterOmenTitle_default => '그림자가 다가온다';

  @override
  String get encounterOmenLine_default => '하늘의 주인이 따로 있다…';

  @override
  String get encounterOmenTitle_pirate => '돛이 보인다!';

  @override
  String get encounterOmenLine_pirate => '밀물을 타고 배 한 척이 다가온다…';

  @override
  String get bossGuardianEyebrow => '수호자';

  @override
  String bossEncounterEyebrow(String number) {
    return '조우 $number';
  }

  @override
  String get bossGuardianDown => '수호자 격파!';

  @override
  String get bossSkyReclaimed => '하늘 탈환';

  @override
  String bossVictoryPoints(int points) {
    return '+$points점   ·   보호막 회복';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': '박쥐 남작 격파',
      'spitterBeetle': '퉤퉤 왕 격파',
      'duskMoth': '황혼 여제 격파',
      'pirate': '해적 선장 격파',
      'dragon': '불씨 드래곤 격파',
      'kingCoo': '킹구구 격파',
      'searchlightGargoyle': '탐조등 가고일 격파',
      'other': '네페르후 격파',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '“$line”';
  }

  @override
  String get bossPirateRoar => '요호호!';

  @override
  String get bossGargoyleCardSmall => '탐조등';

  @override
  String get bossGargoyleCardBig => '가고일';

  @override
  String get bossGargoyleCardOrder => 'small-big';

  @override
  String get bossDodgeFlyLow => '낮게 날아!';

  @override
  String get bossDodgeFlyHigh => '높이 날아!';

  @override
  String get bossDodgeClimbOrDive => '위나 아래로!';

  @override
  String get bossDodgeSlipBetween => '빛줄기 사이로\n빠져나가!';

  @override
  String get bossSpotted => '발각!';

  @override
  String get bossShieldLost => '보호막 잃음';

  @override
  String get bossHeartLost => '하트 -1';

  @override
  String get bossGargoyleLampOpen => '가슴 등 열림';

  @override
  String get bossGargoyleShoot => '쏴!';

  @override
  String get bossScreechFlyToGap => '틈으로 날아!';

  @override
  String get bossScreechHoldGap => '틈에서 버텨!';

  @override
  String get bossPirateHighTide => '만조';

  @override
  String get bossBarDefeated => '격파';

  @override
  String get bossBarIncoming => '등장 중';

  @override
  String get bossBarFury => '분노';

  @override
  String get bossBarHeartDouble => '심장 ×2';

  @override
  String get bossStronger => '강화!';

  @override
  String get bossKingCooPuffed => '부풀림';

  @override
  String get bossKingCooShout => '구구!';

  @override
  String get bossKingCooPop => '펑!';

  @override
  String get bossKingCooPoof => '푸슉!';

  @override
  String get bossSquadOpenLane => '열린 길로!';

  @override
  String get bossSquadUseGap => '틈으로 가!';

  @override
  String get bossSquadThenV => '다음: V';

  @override
  String get bossSquadThenGap => '다음: 틈';

  @override
  String get bossSquadCancelled => '비행대 해산';

  @override
  String get bossNeferhooFound => '잃어버린 편지를 찾았다';

  @override
  String get bossNeferhooHoo => '후';

  @override
  String get bossNeferhooPoo => '투';

  @override
  String get bossNeferhooMailCall => '편지 왔소';

  @override
  String get bossNeferhooExpressPost => '빠른우편';

  @override
  String get bossNeferhooShootBack => '쏴서 돌려보내요!';

  @override
  String get bossNeferhooAnkh => '앙크';

  @override
  String get bossNeferhooTwoAnkhs => '앙크 두 개';

  @override
  String get bossNeferhooComesBack => '다시 돌아와요!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '산불!',
      'skyfall': '하늘사태!',
      'eruption': '분화!',
      'other': '박쥐 떼!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '대시 링을 잡고 불길을 따돌려요!',
      'skyfall': '대시 링을 잡고 운석보다 빨리!',
      'eruption': '대시 링을 잡고 분화를 이겨 내요!',
      'other': '대시 링을 잡고 뚫고 나가요!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return '탈출! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return '무결점! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': '산불을 따돌렸어요',
      'skyfall': '하늘사태를 버텨 냈어요',
      'eruption': '분화를 이겨 냈어요',
      'other': '박쥐 떼를 뚫고 나왔어요',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => '강풍!';

  @override
  String encounterGaleDetail(String mark) {
    return '$mark 표시가 깜빡이면 잡동사니를 피해요!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return '버텼다! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail => '강풍을 견뎠어요';

  @override
  String get encounterAllRings => '링 모두 획득!';

  @override
  String encounterAllRingsDetail(String seconds) {
    return '터보 부스트 +$seconds초';
  }

  @override
  String get encounterFinish => '골인';

  @override
  String get builderMode_pushUp => '팔굽혀펴기';

  @override
  String get builderMode_squat => '스쿼트';

  @override
  String get builderMode_jump => '점프';

  @override
  String builderSeconds(String seconds) {
    return '$seconds초';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes분 $seconds초';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '팔굽혀펴기 $count회',
      one: '팔굽혀펴기 1회',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '스쿼트 $count회',
      one: '스쿼트 1회',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => '내 탭 레벨';

  @override
  String get builderNewLevel_pushUp => '내 팔굽혀펴기 레벨';

  @override
  String get builderNewLevel_squat => '내 스쿼트 레벨';

  @override
  String get builderNewLevel_jump => '내 점프 레벨';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => '내 레벨';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return '내 Beakbound 레벨 “$name”($mode) 같이 날아 보자: $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '별 $total개 중 $earned개';
  }

  @override
  String get builderBackSemantics => '뒤로';

  @override
  String get builderKeepIt => '그대로 두기';

  @override
  String builderLessSemantics(String name) {
    return '$name 줄이기';
  }

  @override
  String builderMoreSemantics(String name) {
    return '$name 늘리기';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => '복제';

  @override
  String get builderCopy => '복사';

  @override
  String get builderDeleteSemantics => '삭제';

  @override
  String get builderDelete => '삭제';

  @override
  String get builderMoreBelow => '아래에 더 있음';

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
    return '$percent%';
  }

  @override
  String get builderLane => '레인';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '스쿼트의 위 또는 아래',
      'other': '팔굽혀펴기의 위 또는 아래',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => '위';

  @override
  String get builderLaneBottom => '아래';

  @override
  String get builderHeight => '높이';

  @override
  String get builderHeightHint => '하늘 기준';

  @override
  String get builderLowerSemantics => '낮추기';

  @override
  String get builderHigherSemantics => '높이기';

  @override
  String get builderOpening => '틈 크기';

  @override
  String builderOpeningHint(int percent) {
    return '최소 $percent%';
  }

  @override
  String get builderNarrowerSemantics => '좁히기';

  @override
  String get builderWiderSemantics => '넓히기';

  @override
  String get builderMotion => '움직임';

  @override
  String get builderMotionGardenHint => '정원 관문은 움직이지 않아요';

  @override
  String get builderMotionStill => '고정';

  @override
  String get builderMotionGentle => '살랑';

  @override
  String get builderMotionLively => '출렁';

  @override
  String get builderMotionGardenToast =>
      '정원 관문은 움직이지 않아요. 움직이게 하려면 다른 관문 종류를 골라요.';

  @override
  String get builderSway => '흔들림';

  @override
  String builderSwayHint(String seconds) {
    return '한 번 흔들림: $seconds';
  }

  @override
  String get builderSwayFast => '빠름';

  @override
  String get builderSwayMedium => '보통';

  @override
  String get builderSwaySlow => '느림';

  @override
  String get builderPhase => '도착할 때';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position / $count';
  }

  @override
  String get builderPhaseHint => '흔들림 중 위치';

  @override
  String get builderPhaseEarlierSemantics => '흔들림에서 더 앞으로';

  @override
  String get builderPhaseLaterSemantics => '흔들림에서 더 뒤로';

  @override
  String get builderLook => '모양';

  @override
  String builderLookSemantics(int number) {
    return '모양 $number';
  }

  @override
  String get builderDoor => '돌문';

  @override
  String get builderDoorHint => '쏴서 열어요';

  @override
  String get builderDoorNone => '문 없음';

  @override
  String get builderDoorNeedsShootToast => '문을 쓰려면 레벨 설정에서 발사를 켜요.';

  @override
  String get builderPlace => '위치';

  @override
  String get builderPlaceHint => '출발부터';

  @override
  String get builderEarlierSemantics => '더 앞으로';

  @override
  String get builderLaterSemantics => '더 뒤로';

  @override
  String builderFamilySemantics(String family) {
    return '관문 종류: $family. 바꾸기';
  }

  @override
  String get builderChangeFamily => '종류 바꾸기';

  @override
  String get builderItemStar => '별';

  @override
  String get builderItemTrio => '별 삼총사';

  @override
  String get builderItemHeart => '하트';

  @override
  String get builderItemEnemy => '적';

  @override
  String get builderItemGate => '관문';

  @override
  String get builderItemStarDetail => '모을 별 하나';

  @override
  String get builderItemTrioDetail => '셋 다 모으면 보너스';

  @override
  String get builderItemHeartDetail => '하트 하나 회복';

  @override
  String get builderEnemyKind => '종류';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '새는 스쿼트할 때마다 위와 아래를 날아요. 아이템을 노란 선 위나 그 사이에 놓아요.',
      'other': '새는 팔굽혀펴기할 때마다 위와 아래를 날아요. 아이템을 노란 선 위나 그 사이에 놓아요.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => '보라 박쥐';

  @override
  String get builderEnemy_caveBat => '동굴 박쥐';

  @override
  String get builderEnemy_spitterBeetle => '퉤퉤 딱정벌레';

  @override
  String get builderEnemy_duskMoth => '황혼 나방';

  @override
  String get builderEnemy_alleyPigeon => '골목 비둘기';

  @override
  String get builderEnemy_mummyBat => '미라 박쥐';

  @override
  String get builderSummaryTitle => '이 레벨';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => '길이';

  @override
  String get builderFactStars => '별';

  @override
  String get builderFactMarks => '별 눈금';

  @override
  String get builderFactWorkout => '운동량';

  @override
  String get builderFactPace => '속도';

  @override
  String get builderFactBoss => '보스';

  @override
  String get builderPace_relaxed => '느긋하게';

  @override
  String get builderPace_steady => '꾸준하게';

  @override
  String get builderPace_brisk => '빠르게';

  @override
  String get builderSummaryStarterNote =>
      '그대로 날아도 되고, 리믹스해서 나만의 레벨로 만들어도 되는 기본 레벨이에요.';

  @override
  String get builderSummaryClearedNote => '직접 클리어: 결승선까지 날았어요.';

  @override
  String get builderSummaryClearNote => '결승선까지 시험 비행하면 클리어로 표시돼요.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    return '시험 비행에서 $boss 격파 후 결승선을 넘으면 클리어로 표시돼요.';
  }

  @override
  String get builderSummaryHowTo => '왼쪽에서 도구를 고르고 하늘을 탭해요. 탭하면 바꾸고, 끌면 옮겨요.';

  @override
  String get builderFamily_garden_detail => '움직이지 않아요. 돌문을 달 수 있어요.';

  @override
  String get builderFamily_windLift_detail => '틈이 오르락내리락해요.';

  @override
  String get builderFamily_petalGate_detail => '틈이 좁아졌다 넓어졌다 해요.';

  @override
  String get builderFamily_switchback_detail => '두 틈이 서로 멀어져요.';

  @override
  String get builderFamily_lanternDrift_detail => '매달린 등불이 둥실둥실.';

  @override
  String get builderFamily_sunWheels_detail => '바퀴가 다가왔다 물러나요.';

  @override
  String get builderFamily_crystalSteps_detail => '물결치는 계단 세 개.';

  @override
  String get builderFamiliesCloseSemantics => '관문 종류 닫기';

  @override
  String get builderFamiliesTitle => '관문 종류';

  @override
  String get builderFamiliesSubtitle => '관문의 모양과 움직임.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '레벨 이름을 $count자 이내로 지어요.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort => '결승선을 더 멀리 옮겨요. 레벨이 너무 짧아요.';

  @override
  String get reach_tooLong => '결승선을 더 가까이 옮겨요. 레벨이 너무 길어요.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '너무 많아요. 한 레벨에 최대 $count개까지예요.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap => '보스로 끝나는 건 탭 & 비행 레벨뿐이에요.';

  @override
  String get reach_noGates => '새가 지나갈 관문을 추가해요.';

  @override
  String get reach_startZone => '출발점에 너무 가까워요. 출발 구역 밖으로 옮겨요.';

  @override
  String get reach_finishRoom => '이 관문 뒤, 결승선 앞에 공간을 남겨요.';

  @override
  String get reach_overlap => '관문 두 개가 겹쳐요. 떨어뜨려 놓아요.';

  @override
  String get reach_gateHeight => '이 관문이 너무 높거나 낮아요.';

  @override
  String get reach_gateMotion => '이 관문은 그렇게 움직일 수 없어요.';

  @override
  String get reach_gateLook => '이 관문의 모양을 알 수 없어요.';

  @override
  String get reach_gateNarrow => '관문을 더 넓게 열어요. 새가 못 지나가요.';

  @override
  String get reach_gateWide => '이 관문이 너무 넓게 열려 있어요.';

  @override
  String get reach_doorNeedsShoot => '돌문은 발사가 켜진 탭 & 비행 레벨에서만 써요.';

  @override
  String get reach_doorNeedsGarden => '돌문은 정원 관문에만 달 수 있어요.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '빠듯한 전환: 꾸준한 스쿼트로는 제때 못 갈 수도 있어요.',
      'other': '빠듯한 전환: 꾸준한 팔굽혀펴기로는 제때 못 갈 수도 있어요.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb => '가파른 오르막: 이 관문까지 점프할 공간을 더 남겨요.';

  @override
  String get reach_enemyNeedsTap => '적은 탭 & 비행 레벨에서만 날아요.';

  @override
  String get reach_outsideSky => '하늘 안에 두어요.';

  @override
  String get reach_pastFinish => '결승선 앞에 놓아요.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '스쿼트로 닿지 않아요. 레인 가까이 옮겨요.',
      'other': '팔굽혀펴기로 닿지 않아요. 레인 가까이 옮겨요.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => '벽 속에 있어요. 틈 안으로 옮겨요.';

  @override
  String get reach_noStars => '별을 하나 이상 놓아요.';

  @override
  String get reach_marks => '별 눈금이 레벨에 있는 별보다 많아요.';

  @override
  String reach_cannotFly(String problem) {
    return '이 레벨은 아직 날 수 없어요($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      '레벨이 저장되지 않아 아직 날 수 없어요. 이름을 탭해 다시 시도해요.';

  @override
  String get builderShareBlockedToast => '빨간 깃발부터 고쳐요. 그러면 레벨을 공유할 수 있어요.';

  @override
  String get builderEditorBackSemantics => '만들기로 돌아가기';

  @override
  String get builderSettingsSemantics => '레벨 설정';

  @override
  String get builderFly => '날자!';

  @override
  String get builderTestFly => '시험 비행';

  @override
  String get builderFlySemantics => '이 레벨 날기';

  @override
  String get builderTestFlySemantics => '레벨 전체 시험 비행';

  @override
  String get builderUndoSemantics => '실행 취소';

  @override
  String get builderRedoSemantics => '다시 실행';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '팁 $advice개',
    );
    return '고칠 것 $blocking개, $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '팁 $advice개',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => '날 준비 완료';

  @override
  String get builderShareSemantics => '공유 코드';

  @override
  String get builderFromHereSemantics => '여기서부터 시험 비행';

  @override
  String get builderFromHere => '여기서부터';

  @override
  String get builderStatusStarter => '기본 레벨 · 보기, 날기, 리믹스';

  @override
  String get builderStatusSaveFailed => '저장 실패 · 탭해서 다시 시도';

  @override
  String get builderStatusSaving => '저장 중…';

  @override
  String get builderStatusSaved => '변경 사항 모두 저장됨';

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
    return '$name. $mode. $status. 탭해서 이름 바꾸기.';
  }

  @override
  String get builderStarterBanner => '리믹스해서 내 레벨로!';

  @override
  String get builderRemix => '리믹스';

  @override
  String get builderRemixSemantics => '리믹스';

  @override
  String get builderIssuesCloseSemantics => '문제와 팁 닫기';

  @override
  String get builderIssuesReadyTitle => '날 준비 완료!';

  @override
  String get builderIssuesFixTitle => '날기 전에 고칠 것';

  @override
  String get builderIssuesTipsTitle => '준비 완료, 팁 몇 개';

  @override
  String get builderIssuesReadyDetail => '고칠 게 없어요. 결승선까지 시험 비행하면 클리어돼요.';

  @override
  String get builderIssuesDetail => '하나를 탭하면 항로의 그 자리로 가요.';

  @override
  String get builderSettingsCloseSemantics => '설정 닫기';

  @override
  String get builderSettingsTitle => '레벨 설정';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · 바꾸면 바로 저장돼요';
  }

  @override
  String get builderSettingsName => '이름';

  @override
  String get builderRename => '이름 바꾸기';

  @override
  String get builderRenameSemantics => '이름 바꾸기';

  @override
  String get builderSettingsRegion => '지역';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count곳 · 밀어서 더 보기',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => '속도';

  @override
  String get builderSettingsPaceHint => '하늘이 흐르는 속도';

  @override
  String get builderSettingsMarks => '별 눈금';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개 배치됨',
      one: '별 1개 배치됨',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => '별 2개 눈금';

  @override
  String get builderMarkThreeSemantics => '별 3개 눈금';

  @override
  String get builderMarksAuto => '자동: 별 개수에 맞춤';

  @override
  String get builderMarksByHand => '직접 설정';

  @override
  String get builderSettingsControls => '조작';

  @override
  String get builderShootOn => '발사 켜짐';

  @override
  String get builderShootOff => '발사 꺼짐';

  @override
  String get builderSprintOn => '대시 켜짐';

  @override
  String get builderSprintOff => '대시 꺼짐';

  @override
  String get builderSettingsBoss => '보스 피날레';

  @override
  String get builderSettingsBossHint => '끝에서 기다려요';

  @override
  String get builderNoBossSemantics => '보스 없음: 결승선';

  @override
  String get builderNoBoss => '없음';

  @override
  String get builderBossShort_baronBat => '남작';

  @override
  String get builderBossShort_spitterBeetle => '퉤퉤 왕';

  @override
  String get builderBossShort_duskMoth => '여제';

  @override
  String get builderBossShort_pirate => '선장';

  @override
  String get builderBossShort_dragon => '드래곤';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          '새는 두 레인을 날아요. 스쿼트의 위와 아래예요. 느린 플레이어는 같은 레벨을 더 느긋한 속도로 만나요. 여기선 발사, 대시, 보스가 없어요.',
      'other':
          '새는 두 레인을 날아요. 팔굽혀펴기의 위와 아래예요. 느린 플레이어는 같은 레벨을 더 느긋한 속도로 만나요. 여기선 발사, 대시, 보스가 없어요.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      '점프할 때마다 새가 떠오르고, 그 사이엔 활공해요. 여기선 발사, 대시, 보스가 없어요.';

  @override
  String get builderStartZoneToast => '출발 구역은 비워 둬요. 점선 오른쪽에 놓아요.';

  @override
  String get builderSkySemantics => '레벨 하늘. 탭해서 놓고, 끌어서 옮기거나 스크롤해요.';

  @override
  String get builderSkyReadOnlySemantics => '레벨 하늘. 무언가를 탭해서 살펴봐요.';

  @override
  String get builderCoachTitle => '나만의 레벨 만들기';

  @override
  String get builderCoachPickTool => '왼쪽에서 도구 고르기';

  @override
  String get builderCoachTapSky => '하늘을 탭해서 놓기';

  @override
  String get builderCoachTestFly => '시험 비행!';

  @override
  String get builderCoachDrag => '끌어서 옮기기 · 하늘을 끌면 스크롤';

  @override
  String get builderTipDrag => '끌어서 옮기기 · 하늘을 끌면 스크롤';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '스쿼트 맨 위',
      'other': '팔굽혀펴기 맨 위',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => '맨 위';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': '스쿼트 맨 아래',
      'other': '팔굽혀펴기 맨 아래',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => '맨 아래';

  @override
  String get builderCanvasStartZoneFull => '출발 구역 · 비워 두기';

  @override
  String get builderCanvasStartZone => '출발 구역';

  @override
  String get builderCanvasFinishHere => '여기가 결승선';

  @override
  String get builderTool_select => '선택';

  @override
  String get builderToolHint_select => '선택: 탭해서 바꾸고, 끌어서 옮겨요';

  @override
  String get builderTool_gate => '관문';

  @override
  String get builderToolHint_gate => '관문: 하늘을 탭해 관문 놓기';

  @override
  String get builderTool_star => '별';

  @override
  String get builderToolHint_star => '별: 하늘을 탭해 별 놓기';

  @override
  String get builderTool_trio => '삼총사';

  @override
  String get builderToolHint_trio => '별 삼총사: 하늘을 탭해 별 세 개 놓기';

  @override
  String get builderTool_heart => '하트';

  @override
  String get builderToolHint_heart => '하트: 하늘을 탭해 하트 놓기';

  @override
  String get builderTool_enemy => '적';

  @override
  String get builderToolHint_enemy => '적: 하늘을 탭해 적 놓기';

  @override
  String get builderTool_finish => '결승선';

  @override
  String get builderToolHint_finish => '결승선: 하늘을 탭해 결승선 옮기기';

  @override
  String get builderTool_boss => '보스';

  @override
  String get builderToolHint_boss => '보스 표시: 하늘을 탭해 보스가 기다릴 곳 옮기기';

  @override
  String get builderStarterToolsToast => '기본 레벨은 바꿀 수 없어요. 리믹스해서 바꿔요.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss': '항로 전체 보기. 보스까지 $length. 끌어서 항로를 따라 이동해요.',
      'other': '항로 전체 보기. 결승선까지 $length. 끌어서 항로를 따라 이동해요.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss': '항로 전체 보기. 보스까지 $length. $reps. 끌어서 항로를 따라 이동해요.',
      'other': '항로 전체 보기. 결승선까지 $length. $reps. 끌어서 항로를 따라 이동해요.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '보스까지 $length';
  }

  @override
  String get builtResultTestFlight => '시험 비행';

  @override
  String get builtResultCleared => '클리어!';

  @override
  String get builtResultBonk => '콩!';

  @override
  String get builtResultLanded => '착지';

  @override
  String get builtResultTestTab => '시험';

  @override
  String get builtResultGoalFinish => '결승선';

  @override
  String get builtResultGoalBoss => '보스';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. 완료.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개 모으기.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개 모으기. 완료.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => '완료';

  @override
  String get builtResultNotYet => '아직';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 남음',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => '결승선부터';

  @override
  String get builtResultClearedByYou => '직접 클리어';

  @override
  String get builtResultNewBest => '신기록!';

  @override
  String get builtResultPractice => '연습';

  @override
  String builtResultBest(int count) {
    return '최고 $count';
  }

  @override
  String get builtResultFirstClear => '첫 클리어!';

  @override
  String get builtResultStarsCollected => '모은 별';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '레벨 별 3개 중 $count개',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => '필요 횟수';

  @override
  String get builtResultWorkout => '운동량';

  @override
  String get builtResultGotTo => '도달';

  @override
  String get builtResultScore => '점수';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '팔굽혀펴기',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '스쿼트',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '점프',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '카메라로 팔굽혀펴기',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '카메라로 스쿼트',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return '전체 $length 중';
  }

  @override
  String get builtResultNotKept => '기록 안 됨';

  @override
  String get builtResultNoBest => '최고 기록 없음';

  @override
  String get builtResultClearedStrip => '직접 클리어 · 공유 준비 완료!';

  @override
  String builtResultFlownFrom(String from) {
    return '$from부터 날았어요. 처음부터 끝까지 날아야 클리어돼요.';
  }

  @override
  String get builtResultTestNothingSaved => '시험 비행 · 저장 안 됨';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return '시험 비행 · $length 중 $reached 도달';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return '$length 중 $reached 도달. 결승선까지 가야 별을 받아요.';
  }

  @override
  String get builtResultReachFinish => '결승선에 도착해야 별을 받아요.';

  @override
  String get builtResultSaved => '이 휴대폰에 저장됨';

  @override
  String get builtResultSaving => '비행 저장 중…';

  @override
  String get builtResultBuilder => '만들기';

  @override
  String get builtResultEditLevel => '레벨 편집';

  @override
  String get builtResultEdit => '편집';

  @override
  String get builtResultFlyAgain => '다시 날기';

  @override
  String get builtResultWatchReplay => '다시 보기';

  @override
  String get builtResultPreparing => '준비 중…';

  @override
  String get builtResultSessionSaving => '저장 중…';

  @override
  String get builtResultSaveSession => '다시 보기 저장';

  @override
  String get builderShelfTitle => '레벨 만들기';

  @override
  String get builderShelfPasteCode => '코드 붙여넣기';

  @override
  String get builderShelfNewLevel => '새 레벨';

  @override
  String get builderShelfSaveFailed => '저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String builderShelfDeleteTitle(String name) {
    return '“$name” 삭제할까요?';
  }

  @override
  String get builderShelfDeleteBody =>
      '최고 기록도 함께 지워져요. 이 레벨에서 한 팔굽혀펴기, 스쿼트, 점프 기록은 그대로 남아요.';

  @override
  String get builderShelfDelete => '삭제';

  @override
  String builderShelfDeleted(String name) {
    return '“$name” 삭제됨.';
  }

  @override
  String get builderShelfFixFirst => '공유하기 전에 빨간 표시를 고쳐요. ‘고치기’를 탭해요.';

  @override
  String get builderShelfCodeCopied => '코드 복사 완료! 친구에게 붙여넣어 보내요.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      '코드 복사 완료! 결승선까지 직접 날아 봐요. 그래야 친구들이 깰 수 있는 레벨인 걸 알아요.';

  @override
  String get builderShelfNotReady => '아직 날 수 없는 레벨이에요. ‘고치기’를 탭해요.';

  @override
  String get builderShelfPasteMissingTitle => '붙여넣을 레벨 코드가 없어요';

  @override
  String get builderShelfPasteNewerTitle => '더 새로운 Beakbound의 레벨이에요';

  @override
  String get builderShelfPasteDamagedTitle => '코드가 뒤죽박죽됐어요';

  @override
  String get builderShelfPasteMissingBody =>
      '친구의 레벨 코드(BEAK1.로 시작)를 복사하고 ‘코드 붙여넣기’를 다시 탭해요.';

  @override
  String get builderShelfPasteNewerBody => 'Beakbound를 업데이트한 뒤 코드를 다시 붙여넣어요.';

  @override
  String get builderShelfPasteDamagedBody =>
      '일부가 빠졌거나 잘못 입력됐어요. 친구에게 코드 전체를 다시 복사해 달라고 해요.';

  @override
  String builderShelfImported(String name) {
    return '선반에 “$name” 도착!';
  }

  @override
  String get builderShelfUnavailable => '레벨을 잠깐 못 불러왔어요.';

  @override
  String get builderShelfMine => '내 레벨';

  @override
  String get builderShelfStarters => '기본 레벨';

  @override
  String get builderShelfStartersHint => '그대로 날거나, 리믹스해서 내 레벨로 만들어요';

  @override
  String get builderShelfEmptyTitle => '첫 레벨을 만들어 봐요';

  @override
  String get builderShelfEmptyBody => '관문, 별, 하트를 직접 놓고, 결승선을 정한 뒤 시험 비행해요.';

  @override
  String get builderShelfPasteFriend => '친구 코드 붙여넣기';

  @override
  String get builderShelfNeedsWork => '손볼 곳 있음';

  @override
  String get builderShelfClearedByYou => '직접 클리어';

  @override
  String get builderShelfFromFriend => '친구가 보냄';

  @override
  String get builderShelfFly => '날자!';

  @override
  String builderShelfFlySemantics(String name) {
    return '$name 날기';
  }

  @override
  String get builderShelfFixIt => '고치기';

  @override
  String builderShelfFixSemantics(String name) {
    return '$name 고치기';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return '$name 편집';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return '$name 공유';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return '$name 공유: 직접 클리어함';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return '$name 더 보기';
  }

  @override
  String get builderShelfRemix => '리믹스';

  @override
  String builderShelfRemixSemantics(String name) {
    return '$name 리믹스';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '편집기에서 고칠 것 $count개',
      one: '편집기에서 고칠 것 1개',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개',
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
    return '$name. $region에서 $mode. $length.';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '최고 별 3개 중 $stars개.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '손볼 곳 있음: 고칠 것 $count개.',
      one: '손볼 곳 있음: 고칠 것 1개.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => '직접 클리어함.';

  @override
  String get builderShelfFromFriendSemantics => '친구가 보낸 레벨.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return '$name 살펴보기. $mode, $length, $fact.';
  }

  @override
  String get builderShelfRemixSuffix => '리믹스';

  @override
  String get builderShelfCopySuffix => '사본';

  @override
  String get commonOk => '확인';

  @override
  String get commonCancel => '취소';

  @override
  String get starter_t_tap_1_name => '정원 깡충';

  @override
  String get starter_t_push_1_name => '팔굽혀펴기 열 번';

  @override
  String get starter_t_squat_1_name => '계단 스쿼트';

  @override
  String get starter_t_jump_1_name => '통통 바닷가';

  @override
  String get starter_t_tap_boss_name => '남작의 다리';

  @override
  String get builderPickCloseNewLevel => '새 레벨 닫기';

  @override
  String get builderPickModeTitle => '어떤 레벨로 할까요?';

  @override
  String get builderPickRegionTitle => '어디를 날까요?';

  @override
  String get builderPickModeSubtitle =>
      '나는 방식을 골라요(나중에 못 바꿔요). 모든 레벨은 터치로 시험 비행해요.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · 날 곳을 골라요. 나중에 바꿀 수 있어요.';
  }

  @override
  String get builderPickTouchLine => '탭해서 날갯짓. 관문, 별, 적, 보스까지.';

  @override
  String get builderPickPushUpLine => '높은 레인과 낮은 레인: 내려갈 때마다 팔굽혀펴기 한 번.';

  @override
  String get builderPickSquatLine => '높은 레인과 낮은 레인: 내려갈 때마다 스쿼트 한 번.';

  @override
  String get builderPickJumpLine => '점프로 날아올라요. 관문은 하늘 어디든.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => '카메라';

  @override
  String get builderPickSuggested => '추천';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, 추천';
  }

  @override
  String get builderPickClose => '닫기';

  @override
  String get builderPickNotYet => '아직 안 돼요. 빨간 표시부터 고쳐요.';

  @override
  String get builderPickShare => '공유 코드';

  @override
  String get builderPickShareLine => '친구가 자기 Beakbound에 붙여넣을 코드를 복사해요.';

  @override
  String get builderPickDuplicate => '복제';

  @override
  String get builderPickDuplicateLine => '사본을 만들어 다른 아이디어를 시험해요.';

  @override
  String get builderPickDeleteLine => '레벨을 버려요. 먼저 한 번 물어봐요.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => '가져오기 취소';

  @override
  String get builderPickImportTitle => '날아 볼 레벨이에요!';

  @override
  String get builderPickImportSubtitle => '누군가 이 레벨을 공유했어요.';

  @override
  String get builderPickClearedByMaker => '만든 사람이 클리어함';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '모을 별 $count개',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    return '마지막 보스: $boss';
  }

  @override
  String get builderPickNotFlown => '만든 사람이 아직 끝까지 날아 보지 않았어요.';

  @override
  String get builderPickRoute => '항로';

  @override
  String builderPickAlreadyHave(String name) {
    return '이미 있는 레벨이에요: “$name”.';
  }

  @override
  String get builderPickImportCopy => '사본으로 가져오기';

  @override
  String get builderPickOpenYours => '내 레벨 열기';

  @override
  String get builderPickImport => '가져오기';

  @override
  String get builderShelfRenameCancelSemantics => '이름 바꾸기 취소';

  @override
  String get builderShelfRenameTitle => '레벨 이름 짓기';

  @override
  String get builderShelfRenameEmpty => '이름은 한두 글자 이상 필요해요';

  @override
  String get builderShelfRenameSaveSemantics => '이름 저장';

  @override
  String get builderShelfRenameSave => '저장';

  @override
  String get coopMode_roped => '로프 연결';

  @override
  String get coopMode_free => '로프 없음';

  @override
  String get coopMode_duel => '1 대 1';

  @override
  String get coopTitle => '함께 날기';

  @override
  String get coopPlayersTag => '2인 플레이 · 폰 하나';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode 최고 $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: 최고 기록 없음';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · 대결 $count회',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode: 첫 대결';
  }

  @override
  String get coopRopedLead => '두 새가 로프 하나로 연결돼요.';

  @override
  String get coopRopedBody =>
      '함께 날갯짓하면 높이 올라가요. 혼자 날갯짓해도 둘 다 뜨지만 조금만 떠요. 대시로 짝꿍을 끌고 가요.';

  @override
  String get coopFreeLead => '로프 없음:';

  @override
  String get coopFreeBody => '새가 각자 날고, 서로 부딪히기만 해요. 하트, 보호막, 점수는 여전히 함께 써요.';

  @override
  String get duelLead => '대결!';

  @override
  String get duelBody =>
      '새마다 하트가 따로 있어요. 깜짝 상자를 잡아요. 상대에게 박쥐, 퉤퉤 딱정벌레, 운석을 보내거나 하트, 보호막, 별의 힘을 받아요. 마지막까지 나는 새가 이겨요.';

  @override
  String get coopStart => '함께 날기';

  @override
  String get duelStart => '대결!';

  @override
  String get coopFlightSemantics => '플레이어 1은 왼쪽 절반, 플레이어 2는 오른쪽 절반을 탭해 날갯짓';

  @override
  String get coopPauseSemantics => '비행 일시 정지';

  @override
  String coopShootSemantics(int player) {
    return '플레이어 $player 발사';
  }

  @override
  String coopSprintSemantics(int player) {
    return '플레이어 $player 대시';
  }

  @override
  String coopPlayerShort(int player) {
    return 'P$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return '플레이어 $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '별 자석: $seconds초 남음',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: '자석 충전 중: 퍼펙트 관문 $gates개 중 $charge개',
    );
    return '$_temp0';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds초',
    );
    return '$_temp0';
  }

  @override
  String get coopCountdownRoped => '로프 연결. 제자리에, 준비…';

  @override
  String get coopCountdownFree => '제자리에, 준비…';

  @override
  String get duelCountdown => '대결 준비…';

  @override
  String get coopCountdownRopedHint => '함께 날갯짓해서 높이 올라가요.\n대시로 짝꿍을 끌고 가요!';

  @override
  String get coopCountdownFreeHint => '새가 각자 날아요.\n하트를 나누고, 관문을 넘어요!';

  @override
  String get duelCountdownHint => '깜짝 상자를 잡아요!\n마지막까지 나는 새가 이겨요.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '플레이어 $player 별의 힘: $seconds초 남음',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => '홈';

  @override
  String get coopChangeBirds => '새 바꾸기';

  @override
  String get coopSaved => '저장됨';

  @override
  String get coopSaving => '저장 중…';

  @override
  String get coopSaveSession => '다시 보기 저장';

  @override
  String get duelRematch => '재대결';

  @override
  String get coopFlyAgain => '다시 날기';

  @override
  String duelWinner(int player) {
    return '플레이어 $player 승리!';
  }

  @override
  String get duelDraw => '무승부!';

  @override
  String get duelStopped => '대결 중단';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first 대 $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner, $loser에게 승리!';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return 'P$rival에게 $prize!';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize!';
  }

  @override
  String get duelPrize_batSwarm => '박쥐 떼';

  @override
  String get duelPrize_spitter => '퉤퉤 딱정벌레';

  @override
  String get duelPrize_meteorShower => '유성우';

  @override
  String get duelPrize_heart => '하트';

  @override
  String get duelPrize_shield => '보호막';

  @override
  String get duelPrize_starPower => '별의 힘';

  @override
  String get coopTapLeftHalf => '왼쪽 절반을 탭해요';

  @override
  String get coopTapRightHalf => '오른쪽 절반을 탭해요';

  @override
  String coopPickSemantics(int player, String bird) {
    return '플레이어 $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'P$player · 이쪽을 탭해요';
  }

  @override
  String get coopKeysP1 => 'P1 · W 날갯짓 · D 발사 · A 대시';

  @override
  String get coopKeysP2 => 'P2 · 위 날갯짓 · 오른쪽 발사 · 왼쪽 대시';

  @override
  String get coopRopedSemantics => '로프 연결: 두 새가 로프 하나를 함께 써요';

  @override
  String get coopFreeSemantics => '로프 없음: 새가 각자 날아요';

  @override
  String get duelModeSemantics => '1 대 1: 새끼리 대결해요';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => '다시 보기 저장됨 · 기록실에서 보기';

  @override
  String get coopNewTeamBest => '팀 최고 기록 경신!';

  @override
  String get coopWhatATeam => '환상의 팀워크!';

  @override
  String coopPairCaption(String first, String second) {
    return '$first & $second';
  }

  @override
  String get coopTeamScore => '팀 점수';

  @override
  String get coopTeamBest => '팀 최고 기록';

  @override
  String get coopNewTeamBestRibbon => '팀 신기록!';

  @override
  String get coopStatFlightTime => '비행 시간';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '관문',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => '날갯짓 비율';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'P$player 날갯짓',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return '대결 시간 $time';
  }

  @override
  String get duelSeries => '전적';

  @override
  String get duelHeartsLeft => '남은 하트';

  @override
  String get duelBoxesOpened => '연 상자';

  @override
  String get duelHitsLanded => '공격 성공';

  @override
  String get coopPauseSubtitle => '둘 다 횃대에 앉아 기다려요. 카운트다운 후에 함께 출발해요.';

  @override
  String get coopFinishFlight => '비행 끝내기';

  @override
  String get cameraLabIntro => '휴대폰을 가로로 낮게 세워 두고, 나를 향하게 하거나 옆에 둬요.';

  @override
  String cameraLabAlmostThere(String parts) {
    return '거의 다 됐어요 · 더 잘 보여야 해요: $parts';
  }

  @override
  String get cameraLabJointShoulder => '어깨';

  @override
  String get cameraLabJointElbow => '팔꿈치';

  @override
  String get cameraLabJointWrist => '손목';

  @override
  String get cameraLabJointHip => '엉덩이';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => '카메라 켜는 중…';

  @override
  String get cameraLabDenied => '카메라 접근이 꺼져 있어요. 앱 설정에서 허용한 뒤 다시 시도해요.';

  @override
  String cameraLabFailed(String error) {
    return '카메라를 켜지 못했어요: $error';
  }

  @override
  String get cameraLabStopped => '카메라가 멈췄어요. ‘카메라 시작’을 탭해 다시 보정해요.';

  @override
  String get cameraLabBack => '카메라 실험실 · 홈으로';

  @override
  String get cameraLabStepShow => '1. 팔과 엉덩이 보여 주기';

  @override
  String get cameraLabStepPushUps => '2. 팔굽혀펴기 두 번';

  @override
  String get cameraLabStepMove => '3. 새를 움직여 봐요!';

  @override
  String get cameraLabStepSquat => '스쿼트 범위 찾기';

  @override
  String get cameraLabStepJump => '서 있는 자세 찾기';

  @override
  String get cameraLabPushUpHelp =>
      '휴대폰은 낮게, 나를 향하게 하거나 옆에.\n정면이라면? 양어깨, 팔 하나, 엉덩이가 보이게.\n내 속도대로 두 번 내려갔다 올라와요.';

  @override
  String get cameraLabSquatHelp =>
      '가만히 섰다가 편하게 앉아 잠깐 버틴 뒤 다시 일어나요. 앉으면 내려가고, 서면 올라가요.';

  @override
  String get cameraLabJumpHelp =>
      '온몸과 발이 보이게 휴대폰을 마주 보고 서요. 가만히 있다가 작게 점프해요. 점프 한 번 = 큰 부스트 한 번.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '보정\n$total회 중 $done회 완료',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return '보정\n$percent% 완료';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '조작 테스트\n팔굽혀펴기 $count회',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '조작 테스트\n스쿼트 $count회',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '조작 테스트\n점프 $count회',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '초당 $hz회 · $ms ms p95';
  }

  @override
  String get cameraLabStartingButton => '시작 중…';

  @override
  String get cameraLabRecalibrate => '다시 보정';

  @override
  String get cameraLabStartCamera => '카메라 시작';

  @override
  String get cameraLabTapStart => '‘카메라 시작’을 탭해요';

  @override
  String cameraLabTry(String mode) {
    return '$mode 해 보기';
  }

  @override
  String get cameraBadgeWaking => '깨우는 중';

  @override
  String get cameraBadgeLive => '작동 중';

  @override
  String get cameraBadgeLockedOn => '인식 완료';

  @override
  String get cameraBadgeOffline => '꺼짐';

  @override
  String get trackingCatchingUp => '카메라가 따라잡는 중';

  @override
  String get trackingStepIntoOutline => '몸 윤곽선 안으로 들어와요';

  @override
  String get trackingKeepShoulders => '양어깨가 다 보이게 해요';

  @override
  String get trackingShowSide => '옆에서 어깨, 팔꿈치, 손목, 엉덩이가 하나씩 보이게 해요';

  @override
  String get trackingMoveCloser => '조금 더 가까이 와요';

  @override
  String get trackingGetDown => '팔굽혀펴기 자세로 엎드려요';

  @override
  String get trackingHandsOnFloor => '손을 바닥에 짚고 몸을 뒤로 쭉 뻗어요';

  @override
  String get trackingExtendBody => '몸을 손 뒤로 조금 더 뻗어요';

  @override
  String get trackingComfortableRange => '편한 팔굽혀펴기 범위 안에서 움직여요';

  @override
  String get trackingPlaceHands => '손을 바닥에 짚고 몸은 손 뒤에 둬요';

  @override
  String get trackingFrontTracked => '정면 인식됨 · 손이 보이게 해요';

  @override
  String get trackingBodyInView => '몸 인식됨 · 얼굴은 아래를 봐도 돼요';

  @override
  String get trackingArmsTracked => '팔 인식됨 · 다리는 일부만 확인';

  @override
  String get trackingFindTop => '편한 윗자세를 찾아요';

  @override
  String get trackingCalibrated => '보정 완료! 새를 움직여 봐요.';

  @override
  String get trackingFreshFrame => '새 화면을 기다리는 중';

  @override
  String get trackingDistanceChanged => '카메라 거리가 바뀌었어요 · 다시 보정해요';

  @override
  String get trackingKeepArm => '팔 하나가 보이게 해요';

  @override
  String get trackingSquatStepBack => '어깨, 엉덩이, 무릎, 발이 보이게 뒤로 물러나요';

  @override
  String get trackingSquatFaceCamera => '두 발을 바닥에 붙이고 카메라를 마주 봐요';

  @override
  String get trackingSquatControls => '앉으면 내려가고 · 서면 올라가요';

  @override
  String get trackingStartingDistance => '처음 거리에서 카메라를 마주 봐요 · 움직였다면 다시 보정해요';

  @override
  String get trackingFeetPlanted => '두 발을 처음 자리에 단단히 붙여요';

  @override
  String get trackingSquatStandTall => '두 발이 보이게 똑바로 가만히 서요';

  @override
  String get trackingStandStill => '잠깐 똑바로 가만히 서요';

  @override
  String get trackingSquatDepth => '편한 깊이까지 앉아서 잠깐 버텨요';

  @override
  String get trackingSquatHold => '편하게 앉은 뒤 잠깐 버텨요';

  @override
  String get trackingSquatHoldBriefly => '이 편한 자세로 잠깐 버텨요';

  @override
  String get trackingSquatStandUp => '다시 일어나면 보정이 끝나요';

  @override
  String get trackingSquatReady => '준비 완료! 앉으면 내려가고 · 서면 올라가요';

  @override
  String get trackingJumpStepBack => '어깨, 엉덩이, 두 발이 보이게 뒤로 물러나요';

  @override
  String get trackingJumpFaceCamera => '위로 뛸 공간을 두고 카메라를 마주 보고 서요';

  @override
  String get trackingJumpSmall => '작은 점프면 충분해요 · 착지한 뒤 다시 뛰어요';

  @override
  String get trackingJumpStandStill => '온몸과 두 발이 보이게 가만히 서요';

  @override
  String get trackingJumpReady => '준비 완료! 작은 점프 한 번에 큰 부스트 한 번.';

  @override
  String get trackingFindPosition => '자리를 잡아요';

  @override
  String get trackingInterrupted => '동작 인식이 끊겼어요';

  @override
  String get trackingCameraInterrupted => '카메라가 끊겼어요. 카메라 권한을 확인하고 다시 시도해요.';

  @override
  String get trackingCameraAway => '앱을 나가 있는 동안 카메라가 멈췄어요';

  @override
  String get trackingJumpBoost => '점프하면 크게 부스트!';

  @override
  String get trackingJumpLand => '착지해서 다음 점프 준비';

  @override
  String trackingLowerMore(int step, int total) {
    return '조금 더 내려가요 · $step/$total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return '편하게 내려가요 · $step/$total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return '다시 밀어 올라와요 · $step/$total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return '처음처럼 편한 범위로 · $step/$total';
  }

  @override
  String commonSaveFailed(String error) {
    return '이 변경을 저장하지 못했어요. 다시 시도해 주세요. ($error)';
  }

  @override
  String get commonDelete => '삭제';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 더 필요',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => '둥지를 잠깐 못 불러왔어요.';

  @override
  String get homeSettings => '설정';

  @override
  String homeGreetingFirst(String bird) {
    return '안녕, 나는 $bird! 날아 볼까?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '모험 완료! $bird 뿌듯뿌듯!',
      'female': '모험 완료! $bird 뿌듯뿌듯!',
      'other': '모험 완료! $bird 뿌듯뿌듯!',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird 준비 완료. 너는?',
      'female': '$bird 준비 완료. 너는?',
      'other': '$bird 준비 완료. 너는?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => '무한 비행';

  @override
  String get homeEndlessDetail => '최대한 멀리 날아요';

  @override
  String get homeEndlessSemantics => '무한 비행. 최대한 멀리 날아요.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: '무한 비행. 최대한 멀리 날아요. 최고: 별 $best점.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => '최고';

  @override
  String get homeBestNone => '첫 기록을 세워요';

  @override
  String get homeCampaignTitle => '캠페인';

  @override
  String get homeCampaignDone => '모든 편지, 배달 완료';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '캠페인. 다음: $level. 별 $total개 중 $stars개.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '캠페인. 모든 편지, 배달 완료. 별 $total개 중 $stars개.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => '미니 게임';

  @override
  String get homeMiniGamesDetail => '몸으로 날기 · 2인';

  @override
  String get homeMiniGamesSemantics => '미니 게임. 팔굽혀펴기, 스쿼트, 점프, 또는 2인 플레이.';

  @override
  String get homeBuilderTitle => '레벨 만들기';

  @override
  String get homeBuilderDetail => '만들고 · 날고 · 공유';

  @override
  String get homeBuilderSemantics => '레벨 만들기. 나만의 레벨을 만들어 날고 공유해요.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count번 더 날면 열려요',
      one: '1번 더 날면 열려요',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '레벨 만들기. 잠김. $count번 더 날면 열려요.',
      one: '레벨 만들기. 잠김. 1번 더 날면 열려요.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => '모험';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '오늘의 모험. 목표 3개 중 $done개 완료.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => '새 친구들';

  @override
  String homeDockBirdsSemantics(String bird) {
    return '새 친구들. 함께 나는 새: $bird.';
  }

  @override
  String get homeDockUpgrades => '업그레이드';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '업그레이드. 쓸 수 있는 별 $stars개.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => '여권';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: '여권. 메달 $total개 중 $earned개.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => '기록실';

  @override
  String get homeMiniGamesPickerTitle => '미니 게임';

  @override
  String get homeMiniGamesPickerIntro => '몸을 움직여 날거나, 친구와 폰 하나로 함께 놀아요.';

  @override
  String get homeMiniGamesCloseSemantics => '미니 게임 닫기';

  @override
  String get homeMiniGamesPushUpCard => '내려가면 쑥.\n밀어 올리면 훨훨.';

  @override
  String get homeMiniGamesSquatCard => '낮게 앉고.\n일어서면 훨훨.';

  @override
  String get homeMiniGamesJumpCard => '점프하면 둥실.\n활공하며 별 모으기.';

  @override
  String get homeMiniGamesCoopCard => '두 명이 폰 하나로.\n협동하거나 대결해요.';

  @override
  String get homeMiniGamesCamera => '카메라';

  @override
  String get homeMiniGamesPlayers => '2인용';

  @override
  String get homeMiniGamesCoop => '함께 날기';

  @override
  String get birdsTitle => '비행 동료들을 만나 봐요.';

  @override
  String birdsFlownTag(int flown, int total) {
    return '$total 중 $flown 비행함';
  }

  @override
  String get birdsStatusCopilot => '나의 짝꿍';

  @override
  String get birdsStatusReady => '비행 준비 완료';

  @override
  String get birdsStatusLocked => '잠김';

  @override
  String get birdsNotFlown => '아직 안 날아 봄';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '비행 $count회',
      one: '비행 1회',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return '$bird, 같이 날자!';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return '$current 대신 $bird 선택';
  }

  @override
  String birdsUnlock(String bird) {
    return '$bird 잠금 해제';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '별 $price개로 $bird 잠금 해제',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '별 $price개로 $bird 잠금 해제, 아직 별이 부족해요',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => '함께 나는 중';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, 함께 나는 중';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, 함께 나는 중, 신규';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, 잠김, 별 $price개',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird, 신규';
  }

  @override
  String get birdsTagFlying => '비행 중';

  @override
  String get birdsTagNew => '신규';

  @override
  String get bird_0_description => '작은 새. 넓은 하늘.';

  @override
  String get bird_0_trail => '햇살 방울';

  @override
  String get bird_1_description => '발그레한 볼, 곱슬 볏, 마음은 한가득.';

  @override
  String get bird_1_trail => '복숭아 하트';

  @override
  String get bird_2_description => '꼬마 벌새. 상큼한 민트. 전속력.';

  @override
  String get bird_2_trail => '민트 잎';

  @override
  String get bird_3_description => '별빛 따라 나는 꿈꾸는 부엉이.';

  @override
  String get bird_3_trail => '별가루 반짝이';

  @override
  String get upgradesWalletLabel => '모은\n별';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '쓸 수 있는 별 $stars개',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => '새를 업그레이드해요.';

  @override
  String get upgradesIntro => '톱니바퀴를 탭하면 효과를 볼 수 있어요. 비행 중 주운 별 하나하나를 쓸 수 있어요.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, 레벨 $max 중 $level. 다음 레벨 별 $cost개',
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
      other: '$power, 레벨 $max 중 $level. 다음 레벨 별 $cost개, 아직 부족해요',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, 레벨 $max 중 $level. 최대';
  }

  @override
  String get upgradesMax => '최대';

  @override
  String upgradesLevel(int level) {
    return '레벨 $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return '레벨 $level, 최고';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now, 다음 레벨 $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value%';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value초';
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
      other: '별 $count개가 남아요.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => '업그레이드';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '별 $cost개로 업그레이드',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '별 $cost개로 업그레이드, 아직 별이 부족해요',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => '최대 레벨';

  @override
  String get power_shot_name => '던지기 위력';

  @override
  String get power_shot_blurb => '발사를 꾹 누르면 더 크고 단단한 돌멩이를 충전해요.';

  @override
  String get power_sprint_name => '대시';

  @override
  String get power_sprint_blurb => '앞을 막는 적을 박살 내는 순간 가속.';

  @override
  String get power_shield_name => '보호막';

  @override
  String get power_shield_blurb => '공격을 한 번 막아 줘요. 비행 중 별을 모으면 다시 채워져요.';

  @override
  String get power_magnet_name => '자석';

  @override
  String get power_magnet_blurb => '관문을 퍼펙트로 통과하면 얻어요. 별을 끌어당겨요.';

  @override
  String get power_stat_maxCharge => '최대 충전';

  @override
  String get power_stat_burstLength => '대시 지속 시간';

  @override
  String get power_stat_cooldown => '재사용 대기';

  @override
  String get power_stat_starsToRefill => '충전에 필요한 별';

  @override
  String get power_stat_safeTime => '깨진 뒤 무적 시간';

  @override
  String get power_stat_perfectGates => '필요한 퍼펙트 관문';

  @override
  String get power_stat_lasts => '지속 시간';

  @override
  String get power_stat_reach => '범위';

  @override
  String get passportTitle => '나의 하늘 여권.';

  @override
  String get passportDailyCard => '오늘의 카드';

  @override
  String passportMedalsTag(int earned, int total) {
    return '메달 $earned / $total';
  }

  @override
  String get passportIntro => '작은 모험, 오래 남는 기념품. 도장마다 동메달, 은메달, 금메달.';

  @override
  String get passportNoMedal => '아직 메달 없음';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': '동메달',
      'silver': '은메달',
      'other': '금메달',
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
    return '$stamp. $held. 다음 $next: $goal $target 중 $current.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. 금메달. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': '동메달까지',
      'silver': '은메달까지',
      'other': '금메달까지',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => '도장 쾅!';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: 아직 없음';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => '동메달';

  @override
  String get passportMedal_silver => '은메달';

  @override
  String get passportMedal_gold => '금메달';

  @override
  String get stamp_frequentFlyer_name => '단골 비행사';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '기록 비행 $n번 끝내기.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => '백발백중';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '조준점을 따라 퍼펙트 통과 $n번 하기.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => '별 사냥꾼';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $n개 모으기.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => '별자리';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '끊김 없는 콤보로 별 $n개 모으기.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => '하늘의 기장';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '무한 비행 한 번에 $n점 내기.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => '개척자';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '무한 비행 $n번을 각각 60초 이상 날기.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => '끼리끼리 훨훨';

  @override
  String get stamp_allRounder_name => '만능 재주꾼';

  @override
  String get stamp_flockTogether_goalBronze => '서로 다른 새 두 마리로 기록 비행하기.';

  @override
  String get stamp_flockTogether_goalSilver => '새 네 마리 모두로 기록 비행하기.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '새마다 기록 비행 $n번씩 하기.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze => '팔굽혀펴기, 스쿼트, 점프 미니 게임 중 하나 날기.';

  @override
  String get stamp_allRounder_goalSilver => '미니 게임 셋 다 날기: 팔굽혀펴기, 스쿼트, 점프.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '미니 게임마다 기록 비행 $n번씩 하기.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · 메달 $medals개 · 현재 $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => '모험을 잠깐 못 불러왔어요.';

  @override
  String get dailyTitle => '오늘의 작은 모험.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · 목표 $done/3';
  }

  @override
  String get dailyIntro => '목표 셋. 조작은 자유. 무한 비행 한 번으로 셋 다 할 수 있어요.';

  @override
  String get dailyLaunchEndless => '무한 비행';

  @override
  String get dailyPostcardKicker => '하늘 클럽 엽서';

  @override
  String get dailyStamped => '엽서에 도장 쾅!';

  @override
  String dailyGoalsComplete(int done) {
    return '목표 $done / 3 완료';
  }

  @override
  String get dailyDoneNote => '작은 모험, 오롯이 내 것.';

  @override
  String get dailyOpenNote => '셋 다 끝내면 이 카드에 도장 쾅!';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal 완료';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $target 중 $current';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: 엽서 도장 완료';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: 목표 $done/3';
  }

  @override
  String get dailyNoStreak => '매일 새 목표. 잃을 연속 기록은 없어요.';

  @override
  String get dailyTheme_0 => '해돋이 배달';

  @override
  String get dailyTheme_1 => '복숭아 소풍';

  @override
  String get dailyTheme_2 => '달빛 우편';

  @override
  String get dailyTheme_3 => '구름 퍼레이드';

  @override
  String get dailyTheme_4 => '황혼의 보물';

  @override
  String get dailyTheme_5 => '정원 파티';

  @override
  String get task_flights_title => '날개를 활짝';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 기록 비행 $count번 끝내기.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => '탁 트인 지평선';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 기록 비행에서 관문 $count개 통과하기.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => '주머니 가득 별';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 비행에서 별 $count개 모으기.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => '반짝임을 이어 가';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '끊김 없는 콤보로 별 $count개 모으기.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => '딱 한가운데';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 퍼펙트 통과 $count번 하기.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => '머나먼 여정';

  @override
  String get task_finishTrail_goal => '무한 비행 한 번에 60초 이상 날기.';

  @override
  String get recordsTitle => '나의 작은 승리들.';

  @override
  String get recordsBestsTitle => '깨야 할 나의 별 점수';

  @override
  String get recordsSectionMain => '메인 게임';

  @override
  String get recordsSectionMini => '미니 게임';

  @override
  String get recordsEndless => '무한 비행 · 탭 & 비행';

  @override
  String get recordsCampaignStars => '캠페인 별';

  @override
  String recordsCoopName(String mode) {
    return '함께 날기 · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '기록 비행',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '관문',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '함께 날기',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '대결',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '팔굽혀펴기',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '스쿼트',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => '최근 비행';

  @override
  String get recordsEmptyTitle => '넓은 하늘. 깨끗한 새 출발.';

  @override
  String get recordsEmptyBody => '첫 기록 비행에서 이야기가 시작돼요.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds초';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return '클래식 · $date · $seconds초';
  }

  @override
  String get replaySavedSessions => '저장된 비행';

  @override
  String get replayBackToRecordsSemantics => '기록실로 돌아가기';

  @override
  String get replaySessionsLoadFailed => '저장된 비행을 못 불러왔어요. 다시 시도';

  @override
  String get replayEmptyTitle => '비행은 여기에 모여요';

  @override
  String get replayEmptyBody => '비행 후 다시 보기를 저장하면 여기서 볼 수 있어요.';

  @override
  String get replayEmptyButton => '비행 고르기';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds초 · 별 $score점',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds초 · 관문 $score개',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => '저장된 비행 삭제';

  @override
  String get replayDeleteTitle => '이 비행을 삭제할까요?';

  @override
  String get replayDeleteBody => '카메라 영상과 다시 보기가 지워져요. 점수는 기록실에 남아요.';

  @override
  String get replayDeleteFailed => '삭제하지 못했어요. 다시 시도해 주세요.';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return '레벨 $id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · 무한 비행';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · 연습';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · 무한 비행 · 연습';
  }

  @override
  String get replayOpenFailed => '이 비행을 열 수 없어요.';

  @override
  String get replayBackToSessions => '저장된 비행으로';

  @override
  String get replayCameraPaused => '이 구간에선 카메라가 멈춰 있었어요';

  @override
  String get replayCameraUnavailable => '카메라 영상 없음 · 게임 화면은 재생돼요';

  @override
  String get replayCameraLoading => '카메라 불러오는 중…';

  @override
  String get replayPaused => '잠깐 숨 돌리는 중';

  @override
  String get replayHideControlsSemantics => '다시 보기 조작 숨기기';

  @override
  String get replayShowControlsSemantics => '다시 보기 조작 보이기';

  @override
  String get replayBackToSavedSemantics => '저장된 비행으로 돌아가기';

  @override
  String get replayTitle => '다시 보기';

  @override
  String replayTitleSession(String session) {
    return '다시 보기 · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return '점수: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '하트 $hearts개',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return '하트 P1 $p1 · P2 $p2 · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String replayMagnet(int seconds) {
    return '자석 · $seconds초';
  }

  @override
  String get replayPauseSemantics => '다시 보기 일시 정지';

  @override
  String get replayPlaySemantics => '다시 보기 재생';

  @override
  String get replayRestartSemantics => '다시 보기 처음부터';

  @override
  String get replayBack5Semantics => '5초 뒤로';

  @override
  String get replayForward5Semantics => '5초 앞으로';

  @override
  String get replayHighlightsFinding => '비행 하이라이트 찾는 중';

  @override
  String get replayHighlightsNone => '비행 하이라이트 없음';

  @override
  String get replayHighlights => '비행 하이라이트';

  @override
  String get replayHighlightsCloseSemantics => '하이라이트 닫기';

  @override
  String get replayHighlightsHint => '순간을 골라요. 그 직전부터 보여 줘요.';

  @override
  String get replayViewCorner => '구석 카메라';

  @override
  String get replayViewBackground => '카메라 배경';

  @override
  String get replayViewGameplay => '게임 화면만';

  @override
  String get replayMoveCornerSemantics => '카메라 창 옮기기';

  @override
  String get replayMuteRecordedSemantics => '녹음된 소리 끄기';

  @override
  String get replayUnmuteRecordedSemantics => '녹음된 소리 켜기';

  @override
  String get replayMuteGameSemantics => '게임 소리 끄기';

  @override
  String get replayUnmuteGameSemantics => '게임 소리 켜기';

  @override
  String get replayFullScreenSemantics => '조작 숨기기 / 전체 화면';

  @override
  String get replayMomentTakeoff => '이륙';

  @override
  String get replayMomentTakeoffDetail => '하늘이 활짝 열렸어요.';

  @override
  String get replayMomentMagnet => '별 자석';

  @override
  String get replayMomentMagnetDetail => '퍼펙트 통과 세 번으로 별이 가까이 와요.';

  @override
  String get replayMomentStarTrio => '첫 별 삼총사';

  @override
  String get replayMomentStarTrioDetail => '별 세 개가 별자리가 됐어요. +5점!';

  @override
  String get replayMomentStarTrioSubtleDetail => '무리의 별을 모두 모았어요. +5점!';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier× 별의 힘';
  }

  @override
  String get replayMomentStreakDetail => '반짝반짝 이어진 별 콤보.';

  @override
  String get replayMomentShield => '보호막 방어';

  @override
  String get replayMomentShieldDetail => '아슬아슬, 한 번 더 기회.';

  @override
  String get replayMomentPerfect => '첫 퍼펙트 통과';

  @override
  String get replayMomentPerfectDetail => '조준점을 정확히 통과.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '관문 $count개 통과',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => '하늘로 조금 더 멀리.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '긁힌 데 하나 없이. +$points점!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '대시 링 타고 무사 탈출. +$points점!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => '강풍을 견뎠다';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '날아오는 잡동사니를 피했어요. +$points점!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => '항로 완주';

  @override
  String get replayMomentFinal => '마지막 순간';

  @override
  String get replayMomentCompleteDetail => '항로 끝까지 날았어요.';

  @override
  String get replayMomentCollisionDetail => '마지막 접근을 다시 봐요.';

  @override
  String get replayMomentEndDetail => '이번 비행의 끝.';

  @override
  String get welcomeTitle => '언어를 골라 주세요';

  @override
  String get welcomeContinue => '날아 보자!';

  @override
  String get welcomeHint => '설정에서 언제든지 바꿀 수 있어요.';

  @override
  String get welcomeDevice => '휴대폰 언어';

  @override
  String get tutorialTitle => '비행 학교';

  @override
  String get tutorialSkip => '수업 건너뛰기';

  @override
  String get tutorialSkipTitle => '비행 학교를 건너뛸까요?';

  @override
  String get tutorialSkipBody => '수업은 설정에서 언제든 다시 들을 수 있어요.';

  @override
  String get tutorialSkipConfirm => '건너뛰기';

  @override
  String get tutorialSkipCancel => '계속 배우기';

  @override
  String get tutorialRestart => '처음부터';

  @override
  String get tutorialGoalFlaps => '날갯짓';

  @override
  String get tutorialGoalStars => '별 모으기';

  @override
  String get tutorialGoalGates => '관문 통과';

  @override
  String get tutorialGoalBats => '박쥐 물리치기';

  @override
  String get tutorialGoalDoor => '돌문 부수기';

  @override
  String get tutorialGoalSprint => '대시';

  @override
  String get tutorialGoalBoss => '선장 물리치기';

  @override
  String get tutorialPromptTap => '탭!';

  @override
  String get tutorialPromptShoot => '발사를 탭';

  @override
  String get tutorialPromptHoldShoot => '발사 꾹 누르기';

  @override
  String get tutorialPromptSprint => '대시를 탭';

  @override
  String get tutorialPraiseNice => '좋아요!';

  @override
  String get tutorialPraiseGreat => '멋져요!';

  @override
  String get tutorialPraiseSuper => '훌륭해요!';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return '수업이 기다리는 중: $prompt';
  }

  @override
  String get licenceTitle => '배달부 면허증';

  @override
  String get licenceIssuer => '하늘 클럽 우체국';

  @override
  String get licenceHolder => '배달부';

  @override
  String get licenceRank => '등급';

  @override
  String get licenceRankRookie => '신참 배달부';

  @override
  String get licenceSkills => '기술';

  @override
  String get licenceStamp => '인증';

  @override
  String licenceSignedBy(String name) {
    return '서명: $name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '별 $count개',
      one: '별 1개',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => '첫 항로로 출발!';

  @override
  String get licenceAgain => '다시 날기';

  @override
  String get settingsTutorial => '비행 학교';

  @override
  String get settingsTutorialDetail => '첫 수업 다시 듣기';
}
