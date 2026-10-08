import 'dart:async';


import '../l10n/app_language.dart';
import '../l10n/voice_pack_seam.dart';
import 'voice_packs.dart';

/// The voice packs behind the language picker's seam
/// (lib/l10n/voice_pack_seam.dart): put these in the root ProviderScope.
final voicePackSeamOverrides = [
  voicePackViewProvider.overrideWith(
    (ref, language) =>
        voicePackView(ref.watch(voicePackInfoProvider(language))),
  ),
  voicePackActionsProvider.overrideWith(
    (ref) => VoicePackRuntimeActions(ref.watch(voicePacksProvider)),
  ),
];

/// What the picker's badge shows for a pack.
VoicePackView voicePackView(VoicePackInfo info) {
  if (info.builtIn) return VoicePackView.nothing;
  return switch (info.state) {
    VoicePackState.unrecorded => const VoicePackView(
      VoicePackStatus.englishVoices,
    ),
    VoicePackState.absent => const VoicePackView(VoicePackStatus.available),
    VoicePackState.downloading => VoicePackView(
      VoicePackStatus.downloading,
      progress: info.progress,
    ),
    // An installed pack with nothing in it speaks English.
    VoicePackState.installed when info.storyClips + info.flightLines == 0 =>
      const VoicePackView(VoicePackStatus.englishVoices),
    VoicePackState.installed => const VoicePackView(VoicePackStatus.installed),
    VoicePackState.failed => const VoicePackView(VoicePackStatus.failed),
  };
}

/// The picker's actions, carried out by the voice packs.
class VoicePackRuntimeActions extends VoicePackActions {
  const VoicePackRuntimeActions(this.packs);
  final VoicePacks packs;

  /// The voices follow the language the game now speaks (the app root's
  /// `follow` does too; asking twice installs once).
  @override
  void languageChosen(AppLanguage? language, AppLanguage resolved) =>
      unawaited(packs.activate(resolved));

  /// Download a pack, or retry a failed one, without switching to it.
  @override
  void badgeTapped(AppLanguage language) => unawaited(packs.ensure(language));
}
