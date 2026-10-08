import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart' show AudioCache;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_language.dart';
import 'flight_voice_clips.dart';
import 'flight_voice_director.dart' show VoiceClip;

/// One take of a voice pack: how long it plays and the face it is said
/// with (the mouth every 50 ms, 0 shut to 3 wide, and a StoryMood name).
@immutable
class VoicePackClip {
  const VoicePackClip(this.ms, {this.mouth = '', this.mood = 'plain'});
  final int ms;
  final String mouth, mood;
}

/// A language's own recordings (l10n-ws/VOICE-PLAN.md): its story clips and
/// in-flight lines, under the English clip names, in
/// `assets/voice/<slug>/{story,flight}/<name>.ogg`, listed with their faces
/// in `assets/voice/<slug>/manifest.json`. Any subset of either may be
/// recorded, none at all included. Written by
/// tool/l10n/prepare_localized_voices.py.
class VoicePack {
  VoicePack({
    required this.language,
    required this.story,
    required this.flight,
  });

  /// The newest manifest format this game reads.
  static const format = 1;

  final AppLanguage language;

  /// Clip name to take, for the story clips and the in-flight lines.
  final Map<String, VoicePackClip> story, flight;

  /// The asset folder, as audioplayers' AssetSource names it.
  String get folder => 'voice/${language.slug}';
  String storyAsset(String name) => '$folder/story/$name.ogg';
  String flightAsset(String name) => '$folder/flight/$name.ogg';

  /// The packs' index in the base bundle: each pack's clip counts and size,
  /// so an empty pack is never downloaded (tool/l10n/prepare_localized_voices.py).
  static const indexKey = 'assets/voice/index.json';

  /// The manifest's key in the asset bundle.
  static String manifestKey(AppLanguage language) =>
      'assets/voice/${language.slug}/manifest.json';

  /// The Flutter deferred component (Play feature module) carrying it.
  static String component(AppLanguage language) => 'voice_${language.slug}';

  /// Story clip [name] as a line the flight can say (a sprint call, a name
  /// card), or null when this pack has no take of it.
  VoiceClip? storyClip(String name) {
    final take = story[name];
    return take == null
        ? null
        : VoiceClip(
            name,
            storyAsset(name),
            take.ms,
            mouth: take.mouth,
            mood: take.mood,
          );
  }

  /// Every in-flight line of this pack.
  Iterable<VoiceClip> get flightClips => [
    for (final MapEntry(key: name, value: take) in flight.entries)
      VoiceClip(
        name,
        flightAsset(name),
        take.ms,
        mouth: take.mouth,
        mood: take.mood,
      ),
  ];

  /// Reads a manifest. In-flight lines the English script no longer has are
  /// left out, so a pack never adds a pool the game does not ask for.
  static VoicePack parse(AppLanguage language, String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final version = json['format'] as int? ?? 1;
    if (version > format) {
      throw FormatException(
        'voice pack format $version, this game reads $format',
      );
    }
    final slug = json['slug'] as String?;
    if (slug != null && slug != language.slug) {
      throw FormatException('voice pack for $slug, not ${language.slug}');
    }
    Map<String, VoicePackClip> takes(Object? section, {Set<String>? known}) => {
      for (final MapEntry(:key, :value)
          in ((section as Map?) ?? const {}).cast<String, Map>().entries)
        if (known == null || known.contains(key))
          key: VoicePackClip(
            value['ms'] as int,
            mouth: value['mouth'] as String? ?? '',
            mood: value['mood'] as String? ?? 'plain',
          ),
    };
    return VoicePack(
      language: language,
      story: takes(json['story']),
      flight: takes(json['flight'], known: flightVoiceClips.keys.toSet()),
    );
  }
}

/// Where a language's voice pack stands on this device.
enum VoicePackState {
  /// Not on this device; it can be downloaded.
  absent,

  /// Being downloaded and installed.
  downloading,

  /// On this device: its takes play.
  installed,

  /// The last download failed ([VoicePackInfo.error]); it can be retried.
  failed,

  /// Nothing is recorded in this language yet (the packs' index says so):
  /// English voices under its captions, nothing to download.
  unrecorded,
}

