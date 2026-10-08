// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get commonTryAgain => 'Coba lagi';

  @override
  String get languageKeyLabel => 'Bahasa';

  @override
  String languageKeySemantics(String language) {
    return 'Bahasa: $language. Ganti bahasa gim.';
  }

  @override
  String get languageSystemDefault => 'Bawaan sistem';

  @override
  String languageSystemDetail(String language) {
    return 'Ikuti ponselmu: $language';
  }

  @override
  String get languageCurrent => 'Bahasa saat ini';

  @override
  String get languageName_en => 'Inggris';

  @override
  String get languageName_es_419 => 'Spanyol (Amerika Latin)';

  @override
  String get languageName_pt_br => 'Portugis (Brasil)';

  @override
  String get languageName_id => 'Indonesia';

  @override
  String get languageName_fr => 'Prancis';

  @override
  String get languageName_de => 'Jerman';

  @override
  String get languageName_ja => 'Jepang';

  @override
  String get languageName_ko => 'Korea';

  @override
  String get languageName_tr => 'Turki';

  @override
  String get languageName_zh_hant => 'Tionghoa Tradisional';

  @override
  String get languageName_ru => 'Rusia';

  @override
  String get languageName_ar => 'Arab';

  @override
  String get voicePackReady => 'Suara siap';

  @override
  String get voicePackDownload => 'Unduh suara';

  @override
  String voicePackDownloading(int percent) {
    return 'Suara $percent%';
  }

  @override
  String get voicePackStarting => 'Mengunduh suara';

  @override
  String get voicePackEnglish => 'Suara Inggris';

  @override
  String get voicePackFailed => 'Unduhan gagal';

  @override
  String get settingsTitle => 'Anggap rumah sendiri.';

  @override
  String get settingsSectionSound => 'Suara';

  @override
  String get settingsSectionComfort => 'Kenyamanan';

  @override
  String get settingsMusicTitle => 'Musik Klub Langit';

  @override
  String get settingsMusicDetail => 'Musik menu, petualangan, dan bos.';

  @override
  String get settingsEffectsTitle => 'Efek suara';

  @override
  String get settingsEffectsDetail =>
      'Penerbangan, pertarungan, item, dan menu.';

  @override
  String get settingsVoicesTitle => 'Suara karakter';

  @override
  String get settingsVoicesDetail =>
      'Cerita, ucapan terima kasih, dan seruan melesat.';

  @override
  String get settingsReducedMotionTitle => 'Kurangi gerakan';

  @override
  String get settingsReducedMotionDetail =>
      'Menu lebih tenang, efek hiasan dikurangi.';

  @override
  String get settingsSwitchOn => 'ON';

  @override
  String get settingsSwitchOff => 'OFF';

  @override
  String get settingsUnavailable => 'Pengaturanmu belum siap.';

  @override
  String get settingsPrivacyKicker => 'DI PERANGKAT. SELALU.';

  @override
  String get settingsPrivacyTitle => 'Kameramu tetap milikmu.';

  @override
  String get settingsPrivacyBody =>
      'Video dan audio mikrofon opsional tetap di ponsel ini. Klip yang tak disimpan dibuang. Tanpa unggahan.';

  @override
  String get settingsCameraLab => 'Lab kamera & pelacakan';

  @override
  String get settingsAbout => 'Tentang & lisensi';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'Tentang & lisensi, versi $version';
  }

  @override
  String get settingsReset => 'Atur ulang progres lokal';

  @override
  String settingsResetDone(String bird) {
    return 'Mulai dari awal. $bird siap menemanimu.';
  }

  @override
  String get settingsResetTitle => 'Mulai petualangan baru?';

  @override
  String get settingsResetBody =>
      'Ini menghapus video, tayangan ulang, skor, sesi, level buatan, dan pengaturan yang tersimpan di ponsel ini. Tak bisa dibatalkan.';

  @override
  String get settingsResetBodyCloud =>
      'Ini menghapus video, tayangan ulang, skor, sesi, level buatan, dan pengaturan yang tersimpan di ponsel ini, juga simpanan cloud Play Game-mu. Tak bisa dibatalkan.';

  @override
  String get settingsResetConfirm => 'Hapus semuanya';

  @override
  String get settingsResetKeep => 'Simpan progresku';

  @override
  String get playGamesName => 'Play Game';

  @override
  String get playGamesConnected => 'Terhubung';

  @override
  String get playGamesNotConnected => 'Tak terhubung';

  @override
  String get playGamesConnecting => 'Menghubungkan…';

  @override
  String get playGamesConnectFailed => 'Gagal terhubung';

  @override
  String get playGamesIdle => 'Simpanan cloud & pencapaian';

  @override
  String get playGamesSaving => 'Menyimpan ke cloud…';

  @override
  String get playGamesOfflineUnsaved => 'Offline · belum tersimpan';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'Offline · tersimpan $ago';
  }

  @override
  String get playGamesUpdateNeeded => 'Perbarui gim untuk sinkron';

  @override
  String get playGamesUnreadable => 'Simpanan cloud tak terbaca';

  @override
  String get playGamesOn => 'Simpanan cloud aktif';

  @override
  String get playGamesResetElsewhere => 'Diatur ulang di ponsel lain';

  @override
  String playGamesRestored(String ago) {
    return 'Cloud dipulihkan · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'Tersimpan di cloud · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Pencapaian Play Game';

  @override
  String get playGamesConnectSemantics => 'Hubungkan Play Game';

  @override
  String get playGamesAchievements => 'Pencapaian';

  @override
  String get playGamesConnect => 'Hubungkan';

  @override
  String get timeAgoJustNow => 'baru saja';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes mnt lalu',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours jam lalu',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days hr lalu',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '+1 NYAWA!';

  @override
  String calloutStarTrio(int points) {
    return 'TRIO BINTANG +$points';
  }

  @override
  String get calloutNiceShot => 'TEMBAKAN JITU!';

  @override
  String calloutNiceShotPoints(int points) {
    return 'JITU! +$points';
  }

  @override
  String get calloutSmash => 'HANCUR!';

  @override
  String calloutSmashPoints(int points) {
    return 'HANCUR +$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return 'HANCUR ×$count!';
  }

  @override
  String get calloutBossDown => 'BOS TUMBANG!';

  @override
  String calloutBossDownPoints(int points) {
    return 'BOS TUMBANG +$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier× DAYA BINTANG!';
  }

  @override
  String get calloutPerfect => 'SEMPURNA!';

  @override
  String calloutPerfectChain(int count) {
    return 'SEMPURNA ×$count';
  }

  @override
  String get calloutShieldReady => 'PERISAI SIAP';

  @override
  String get calloutShieldSave => 'TERSELAMATKAN!';

  @override
  String get calloutKeepFlying => 'TERUS TERBANG!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count GERBANG!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds DETIK LAGI',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => 'MAGNET BINTANG';

  @override
  String get calloutSprintRing => 'CINCIN LESAT!';

  @override
  String calloutRushChain(int count) {
    return 'SERBUAN ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'METEOR +$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return 'KELELAWAR+$points';
  }

  @override
  String get calloutScorched => 'HANGUS!';

  @override
  String get region_jungle => 'Hutan Rimba';

  @override
  String get region_antarctica => 'Antarktika';

  @override
  String get region_aztec => 'Aztek';

  @override
  String get region_paris => 'Paris';

  @override
  String get region_egypt => 'Mesir';

  @override
  String get region_cyberpunk => 'Kota Siberpunk';

  @override
  String get region_china => 'Tiongkok';

  @override
  String get region_brazil => 'Brasil';

  @override
  String get region_newYork => 'New York';

  @override
  String get region_arabia => 'Arab Kuno';

  @override
  String get region_rome => 'Roma Kuno';

  @override
  String get region_mexico => 'Meksiko';

  @override
  String get region_sea => 'Laut Lepas';

  @override
  String get boss_baronBat_name => 'Baron Kelelawar';

  @override
  String get boss_spitterBeetle_name => 'Raja Peludah';

  @override
  String get boss_duskMoth_name => 'Maharani Senja';

  @override
  String get boss_pirate_name => 'Kapten Bajak Laut';

  @override
  String get boss_dragon_name => 'Naga Bara';

  @override
  String get boss_kingCoo_name => 'Raja Kurkur';

  @override
  String get boss_searchlightGargoyle_name => 'Gargoyle Lampu Sorot';

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
  String get playMode_pushUp => 'Terbang Push-Up';

  @override
  String get playMode_jump => 'Lompat & Terbang';

  @override
  String get playMode_touch => 'Ketuk & Terbang';

  @override
  String get playMode_squat => 'Squat & Terbang';

  @override
  String get chapter_1_route => 'Rute Kanopi';

  @override
  String get chapter_1_postmark => 'RUTE KANOPI';

  @override
  String get chapter_1_postcard =>
      'Surat-surat mendarat lagi di puncak pohon! Para tukan bilang terima kasih (keras sekali). Mahkota Baron Kelelawar kini menghiasi lemari kami.';

  @override
  String get chapter_1_postscript =>
      'Jalan kuno berbau seperti ada yang sedang mendidih.';

  @override
  String get chapter_2_route => 'Jalan Kuno';

  @override
  String get chapter_2_postmark => 'JALAN KUNO';

  @override
  String get chapter_2_postcard =>
      'Kafilah berjalan lagi, dan yang diramu kini cuma teh mint. Mahkota botol sang Raja kami jadikan vas.';

  @override
  String get chapter_2_postscript =>
      'Lampu-lampu kota padam semalam. Bawalah cahaya.';

  @override
  String get chapter_3_route => 'Jalur Lampu Kota';

  @override
  String get chapter_3_postmark => 'JALUR LAMPU KOTA';

  @override
  String get chapter_3_postcard =>
      'Lampu sudah menyala dan pos malam terjaga penuh! Paris mengirim croissant. New York mengirim pretzel.';

  @override
  String get chapter_3_postscript => 'Lonceng pelabuhan berhenti berdentang.';

  @override
  String get chapter_4_route => 'Rute Pasang Surut';

  @override
  String get chapter_4_postmark => 'RUTE PASANG SURUT';

  @override
  String get chapter_4_postcard =>
      'Lonceng pelabuhan berdentang lagi untuk surat, bukan untuk meriam. Nuri memilih tinggal. Dia titip salam.';

  @override
  String get chapter_4_postscript =>
      'Katanya langit di ujung peta sedang terbakar.';

  @override
  String get chapter_5_route => 'Ujung Peta';

  @override
  String get chapter_5_postmark => 'UJUNG PETA';

  @override
  String get chapter_5_postcard =>
      'Langit cerah dari kutub ke kutub dan semua rute berjalan lagi. Seluruh Klub Langit bangga padamu.';

  @override
  String get chapter_5_postscript =>
      'Langit tanpa batas masih menunggu, kapan pun kamu siap.';

  @override
  String get level_1_1_name => 'Kiriman Pertama';

  @override
  String get level_1_1_cargo => 'Kartu ulang tahun untuk si kembar tukan';

  @override
  String get level_1_1_sender => 'Si kembar tukan';

  @override
  String get level_1_1_hint =>
      'Ketuk untuk mengepak. Terbang lewat bintang-bintang.';

  @override
  String get level_1_2_name => 'Rantai Bintang';

  @override
  String get level_1_2_cargo => 'Peta bintang untuk kungkang pengamat bintang';

  @override
  String get level_1_2_sender => 'Kungkang pengamat bintang';

  @override
  String get level_1_2_hint =>
      'Rangkai bintang untuk 3×; tiga gerbang sempurna memberi magnet.';

  @override
  String get level_1_3_name => 'Patroli Kelelawar';

  @override
  String get level_1_3_cargo =>
      'Lampu tidur untuk penitipan anak kunang-kunang';

  @override
  String get level_1_3_sender => 'Penitipan anak kunang-kunang';

  @override
  String get level_1_3_hint =>
      'Tembak. Ketuk Tembak untuk menjatuhkan kelelawar.';

  @override
  String get level_1_4_name => 'Langit Karnaval';

  @override
  String get level_1_4_cargo => 'Syal bulu untuk parade karnaval';

  @override
  String get level_1_4_sender => 'Para makau samba';

  @override
  String get level_1_4_hint =>
      'Angin ribut! Awasi tanda ! dan hindari bola sepak.';

  @override
  String get level_1_5_name => 'Pos Kilat';

  @override
  String get level_1_5_cargo => 'Undangan kilat untuk pemimpin drum';

  @override
  String get level_1_5_sender => 'Pemimpin drum';

  @override
  String get level_1_5_hint =>
      'Melesat menghancurkan kelelawar dan melaju jauh ke depan.';

  @override
  String get level_1_6_name => 'Tangga Kuil';

  @override
  String get level_1_6_cargo => 'Biji kakao untuk para koki kuil';

  @override
  String get level_1_6_sender => 'Para koki kuil';

  @override
  String get level_1_7_name => 'Sarang Fajar';

  @override
  String get level_1_7_cargo => 'Jam matahari untuk penjaga fajar';

  @override
  String get level_1_7_sender => 'Penjaga fajar';

  @override
  String get level_1_8_name => 'Baron Kelelawar';

  @override
  String get level_1_8_cargo => 'Peringatan terakhir untuk Baron Kelelawar';

  @override
  String get level_1_8_sender => 'Baron Kelelawar';

  @override
  String get level_2_1_name => 'Jalan Kumbang';

  @override
  String get level_2_1_cargo =>
      'Mahkota laurel untuk para pembalap kereta kuda';

  @override
  String get level_2_1_sender => 'Para pembalap kereta kuda';

  @override
  String get level_2_1_hint => 'Kumbang meludahkan biji. Tembak jatuh bijinya.';

  @override
  String get level_2_2_name => 'Gerbang Tersegel';

  @override
  String get level_2_2_cargo => 'Pahat baru untuk pemahat patung';

  @override
  String get level_2_2_sender => 'Pemahat patung';

  @override
  String get level_2_2_hint =>
      'Tahan Tembak untuk batu besar yang bisa memecah lempeng batu.';

  @override
  String get level_2_3_name => 'Kejaran Api Liar';

  @override
  String get level_2_3_cargo => 'Ember air untuk regu pemadam kebakaran';

  @override
  String get level_2_3_sender => 'Regu pemadam kebakaran';

  @override
  String get level_2_3_hint => 'Terbang lewat cincin emas, api pun tertinggal!';

  @override
  String get level_2_4_name => 'Zigzag Sungai Nil';

  @override
  String get level_2_4_cargo => 'Buku teka-teki baru untuk Sfinks';

  @override
  String get level_2_4_sender => 'Sfinks';

  @override
  String get level_2_5_name => 'Langit Runtuh';

  @override
  String get level_2_5_cargo => 'Teleskop untuk astronom piramida';

  @override
  String get level_2_5_sender => 'Astronom piramida';

  @override
  String get level_2_5_hint => 'Lesatan cincin menghancurkan meteor.';

  @override
  String get level_2_6_name => 'Kembali ke Pengirim';

  @override
  String get level_2_6_cargo => 'Kemoceng untuk juru kunci';

  @override
  String get level_2_6_sender => 'Juru kunci piramida';

  @override
  String get level_2_6_hint =>
      'Tembak surat-suratnya agar terkirim balik. Kembali ke pengirim!';

  @override
  String get level_2_7_name => 'Bazar Lentera';

  @override
  String get level_2_7_cargo => 'Minyak lampu untuk para penjual lentera';

  @override
  String get level_2_7_sender => 'Para penjual lentera';

  @override
  String get level_2_8_name => 'Kafilah Panjang';

  @override
  String get level_2_8_cargo => 'Botol air untuk kafilah panjang';

  @override
  String get level_2_8_sender => 'Pemimpin kafilah';

  @override
  String get level_2_9_name => 'Raja Peludah';

  @override
  String get level_2_9_cargo => 'Perintah stop meramu untuk Raja Peludah';

  @override
  String get level_2_9_sender => 'Raja Peludah';

  @override
  String get level_3_1_name => 'Cahaya Ngengat';

  @override
  String get level_3_1_cargo => 'Bola lampu untuk kanopi teater';

  @override
  String get level_3_1_sender => 'Manajer panggung';

  @override
  String get level_3_1_hint =>
      'Ngengat menembakkan kipas isi tiga. Menyelinaplah di celahnya.';

  @override
  String get level_3_2_name => 'Roda dalam Hujan';

  @override
  String get level_3_2_cargo => 'Payung untuk merpati kios koran';

  @override
  String get level_3_2_sender => 'Merpati kios koran';

  @override
  String get level_3_2_hint =>
      'Merpati Gang menukik untuk merebut bintang. Tembak mereka duluan!';

  @override
  String get level_3_3_name => 'Gang Uap';

  @override
  String get level_3_3_cargo => 'Pretzel hangat untuk sopir taksi malam';

  @override
  String get level_3_3_sender => 'Sopir taksi malam';

  @override
  String get level_3_3_hint =>
      'Lubang uap mendesis, lalu menyembur. Lompati yang panas, tunggangi yang lembut.';

  @override
  String get level_3_4_name => 'Peringatan Badai';

  @override
  String get level_3_4_cargo => 'Penunjuk angin untuk menara tertinggi';

  @override
  String get level_3_4_sender => 'Penjaga menara';

  @override
  String get level_3_4_hint =>
      'Jauhi sorotan. Tembak lampunya saat terbuka! Tak bisa Melesat di sini.';

  @override
  String get level_3_5_name => 'Atap Kristal';

  @override
  String get level_3_5_cargo => 'Croissant untuk pelukis atap';

  @override
  String get level_3_5_sender => 'Pelukis atap';

  @override
  String get level_3_6_name => 'Usai Angin Ribut';

  @override
  String get level_3_6_cargo => 'Partitur lagu untuk pemain akordeon';

  @override
  String get level_3_6_sender => 'Pemain akordeon';

  @override
  String get level_3_6_hint =>
      'Angin ribut! Awasi tanda ! dan ambil sisi yang terbuka.';

  @override
  String get level_3_7_name => 'Kilat Tengah Malam';

  @override
  String get level_3_7_cargo => 'Surat cinta tengah malam untuk tukang roti';

  @override
  String get level_3_7_sender => 'Tukang roti';

  @override
  String get level_3_7_hint => 'Melesat menembus kawanan.';

  @override
  String get level_3_8_name => 'Maharani Senja';

  @override
  String get level_3_8_cargo => 'Alarm bangun untuk Maharani Senja';

  @override
  String get level_3_8_sender => 'Maharani Senja';

  @override
  String get level_4_1_name => 'Cahaya Pelabuhan';

  @override
  String get level_4_1_cargo => 'Lensa baru untuk penjaga mercusuar';

  @override
  String get level_4_1_sender => 'Penjaga mercusuar';

  @override
  String get level_4_2_name => 'Celah Gunung Berapi';

  @override
  String get level_4_2_cargo =>
      'Sarung tangan oven untuk tukang kue gunung berapi';

  @override
  String get level_4_2_sender => 'Tukang kue gunung berapi';

  @override
  String get level_4_2_hint => 'Lompati semburan lava.';

  @override
  String get level_4_3_name => 'Menyusuri Pantai';

  @override
  String get level_4_3_cargo => 'Benang layangan untuk festival pantai';

  @override
  String get level_4_3_sender => 'Para pemain layang-layang';

  @override
  String get level_4_4_name => 'Air Surut';

  @override
  String get level_4_4_cargo => 'Surat balasan untuk pertapa pulau';

  @override
  String get level_4_4_sender => 'Pertapa pulau';

  @override
  String get level_4_4_hint => 'Jangan sentuh airnya.';

  @override
  String get level_4_5_name => 'Pasang Purnama';

  @override
  String get level_4_5_cargo => 'Jadwal pasang surut untuk awak kapal feri';

  @override
  String get level_4_5_sender => 'Awak kapal feri';

  @override
  String get level_4_5_hint => 'Saat lonceng berbunyi, terbanglah tinggi.';

  @override
  String get level_4_6_name => 'Teluk Gempuran';

  @override
  String get level_4_6_cargo => 'Biskuit ikan untuk koloni camar';

  @override
  String get level_4_6_sender => 'Koloni camar';

  @override
  String get level_4_7_name => 'Penyeberangan Badai';

  @override
  String get level_4_7_cargo => 'Kaus kaki kering untuk pelaut jaga badai';

  @override
  String get level_4_7_sender => 'Pelaut jaga badai';

  @override
  String get level_4_8_name => 'Kapten Bajak Laut';

  @override
  String get level_4_8_cargo => 'Perintah kembalikan surat untuk sang Kapten';

  @override
  String get level_4_8_sender => 'Kapten Bajak Laut';

  @override
  String get level_5_1_name => 'Pos Aurora';

  @override
  String get level_5_1_cargo => 'Kupluk wol untuk paduan suara penguin';

  @override
  String get level_5_1_sender => 'Paduan suara penguin';

  @override
  String get level_5_1_hint =>
      'Serbuan apa pun bisa datang sekarang. Baca bannernya!';

  @override
  String get level_5_2_name => 'Malam Kutub';

  @override
  String get level_5_2_cargo => 'Cokelat panas untuk stasiun kutub';

  @override
  String get level_5_2_sender => 'Stasiun kutub';

  @override
  String get level_5_3_name => 'Kilat Neon';

  @override
  String get level_5_3_cargo => 'Sekring cadangan untuk papan nama kedai mi';

  @override
  String get level_5_3_sender => 'Koki mi';

  @override
  String get level_5_4_name => 'Badai Data';

  @override
  String get level_5_4_cargo => 'Surat kertas untuk robot yang penasaran';

  @override
  String get level_5_4_sender => 'Unit 7';

  @override
  String get level_5_5_name => 'Lesatan Langit Kota';

  @override
  String get level_5_5_cargo => 'Tiket lomba untuk pelari atap';

  @override
  String get level_5_5_sender => 'Pelari atap';

  @override
  String get level_5_6_name => 'Festival Lentera';

  @override
  String get level_5_6_cargo => 'Lentera kertas untuk festival';

  @override
  String get level_5_6_sender => 'Pembuat lentera';

  @override
  String get level_5_7_name => 'Etape Terakhir';

  @override
  String get level_5_7_cargo => 'Teh gunung untuk biara';

  @override
  String get level_5_7_sender => 'Para biksu gunung';

  @override
  String get level_5_8_name => 'Naga Bara';

  @override
  String get level_5_8_cargo =>
      'Surat pertama yang pernah dikirim untuk sang Naga';

  @override
  String get level_5_8_sender => 'Naga Bara';

  @override
  String get storyPostmasterName => 'Kepala Pos Bill';

  @override
  String get storySkip => 'Lewati';

  @override
  String get storyNextLineSemantics => 'Baris berikutnya';

  @override
  String get storyFinishSemantics => 'Selesai';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => 'Setiap surat pasti sampai.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => 'Terbang!';

  @override
  String levelIntroRunUp(int seconds) {
    return 'Ancang-ancang $seconds detik dulu';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'Sekitar $seconds detik ke garis finis';
  }

  @override
  String get campaignGuardian => 'PENJAGA';

  @override
  String get levelIntroBossFight => 'LAWAN BOS';

  @override
  String get levelIntroNew => 'BARU';

  @override
  String get levelIntroTip => 'TIPS';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    return 'Kalahkan $boss';
  }

  @override
  String get levelIntroGoalFinish => 'Capai garis finis';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kumpulkan $count bintang',
      one: 'Kumpulkan 1 bintang',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Satu bintang: $goal.',
      'two': 'Dua bintang: $goal.',
      'other': 'Tiga bintang: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'Satu bintang: $goal. Sudah didapat.',
      'two': 'Dua bintang: $goal. Sudah didapat.',
      'other': 'Tiga bintang: $goal. Sudah didapat.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terbaik: $count bintang',
      one: 'Terbaik: 1 bintang',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'Belum terkirim';

  @override
  String get levelIntroFirstFlight => 'Penerbangan pertama';

  @override
  String get levelIntroControlFlap => 'Kepak';

  @override
  String get levelIntroControlShoot => 'Tembak';

  @override
  String get levelIntroControlSprint => 'Melesat';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Kontrol: Kepak.',
      'shoot': 'Kontrol: Kepak, Tembak.',
      'sprint': 'Kontrol: Kepak, Melesat.',
      'other': 'Kontrol: Kepak, Tembak, Melesat.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => 'KIRIMAN KHUSUS';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return 'Kiriman khusus: $cargo.';
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
    return 'Level $level, $name. $region. Level penjaga: $boss.';
  }

  @override
  String get levelIntroStory => 'Cerita';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonContinue => 'Lanjut';

  @override
  String get commonHome => 'Beranda';

  @override
  String get commonBackHome => 'Ke beranda';

  @override
  String get campaignComingSoon => 'Segera hadir';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — segera hadir';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    return 'Kalahkan $boss untuk membuka';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'Selesaikan $level untuk membuka';
  }

  @override
  String get campaignMapUnavailable => 'Petanya butuh waktu sebentar.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return 'Tutup $name';
  }

  @override
  String get campaignMapPreviousStop => 'Perhentian sebelumnya';

  @override
  String get campaignMapNextStop => 'Perhentian berikutnya';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. Bab $chapter, $route. Segera hadir.',
      'locked': '$region. Bab $chapter, $route. Terkunci.',
      'other': '$region. Bab $chapter, $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return 'BAB $chapter · $route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level, $name, bos',
      'guardian': 'Level $level, $name, penjaga $boss',
      'other': 'Level $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. Terkunci.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. Terkunci. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars dari 3 bintang',
    );
    return '$node. Berikutnya. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars dari 3 bintang',
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
    return 'Kartu pos bab $chapter';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars dari $total bintang kampanye',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'Kurir yang baik,';

  @override
  String get campaignPostcardPs => 'N.B.';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'Kartu pos dari $route. Kurir yang baik, $body N.B. $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'Salam dari';

  @override
  String get campaignPostcardHeader => 'KARTU POS KLUB LANGIT';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'Yth. Kurir';

  @override
  String get campaignPostcardAddressStreet => 'Pos Klub Langit';

  @override
  String get campaignPostcardAddressCity => 'Di atas awan';

  @override
  String get campaignPostmarkDelivered => 'TERKIRIM';

  @override
  String get campaignPostmarkClub => 'POS KLUB LANGIT';

  @override
  String get campaignStampSkyClub => 'KLUB LANGIT';

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
    return 'Ucapan terima kasih dari $sender: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'Sedikit persiapan, banyak langit.';

  @override
  String get flightSetupTitleSquat => 'Kaki menapak. Sayap terbuka.';

  @override
  String get flightSetupTitleJump => 'Lompatan kecil. Sayap besar.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'LEVEL · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · BERSKOR';
  }

  @override
  String get flightSetupRoomPushUp => 'Beri sedikit ruang untuk bergerak.';

  @override
  String get flightSetupRoomBody => 'Tunjukkan seluruh tubuhmu.';

  @override
  String get flightSetupTipsPushUp =>
      'Ponsel di bawah. Tunjukkan lengan dan pinggul.\nMenghadap ponsel? Pastikan kedua bahu terlihat.';

  @override
  String get flightSetupTipsSquat =>
      'Squat untuk turun. Berdiri untuk naik.\nKedua kaki tetap di lantai.';

  @override
  String get flightSetupTipsJump =>
      'Lompat untuk dorongan + 3 dtk melayang.\nMendarat dulu sebelum lompat lagi.';

  @override
  String get flightSetupHowToFly => 'CARA TERBANG';

  @override
  String get flightSetupStep1PushUp => 'Tunjukkan lengan dan pinggul';

  @override
  String get flightSetupStep1Squat => 'Beri ruang untuk squat';

  @override
  String get flightSetupStep1Jump => 'Beri ruang untuk melompat';

  @override
  String get flightSetupStep1DetailPushUp =>
      'Menghadap ponsel? Tunjukkan kedua bahu, satu lengan, dan pinggul.';

  @override
  String get flightSetupStep1DetailBody =>
      'Ponsel posisi mendatar. Tunjukkan tubuh dan kedua kakimu.';

  @override
  String get flightSetupStep2PushUp => 'Temukan jangkauan gerakmu';

  @override
  String get flightSetupStep2Squat => 'Temukan squat yang nyaman';

  @override
  String get flightSetupStep2Jump => 'Berdiri tegak dan diam';

  @override
  String get flightSetupStep2DetailPushUp =>
      'Cari posisi atas yang nyaman, lalu turun dan naik dua kali.';

  @override
  String get flightSetupStep2DetailSquat =>
      'Berdiri diam, squat dan tahan sebentar, lalu berdiri lagi.';

  @override
  String get flightSetupStep2DetailJump =>
      'Diam sebentar. Lalu lompat untuk dorongan besar.';

  @override
  String get flightSetupStep3Stars => 'Kumpulkan bintang';

  @override
  String get flightSetupStep3DetailJump =>
      'Bintang menambah 0,75 dtk melayang, hingga 5 dtk. Kumpulkan trio untuk +5 poin.';

  @override
  String get flightSetupLivesEndless =>
      'Tiga hati + satu perisai. Kamu bisa jeda kapan saja.';

  @override
  String get flightSetupLivesClassic =>
      'Tabrakan atau keluar dari posisi mengakhiri penerbangan berskor. Kamu bisa jeda kapan saja.';

  @override
  String get flightSetupCameraButton => 'Siapkan kameraku';

  @override
  String get flightMicTitle => 'Rekam mikrofon';

  @override
  String get flightMicOn => 'Aktif';

  @override
  String get flightMicOptional => 'Opsional';

  @override
  String get flightMicDetail =>
      'Tambahkan suaramu dan suara ruangan ke tayangan ulang. Mikrofon hanya dipakai saat terbang. Disimpan di ponsel ini.';

  @override
  String get flightMicSemantics => 'Rekam mikrofon untuk tayangan ulang';

  @override
  String get flightMicSettings => 'Pengaturan mikrofon';

  @override
  String get flightCalibrationTitleReady => 'Kamu sudah menemukan sayapmu!';

  @override
  String get flightCalibrationTitleWaking => 'Membangunkan kameramu…';

  @override
  String get flightCalibrationTitleError => 'Ayo sambungkan ulang kameramu.';

  @override
  String get flightCalibrationTitleRange => 'Temukan jangkauan gerakmu.';

  @override
  String get flightCalibrationTitleStill => 'Berdiri tegak dan diam.';

  @override
  String get flightCalibrationStepTry => 'Coba gerakkan burungmu.';

  @override
  String get flightCalibrationStepTop => 'Cari posisi atas yang nyaman.';

  @override
  String get flightCalibrationStepLower => 'Turunkan badan perlahan.';

  @override
  String get flightCalibrationStepPushBack => 'Dorong naik lagi.';

  @override
  String get flightCalibrationStepStill => 'Berdiri tegak dan diam.';

  @override
  String get flightCalibrationStepSquat => 'Squat dengan nyaman.';

  @override
  String get flightCalibrationStepStandUp => 'Berdiri lagi.';

  @override
  String get flightCalibrationStepDone => 'Kamu sudah menemukan sayapmu!';

  @override
  String get flightCalibrationReadyPushUp =>
      'Dorong untuk naik. Turun untuk melayang.';

  @override
  String get flightCalibrationReadySquat =>
      'Squat untuk turun. Berdiri untuk naik.';

  @override
  String get flightCalibrationReadyJump =>
      'Lompat, lalu istirahat selagi burungmu melayang.';

  @override
  String get flightCalibrationKeepPushUp =>
      'Pastikan bahu, satu lengan, dan pinggul terlihat. Bergeraklah dengan nyaman.';

  @override
  String get flightCalibrationKeepBody =>
      'Pastikan bahu, pinggul, dan kedua kaki terlihat.';

  @override
  String get flightCalibrationLearning => 'Mempelajari jangkauan gerakmu.';

  @override
  String get flightCalibrationAfter => 'Burungmu bergerak setelah kalibrasi.';

  @override
  String get flightCalibrationJump => 'Lompat!';

  @override
  String get flightCalibrationTagCheck => 'CEK KONTROL';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '$count / 2 PUSH-UP';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '$percent% TERKALIBRASI';
  }

  @override
  String get flightCalibrationTakeoff => 'Siap lepas landas';

  @override
  String get flightCalibrationStarting => 'Memulai…';

  @override
  String get flightCalibrationRestart => 'Ulangi kalibrasi';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate pembaruan/dtk · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate pembaruan/dtk · $p95 ms p95 (hanya pemrosesan)';
  }

  @override
  String get flightCalibrationStatusReady => 'SIAP';

  @override
  String get flightCalibrationStatusStarting => 'MEMULAI';

  @override
  String get flightCalibrationStatusCameraOff => 'KAMERA MATI';

  @override
  String get flightCalibrationStatusCalibrating => 'MENGKALIBRASI';

  @override
  String get flightSwitchCameraSemantics => 'Ganti kamera';

  @override
  String get flightCalibrationStepIntoView => 'Masuklah ke depan kamera';

  @override
  String get flightCameraTroubleTitle => 'Mulai ulang biasanya membantu.';

  @override
  String get flightCameraTroubleAllow => 'Izinkan akses kamera di Pengaturan.';

  @override
  String get flightCameraTroubleClose =>
      'Tutup aplikasi kamera lain, lalu coba lagi.';

  @override
  String get flightCameraPermissionSemantics => 'Pengaturan izin kamera';

  @override
  String get flightNoteRememberFailed =>
      'Diubah untuk penerbangan ini. Pilihanmu tak bisa disimpan.';

  @override
  String get flightNoteMicUnavailable =>
      'Mikrofon tak tersedia. Video dan permainan tetap jalan.';

  @override
  String get flightNoteMicBlocked =>
      'Mikrofon diblokir. Kamu bisa mengizinkannya di Pengaturan; video tetap jalan.';

  @override
  String get flightNoteMicOff =>
      'Mikrofon mati. Kamu tetap bisa main dan menyimpan video.';

  @override
  String get flightNoteVideoUnavailable =>
      'Video kamera tak tersedia. Permainan tetap bisa disimpan.';

  @override
  String get flightNoteMicAudioLost =>
      'Audio mikrofon tak tersedia. Video dan permainanmu tetap bisa disimpan.';

  @override
  String get flightNoteVideoInterrupted =>
      'Video kamera terputus. Rekaman yang ada dan permainan tetap bisa disimpan.';

  @override
  String get flightNoteSessionSaveFailed =>
      'Sesi gagal disimpan. Ketuk Simpan sesi untuk mencoba lagi.';

  @override
  String get flightNoteWakingCamera => 'Membangunkan kameramu…';

  @override
  String get flightNoteCameraOff =>
      'Akses kamera mati. Izinkan di pengaturan Android, lalu kembali dan coba lagi.';

  @override
  String get flightNoteCameraFailed =>
      'Kamera tak bisa menyala. Coba lagi atau ganti kamera.';

  @override
  String get flightNotePreparing => 'Menyiapkan sesimu…';

  @override
  String get flightNoteSaveFailed =>
      'Penerbangan gagal disimpan. Ketuk untuk mencoba lagi.';

  @override
  String get flightNoteWelcomeBack =>
      'Selamat datang kembali. Ayo cek posisimu lagi.';

  @override
  String get flightNoteCameraInterrupted =>
      'Kamera terputus. Periksa izin kamera dan coba lagi.';

  @override
  String get flightNoteTrackingInterrupted => 'Pelacakan terputus';

  @override
  String get flightFindPosition => 'Cari posisimu';

  @override
  String get flightTapSemantics => 'Ketuk untuk mengepak';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'Ketuk untuk mengepak. $group datang mendahului bos mereka';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'Ketuk untuk mengepak. $boss: darah $hp dari $maxHp';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'Ketuk untuk mengepak. $boss: darah $hp dari $maxHp. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'Lewati ke hasil';

  @override
  String get hudPauseSemantics => 'Jeda penerbangan';

  @override
  String get flightHintTestSteerKeys =>
      'Uji terbang: Atas dan Bawah untuk mengarahkan.';

  @override
  String get flightHintTestSteerDrag =>
      'Uji terbang: seret ke atas dan bawah untuk mengarahkan.';

  @override
  String get flightHintTestJumpKeys => 'Uji terbang: Space untuk melompat.';

  @override
  String get flightHintTestJumpTap => 'Uji terbang: ketuk untuk melompat.';

  @override
  String get flightHintKeysStars =>
      'Space untuk mengepak. Terbang lewat bintang.';

  @override
  String get flightHintKeysShoot =>
      'Space untuk mengepak. Tahan D untuk mengisi tembakan.';

  @override
  String get flightHintKeysCombat =>
      'Space untuk mengepak. Tahan D untuk mengisi tembakan. A untuk melesat!';

  @override
  String get flightHintKeysPause => 'Space untuk mengepak. Esc untuk jeda.';

  @override
  String get flightHintTapStars =>
      'Ketuk langit untuk mengepak. Terbang lewat bintang.';

  @override
  String get flightHintTapShoot =>
      'Ketuk langit untuk mengepak. Tahan Tembak untuk mengisi.';

  @override
  String get flightHintTapCombat =>
      'Ketuk langit untuk mengepak. Tahan Tembak untuk mengisi. Melesat dan hancurkan!';

  @override
  String get flightHintTapRelease =>
      'Ketuk untuk mengepak. Lepaskan di antara ketukan.';

  @override
  String get flightHintTrail => 'Ikuti bintang-bintang. Perisaimu siap.';

  @override
  String get flightHintSky => 'Langit milikmu.';

  @override
  String hudClockSemantics(String time) {
    return 'Sisa $time';
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
      other: 'Magnet bintang: sisa $seconds detik',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Magnet terisi: $charge dari $gates gerbang sempurna',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'Mencarimu…';

  @override
  String get hudShoot => 'Tembak';

  @override
  String get hudSprint => 'Melesat';

  @override
  String get flightTestNothingSaved => 'tidak disimpan';

  @override
  String get flightCountdownReady => 'Bersedia, siap…';

  @override
  String get flightPauseTitle => 'Tarik napas dulu.';

  @override
  String get flightPauseKeepFlying => 'Lanjut terbang';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. Burungmu bertengger dan menunggu.';
  }

  @override
  String flightPausedTest(String name) {
    return 'Uji terbang $name. Tak ada yang disimpan.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. Burungmu bertengger dan menunggu.';
  }

  @override
  String get flightPausedTouch =>
      'Burungmu bertengger dan menunggu. Nanti kami hitung mundur lagi.';

  @override
  String get flightPausedCamera =>
      'Lemaskan badan, lalu kembali ke posisi. Nanti kami hitung mundur.';

  @override
  String get flightPauseEdit => 'Ubah';

  @override
  String get flightPauseBuilder => 'Pembuat';

  @override
  String get flightPauseFinish => 'Akhiri terbang';

  @override
  String get hudShieldRecovering => 'Memulihkan';

  @override
  String get hudShieldReady => 'Perisai siap';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Perisai terisi: $charge dari $stars bintang',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $count hati',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'Sedang melesat';

  @override
  String get hudSprintReady => 'Siap';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Mengisi ulang, $seconds detik',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint =>
      'Melaju untuk menghancurkan kelelawar dan lempeng batu';

  @override
  String get hudShotReloading => 'Mengisi ulang…';

  @override
  String hudShotFullCharge(int ms) {
    return 'Terisi penuh, sisa $ms ms';
  }

  @override
  String hudShotCharging(int percent) {
    return 'Mengisi $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'Amunisi $percent%';
  }

  @override
  String get hudShotHint => 'Tahan untuk mengisi batu yang lebih besar';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang tercapai',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang di $at',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars bintang terkumpul',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'MAKS';

  @override
  String hudRouteSemantics(int percent) {
    return 'Rute $percent% ditempuh';
  }

  @override
  String hudGlideCompact(String time) {
    return 'Layang · $time';
  }

  @override
  String get hudJumpToGlide => 'Lompat dulu!';

  @override
  String get hudJump => 'Lompat';

  @override
  String hudGlideSemantics(String time) {
    return 'Melayang, sisa $time';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'Melayang hampir habis, sisa $time';
  }

  @override
  String get hudJumpChargeSemantics => 'Lompat untuk mengisi 3 detik melayang';

  @override
  String get hudRecordNewBest => 'Rekor baru!';

  @override
  String get hudRecordMatched => 'Rekor disamai!';

  @override
  String hudRecordBest(int best) {
    return 'Terbaik $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '+$points lewat rekormu';
  }

  @override
  String get hudRecordOneMore => 'Satu lagi jadi rekor!';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagi menuju rekor',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'Skor $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'Skor $score, pengali $multiplier kali';
  }

  @override
  String get commonBusySemantics => 'Sedang diproses';

  @override
  String get flightResultBumpClouds => 'Sedikit benturan di awan.';

  @override
  String get flightResultPersonalBest => 'REKOR PRIBADI';

  @override
  String get flightResultNewPersonalBest => 'REKOR PRIBADI BARU!';

  @override
  String get flightResultStarsCollected => 'BINTANG TERKUMPUL';

  @override
  String get flightResultDailyStamped => 'Kartu pos hari ini sudah dicap!';

  @override
  String flightResultNextStamp(String stamp) {
    return 'Berikutnya: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'Tersimpan di ponsel ini';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Tersimpan di ponsel · total $total gerbang',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'Menyimpan penerbanganmu…';

  @override
  String get flightResultSessionSaved => 'Sesi tersimpan · Tonton di Rekor';

  @override
  String get flightResultWatchReplay => 'Tonton ulang';

  @override
  String get flightResultPreparing => 'Menyiapkan…';

  @override
  String get flightResultSavingShort => 'Menyimpan…';

  @override
  String get flightResultSaveSession => 'Simpan sesi';

  @override
  String get flightResultFlyAgain => 'Terbang lagi';

  @override
  String get commonRetry => 'Ulangi';

  @override
  String get commonMap => 'Peta';

  @override
  String get commonNext => 'Berikutnya';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'push-up',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squat',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lompatan',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kepakan',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'waktu terbang';

  @override
  String get flightStatPerfect => 'sempurna';

  @override
  String get flightStatBestStreak => 'rantai terbaik';

  @override
  String get flightStatRank => 'peringkat';

  @override
  String get flightRankSkyCaptain => 'Kapten langit';

  @override
  String get flightRankCloudExplorer => 'Pengelana awan';

  @override
  String get flightRankFirstWings => 'Sayap pertama';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => 'Terbentur, tapi rekor baru tercipta!';

  @override
  String get gameOverCaptionSea => 'Sedikit tercebur ke laut.';

  @override
  String get gameOverSplash => 'Byur!';

  @override
  String get gameOverBonk => 'Duk!';

  @override
  String get gameOverEveryMarkSemantics => 'Semua tanda tercapai';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang lagi untuk $mark bintang',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: sisa darah $hp dari $maxHp';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '$percent persen rute ditempuh';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: SISA $hp HP';
  }

  @override
  String gameOverBossLeft(String boss) {
    return 'SISA DARAH $boss';
  }

  @override
  String get gameOverRouteFlown => 'RUTE DITEMPUH';

  @override
  String gameOverHp(int hp) {
    return '$hp HP';
  }

  @override
  String gameOverMoreFor(int count) {
    return '$count lagi untuk';
  }

  @override
  String get gameOverBothMarks => 'Kedua tanda tercapai';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    return 'Dua tanda tercapai. Kalahkan $boss!';
  }

  @override
  String get miniResultTitle => 'Setiap penerbangan berarti.';

  @override
  String get miniResultComplete => 'TERBANG SELESAI';

  @override
  String get miniResultCheerBest => 'Wah, hebat sekali!';

  @override
  String get miniResultCheerComplete => 'Terbang selesai!';

  @override
  String get miniResultCheerNice => 'Terbangmu keren.';

  @override
  String get miniResultNew => 'BARU';

  @override
  String get flightEndTrackingLost => 'Kami sempat kehilangan jejakmu.';

  @override
  String get flightEndPostureLost => 'Posisimu keluar dari jangkauan.';

  @override
  String get flightEndBackgrounded => 'Kamu meninggalkan langit sebentar.';

  @override
  String get flightEndBreak => 'Istirahat yang pantas.';

  @override
  String get flightEndQuit => 'Sampai petualangan berikutnya.';

  @override
  String get flightEndStalled => 'Permainan terhenti.';

  @override
  String get flightEndCompleted =>
      'Satu langit penuh bintang. Semuanya milikmu.';

  @override
  String get levelResultTryAgain => 'Coba lagi!';

  @override
  String get levelResultVictory => 'Menang!';

  @override
  String get levelResultGuardianDown => 'Penjaga tumbang!';

  @override
  String get levelResultDelivered => 'Terkirim!';

  @override
  String levelResultComingSoon(String region) {
    return '$region segera hadir!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned dari 3 bintang';
  }

  @override
  String levelResultBest(int best) {
    return 'Terbaik $best';
  }

  @override
  String get levelResultNoBest => 'Belum ada rekor';

  @override
  String get levelResultFirstClear => 'Tamat perdana!';

  @override
  String get levelResultNewBest => 'REKOR BARU!';

  @override
  String get levelResultScore => 'SKOR';

  @override
  String get levelResultGoalBoss => 'Bos';

  @override
  String get levelResultGoalGuardian => 'Penjaga';

  @override
  String get levelResultGoalFinish => 'Finis';

  @override
  String get levelResultGoalDone => 'Tercapai';

  @override
  String get levelResultGoalNotYet => 'Belum';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagi',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'Finis dulu';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. Tercapai.';
  }

  @override
  String get levelResultPostcardWaiting => 'Ada kartu pos menunggu di peta!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '$id $name terbuka!';
  }

  @override
  String get levelResultReachFinish => 'Capai garis finis untuk dapat bintang.';

  @override
  String get course_classic_title => 'Klasik';

  @override
  String get course_starTrail_title => 'Tanpa Batas';

  @override
  String get course_classic_instructions =>
      'Temukan celahnya. Ikuti titik bidik untuk lintasan sempurna.';

  @override
  String get course_starTrail_instructions =>
      'Kumpulkan ketiga bintang dalam satu grup untuk +5. Rangkai bintang hingga 3×. Bintang memulihkan perisaimu; gerbang sempurna memberi magnet bintang. Tingkatkan keduanya dengan bintang!';

  @override
  String get course_classic_scoreLabel => 'RINTANGAN';

  @override
  String get course_starTrail_scoreLabel => 'POIN BINTANG';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gerbang',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'poin bintang',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics =>
      'Klasik: terbang melewati celah.';

  @override
  String get course_starTrail_previewSemantics =>
      'Tanpa Batas: kumpulkan bintang dengan tiga hati dan satu perisai.';

  @override
  String get obstacle_garden_name => 'Gerbang taman';

  @override
  String get obstacle_windLift_name => 'Gerbang angin';

  @override
  String get obstacle_petalGate_name => 'Tirai kelopak';

  @override
  String get obstacle_switchback_name => 'Zigzag';

  @override
  String get obstacle_lanternDrift_name => 'Lentera melayang';

  @override
  String get obstacle_sunWheels_name => 'Roda matahari';

  @override
  String get obstacle_crystalSteps_name => 'Tangga kristal';

  @override
  String get rush_wildfire_name => 'Api Liar';

  @override
  String get rush_wildfire_escape => 'Lolos dari api liar';

  @override
  String get rush_skyfall_name => 'Langit Runtuh';

  @override
  String get rush_skyfall_escape => 'Selamat dari langit runtuh';

  @override
  String get rush_eruption_name => 'Letusan';

  @override
  String get rush_eruption_escape => 'Lolos dari letusan';

  @override
  String get rush_swarm_name => 'Kawanan';

  @override
  String get rush_swarm_escape => 'Menerobos kawanan';

  @override
  String get boss_baronBat_title => 'PENGUASA BADAI';

  @override
  String get boss_spitterBeetle_title => 'PERAMU PASUKAN KUMBANG';

  @override
  String get boss_duskMoth_title => 'PENJAGA SELUBUNG SENJA';

  @override
  String get boss_pirate_title => 'TEROR AIR PASANG';

  @override
  String get boss_dragon_title => 'PENGUASA LANGIT MEMBARA';

  @override
  String get boss_kingCoo_title => 'KOMISARIS KAKI LIMA';

  @override
  String get boss_searchlightGargoyle_title => 'PENJAGA MENARA TERTINGGI';

  @override
  String get boss_neferhoo_title => 'PENJAGA SURAT YANG HILANG';

  @override
  String get boss_baronBat_returnTitle => 'BADAI KEMBALI';

  @override
  String get boss_baronBat_barName => 'BARON KELELAWAR';

  @override
  String get boss_spitterBeetle_barName => 'RAJA PELUDAH';

  @override
  String get boss_duskMoth_barName => 'MAHARANI SENJA';

  @override
  String get boss_pirate_barName => 'KAPTEN';

  @override
  String get boss_dragon_barName => 'NAGA BARA';

  @override
  String get boss_kingCoo_barName => 'RAJA KURKUR';

  @override
  String get boss_searchlightGargoyle_barName => 'GARGOYLE';

  @override
  String get boss_neferhoo_barName => 'NEFERHOO';

  @override
  String get vanguard_baronBat_title => 'SEPUPU-SEPUPU SANG BARON';

  @override
  String get vanguard_baronBat_call =>
      'Mereka datang! Sang Baron tepat di belakang.';

  @override
  String get vanguard_spitterBeetle_title => 'PASUKAN RAJA PELUDAH';

  @override
  String get vanguard_spitterBeetle_call =>
      'Mereka datang! Raja Peludah tepat di belakang.';

  @override
  String get vanguard_duskMoth_title => 'NGENGAT-NGENGAT MAHARANI SENJA';

  @override
  String get vanguard_duskMoth_call =>
      'Mereka datang! Sang Maharani tepat di belakang.';

  @override
  String get vanguard_kingCoo_title => 'SKUADRON RAJA KURKUR';

  @override
  String get vanguard_kingCoo_call =>
      'Mereka datang! Raja Kurkur tepat di belakang.';

  @override
  String get vanguard_kingCoo_callCrusts =>
      'Mereka datang! Hindari kerak rotinya!';

  @override
  String get vanguard_kingCoo_callReturns =>
      'Hindari kerak rotinya! Yang lolos bakal kembali!';

  @override
  String get bossVanguardClear => 'BERSIH!';

  @override
  String get bossVanguardLeft => 'LAGI';

  @override
  String get bossStragglersCaught => 'SEMUA TERTANGKAP';

  @override
  String get bossHint_strongerBaronBat =>
      'LEBIH KUAT · Tembakan tiga, dan kelelawarnya ikut menyerang!';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'LEBIH KUAT · Kipas penuh, dan kumbang-kumbangnya ikut menyerang!';

  @override
  String get bossHint_strongerDuskMoth =>
      'LEBIH KUAT · Kipas isi tujuh, dan ngengatnya ikut menyerang!';

  @override
  String get bossHint_strongerPirate => 'LEBIH KUAT · Arus berbalik!';

  @override
  String get bossHint_strongerDragon =>
      'LEBIH KUAT · Awas napas naga dan kawanannya!';

  @override
  String get bossHint_strongerKingCoo =>
      'LEBIH KUAT · Dia bersiul memanggil skuadronnya!';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'LEBIH KUAT · Bulu berjatuhan saat lampunya terbuka!';

  @override
  String get bossHint_strongerGargoyle => 'LEBIH KUAT · Bulu batu berjatuhan!';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'LEBIH KUAT · Ankh, plus kelelawar muminya!';

  @override
  String get bossHint_strongerNeferhoo =>
      'LEBIH KUAT · Ankh emas datang kembali!';

  @override
  String get bossHint_tideRising => 'AIR NAIK · Terbang tinggi!';

  @override
  String get bossHint_highTide => 'AIR PASANG · Tetap di atas air';

  @override
  String get bossHint_tideFury => 'MURKA · Gempuran meriam di sela gelombang';

  @override
  String get bossHint_tideCalm => 'Hindari peluru meriam · Jauhi air';

  @override
  String get bossHint_dragonSwarm =>
      'KAWANAN · Hindari kelelawar atau melesat menembusnya';

  @override
  String get bossHint_dragonFuryDebut => 'MURKA · Bola api lebih cepat';

  @override
  String get bossHint_dragonFury => 'MURKA · Bola api pecah jadi bara';

  @override
  String get bossHint_dragonCalm => 'Hindari bola api · Awas napas naga';

  @override
  String get bossHint_screechFury =>
      'MURKA · Bola api lebih cepat, kelelawar lebih banyak';

  @override
  String get bossHint_screechCalm =>
      'Hindari bola api dan kelelawar · Awas jeritannya';

  @override
  String get bossHint_cooPopped => 'DOR! · Tak ada skuadron';

  @override
  String get bossHint_cooSquadron => 'SKUADRON · Ikuti lajur terbuka!';

  @override
  String get bossHint_cooPuffed => 'MENGGEMBUNG · Tembak dadanya (x2)!';

  @override
  String get bossHint_cooCrumbBomb => 'BOM REMAH · Keluar dari lingkaran!';

  @override
  String get bossHint_cooFury => 'MURKA · Tetap di antara lingkaran';

  @override
  String get bossHint_cooCalm =>
      'Hindari bom remah · Tembak dadanya saat menggembung';

  @override
  String get bossHint_beamOn => 'SOROTAN · Tetap di tempat gelap';

  @override
  String get bossHint_beamFury => 'MURKA · Menyelinap di sela dua sorotan';

  @override
  String get bossHint_beamIncomingHigh => 'SOROTAN DATANG · Terbang rendah!';

  @override
  String get bossHint_beamIncomingLow => 'SOROTAN DATANG · Terbang tinggi!';

  @override
  String get bossHint_lampOpen => 'LAMPU TERBUKA · Tembak lampunya!';

  @override
  String get bossHint_shuttersClosed => 'LAMPU TERTUTUP · Simpan tembakanmu';

  @override
  String get bossHint_mothFuryNoVeil =>
      'MURKA · Kipas isi tujuh. Belum ada selubung!';

  @override
  String get bossHint_mothNoVeil =>
      'Belum ada selubung · Tembak di sela kipas!';

  @override
  String get bossHint_mothShielded =>
      'TERLINDUNG · Menghindar sampai selubungnya turun';

  @override
  String get bossHint_mothShieldForming =>
      'SELUBUNG TERBENTUK · Bersiaplah menghindar';

  @override
  String get bossHint_mothFury => 'MURKA · Kipas isi tujuh. Selubung turun!';

  @override
  String get bossHint_mothCalm => 'Selubung turun · Tembak di sela kipas!';

  @override
  String get bossHint_neferhooMailCall => 'SURAT DATANG · Tembak balik!';

  @override
  String get bossHint_neferhooReturn => 'KEMBALI KE PENGIRIM! · −25';

  @override
  String get bossHint_neferhooReturnFaster => 'KEMBALI KE PENGIRIM! · −18';

  @override
  String get bossHint_neferhooAnkh => 'ANKH · Bisa balik lagi!';

  @override
  String get bossHint_neferhooExpress => 'POS KILAT · Lima surat, lebih cepat';

  @override
  String get bossHint_neferhooTwoAnkhs => 'DUA ANKH · Jauhi kedua lajurnya';

  @override
  String get bossHint_neferhooBats => 'KELELAWAR MUMI · Tembak jatuh!';

  @override
  String get bossHint_neferhooScuff =>
      'Batu cuma menggores balutannya. Tembak balik SURAT-SURATNYA!';

  @override
  String get bossHint_neferhooWarmUp =>
      'Tembak balik surat-suratnya · Kembali ke pengirim';

  @override
  String get bossHint_neferhooCalm =>
      'Tembak balik suratnya · Hindari ankh emas';

  @override
  String get bossHint_neferhooFury => 'MURKA · Pos kilat dan dua ankh';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'NAPAS NAGA · Terbang rendah! Jantungnya terbuka',
      'middle': 'NAPAS NAGA · Naik atau menukik! Jantungnya terbuka',
      'other': 'NAPAS NAGA · Terbang tinggi! Jantungnya terbuka',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'API · Terbang rendah! Serang jantung yang menyala',
      'middle': 'API · Naik atau menukik! Serang jantung yang menyala',
      'other': 'API · Terbang tinggi! Serang jantung yang menyala',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'JERITAN SONIK · Terbang ke celah atas!',
      'middle': 'JERITAN SONIK · Terbang ke celah tengah!',
      'other': 'JERITAN SONIK · Terbang ke celah bawah!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'JERITAN · Bertahan di celah atas',
      'middle': 'JERITAN · Bertahan di celah tengah',
      'other': 'JERITAN · Bertahan di celah bawah',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'HINDARI KIPASNYA  ·  TEMBAK SAAT SELUBUNG TURUN';

  @override
  String get encounterCaption_pirate => 'HINDARI MERIAM  ·  JAUHI AIR';

  @override
  String get encounterCaption_dragon =>
      'HINDARI BOLA API  ·  LOLOS DARI NAPAS NAGA';

  @override
  String get encounterCaption_kingCoo =>
      'KELUAR DARI LINGKARAN  ·  TEMBAK DADANYA SAAT MENGGEMBUNG';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'JAUHI SOROTAN  ·  TEMBAK LAMPUNYA SAAT TERBUKA';

  @override
  String get encounterCaption_neferhoo =>
      'BERSIAPLAH  ·  TEMBAK BALIK SURAT-SURATNYA';

  @override
  String get encounterCaption_screech =>
      'SAAT DIA MENJERIT  ·  TERBANG KE CELAH';

  @override
  String get encounterCaption_default =>
      'BERSIAPLAH  ·  KEPAK, HINDARI, TEMBAK';

  @override
  String get encounterCoasting => 'Burungmu melayang dengan aman';

  @override
  String get encounterOpenSky => 'Kembali ke langit lepas';

  @override
  String get encounterOmenTitle_duskMoth => 'SENJA MENGEPAKKAN SAYAP';

  @override
  String get encounterOmenLine_duskMoth =>
      'Selubung sutra terajut di kala senja…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'ADA YANG SEDANG DIRAMU';

  @override
  String get encounterOmenLine_spitterBeetle => 'Udara mulai berdesis…';

  @override
  String get encounterOmenTitle_dragon => 'LANGIT TERBAKAR';

  @override
  String get encounterOmenLine_dragon => 'Sayap raksasa mengepak di atas awan…';

  @override
  String get encounterOmenTitle_kingCoo => 'KAKI LIMA DITUTUP';

  @override
  String get encounterOmenLine_kingCoo =>
      'Ada yang marah besar soal gerobak roti…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => 'PERINGATAN BADAI';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      'Sesuatu di tepian sedang mengawasi…';

  @override
  String get encounterOmenTitle_neferhoo => 'PIRAMIDA TERBANGUN';

  @override
  String get encounterOmenLine_neferhoo => 'Debu piramida mulai bergerak…';

  @override
  String get encounterOmenTitle_baronReturns => 'SANG BARON KEMBALI';

  @override
  String get encounterOmenLine_baronReturns =>
      'Dia kembali, dan jauh lebih berisik…';

  @override
  String get encounterOmenTitle_default => 'BAYANGAN MENDEKAT';

  @override
  String get encounterOmenLine_default => 'Langit ini sudah ada yang punya…';

  @override
  String get encounterOmenTitle_pirate => 'ADA KAPAL!';

  @override
  String get encounterOmenLine_pirate =>
      'Sebuah kapal datang bersama air pasang…';

  @override
  String get bossGuardianEyebrow => 'PENJAGA';

  @override
  String bossEncounterEyebrow(String number) {
    return 'PERTARUNGAN $number';
  }

  @override
  String get bossGuardianDown => 'PENJAGA TUMBANG!';

  @override
  String get bossSkyReclaimed => 'LANGIT BEBAS LAGI';

  @override
  String bossVictoryPoints(int points) {
    return '+$points POIN   ·   PERISAI PULIH';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'BARON KELELAWAR TUMBANG',
      'spitterBeetle': 'RAJA PELUDAH TUMBANG',
      'duskMoth': 'MAHARANI SENJA TUMBANG',
      'pirate': 'KAPTEN BAJAK LAUT TUMBANG',
      'dragon': 'NAGA BARA TUMBANG',
      'kingCoo': 'RAJA KURKUR TUMBANG',
      'searchlightGargoyle': 'GARGOYLE LAMPU SOROT TUMBANG',
      'other': 'NEFERHOO TUMBANG',
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
  String get bossGargoyleCardSmall => 'LAMPU SOROT';

  @override
  String get bossGargoyleCardBig => 'GARGOYLE';

  @override
  String get bossGargoyleCardOrder => 'big-small';

  @override
  String get bossDodgeFlyLow => 'KE BAWAH';

  @override
  String get bossDodgeFlyHigh => 'KE ATAS';

  @override
  String get bossDodgeClimbOrDive => 'NAIK ATAU TURUN';

  @override
  String get bossDodgeSlipBetween => 'MENYELINAP DI\nSELA SOROTAN';

  @override
  String get bossSpotted => 'TERSOROT!';

  @override
  String get bossShieldLost => 'PERISAI HILANG';

  @override
  String get bossHeartLost => '-1 HATI';

  @override
  String get bossGargoyleLampOpen => 'LAMPU BUKA';

  @override
  String get bossGargoyleShoot => 'TEMBAK!';

  @override
  String get bossScreechFlyToGap => 'TERBANG KE CELAH';

  @override
  String get bossScreechHoldGap => 'TETAP DI CELAH';

  @override
  String get bossPirateHighTide => 'AIR PASANG';

  @override
  String get bossBarDefeated => 'TUMBANG';

  @override
  String get bossBarIncoming => 'MENDEKAT';

  @override
  String get bossBarFury => 'MURKA';

  @override
  String get bossBarHeartDouble => 'JANTUNG ×2';

  @override
  String get bossStronger => 'LEBIH KUAT!';

  @override
  String get bossKingCooPuffed => 'GEMBUNG';

  @override
  String get bossKingCooShout => 'KURRR!';

  @override
  String get bossKingCooPop => 'DOR!';

  @override
  String get bossKingCooPoof => 'PUF!';

  @override
  String get bossSquadOpenLane => 'KE LAJUR TERBUKA';

  @override
  String get bossSquadUseGap => 'LEWAT CELAH';

  @override
  String get bossSquadThenV => 'LALU: V';

  @override
  String get bossSquadThenGap => 'LALU: CELAH';

  @override
  String get bossSquadCancelled => 'SKUADRON BATAL';

  @override
  String get bossNeferhooFound => 'SURAT YANG HILANG DITEMUKAN';

  @override
  String get bossNeferhooHoo => 'HUU';

  @override
  String get bossNeferhooPoo => 'HU';

  @override
  String get bossNeferhooMailCall => 'SURAT DATANG';

  @override
  String get bossNeferhooExpressPost => 'POS KILAT';

  @override
  String get bossNeferhooShootBack => 'Tembak balik!';

  @override
  String get bossNeferhooAnkh => 'ANKH';

  @override
  String get bossNeferhooTwoAnkhs => 'DUA ANKH';

  @override
  String get bossNeferhooComesBack => 'Bisa balik lagi!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'API LIAR!',
      'skyfall': 'LANGIT RUNTUH!',
      'eruption': 'LETUSAN!',
      'other': 'KAWANAN!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Ambil cincin lesat dan kabur darinya!',
      'skyfall': 'Ambil cincin lesat dan berpacu dengan meteor!',
      'eruption': 'Ambil cincin lesat dan lolos dari ledakan!',
      'other': 'Ambil cincin lesat dan terobos kawanannya!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return 'LOLOS! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'TANPA CELA! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Kamu lolos dari api liar',
      'skyfall': 'Kamu selamat dari langit runtuh',
      'eruption': 'Kamu lolos dari letusan',
      'other': 'Kamu menerobos kawanan',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => 'ANGIN RIBUT!';

  @override
  String encounterGaleDetail(String mark) {
    return 'Hindari puing di tempat $mark berkedip!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'BERTAHAN! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail =>
      'Kamu berhasil melewati angin ribut';

  @override
  String get encounterAllRings => 'SEMUA CINCIN!';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'Dorongan turbo +${seconds}s';
  }

  @override
  String get encounterFinish => 'FINIS';

  @override
  String get builderMode_pushUp => 'Push-up';

  @override
  String get builderMode_squat => 'Squat';

  @override
  String get builderMode_jump => 'Lompatan';

  @override
  String builderSeconds(String seconds) {
    return '$seconds dtk';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes mnt $seconds dtk';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count push-up',
      one: '1 push-up',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count squat',
      one: '1 squat',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'Level ketukku';

  @override
  String get builderNewLevel_pushUp => 'Level push-up-ku';

  @override
  String get builderNewLevel_squat => 'Level squat-ku';

  @override
  String get builderNewLevel_jump => 'Level lompatku';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'Levelku';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Ayo terbangkan level Beakbound-ku “$name” ($mode): $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$earned dari $total bintang';
  }

  @override
  String get builderBackSemantics => 'Kembali';

  @override
  String get builderKeepIt => 'Tetap simpan';

  @override
  String builderLessSemantics(String name) {
    return 'Kurangi $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'Tambah $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => 'Duplikat';

  @override
  String get builderCopy => 'Salin';

  @override
  String get builderDeleteSemantics => 'Hapus';

  @override
  String get builderDelete => 'Hapus';

  @override
  String get builderMoreBelow => 'Lanjut ke bawah';

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
  String get builderLane => 'Lajur';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'atas atau bawah squat',
      'other': 'atas atau bawah push-up',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'Atas';

  @override
  String get builderLaneBottom => 'Bawah';

  @override
  String get builderHeight => 'Tinggi';

  @override
  String get builderHeightHint => 'dari langit';

  @override
  String get builderLowerSemantics => 'Turunkan';

  @override
  String get builderHigherSemantics => 'Naikkan';

  @override
  String get builderOpening => 'Celah';

  @override
  String builderOpeningHint(int percent) {
    return 'minimal $percent%';
  }

  @override
  String get builderNarrowerSemantics => 'Persempit';

  @override
  String get builderWiderSemantics => 'Perlebar';

  @override
  String get builderMotion => 'Gerak';

  @override
  String get builderMotionGardenHint => 'gerbang taman selalu diam';

  @override
  String get builderMotionStill => 'Diam';

  @override
  String get builderMotionGentle => 'Pelan';

  @override
  String get builderMotionLively => 'Lincah';

  @override
  String get builderMotionGardenToast =>
      'Gerbang taman selalu diam: pilih jenis lain agar bisa bergerak.';

  @override
  String get builderSway => 'Ayunan';

  @override
  String builderSwayHint(String seconds) {
    return 'satu ayunan: $seconds';
  }

  @override
  String get builderSwayFast => 'Cepat';

  @override
  String get builderSwayMedium => 'Sedang';

  @override
  String get builderSwaySlow => 'Lambat';

  @override
  String get builderPhase => 'Saat kamu tiba';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position dari $count';
  }

  @override
  String get builderPhaseHint => 'posisinya dalam ayunan';

  @override
  String get builderPhaseEarlierSemantics => 'Lebih awal dalam ayunan';

  @override
  String get builderPhaseLaterSemantics => 'Lebih akhir dalam ayunan';

  @override
  String get builderLook => 'Tampilan';

  @override
  String builderLookSemantics(int number) {
    return 'Tampilan $number';
  }

  @override
  String get builderDoor => 'Pintu batu';

  @override
  String get builderDoorHint => 'tembak agar terbuka';

  @override
  String get builderDoorNone => 'Tanpa pintu';

  @override
  String get builderDoorNeedsShootToast =>
      'Nyalakan Tembak di pengaturan level untuk memakai pintu.';

  @override
  String get builderPlace => 'Posisi';

  @override
  String get builderPlaceHint => 'dari awal';

  @override
  String get builderEarlierSemantics => 'Lebih awal';

  @override
  String get builderLaterSemantics => 'Lebih akhir';

  @override
  String builderFamilySemantics(String family) {
    return 'Jenis gerbang: $family. Ganti';
  }

  @override
  String get builderChangeFamily => 'Ganti jenis';

  @override
  String get builderItemStar => 'Bintang';

  @override
  String get builderItemTrio => 'Trio bintang';

  @override
  String get builderItemHeart => 'Hati';

  @override
  String get builderItemEnemy => 'Musuh';

  @override
  String get builderItemGate => 'Gerbang';

  @override
  String get builderItemStarDetail => 'Satu bintang untuk diambil';

  @override
  String get builderItemTrioDetail => 'Ambil ketiganya, dapat bonus';

  @override
  String get builderItemHeartDetail => 'Pulihkan satu hati';

  @override
  String get builderEnemyKind => 'Jenis';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Burung terbang di atas dan bawah setiap squat: taruh item tepat di garis kuning atau di antaranya.',
      'other':
          'Burung terbang di atas dan bawah setiap push-up: taruh item tepat di garis kuning atau di antaranya.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'Kelelawar ungu';

  @override
  String get builderEnemy_caveBat => 'Kelelawar gua';

  @override
  String get builderEnemy_spitterBeetle => 'Kumbang peludah';

  @override
  String get builderEnemy_duskMoth => 'Ngengat senja';

  @override
  String get builderEnemy_alleyPigeon => 'Merpati Gang';

  @override
  String get builderEnemy_mummyBat => 'Kelelawar mumi';

  @override
  String get builderSummaryTitle => 'Level ini';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'Durasi';

  @override
  String get builderFactStars => 'Bintang';

  @override
  String get builderFactMarks => 'Tanda bintang';

  @override
  String get builderFactWorkout => 'Olahraga';

  @override
  String get builderFactPace => 'Tempo';

  @override
  String get builderFactBoss => 'Bos';

  @override
  String get builderPace_relaxed => 'Santai';

  @override
  String get builderPace_steady => 'Sedang';

  @override
  String get builderPace_brisk => 'Cepat';

  @override
  String get builderSummaryStarterNote =>
      'Level awal untuk diterbangkan apa adanya, atau di-remix jadi levelmu sendiri.';

  @override
  String get builderSummaryClearedNote =>
      'Sudah kamu tamatkan: kamu terbang sampai finis.';

  @override
  String get builderSummaryClearNote =>
      'Uji terbang sampai garis finis untuk menandainya tamat.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    return 'Uji terbang, kalahkan $boss, dan lewati garis finis untuk menandainya tamat.';
  }

  @override
  String get builderSummaryHowTo =>
      'Pilih alat di kiri, lalu ketuk langit. Ketuk sebuah benda untuk mengubahnya; seret untuk memindahkannya.';

  @override
  String get builderFamily_garden_detail =>
      'Selalu diam. Bisa dipasangi pintu batu.';

  @override
  String get builderFamily_windLift_detail => 'Celahnya naik dan turun.';

  @override
  String get builderFamily_petalGate_detail =>
      'Celahnya menyempit dan melebar.';

  @override
  String get builderFamily_switchback_detail =>
      'Dua celah yang bergeser menjauh.';

  @override
  String get builderFamily_lanternDrift_detail =>
      'Lentera gantung yang naik-turun.';

  @override
  String get builderFamily_sunWheels_detail =>
      'Roda yang merapat lalu menjauh.';

  @override
  String get builderFamily_crystalSteps_detail =>
      'Tiga anak tangga yang bergelombang.';

  @override
  String get builderFamiliesCloseSemantics => 'Tutup jenis gerbang';

  @override
  String get builderFamiliesTitle => 'Jenis gerbang';

  @override
  String get builderFamiliesSubtitle => 'Tampilan dan gerak gerbangnya.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Beri level nama, maksimal $count huruf.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort =>
      'Geser garis finis lebih jauh: levelnya terlalu pendek.';

  @override
  String get reach_tooLong => 'Dekatkan garis finis: levelnya terlalu panjang.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terlalu banyak benda: satu level maksimal $count.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap =>
      'Hanya level Ketuk & Terbang yang bisa berakhir dengan bos.';

  @override
  String get reach_noGates => 'Tambahkan gerbang untuk dilewati burung.';

  @override
  String get reach_startZone =>
      'Terlalu dekat dengan awal: pindahkan melewati zona mulai.';

  @override
  String get reach_finishRoom =>
      'Sisakan ruang sebelum garis finis setelah gerbang ini.';

  @override
  String get reach_overlap => 'Dua gerbang bertumpuk: jauhkan keduanya.';

  @override
  String get reach_gateHeight =>
      'Gerbang ini terlalu tinggi atau terlalu rendah.';

  @override
  String get reach_gateMotion => 'Gerbang ini tak bisa bergerak seperti itu.';

  @override
  String get reach_gateLook => 'Tampilan gerbang ini tidak dikenal.';

  @override
  String get reach_gateNarrow =>
      'Lebarkan celah gerbang ini: burungnya tak muat.';

  @override
  String get reach_gateWide => 'Celah gerbang ini terlalu lebar.';

  @override
  String get reach_doorNeedsShoot =>
      'Pintu batu butuh Ketuk & Terbang dengan Tembak menyala.';

  @override
  String get reach_doorNeedsGarden =>
      'Hanya gerbang taman yang bisa dipasangi pintu batu.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Pergantian lajur rapat: squat dengan tempo biasa mungkin tak keburu.',
      'other':
          'Pergantian lajur rapat: push-up dengan tempo biasa mungkin tak keburu.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'Tanjakan curam: beri ruang lebih untuk melompat ke gerbang ini.';

  @override
  String get reach_enemyNeedsTap =>
      'Musuh hanya terbang di level Ketuk & Terbang.';

  @override
  String get reach_outsideSky => 'Taruh di dalam langit.';

  @override
  String get reach_pastFinish => 'Taruh sebelum garis finis.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Di luar jangkauan squat: dekatkan ke lajur.',
      'other': 'Di luar jangkauan push-up: dekatkan ke lajur.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'Di dalam dinding: pindahkan ke celahnya.';

  @override
  String get reach_noStars => 'Taruh minimal satu bintang.';

  @override
  String get reach_marks =>
      'Tanda bintang meminta lebih banyak bintang daripada yang ada di level.';

  @override
  String reach_cannotFly(String problem) {
    return 'Level ini belum bisa diterbangkan ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'Level gagal disimpan, jadi belum bisa terbang. Ketuk namanya untuk mencoba lagi.';

  @override
  String get builderShareBlockedToast =>
      'Perbaiki tanda merah dulu: setelah itu level bisa dibagikan.';

  @override
  String get builderEditorBackSemantics => 'Kembali ke pembuat level';

  @override
  String get builderSettingsSemantics => 'Pengaturan level';

  @override
  String get builderFly => 'TERBANG';

  @override
  String get builderTestFly => 'UJI TERBANG';

  @override
  String get builderFlySemantics => 'Terbangkan level ini';

  @override
  String get builderTestFlySemantics => 'Uji terbang seluruh level';

  @override
  String get builderUndoSemantics => 'Urungkan';

  @override
  String get builderRedoSemantics => 'Ulangi';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice tips',
    );
    return '$blocking perlu diperbaiki, $_temp0';
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
  String get builderReadySemantics => 'Siap terbang';

  @override
  String get builderShareSemantics => 'Kode bagikan';

  @override
  String get builderFromHereSemantics => 'Uji terbang dari sini';

  @override
  String get builderFromHere => 'Dari sini';

  @override
  String get builderStatusStarter => 'Level awal · lihat, terbang, remix';

  @override
  String get builderStatusSaveFailed => 'Gagal disimpan · ketuk untuk ulangi';

  @override
  String get builderStatusSaving => 'Menyimpan…';

  @override
  String get builderStatusSaved => 'Semua perubahan tersimpan';

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
    return '$name. $mode. $status. Ketuk untuk mengganti nama.';
  }

  @override
  String get builderStarterBanner => 'Remix agar jadi milikmu';

  @override
  String get builderRemix => 'Remix';

  @override
  String get builderRemixSemantics => 'Remix';

  @override
  String get builderIssuesCloseSemantics => 'Tutup masalah dan tips';

  @override
  String get builderIssuesReadyTitle => 'Siap terbang!';

  @override
  String get builderIssuesFixTitle => 'Perbaiki sebelum terbang';

  @override
  String get builderIssuesTipsTitle => 'Siap, dengan beberapa tips';

  @override
  String get builderIssuesReadyDetail =>
      'Semua beres. Uji terbang sampai finis untuk menamatkannya.';

  @override
  String get builderIssuesDetail =>
      'Ketuk salah satu untuk menuju tempatnya di rute.';

  @override
  String get builderSettingsCloseSemantics => 'Tutup pengaturan';

  @override
  String get builderSettingsTitle => 'Pengaturan level';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · perubahan langsung tersimpan';
  }

  @override
  String get builderSettingsName => 'Nama';

  @override
  String get builderRename => 'Ganti nama';

  @override
  String get builderRenameSemantics => 'Ganti nama';

  @override
  String get builderSettingsRegion => 'Wilayah';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tempat · geser untuk melihat',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'Tempo';

  @override
  String get builderSettingsPaceHint => 'seberapa cepat langit bergulir';

  @override
  String get builderSettingsMarks => 'Tanda bintang';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang terpasang',
      one: '1 bintang terpasang',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'tanda dua bintang';

  @override
  String get builderMarkThreeSemantics => 'tanda tiga bintang';

  @override
  String get builderMarksAuto => 'Otomatis: ikuti bintang';

  @override
  String get builderMarksByHand => 'Atur sendiri';

  @override
  String get builderSettingsControls => 'Kontrol';

  @override
  String get builderShootOn => 'Tembak aktif';

  @override
  String get builderShootOff => 'Tembak nonaktif';

  @override
  String get builderSprintOn => 'Melesat aktif';

  @override
  String get builderSprintOff => 'Melesat nonaktif';

  @override
  String get builderSettingsBoss => 'Bos penutup';

  @override
  String get builderSettingsBossHint => 'menunggu di ujung';

  @override
  String get builderNoBossSemantics => 'Tanpa bos: garis finis';

  @override
  String get builderNoBoss => 'Tanpa bos';

  @override
  String get builderBossShort_baronBat => 'Baron';

  @override
  String get builderBossShort_spitterBeetle => 'Peludah';

  @override
  String get builderBossShort_duskMoth => 'Maharani';

  @override
  String get builderBossShort_pirate => 'Kapten';

  @override
  String get builderBossShort_dragon => 'Naga';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Burung terbang di dua lajur: atas dan bawah setiap squat. Pemain yang lebih lambat memainkan level yang sama dengan kecepatan lebih santai. Di sini tak ada tembakan, lesatan, atau bos.',
      'other':
          'Burung terbang di dua lajur: atas dan bawah setiap push-up. Pemain yang lebih lambat memainkan level yang sama dengan kecepatan lebih santai. Di sini tak ada tembakan, lesatan, atau bos.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'Setiap lompatan mengangkat burung; di antaranya ia melayang. Di sini tak ada tembakan, lesatan, atau bos.';

  @override
  String get builderStartZoneToast =>
      'Biarkan zona mulai kosong: taruh benda di kanan garis putus-putus.';

  @override
  String get builderSkySemantics =>
      'Langit level. Ketuk untuk menaruh, seret untuk memindahkan atau menggulir.';

  @override
  String get builderSkyReadOnlySemantics =>
      'Langit level. Ketuk sesuatu untuk melihatnya.';

  @override
  String get builderCoachTitle => 'Bangun levelmu';

  @override
  String get builderCoachPickTool => 'Pilih alat di kiri';

  @override
  String get builderCoachTapSky => 'Ketuk langit untuk menaruhnya';

  @override
  String get builderCoachTestFly => 'Uji terbang!';

  @override
  String get builderCoachDrag =>
      'Seret benda untuk memindahkannya · seret langit untuk menggulir';

  @override
  String get builderTipDrag =>
      'Seret untuk memindahkan · seret langit untuk menggulir';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'POSISI ATAS SQUAT',
      'other': 'POSISI ATAS PUSH-UP',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'ATAS';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'POSISI BAWAH SQUAT',
      'other': 'POSISI BAWAH PUSH-UP',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'BAWAH';

  @override
  String get builderCanvasStartZoneFull => 'ZONA MULAI · BIARKAN KOSONG';

  @override
  String get builderCanvasStartZone => 'ZONA MULAI';

  @override
  String get builderCanvasFinishHere => 'FINIS DI SINI';

  @override
  String get builderTool_select => 'Pilih';

  @override
  String get builderToolHint_select =>
      'Pilih: ketuk sesuatu untuk mengubahnya, seret untuk memindahkannya';

  @override
  String get builderTool_gate => 'Gerbang';

  @override
  String get builderToolHint_gate =>
      'Gerbang: ketuk langit untuk menaruh gerbang';

  @override
  String get builderTool_star => 'Bintang';

  @override
  String get builderToolHint_star =>
      'Bintang: ketuk langit untuk menaruh bintang';

  @override
  String get builderTool_trio => 'Trio';

  @override
  String get builderToolHint_trio =>
      'Trio bintang: ketuk langit untuk menaruh tiga bintang';

  @override
  String get builderTool_heart => 'Hati';

  @override
  String get builderToolHint_heart => 'Hati: ketuk langit untuk menaruh hati';

  @override
  String get builderTool_enemy => 'Musuh';

  @override
  String get builderToolHint_enemy => 'Musuh: ketuk langit untuk menaruh musuh';

  @override
  String get builderTool_finish => 'Finis';

  @override
  String get builderToolHint_finish =>
      'Finis: ketuk langit untuk memindahkan garis finis';

  @override
  String get builderTool_boss => 'Bos';

  @override
  String get builderToolHint_boss =>
      'Tanda bos: ketuk langit untuk memindahkan tempat bos menunggu';

  @override
  String get builderStarterToolsToast =>
      'Level awal tak bisa diubah: remix dulu untuk mengubahnya.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Ringkasan rute. $length sampai bos. Seret untuk bergerak di sepanjang rute.',
      'other':
          'Ringkasan rute. $length sampai finis. Seret untuk bergerak di sepanjang rute.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Ringkasan rute. $length sampai bos. $reps. Seret untuk bergerak di sepanjang rute.',
      'other':
          'Ringkasan rute. $length sampai finis. $reps. Seret untuk bergerak di sepanjang rute.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '$length sampai bos';
  }

  @override
  String get builtResultTestFlight => 'UJI TERBANG';

  @override
  String get builtResultCleared => 'Tamat!';

  @override
  String get builtResultBonk => 'Duk!';

  @override
  String get builtResultLanded => 'Mendarat';

  @override
  String get builtResultTestTab => 'UJI';

  @override
  String get builtResultGoalFinish => 'Finis';

  @override
  String get builtResultGoalBoss => 'Bos';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. Tercapai.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kumpulkan $count bintang.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kumpulkan $count bintang. Tercapai.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'Tercapai';

  @override
  String get builtResultNotYet => 'Belum';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagi',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'Finis dulu';

  @override
  String get builtResultClearedByYou => 'KAMU TAMATKAN!';

  @override
  String get builtResultNewBest => 'REKOR BARU!';

  @override
  String get builtResultPractice => 'Latihan';

  @override
  String builtResultBest(int count) {
    return 'Terbaik $count';
  }

  @override
  String get builtResultFirstClear => 'Tamat perdana!';

  @override
  String get builtResultStarsCollected => 'BINTANG TERKUMPUL';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dari 3 bintang level',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'TARGET';

  @override
  String get builtResultWorkout => 'OLAHRAGA';

  @override
  String get builtResultGotTo => 'SAMPAI';

  @override
  String get builtResultScore => 'SKOR';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'push-up',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squat',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lompatan',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'push-up via kamera',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squat via kamera',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'dari $length';
  }

  @override
  String get builtResultNotKept => 'Tidak disimpan';

  @override
  String get builtResultNoBest => 'Belum ada skor';

  @override
  String get builtResultClearedStrip => 'Sudah kamu tamatkan · siap dibagikan!';

  @override
  String builtResultFlownFrom(String from) {
    return 'Mulai dari $from. Terbang dari awal untuk menamatkan.';
  }

  @override
  String get builtResultTestNothingSaved =>
      'Uji terbang · tidak ada yang disimpan';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'Uji terbang · sampai $reached dari $length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return 'Sampai $reached dari $length. Capai finis untuk dapat bintang.';
  }

  @override
  String get builtResultReachFinish => 'Capai garis finis untuk dapat bintang.';

  @override
  String get builtResultSaved => 'Tersimpan di ponsel ini';

  @override
  String get builtResultSaving => 'Menyimpan penerbanganmu…';

  @override
  String get builtResultBuilder => 'Pembuat';

  @override
  String get builtResultEditLevel => 'Ubah level';

  @override
  String get builtResultEdit => 'Ubah';

  @override
  String get builtResultFlyAgain => 'Terbang lagi';

  @override
  String get builtResultWatchReplay => 'Tonton ulang';

  @override
  String get builtResultPreparing => 'Menyiapkan…';

  @override
  String get builtResultSessionSaving => 'Menyimpan…';

  @override
  String get builtResultSaveSession => 'Simpan sesi';

  @override
  String get builderShelfTitle => 'Pembuat Level';

  @override
  String get builderShelfPasteCode => 'Tempel kode';

  @override
  String get builderShelfNewLevel => 'Level baru';

  @override
  String get builderShelfSaveFailed => 'Gagal disimpan. Coba lagi, ya.';

  @override
  String builderShelfDeleteTitle(String name) {
    return 'Hapus “$name”?';
  }

  @override
  String get builderShelfDeleteBody =>
      'Rekor terbaiknya ikut terhapus. Push-up, squat, dan lompatan yang kamu lakukan di level ini tetap dihitung.';

  @override
  String get builderShelfDelete => 'Hapus';

  @override
  String builderShelfDeleted(String name) {
    return '“$name” dihapus.';
  }

  @override
  String get builderShelfFixFirst =>
      'Perbaiki yang bertanda merah sebelum dibagikan: ketuk Perbaiki.';

  @override
  String get builderShelfCodeCopied => 'Kode disalin! Tempelkan untuk temanmu.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'Kode disalin! Terbangi juga sampai finis, biar temanmu tahu level ini bisa ditamatkan.';

  @override
  String get builderShelfNotReady =>
      'Level ini belum siap terbang: ketuk Perbaiki.';

  @override
  String get builderShelfPasteMissingTitle =>
      'Tak ada kode level untuk ditempel';

  @override
  String get builderShelfPasteNewerTitle => 'Level dari Beakbound versi baru';

  @override
  String get builderShelfPasteDamagedTitle => 'Kodenya berantakan';

  @override
  String get builderShelfPasteMissingBody =>
      'Salin kode level temanmu (diawali BEAK1.) lalu ketuk Tempel kode lagi.';

  @override
  String get builderShelfPasteNewerBody =>
      'Perbarui Beakbound untuk menerbangkannya, lalu tempel kodenya lagi.';

  @override
  String get builderShelfPasteDamagedBody =>
      'Ada bagian yang hilang atau salah ketik. Minta temanmu menyalin seluruh kodenya lagi.';

  @override
  String builderShelfImported(String name) {
    return '“$name” sudah ada di rakmu!';
  }

  @override
  String get builderShelfUnavailable => 'Level-levelmu butuh waktu sebentar.';

  @override
  String get builderShelfMine => 'Levelku';

  @override
  String get builderShelfStarters => 'Level awal';

  @override
  String get builderShelfStartersHint =>
      'Terbangkan salah satu, atau remix jadi levelmu sendiri';

  @override
  String get builderShelfEmptyTitle => 'Buat level pertamamu';

  @override
  String get builderShelfEmptyBody =>
      'Taruh gerbang, bintang, dan hati sendiri, tentukan garis finis, lalu uji terbang.';

  @override
  String get builderShelfPasteFriend => 'Tempel kode teman';

  @override
  String get builderShelfNeedsWork => 'Perlu diperbaiki';

  @override
  String get builderShelfClearedByYou => 'Sudah kamu tamatkan';

  @override
  String get builderShelfFromFriend => 'Dari teman';

  @override
  String get builderShelfFly => 'Terbang';

  @override
  String builderShelfFlySemantics(String name) {
    return 'Terbangkan $name';
  }

  @override
  String get builderShelfFixIt => 'Perbaiki';

  @override
  String builderShelfFixSemantics(String name) {
    return 'Perbaiki $name';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return 'Ubah $name';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return 'Bagikan $name';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return 'Bagikan $name: sudah kamu tamatkan';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'Lainnya untuk $name';
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
      other: '$count hal perlu diperbaiki di editor',
      one: '1 hal perlu diperbaiki di editor',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang',
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
    return '$name. $mode di $region. $length.';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Terbaik $stars dari 3 bintang.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Perlu diperbaiki: $count hal.',
      one: 'Perlu diperbaiki: 1 hal.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'Sudah kamu tamatkan.';

  @override
  String get builderShelfFromFriendSemantics => 'Dari teman.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return 'Lihat $name. $mode, $length, $fact.';
  }

  @override
  String get builderShelfRemixSuffix => 'remix';

  @override
  String get builderShelfCopySuffix => 'salinan';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Batal';

  @override
  String get starter_t_tap_1_name => 'Lompat Taman';

  @override
  String get starter_t_push_1_name => 'Sepuluh Push-Up';

  @override
  String get starter_t_squat_1_name => 'Squat Tangga';

  @override
  String get starter_t_jump_1_name => 'Teluk Pantul';

  @override
  String get starter_t_tap_boss_name => 'Jembatan Baron';

  @override
  String get builderPickCloseNewLevel => 'Tutup level baru';

  @override
  String get builderPickModeTitle => 'Mau level seperti apa?';

  @override
  String get builderPickRegionTitle => 'Terbang di mana?';

  @override
  String get builderPickModeSubtitle =>
      'Pilih cara terbangnya (tak bisa diubah nanti). Semua level diuji terbang dengan sentuhan.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · pilih tempat terbangnya. Bisa diubah nanti.';
  }

  @override
  String get builderPickTouchLine =>
      'Ketuk untuk mengepak. Gerbang, bintang, musuh, dan bos.';

  @override
  String get builderPickPushUpLine =>
      'Lajur atas dan lajur bawah: setiap turun adalah satu push-up.';

  @override
  String get builderPickSquatLine =>
      'Lajur atas dan lajur bawah: setiap turun adalah satu squat.';

  @override
  String get builderPickJumpLine =>
      'Lompat untuk naik. Gerbang di mana saja di langit.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'Kamera';

  @override
  String get builderPickSuggested => 'Disarankan';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, disarankan';
  }

  @override
  String get builderPickClose => 'Tutup';

  @override
  String get builderPickNotYet =>
      'Belum bisa: perbaiki yang bertanda merah dulu.';

  @override
  String get builderPickShare => 'Kode bagikan';

  @override
  String get builderPickShareLine =>
      'Salin kode yang bisa ditempel temanmu di Beakbound miliknya.';

  @override
  String get builderPickDuplicate => 'Duplikat';

  @override
  String get builderPickDuplicateLine => 'Buat salinan untuk mencoba ide lain.';

  @override
  String get builderPickDeleteLine =>
      'Buang level ini. Kamu akan ditanya dulu.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'Batalkan impor';

  @override
  String get builderPickImportTitle => 'Ada level untuk diterbangkan!';

  @override
  String get builderPickImportSubtitle =>
      'Seseorang membagikan level ini untukmu.';

  @override
  String get builderPickClearedByMaker => 'Sudah ditamatkan pembuatnya';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang untuk dikumpulkan',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    return 'Berakhir dengan $boss';
  }

  @override
  String get builderPickNotFlown =>
      'Pembuatnya belum menerbangkannya sampai finis.';

  @override
  String get builderPickRoute => 'Rutenya';

  @override
  String builderPickAlreadyHave(String name) {
    return 'Kamu sudah punya level ini: “$name”.';
  }

  @override
  String get builderPickImportCopy => 'Impor salinan';

  @override
  String get builderPickOpenYours => 'Buka milikmu';

  @override
  String get builderPickImport => 'Impor';

  @override
  String get builderShelfRenameCancelSemantics => 'Batal ganti nama';

  @override
  String get builderShelfRenameTitle => 'Beri nama levelmu';

  @override
  String get builderShelfRenameEmpty => 'Nama butuh satu-dua huruf';

  @override
  String get builderShelfRenameSaveSemantics => 'Simpan nama';

  @override
  String get builderShelfRenameSave => 'Simpan';

  @override
  String get coopMode_roped => 'Bertali';

  @override
  String get coopMode_free => 'Tanpa tali';

  @override
  String get coopMode_duel => '1 lawan 1';

  @override
  String get coopTitle => 'Terbang Bersama';

  @override
  String get coopPlayersTag => 'DUA PEMAIN · SATU PONSEL';

  @override
  String coopBestTag(String mode, int best) {
    return 'REKOR $mode $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: BELUM ADA REKOR';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count DUEL',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode: DUEL PERTAMA';
  }

  @override
  String get coopRopedLead => 'Kedua burungmu terikat satu tali.';

  @override
  String get coopRopedBody =>
      'Kepak bersamaan untuk naik tinggi: burung yang mengepak sendirian ikut mengangkat keduanya, tapi cuma sedikit. Melesat untuk menarik rekanmu.';

  @override
  String get coopFreeLead => 'Tanpa tali:';

  @override
  String get coopFreeBody =>
      'tiap burung terbang sendiri dan hanya bisa bertabrakan dengan yang lain. Hati, perisai, dan skor tetap dibagi bersama.';

  @override
  String get duelLead => 'Bertarung!';

  @override
  String get duelBody =>
      'Tiap burung punya hatinya sendiri. Ambil kotak misteri: ada yang mengirim kelelawar, kumbang peludah, atau meteor ke lawanmu, ada juga yang memberi hati, perisai, atau kekuatan bintang. Burung terakhir yang masih terbang menang.';

  @override
  String get coopStart => 'Terbang bersama';

  @override
  String get duelStart => 'Bertarung!';

  @override
  String get coopFlightSemantics =>
      'Pemain 1 mengetuk separuh kiri untuk mengepak, pemain 2 separuh kanan';

  @override
  String get coopPauseSemantics => 'Jeda penerbangan';

  @override
  String coopShootSemantics(int player) {
    return 'Pemain $player: Tembak';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'Pemain $player: Melesat';
  }

  @override
  String coopPlayerShort(int player) {
    return 'P$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'PEMAIN $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Magnet bintang: sisa $seconds detik',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Magnet terisi: $charge dari $gates gerbang sempurna',
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
  String get coopCountdownRoped => 'Tali terpasang. Bersedia, siap…';

  @override
  String get coopCountdownFree => 'Bersedia, siap…';

  @override
  String get duelCountdown => 'Siap berduel…';

  @override
  String get coopCountdownRopedHint =>
      'Kepak bersamaan untuk naik tinggi.\nMelesat untuk menarik rekanmu!';

  @override
  String get coopCountdownFreeHint =>
      'Tiap burung terbang sendiri.\nBerbagi hati, taklukkan gerbang!';

  @override
  String get duelCountdownHint =>
      'Ambil kotak misterinya!\nBurung terakhir yang terbang menang.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Kekuatan bintang pemain $player: sisa $seconds detik',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'Beranda';

  @override
  String get coopChangeBirds => 'Ganti burung';

  @override
  String get coopSaved => 'Tersimpan';

  @override
  String get coopSaving => 'Menyimpan…';

  @override
  String get coopSaveSession => 'Simpan sesi';

  @override
  String get duelRematch => 'Tanding ulang';

  @override
  String get coopFlyAgain => 'Terbang lagi';

  @override
  String duelWinner(int player) {
    return 'Pemain $player menang!';
  }

  @override
  String get duelDraw => 'Seri!';

  @override
  String get duelStopped => 'Duel dihentikan';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first vs $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner mengalahkan $loser';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize ke P$rival!';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize!';
  }

  @override
  String get duelPrize_batSwarm => 'Badai kelelawar';

  @override
  String get duelPrize_spitter => 'Kumbang peludah';

  @override
  String get duelPrize_meteorShower => 'Hujan meteor';

  @override
  String get duelPrize_heart => 'Hati';

  @override
  String get duelPrize_shield => 'Perisai';

  @override
  String get duelPrize_starPower => 'Kekuatan bintang';

  @override
  String get coopTapLeftHalf => 'Ketuk separuh kiri';

  @override
  String get coopTapRightHalf => 'Ketuk separuh kanan';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'Pemain $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'P$player · ketuk sisi ini';
  }

  @override
  String get coopKeysP1 => 'P1: W kepak, D tembak, A lesat';

  @override
  String get coopKeysP2 => 'P2: Atas kepak, Kanan tembak, Kiri lesat';

  @override
  String get coopRopedSemantics => 'Bertali: kedua burung berbagi satu tali';

  @override
  String get coopFreeSemantics => 'Tanpa tali: tiap burung terbang sendiri';

  @override
  String get duelModeSemantics => '1 lawan 1: kedua burung saling bertarung';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'Sesi tersimpan · Tonton di Rekor';

  @override
  String get coopNewTeamBest => 'Rekor tim baru!';

  @override
  String get coopWhatATeam => 'Tim yang hebat.';

  @override
  String coopPairCaption(String first, String second) {
    return '$first & $second';
  }

  @override
  String get coopTeamScore => 'SKOR TIM';

  @override
  String get coopTeamBest => 'REKOR TIM';

  @override
  String get coopNewTeamBestRibbon => 'REKOR TIM BARU!';

  @override
  String get coopStatFlightTime => 'waktu terbang';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bintang',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gerbang',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'BAGIAN KEPAKAN';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kepakan P$player',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'Waktu duel $time';
  }

  @override
  String get duelSeries => 'TOTAL';

  @override
  String get duelHeartsLeft => 'sisa hati';

  @override
  String get duelBoxesOpened => 'kotak dibuka';

  @override
  String get duelHitsLanded => 'serangan mengena';

  @override
  String get coopPauseSubtitle =>
      'Kalian berdua bertengger dan menunggu. Nanti kami hitung mundur lagi.';

  @override
  String get coopFinishFlight => 'Akhiri terbang';

  @override
  String get cameraLabIntro =>
      'Sandarkan ponselmu rendah dalam posisi mendatar, menghadapmu atau di sampingmu.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'Hampir · perlu tampilan lebih jelas untuk: $parts';
  }

  @override
  String get cameraLabJointShoulder => 'bahu';

  @override
  String get cameraLabJointElbow => 'siku';

  @override
  String get cameraLabJointWrist => 'pergelangan';

  @override
  String get cameraLabJointHip => 'pinggul';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => 'Menyalakan kamera…';

  @override
  String get cameraLabDenied =>
      'Akses kamera mati. Izinkan di pengaturan aplikasi, lalu coba lagi.';

  @override
  String cameraLabFailed(String error) {
    return 'Kamera tak bisa menyala: $error';
  }

  @override
  String get cameraLabStopped =>
      'Kamera berhenti. Ketuk Nyalakan kamera untuk kalibrasi ulang.';

  @override
  String get cameraLabBack => 'LAB KAMERA · Kembali ke beranda';

  @override
  String get cameraLabStepShow => '1. Tunjukkan lengan & pinggul';

  @override
  String get cameraLabStepPushUps => '2. Lakukan dua push-up';

  @override
  String get cameraLabStepMove => '3. Gerakkan burungmu!';

  @override
  String get cameraLabStepSquat => 'Temukan jangkauan squatmu';

  @override
  String get cameraLabStepJump => 'Temukan posisi berdirimu';

  @override
  String get cameraLabPushUpHelp =>
      'Ponsel rendah, menghadapmu atau di sampingmu.\nMenghadap ponsel? Tunjukkan kedua bahu, satu lengan, dan pinggul.\nTurun dan naik dua kali dengan tempomu sendiri.';

  @override
  String get cameraLabSquatHelp =>
      'Berdiri diam, squat dengan nyaman dan tahan sebentar, lalu berdiri lagi. Squat untuk turun; berdiri untuk naik.';

  @override
  String get cameraLabJumpHelp =>
      'Berdiri menghadap ponsel dengan seluruh tubuh dan kaki terlihat. Diam sebentar, lalu lompat kecil-kecil. Satu lompatan = satu dorongan besar.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'KALIBRASI\n$done / $total terkalibrasi',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'KALIBRASI\n$percent% terkalibrasi';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'UJI KONTROL\n$count push-up',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'UJI KONTROL\n$count squat',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'UJI KONTROL\n$count lompatan',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Hz · $ms ms p95';
  }

  @override
  String get cameraLabStartingButton => 'Memulai…';

  @override
  String get cameraLabRecalibrate => 'Kalibrasi ulang';

  @override
  String get cameraLabStartCamera => 'Nyalakan kamera';

  @override
  String get cameraLabTapStart => 'Ketuk Nyalakan kamera';

  @override
  String cameraLabTry(String mode) {
    return 'Coba $mode';
  }

  @override
  String get cameraBadgeWaking => 'MEMULAI';

  @override
  String get cameraBadgeLive => 'AKTIF';

  @override
  String get cameraBadgeLockedOn => 'TERDETEKSI';

  @override
  String get cameraBadgeOffline => 'MATI';

  @override
  String get trackingCatchingUp => 'Kamera sedang menyusul';

  @override
  String get trackingStepIntoOutline => 'Masuk ke dalam garis tubuh';

  @override
  String get trackingKeepShoulders => 'Pastikan kedua bahu terlihat';

  @override
  String get trackingShowSide =>
      'Tunjukkan satu bahu, siku, pergelangan, dan pinggul dari samping';

  @override
  String get trackingMoveCloser => 'Mendekat sedikit';

  @override
  String get trackingGetDown => 'Turun ke posisi push-up';

  @override
  String get trackingHandsOnFloor =>
      'Letakkan tangan di lantai dan luruskan badan ke belakang';

  @override
  String get trackingExtendBody =>
      'Luruskan badan sedikit lebih jauh di belakang tanganmu';

  @override
  String get trackingComfortableRange =>
      'Tetap dalam jangkauan push-up yang nyaman';

  @override
  String get trackingPlaceHands =>
      'Letakkan tangan di lantai dengan badan di belakangnya';

  @override
  String get trackingFrontTracked =>
      'Tampak depan terlacak · jaga tanganmu tetap terlihat';

  @override
  String get trackingBodyInView => 'Badan terlihat · wajah boleh menunduk';

  @override
  String get trackingArmsTracked => 'Lengan terlacak · cek kaki terbatas';

  @override
  String get trackingFindTop => 'Cari posisi atas yang nyaman';

  @override
  String get trackingCalibrated => 'Terkalibrasi! Coba gerakkan burungmu.';

  @override
  String get trackingFreshFrame => 'Menunggu gambar baru';

  @override
  String get trackingDistanceChanged =>
      'Jarak kamera berubah · kalibrasi ulang';

  @override
  String get trackingKeepArm => 'Pastikan satu lengan terlihat';

  @override
  String get trackingSquatStepBack =>
      'Mundur sedikit agar bahu, pinggul, lutut, dan kakimu terlihat';

  @override
  String get trackingSquatFaceCamera =>
      'Hadap kamera dengan kedua kaki di lantai';

  @override
  String get trackingSquatControls => 'Squat untuk turun · berdiri untuk naik';

  @override
  String get trackingStartingDistance =>
      'Hadap kamera di jarak awalmu · kalibrasi ulang kalau kamu pindah';

  @override
  String get trackingFeetPlanted => 'Kedua kaki tetap di titik awalmu';

  @override
  String get trackingSquatStandTall =>
      'Berdiri tegak dan diam dengan kedua kaki terlihat';

  @override
  String get trackingStandStill => 'Berdiri tegak dan diam sebentar';

  @override
  String get trackingSquatDepth =>
      'Squat sedalam yang nyaman dan tahan sebentar';

  @override
  String get trackingSquatHold => 'Squat dengan nyaman, lalu tahan sebentar';

  @override
  String get trackingSquatHoldBriefly => 'Tahan squat yang nyaman ini sebentar';

  @override
  String get trackingSquatStandUp =>
      'Berdiri lagi untuk menyelesaikan kalibrasi';

  @override
  String get trackingSquatReady =>
      'Siap! Squat untuk turun · berdiri untuk naik';

  @override
  String get trackingJumpStepBack =>
      'Mundur sedikit agar bahu, pinggul, dan kedua kakimu terlihat';

  @override
  String get trackingJumpFaceCamera =>
      'Berdiri menghadap kamera dengan ruang di atasmu untuk melompat';

  @override
  String get trackingJumpSmall =>
      'Lompatan kecil sudah cukup · mendarat dulu sebelum lompat lagi';

  @override
  String get trackingJumpStandStill =>
      'Berdiri diam dengan seluruh tubuh dan kedua kaki terlihat';

  @override
  String get trackingJumpReady =>
      'Siap! Satu lompatan kecil memberi satu dorongan besar.';

  @override
  String get trackingFindPosition => 'Cari posisimu';

  @override
  String get trackingInterrupted => 'Pelacakan terputus';

  @override
  String get trackingCameraInterrupted =>
      'Kamera terputus. Periksa izin kamera dan coba lagi.';

  @override
  String get trackingCameraAway => 'Kamera berhenti saat aplikasi ditinggalkan';

  @override
  String get trackingJumpBoost => 'Lompat untuk dorongan besar';

  @override
  String get trackingJumpLand => 'Mendarat untuk siap lompat lagi';

  @override
  String trackingLowerMore(int step, int total) {
    return 'Turun sedikit lagi · $step dari $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'Turun dengan nyaman · $step dari $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'Dorong naik lagi · $step dari $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'Samakan dengan jangkauan nyaman pertamamu · $step dari $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Perubahan ini gagal disimpan. Coba lagi, ya. ($error)';
  }

  @override
  String get commonDelete => 'Hapus';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagi',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'Sarangmu butuh waktu sebentar.';

  @override
  String get homeSettings => 'Pengaturan';

  @override
  String homeGreetingFirst(String bird) {
    return 'Hai, aku $bird! Siap terbang?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Petualangan selesai! $bird bangga padamu.',
      'female': 'Petualangan selesai! $bird bangga padamu.',
      'other': 'Petualangan selesai! $bird bangga padamu.',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird sudah siap. Kamu?',
      'female': '$bird sudah siap. Kamu?',
      'other': '$bird sudah siap. Kamu?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'TANPA BATAS';

  @override
  String get homeEndlessDetail => 'Terbang sejauh mungkin';

  @override
  String get homeEndlessSemantics => 'Tanpa Batas. Terbang sejauh mungkin.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: 'Tanpa Batas. Terbang sejauh mungkin. Terbaik: $best bintang.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'Terbaik';

  @override
  String get homeBestNone => 'Cetak rekor pertamamu';

  @override
  String get homeCampaignTitle => 'KAMPANYE';

  @override
  String get homeCampaignDone => 'Setiap surat terantar';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Kampanye. Berikutnya: $level. $stars dari $total bintang.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Kampanye. Setiap surat terantar. $stars dari $total bintang.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'GIM MINI';

  @override
  String get homeMiniGamesDetail => 'Olahraga · 2 pemain';

  @override
  String get homeMiniGamesSemantics =>
      'Gim mini. Push-up, squat, lompat, atau dua pemain.';

  @override
  String get homeBuilderTitle => 'PEMBUAT LEVEL';

  @override
  String get homeBuilderDetail => 'Buat · terbang · bagikan';

  @override
  String get homeBuilderSemantics =>
      'Pembuat Level. Buat levelmu sendiri, terbangkan, dan bagikan.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kali terbang lagi',
      one: '1 kali terbang lagi',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Pembuat Level. Terkunci. Terbuka setelah $count kali terbang lagi.',
      one: 'Pembuat Level. Terkunci. Terbuka setelah 1 kali terbang lagi.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'Petualangan';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Petualangan hari ini. $done dari 3 misi selesai.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'Burung';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'Burung. Terbang bersama $bird.';
  }

  @override
  String get homeDockUpgrades => 'Peningkatan';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Peningkatan. $stars bintang untuk dibelanjakan.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'Paspor';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Paspor. $earned dari $total medali.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'Rekor';

  @override
  String get homeMiniGamesPickerTitle => 'Gim mini';

  @override
  String get homeMiniGamesPickerIntro =>
      'Bergerak untuk terbang, atau main berdua di satu ponsel.';

  @override
  String get homeMiniGamesCloseSemantics => 'Tutup gim mini';

  @override
  String get homeMiniGamesPushUpCard =>
      'Turun untuk menukik.\nDorong untuk naik.';

  @override
  String get homeMiniGamesSquatCard =>
      'Squat untuk turun.\nBerdiri untuk naik.';

  @override
  String get homeMiniGamesJumpCard =>
      'Lompat untuk naik.\nMelayang ke bintang.';

  @override
  String get homeMiniGamesCoopCard =>
      'Dua pemain, satu ponsel.\nSatu tim atau duel.';

  @override
  String get homeMiniGamesCamera => 'Kamera';

  @override
  String get homeMiniGamesPlayers => '2 pemain';

  @override
  String get homeMiniGamesCoop => 'Terbang Bersama';

  @override
  String get birdsTitle => 'Kenalan dengan kru terbangmu.';

  @override
  String birdsFlownTag(int flown, int total) {
    return '$flown/$total SUDAH TERBANG';
  }

  @override
  String get birdsStatusCopilot => 'KOPILOTMU';

  @override
  String get birdsStatusReady => 'SIAP TERBANG';

  @override
  String get birdsStatusLocked => 'TERKUNCI';

  @override
  String get birdsNotFlown => 'Belum diterbangkan';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penerbangan',
      one: '1 penerbangan',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return 'Terbang dengan $bird';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return 'Terbang dengan $bird, bukan $current';
  }

  @override
  String birdsUnlock(String bird) {
    return 'Buka $bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Buka $bird seharga $price bintang',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Buka $bird seharga $price bintang, bintangmu belum cukup',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'Terbang bersamamu';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, terbang bersamamu';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, terbang bersamamu, baru';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, terkunci, $price bintang',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird, baru';
  }

  @override
  String get birdsTagFlying => 'TERBANG';

  @override
  String get birdsTagNew => 'BARU';

  @override
  String get bird_0_description => 'Burung kecil. Langit luas.';

  @override
  String get bird_0_trail => 'Gelembung mentari';

  @override
  String get bird_1_description =>
      'Pipi merona, jambul ikal, hati penuh cinta.';

  @override
  String get bird_1_trail => 'Hati persik';

  @override
  String get bird_2_description =>
      'Kolibri mungil. Mint segar. Kecepatan penuh.';

  @override
  String get bird_2_trail => 'Daun mint';

  @override
  String get bird_3_description =>
      'Burung hantu pemimpi, terbang diterangi bintang.';

  @override
  String get bird_3_trail => 'Kilau debu bintang';

  @override
  String get upgradesWalletLabel => 'BINTANG\nKAMU';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars bintang untuk dibelanjakan',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'Perkuat burungmu.';

  @override
  String get upgradesIntro =>
      'Ketuk roda gigi untuk melihat fungsinya. Tiap bintang yang kamu ambil bisa dibelanjakan.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, level $level dari $max. Level berikutnya $cost bintang',
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
          '$power, level $level dari $max. Level berikutnya $cost bintang, bintang belum cukup',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, level $level dari $max. Maksimal';
  }

  @override
  String get upgradesMax => 'MAKS';

  @override
  String upgradesLevel(int level) {
    return 'Level $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'Level $level, tertinggi';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now, level berikutnya $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value%';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value dtk';
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
      other: 'Bintangmu akan tersisa $count.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'Tingkatkan';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Tingkatkan seharga $cost bintang',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Tingkatkan seharga $cost bintang, bintang belum cukup',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'Sudah maksimal';

  @override
  String get power_shot_name => 'Daya tembak';

  @override
  String get power_shot_blurb =>
      'Tahan Tembak untuk mengisi batu yang lebih besar dan keras.';

  @override
  String get power_sprint_name => 'Melesat';

  @override
  String get power_sprint_blurb =>
      'Ledakan kecepatan yang menghancurkan musuh di jalanmu.';

  @override
  String get power_shield_name => 'Perisai';

  @override
  String get power_shield_blurb =>
      'Menahan satu serangan. Kumpulkan bintang untuk mengisinya lagi.';

  @override
  String get power_magnet_name => 'Magnet';

  @override
  String get power_magnet_blurb =>
      'Dapatkan lewat gerbang sempurna. Ia menarik bintang ke arahmu.';

  @override
  String get power_stat_maxCharge => 'Isi maksimal';

  @override
  String get power_stat_burstLength => 'Lama lesatan';

  @override
  String get power_stat_cooldown => 'Jeda isi ulang';

  @override
  String get power_stat_starsToRefill => 'Bintang untuk mengisi';

  @override
  String get power_stat_safeTime => 'Waktu aman setelah pecah';

  @override
  String get power_stat_perfectGates => 'Gerbang sempurna dibutuhkan';

  @override
  String get power_stat_lasts => 'Durasi';

  @override
  String get power_stat_reach => 'Jangkauan';

  @override
  String get passportTitle => 'Paspor langitmu.';

  @override
  String get passportDailyCard => 'Kartu harian';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total MEDALI';
  }

  @override
  String get passportIntro =>
      'Petualangan kecil. Kenangan abadi. Perunggu, perak, dan emas untuk setiap cap.';

  @override
  String get passportNoMedal => 'Belum ada medali';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Medali perunggu',
      'silver': 'Medali perak',
      'other': 'Medali emas',
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
    return '$stamp. $held. Berikutnya, $next: $goal $current dari $target.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. Medali emas. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'KE PERUNGGU',
      'silver': 'KE PERAK',
      'other': 'KE EMAS',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'DICAP';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: belum ada';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'Perunggu';

  @override
  String get passportMedal_silver => 'Perak';

  @override
  String get passportMedal_gold => 'Emas';

  @override
  String get stamp_frequentFlyer_name => 'Penerbang setia';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selesaikan $n penerbangan berskor.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'Tepat sasaran';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lakukan $n lintasan sempurna lewat titik bidik.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'Pemburu bintang';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kumpulkan $n bintang.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => 'Rasi bintang';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kumpulkan $n bintang dalam satu rantai tanpa putus.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'Kapten langit';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Raih $n poin dalam satu penerbangan Tanpa Batas.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'Perintis';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terbang minimal 60 detik dalam $n penerbangan Tanpa Batas.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'Terbang berkawan';

  @override
  String get stamp_allRounder_name => 'Serba bisa';

  @override
  String get stamp_flockTogether_goalBronze =>
      'Ajak dua burung berbeda di penerbangan berskor.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'Ajak keempat burung di penerbangan berskor.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lakukan $n penerbangan berskor dengan tiap burung.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'Mainkan gim mini push-up, squat, atau lompat.';

  @override
  String get stamp_allRounder_goalSilver =>
      'Mainkan ketiga gim mini: push-up, squat, lompat.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lakukan $n penerbangan berskor di tiap gim mini.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals medali · di $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'Petualangan butuh waktu sebentar.';

  @override
  String get dailyTitle => 'Petualangan kecil hari ini.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · $done/3 MISI';
  }

  @override
  String get dailyIntro =>
      'Tiga misi. Kontrol bebas. Satu penerbangan Tanpa Batas berlaku untuk ketiganya.';

  @override
  String get dailyLaunchEndless => 'Tanpa Batas';

  @override
  String get dailyPostcardKicker => 'KARTU POS KLUB LANGIT';

  @override
  String get dailyStamped => 'KARTU POS DICAP!';

  @override
  String dailyGoalsComplete(int done) {
    return '$done / 3 MISI SELESAI';
  }

  @override
  String get dailyDoneNote => 'Petualangan kecil, semua milikmu.';

  @override
  String get dailyOpenNote => 'Tuntaskan ketiganya agar kartu dicap.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal Selesai';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current dari $target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: Kartu pos dicap';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: $done/3 misi';
  }

  @override
  String get dailyNoStreak => 'Misi baru tiap hari. Absen pun tak apa.';

  @override
  String get dailyTheme_0 => 'Kiriman fajar';

  @override
  String get dailyTheme_1 => 'Piknik persik';

  @override
  String get dailyTheme_2 => 'Surat sinar bulan';

  @override
  String get dailyTheme_3 => 'Parade awan';

  @override
  String get dailyTheme_4 => 'Harta senja';

  @override
  String get dailyTheme_5 => 'Pesta taman';

  @override
  String get task_flights_title => 'Bentangkan sayap';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selesaikan $count penerbangan berskor hari ini.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'Cakrawala terbuka';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lewati $count gerbang di penerbangan berskor hari ini.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'Saku penuh bintang';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kumpulkan $count bintang di penerbangan hari ini.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'Jaga kilaunya';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kumpulkan $count bintang dalam satu rantai tanpa putus.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'Pas di sasaran';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lakukan $count lintasan sempurna hari ini.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'Perjalanan penuh';

  @override
  String get task_finishTrail_goal =>
      'Terbang minimal 60 detik dalam satu penerbangan Tanpa Batas.';

  @override
  String get recordsTitle => 'Kemenangan kecilmu.';

  @override
  String get recordsBestsTitle => 'Poin bintang untuk dikalahkan';

  @override
  String get recordsSectionMain => 'PERMAINAN UTAMA';

  @override
  String get recordsSectionMini => 'GIM MINI';

  @override
  String get recordsEndless => 'Tanpa Batas · mode ketuk';

  @override
  String get recordsCampaignStars => 'Bintang kampanye';

  @override
  String recordsCoopName(String mode) {
    return 'Terbang Bersama · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'terbang berskor',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gerbang',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kali bersama',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'duel',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'push-up',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squat',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'Penerbangan terbaru';

  @override
  String get recordsEmptyTitle => 'Langit luas. Lembaran baru.';

  @override
  String get recordsEmptyBody =>
      'Penerbangan berskor pertamamu memulai ceritanya.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds dtk';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'Klasik · $date · $seconds dtk';
  }

  @override
  String get replaySavedSessions => 'Sesi tersimpan';

  @override
  String get replayBackToRecordsSemantics => 'Kembali ke Rekor';

  @override
  String get replaySessionsLoadFailed => 'Gagal memuat sesi. Coba lagi';

  @override
  String get replayEmptyTitle => 'Penerbanganmu ada di sini';

  @override
  String get replayEmptyBody =>
      'Simpan sesi setelah terbang untuk menontonnya di sini.';

  @override
  String get replayEmptyButton => 'Pilih penerbangan';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds dtk · $score poin bintang',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds dtk · $score gerbang',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'Hapus sesi';

  @override
  String get replayDeleteTitle => 'Hapus sesi ini?';

  @override
  String get replayDeleteBody =>
      'Video kamera dan tayangan ulangnya akan dihapus. Skormu tetap ada di Rekor.';

  @override
  String get replayDeleteFailed => 'Gagal menghapus sesi. Coba lagi.';

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
    return '$mode · Tanpa Batas';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · Latihan';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · Tanpa Batas · Latihan';
  }

  @override
  String get replayOpenFailed => 'Sesi ini tak bisa dibuka.';

  @override
  String get replayBackToSessions => 'Kembali ke sesi';

  @override
  String get replayCameraPaused => 'Kamera dijeda selama bagian sesi ini';

  @override
  String get replayCameraUnavailable =>
      'Klip kamera tak tersedia · Permainan tetap diputar';

  @override
  String get replayCameraLoading => 'Memuat kamera…';

  @override
  String get replayPaused => 'Tarik napas dulu';

  @override
  String get replayHideControlsSemantics =>
      'Sembunyikan kontrol tayangan ulang';

  @override
  String get replayShowControlsSemantics => 'Tampilkan kontrol tayangan ulang';

  @override
  String get replayBackToSavedSemantics => 'Kembali ke sesi tersimpan';

  @override
  String get replayTitle => 'PUTAR ULANG';

  @override
  String replayTitleSession(String session) {
    return 'PUTAR ULANG · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'Skor: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts hati',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'P1 $p1 · P2 $p2 hati · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String replayMagnet(int seconds) {
    return 'Magnet: ${seconds}s';
  }

  @override
  String get replayPauseSemantics => 'Jeda tayangan';

  @override
  String get replayPlaySemantics => 'Putar tayangan';

  @override
  String get replayRestartSemantics => 'Ulang dari awal';

  @override
  String get replayBack5Semantics => 'Mundur 5 detik';

  @override
  String get replayForward5Semantics => 'Maju 5 detik';

  @override
  String get replayHighlightsFinding => 'Mencari sorotan penerbangan';

  @override
  String get replayHighlightsNone => 'Tak ada sorotan penerbangan';

  @override
  String get replayHighlights => 'Sorotan penerbangan';

  @override
  String get replayHighlightsCloseSemantics => 'Tutup sorotan';

  @override
  String get replayHighlightsHint =>
      'Pilih satu momen. Tonton dari sesaat sebelum terjadi.';

  @override
  String get replayViewCorner => 'Kamera di pojok';

  @override
  String get replayViewBackground => 'Kamera di latar';

  @override
  String get replayViewGameplay => 'Permainan saja';

  @override
  String get replayMoveCornerSemantics => 'Pindahkan pojok kamera';

  @override
  String get replayMuteRecordedSemantics => 'Bisukan audio rekaman';

  @override
  String get replayUnmuteRecordedSemantics => 'Nyalakan audio rekaman';

  @override
  String get replayMuteGameSemantics => 'Bisukan suara gim';

  @override
  String get replayUnmuteGameSemantics => 'Nyalakan suara gim';

  @override
  String get replayFullScreenSemantics => 'Sembunyikan kontrol / layar penuh';

  @override
  String get replayMomentTakeoff => 'Lepas landas';

  @override
  String get replayMomentTakeoffDetail => 'Langit milikmu.';

  @override
  String get replayMomentMagnet => 'Magnet bintang';

  @override
  String get replayMomentMagnetDetail =>
      'Tiga lintasan sempurna mendekatkan bintang-bintang.';

  @override
  String get replayMomentStarTrio => 'Trio bintang pertama';

  @override
  String get replayMomentStarTrioDetail =>
      'Tiga bintang menjadi rasi. +5 poin!';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'Semua bintang dalam grup terkumpul. +5 poin!';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier× kekuatan bintang';
  }

  @override
  String get replayMomentStreakDetail => 'Rantai bintang yang berkilauan.';

  @override
  String get replayMomentShield => 'Perisai menyelamatkan';

  @override
  String get replayMomentShieldDetail =>
      'Nyaris saja, dan dapat kesempatan lagi.';

  @override
  String get replayMomentPerfect => 'Lintasan sempurna pertama';

  @override
  String get replayMomentPerfectDetail => 'Tepat menembus titik bidik.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gerbang dilewati',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'Sedikit lebih jauh ke langit.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Tanpa lecet. +$points poin!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Cincin lesat membawamu selamat. +$points poin!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'Melewati angin ribut';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Menghindari puing yang beterbangan. +$points poin!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'Rute selesai';

  @override
  String get replayMomentFinal => 'Momen terakhir';

  @override
  String get replayMomentCompleteDetail => 'Kamu sampai di ujung rute.';

  @override
  String get replayMomentCollisionDetail => 'Tonton detik-detik terakhirnya.';

  @override
  String get replayMomentEndDetail => 'Akhir penerbangan ini.';

  @override
  String get welcomeTitle => 'Pilih bahasamu';

  @override
  String get welcomeContinue => 'Ayo terbang!';

  @override
  String get welcomeHint => 'Kamu bisa menggantinya kapan saja di Pengaturan.';

  @override
  String get welcomeDevice => 'Bahasa ponselmu';

  @override
  String get tutorialTitle => 'Sekolah Terbang';

  @override
  String get tutorialSkip => 'Lewati pelajaran';

  @override
  String get tutorialSkipTitle => 'Lewati Sekolah Terbang?';

  @override
  String get tutorialSkipBody =>
      'Kamu bisa mengulang pelajaran ini kapan saja dari Pengaturan.';

  @override
  String get tutorialSkipConfirm => 'Lewati';

  @override
  String get tutorialSkipCancel => 'Terus belajar';

  @override
  String get tutorialRestart => 'Ulang dari awal';

  @override
  String get tutorialGoalFlaps => 'Kepak';

  @override
  String get tutorialGoalStars => 'Kumpulkan bintang';

  @override
  String get tutorialGoalGates => 'Lintasi gerbang';

  @override
  String get tutorialGoalBats => 'Jatuhkan kelelawar';

  @override
  String get tutorialGoalDoor => 'Pecahkan pintu batu';

  @override
  String get tutorialGoalSprint => 'Melesat';

  @override
  String get tutorialGoalBoss => 'Kalahkan Kapten';

  @override
  String get tutorialPromptTap => 'Ketuk!';

  @override
  String get tutorialPromptShoot => 'Ketuk Tembak';

  @override
  String get tutorialPromptHoldShoot => 'Tahan Tembak';

  @override
  String get tutorialPromptSprint => 'Ketuk Melesat';

  @override
  String get tutorialPraiseNice => 'Bagus!';

  @override
  String get tutorialPraiseGreat => 'Hebat!';

  @override
  String get tutorialPraiseSuper => 'Luar biasa!';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return 'Pelajaran menunggu: $prompt';
  }

  @override
  String get licenceTitle => 'Surat Izin Kurir';

  @override
  String get licenceIssuer => 'Pos Klub Langit';

  @override
  String get licenceHolder => 'Kurir';

  @override
  String get licenceRank => 'Pangkat';

  @override
  String get licenceRankRookie => 'Kurir pemula';

  @override
  String get licenceSkills => 'Keahlian';

  @override
  String get licenceStamp => 'Disahkan';

  @override
  String licenceSignedBy(String name) {
    return 'Tertanda: $name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang',
      one: '1 bintang',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => 'Mulai rute pertamaku';

  @override
  String get licenceAgain => 'Terbang lagi';

  @override
  String get settingsTutorial => 'Sekolah Terbang';

  @override
  String get settingsTutorialDetail => 'Ulangi pelajaran pertama';
}
