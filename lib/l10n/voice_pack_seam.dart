import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_language.dart';

/// The seam between the language picker and the voice packs
/// (l10n-ws/BRIEF.md, "Shipping the voices"). The picker only shows what
/// [voicePackViewProvider] says and tells [voicePackActionsProvider] what the
/// player did. The voice-pack runtime fills both from the real packs
/// (`voicePackSeamOverrides`, lib/game/voice_pack_seam_runtime.dart) in the
/// app's root ProviderScope (lib/main.dart). Without those overrides (a
/// test pumping a screen under a bare ProviderScope) the picker shows no
/// badge and choosing a language starts nothing.
enum VoicePackStatus {
  /// Nothing to show: English (voices built in) or no runtime yet.
  none,

  /// The language's pack can be downloaded.
  available,

  /// Downloading; see [VoicePackView.progress].
  downloading,

  /// Installed: the characters speak this language.
  installed,

  /// No pack for this language (yet): English voices, translated captions.
  englishVoices,

  /// The download failed; the badge offers a retry.
  failed,
}

/// What the picker shows about one language's voice pack.
class VoicePackView {
  const VoicePackView(this.status, {this.progress});
  static const nothing = VoicePackView(VoicePackStatus.none);
  final VoicePackStatus status;

  /// 0 to 1 while [VoicePackStatus.downloading]; null while Play has not
  /// reported a byte count yet (the badge spins without a percent).
  final double? progress;
}

/// The voice pack state of each language, for the picker's badges.
final voicePackViewProvider = Provider.family<VoicePackView, AppLanguage>(
  (ref, language) => VoicePackView.nothing,
);

/// What the picker reports to the voice-pack runtime.
class VoicePackActions {
  const VoicePackActions();

  /// The player chose [language] (null: "System default", resolved to
  /// [resolved]). A runtime may start installing its pack.
  void languageChosen(AppLanguage? language, AppLanguage resolved) {}

  /// The player tapped a badge: download, or retry a failed download.
  void badgeTapped(AppLanguage language) {}
}

final voicePackActionsProvider = Provider<VoicePackActions>(
  (ref) => const VoicePackActions(),
);