/// A language's voice pack as the Settings picker shows it.
@immutable
class VoicePackInfo {
  const VoicePackInfo(
    this.language,
    this.state, {
    this.phase,
    this.progress,
    this.error,
    this.storyClips = 0,
    this.flightLines = 0,
    this.bytes,
  });

  final AppLanguage language;
  final VoicePackState state;

  /// While downloading, Google Play's step (`requested`, `pending`,
  /// `downloading`, `downloaded`, `installing`), or null before it answers.
  final String? phase;

  /// 0 to 1 while Play downloads, from its byte counts (VoicePackDelivery.kt
  /// reports them); null before and after (an indeterminate bar).
  final double? progress;

  /// Why the last attempt failed.
  final String? error;

  /// What the pack holds: once installed, from its manifest; before, from
  /// the packs' index when the game has one.
  final int storyClips, flightLines;

  /// The pack's size in bytes, from the packs' index (the download's size,
  /// near enough), or null when unknown.
  final int? bytes;

  /// English ships inside the game and needs no pack.
  bool get builtIn => language == AppLanguage.en;

  @override
  bool operator ==(Object other) =>
      other is VoicePackInfo &&
      other.language == language &&
      other.state == state &&
      other.phase == phase &&
      other.progress == progress &&
      other.error == error &&
      other.storyClips == storyClips &&
      other.flightLines == flightLines &&
      other.bytes == bytes;

  @override
  int get hashCode => Object.hash(
    language,
    state,
    phase,
    progress,
    error,
    storyClips,
    flightLines,
    bytes,
  );

  @override
  String toString() =>
      // l10n-ignore: debug text, never shown to players.
      'VoicePackInfo(${language.slug}, ${state.name}'
      '${phase == null ? '' : ', $phase'}${error == null ? '' : ', $error'})';
}

/// Installs and removes voice packs. [DeferredComponentInstaller] in the
/// game; tests use a fake.
abstract interface class VoicePackInstaller {
  /// Completes once [component] is installed and its assets can be read.
  Future<void> install(String component);

  /// The platform's current step for [component], or null if it does not
  /// say.
  Future<String?> phase(String component);

  /// Asks for [component] to be removed (Play does it later).
  Future<void> uninstall(String component);
}

/// Google Play Feature Delivery through Flutter's deferred components. Only
/// Android splits packs off: elsewhere (iOS, desktop, and every debug or
/// `flutter build apk` build) the packs are inside the app, the manifest is
/// found at once, and this is never asked to install.
class DeferredComponentInstaller implements VoicePackInstaller {
  const DeferredComponentInstaller();

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> install(String component) async {
    if (!_android) return;
    await DeferredComponent.installDeferredComponent(componentName: component);
  }

  @override
  Future<String?> phase(String component) async {
    if (!_android) return null;
    try {
      // Not in DeferredComponent's API, but on its channel. Without a
      // DeferredComponentManager the channel never answers: hence the
      // timeout. VoicePackDelivery.kt adds the byte counts.
      return await SystemChannels.deferredComponent
          .invokeMethod<String>(
            'getDeferredComponentInstallState',
            <String, Object>{'loadingUnitId': -1, 'componentName': component},
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> uninstall(String component) async {
    if (!_android) return;
    await DeferredComponent.uninstallDeferredComponent(
      componentName: component,
    ).timeout(const Duration(seconds: 5));
  }
}

class VoicePackException implements Exception {
  const VoicePackException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Where the in-flight lines of the active language come from.
enum FlightVoiceSource {
  /// The English lines ([FlightVoices.recorded]), as the game always had.
  english,

  /// The active language's own lines, and only those.
  pack,

  /// No line at all.
  silent,
}

/// What a language without (enough) in-flight lines of its own says in
/// flight. The owner chooses per language; English is the default.
enum FlightVoicePolicy { english, silent }

typedef VoiceAssetLoader = Future<ByteData> Function(String key);

/// The voice packs (l10n-ws/VOICE-PLAN.md): which recording plays for a story
/// clip or an in-flight line in the active language, and the pack of each
/// language on this device (absent, downloading, installed or failed).
///
/// English needs no pack and is never changed: with English active (the
/// default), or a pack missing a clip, every answer is the English one.
/// Story clips fall back to English clip by clip (the captions stay
/// localized). In-flight lines never mix languages: a language whose pack
/// has lines draws only from them (an empty pool says nothing), and one
/// without lines follows its [FlightVoicePolicy].
///
/// Game code reads [instance]; widgets watch [voicePacksProvider] and
/// [voicePackInfoProvider].
class VoicePacks extends ChangeNotifier {
  VoicePacks({
    this._installer = const DeferredComponentInstaller(),
    VoiceAssetLoader? load,
    this.policies = flightPolicies,
    this.minFlightLines = 1,
    this.startTimeout = const Duration(seconds: 30),
    this.installTimeout = const Duration(minutes: 15),
    this.pollEvery = const Duration(seconds: 1),
  }) : _load = load ?? rootBundle.load;

  /// The game's packs. Tests swap it and put a fresh one back.
  static VoicePacks instance = VoicePacks();

  /// The owner's choice, per language, of what it says in flight while it
  /// has fewer than [minFlightLines] lines of its own (its pack not yet
  /// installed, or recorded without flight lines). A language not listed
  /// says the English lines.
  static const flightPolicies = <AppLanguage, FlightVoicePolicy>{};

  final Map<AppLanguage, FlightVoicePolicy> policies;

  /// Below this many in-flight lines a pack's language follows its policy
  /// instead of drawing from its own lines.
  final int minFlightLines;

  /// A download Play has not started within [startTimeout], or not finished
  /// within [installTimeout], has failed.
  final Duration startTimeout, installTimeout, pollEvery;

  final VoicePackInstaller _installer;
  final VoiceAssetLoader _load;
  final _packs = <AppLanguage, VoicePack>{};
  final _states = <AppLanguage, VoicePackInfo>{};
  final _busy = <AppLanguage, Future<void>>{};

  /// Packs removed this session: Play removes them later, so their assets
  /// may still read, and choosing the language again must reinstall.
  final _removed = <AppLanguage>{};

  AppLanguage _language = AppLanguage.en;
  ValueListenable<AppLanguage>? _source;

  /// The language the voices follow.
  AppLanguage get language => _language;

  /// The active language's installed pack; null for English and while it
  /// is not installed.
  VoicePack? get pack => _language == AppLanguage.en ? null : _packs[_language];

  /// [language]'s pack as the picker shows it.
  VoicePackInfo status(AppLanguage language) {
    if (language == AppLanguage.en) {
      return const VoicePackInfo(AppLanguage.en, VoicePackState.installed);
    }
    final known = _states[language];
    if (known != null) return known;
    final entry = _index?[language];
    if (entry == null) return VoicePackInfo(language, VoicePackState.absent);
    return VoicePackInfo(
      language,
      entry.story + entry.flight == 0
          ? VoicePackState.unrecorded
          : VoicePackState.absent,
      storyClips: entry.story,
      flightLines: entry.flight,
      bytes: entry.bytes,
    );
  }

  /// Each pack's clip counts and size, from the packs' index; null until it
  /// is read, empty when the game has none.
  Map<AppLanguage, ({int story, int flight, int bytes})>? _index;
  Future<void>? _indexRead;

  /// Reads the packs' index (once): with it the picker knows which packs are
  /// empty and how big the others are before any download.
  Future<void> loadIndex() => _indexRead ??= _readIndex();

  Future<void> _readIndex() async {
    final index = <AppLanguage, ({int story, int flight, int bytes})>{};
    try {
      final data = await _load(VoicePack.indexKey);
      final json =
          jsonDecode(
                utf8.decode(
                  data.buffer.asUint8List(
                    data.offsetInBytes,
                    data.lengthInBytes,
                  ),
                ),
              )
              as Map<String, dynamic>;
      final packs = (json['packs'] as Map).cast<String, Map>();
      for (final language in AppLanguage.values) {
        final entry = packs[language.slug];
        if (entry == null) continue;
        index[language] = (
          story: entry['story'] as int? ?? 0,
          flight: entry['flight'] as int? ?? 0,
          bytes: entry['bytes'] as int? ?? 0,
        );
      }
    } catch (_) {
      // No index (a test, an old build): every pack is looked for.
    }
    _index = index;
    notifyListeners();
  }

  /// Keeps the voices on [source]'s language: installs its pack when it
  /// becomes active (a choice in Settings, or a first launch on a device in
  /// that language).
  void follow(ValueListenable<AppLanguage> source) {
    _source?.removeListener(_follow);
    _source = source..addListener(_follow);
    unawaited(loadIndex());
    _follow();
  }

  void _follow() => unawaited(activate(_source!.value));

  /// Makes [language] the voices' language and installs its pack if needed.
  /// Until it is in, the game speaks English (story) and its policy
  /// (flight).
  Future<void> activate(AppLanguage language) {
    if (_language != language) {
      _language = language;
      notifyListeners();
    }
    return ensure(language);
  }

  /// Installs [language]'s pack unless it is already in (or underway).
  Future<void> ensure(AppLanguage language) {
    if (language == AppLanguage.en || _packs.containsKey(language)) {
      return Future.value();
    }
    return _busy[language] ??= _ensure(language).whenComplete(() {
      // A block, not an arrow: returning the removed future would make this
      // one wait for itself.
      _busy.remove(language);
    });
  }

  /// Tries [language]'s pack again after a failure.
  Future<void> retry([AppLanguage? language]) => ensure(language ?? _language);

  /// Removes [language]'s pack (never the active language's): its clips
  /// stop playing now and Play frees the space later.
  Future<void> remove(AppLanguage language) async {
    if (language == AppLanguage.en || language == _language) return;
    if (_busy.containsKey(language)) return;
    _packs.remove(language);
    _removed.add(language);
    _set(VoicePackInfo(language, VoicePackState.absent));
    // audioplayers keeps a copy of every clip it played.
    final prefix = 'voice/${language.slug}/';
    final cache = AudioCache.instance;
    for (final key in [...cache.loadedFiles.keys]) {
      if (!key.startsWith(prefix)) continue;
      try {
        await cache.clear(key);
      } catch (_) {}
    }
    try {
      await _installer.uninstall(VoicePack.component(language));
    } catch (error) {
      debugPrint('VoicePacks: uninstall ${language.slug}: $error');
    }
  }

  Future<void> _ensure(AppLanguage language) async {
    await loadIndex();
    final entry = _index?[language];
    if (entry != null && entry.story + entry.flight == 0) {
      // Nothing recorded: no download, English voices.
      _states.remove(language);
      notifyListeners();
      return;
    }
    final reinstall = _removed.remove(language);
    if (!reinstall) {
      switch (await _probe(language)) {
        case _Probe.loaded || _Probe.broken:
          return;
        case _Probe.missing:
          break;
      }
    }
    _set(
      VoicePackInfo(language, VoicePackState.downloading, bytes: entry?.bytes),
    );
    try {
      await _install(language, VoicePack.component(language));
    } catch (error) {
      _fail(language, '$error');
      return;
    }
    if (await _probe(language) == _Probe.missing) {
      _fail(language, 'installed, but its manifest cannot be read');
    }
  }

  /// Reads [language]'s manifest from the asset bundle: present in the app
  /// (debug, `flutter build apk`, iOS) or installed by Play.
  Future<_Probe> _probe(AppLanguage language) async {
    final ByteData data;
    try {
      data = await _load(VoicePack.manifestKey(language));
    } catch (_) {
      return _Probe.missing;
    }
    try {
      final pack = VoicePack.parse(
        language,
        utf8.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        ),
      );
      _packs[language] = pack;
      _set(
        VoicePackInfo(
          language,
          VoicePackState.installed,
          storyClips: pack.story.length,
          flightLines: pack.flight.length,
          bytes: _index?[language]?.bytes,
        ),
      );
      return _Probe.loaded;
    } catch (error) {
      // Installing again would bring the same file: English it is.
      _fail(language, 'unreadable manifest: $error');
      return _Probe.broken;
    }
  }

  /// Installs [component], following Play's steps. The future of an
  /// install Play never starts (no network, no Play Store) never completes,
  /// so a watchdog fails it.
  Future<void> _install(AppLanguage language, String component) async {
    final watch = Stopwatch()..start();
    var settled = false, started = false;
    Object? failure;
    final install = _installer
        .install(component)
        .then<void>(
          (_) => settled = true,
          onError: (Object error) {
            failure = error;
            settled = true;
          },
        );
    while (!settled) {
      await Future.any([install, Future<void>.delayed(pollEvery)]);
      if (settled) break;
      final (phase, progress) = step(await _installer.phase(component));
      if (settled) break;
      switch (phase) {
        case 'failed' || 'cancelled' || 'canceling':
          throw VoicePackException('Play reported "$phase"');
        // Flutter cannot show Play's confirmation dialog.
        case 'requiresuserconfirmation':
          throw const VoicePackException('Play asks the user to confirm');
      }
      started |= phase != null && phase != 'unknown';
      if (!started && watch.elapsed >= startTimeout) {
        throw const VoicePackException('the download did not start');
      }
      if (watch.elapsed >= installTimeout) {
        throw const VoicePackException('the download took too long');
      }
      final now = VoicePackInfo(
        language,
        VoicePackState.downloading,
        phase: phase == 'unknown' ? null : phase,
        progress: progress,
        bytes: _index?[language]?.bytes,
      );
      if (_states[language] != now) _set(now);
    }
    if (failure != null) throw failure!;
  }

  /// Play's step for a component, as the installer reports it, and the
  /// share downloaded when it says (`downloading:<bytes>/<total>`).
  @visibleForTesting
  static (String?, double?) step(String? raw) {
    if (raw == null) return (null, null);
    final colon = raw.indexOf(':');
    if (colon < 0) return (raw.toLowerCase(), null);
    final counts = raw.substring(colon + 1).split('/');
    final done = counts.length == 2 ? int.tryParse(counts[0]) : null;
    final total = counts.length == 2 ? int.tryParse(counts[1]) : null;
    return (
      raw.substring(0, colon).toLowerCase(),
      done != null && total != null && total > 0
          ? (done / total).clamp(0.0, 1.0)
          : null,
    );
  }

  void _fail(AppLanguage language, String error) {
    debugPrint('VoicePacks: ${language.slug}: $error');
    _set(VoicePackInfo(language, VoicePackState.failed, error: error));
  }

  void _set(VoicePackInfo status) {
    _states[status.language] = status;
    notifyListeners();
  }

  // What plays.

  /// The active language's own take of story clip [name], or null: the
  /// caller then plays the English clip (CampaignVoices).
  String? storyAsset(String name) {
    final pack = this.pack;
    return pack != null && pack.story.containsKey(name)
        ? pack.storyAsset(name)
        : null;
  }

  /// How long a pack's story [asset] plays in milliseconds, or null for an
  /// asset that is not a loaded pack's (an English clip).
  int? storyMs(String asset) {
    if (!asset.startsWith('voice/')) return null;
    for (final pack in _packs.values) {
      final folder = '${pack.folder}/story/';
      if (asset.startsWith(folder) && asset.endsWith('.ogg')) {
        return pack
            .story[asset.substring(folder.length, asset.length - '.ogg'.length)]
            ?.ms;
      }
    }
    return null;
  }

  /// Where the next flight's lines come from.
  FlightVoiceSource get flightSource {
    if (_language == AppLanguage.en) return FlightVoiceSource.english;
    final pack = this.pack;
    if (pack != null && pack.flight.length >= max(1, minFlightLines)) {
      return FlightVoiceSource.pack;
    }
    return switch (policies[_language] ?? FlightVoicePolicy.english) {
      FlightVoicePolicy.english => FlightVoiceSource.english,
      FlightVoicePolicy.silent => FlightVoiceSource.silent,
    };
  }
}

enum _Probe { loaded, missing, broken }

/// The voice packs, for widgets (the Settings language picker).
final voicePacksProvider = Provider<VoicePacks>((ref) => VoicePacks.instance);

/// A language's pack status, rebuilt as it changes.
final voicePackInfoProvider = Provider.family<VoicePackInfo, AppLanguage>((
  ref,
  language,
) {
  final packs = ref.watch(voicePacksProvider);
  void changed() => ref.invalidateSelf();
  packs.addListener(changed);
  ref.onDispose(() => packs.removeListener(changed));
  return packs.status(language);
});
