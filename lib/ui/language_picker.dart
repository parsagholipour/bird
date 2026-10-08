import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../l10n/l10n.dart';
import '../l10n/language_providers.dart';
import '../l10n/voice_pack_seam.dart';
import 'components.dart';
import 'fit_text.dart';
import 'mini_chrome.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// The globe key in the Settings header: the current language in its own
/// name. A globe reads in every language, so a player who landed in one
/// they cannot read still finds the way back.
class LanguageKey extends ConsumerWidget {
  const LanguageKey({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.languageKeySemantics(language.nativeName),
      excludeSemantics: true,
      child: _Key(
        key: const ValueKey('language-key'),
        color: SkyColors.cream,
        onTap: () {
          UiSounds.effect(context);
          showLanguagePicker(context);
        },
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 22, color: SkyColors.ink),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  language.nativeName,
                  maxLines: 1,
                  style: _nativeStyle(language, 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the language picker over [context]'s screen.
Future<void> showLanguagePicker(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const LanguagePicker());

/// "System default" and every language, each in its own name with its name
/// in the current language under it, and a slot for its voice pack's badge
/// ([voicePackViewProvider]). Choosing one saves it and closes the picker.
class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  /// How many languages share a row.
  static const columns = 4;

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    AppLanguage? language,
  ) async {
    UiSounds.effect(context, 'ui_toggle');
    final navigator = Navigator.of(context);
    try {
      await ref.read(progressProvider.notifier).setLanguage(language);
      ref
          .read(voicePackActionsProvider)
          .languageChosen(language, ref.read(appLanguageProvider));
      if (navigator.mounted) navigator.pop();
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final choice = ref.watch(languageChoiceProvider);
    final device = AppLanguage.forDevice(ref.watch(deviceLocalesProvider));
    final languages = AppLanguage.values;
    return Dialog(
      key: const ValueKey('language-picker'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: SkyColors.ink, width: 2.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const MiniCoin(
                    icon: Icons.language_rounded,
                    color: SkyColors.sky,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l.languageKeyLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: heading(24),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: SkyColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LanguageTile(
                        key: const ValueKey('language-system'),
                        title: l.languageSystemDefault,
                        titleStyle: bodyText(15, weight: FontWeight.w900),
                        detail: l.languageSystemDetail(device.nativeName),
                        icon: Icons.smartphone_rounded,
                        selected: choice == null,
                        onTap: () => _choose(context, ref, null),
                      ),
                      const SizedBox(height: 8),
                      for (var row = 0; row * columns < languages.length; row++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var c = 0; c < columns; c++) ...[
                                if (c > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: row * columns + c < languages.length
                                      ? _languageTile(
                                          context,
                                          ref,
                                          languages[row * columns + c],
                                          selected:
                                              choice ==
                                              languages[row * columns + c],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageTile(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language, {
    required bool selected,
  }) => _LanguageTile(
    key: ValueKey('language-${language.slug}'),
    title: language.nativeName,
    titleStyle: _nativeStyle(language, 15),
    detail: context.l10n.languageName(language),
    selected: selected,
    badge: VoicePackBadge(language),
    onTap: () => _choose(context, ref, language),
  );
}

/// A language's own name in its own fonts, whatever the current language.
TextStyle _nativeStyle(AppLanguage language, double size) => bodyText(
  size,
  weight: FontWeight.w900,
).copyWith(fontFamilyFallback: LanguageFonts.of(language).bodyFallback);

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    super.key,
    required this.title,
    required this.titleStyle,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.icon,
    this.badge,
  });
  final String title, detail;
  final TextStyle titleStyle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? '$title, $detail. ${l.languageCurrent}'
          : '$title, $detail',
      excludeSemantics: true,
      child: _Key(
        color: selected
            ? Color.lerp(SkyColors.cream, SkyColors.yellow, .7)!
            : SkyColors.white,
        lip: selected ? SkyColors.gold : null,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: SkyColors.ink),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A name in another script still reads right: the
                  // bidi algorithm orders an Arabic word right to left.
                  FitText(title, style: titleStyle.copyWith(height: 1.15)),
                  FitText(
                    detail,
                    style: bodyText(
                      11.5,
                      color: SkyColors.muted,
                      weight: FontWeight.w800,
                    ).copyWith(height: 1.15),
                  ),
                ],
              ),
            ),
            ?badge,
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: SkyColors.ink,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A language's voice pack, as a small sticker (nothing when the
/// voice-pack runtime has nothing to say).
class VoicePackBadge extends ConsumerWidget {
  const VoicePackBadge(this.language, {super.key});
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(voicePackViewProvider(language));
    final l = context.l10n;
    final progress = view.progress?.clamp(0.0, 1.0);
    final (IconData icon, String? text) = switch (view.status) {
      VoicePackStatus.none => (Icons.circle, null),
      VoicePackStatus.available => (
        Icons.download_rounded,
        l.voicePackDownload,
      ),
      // Play reports no bytes at first (pending, or a size not known yet):
      // a spinning ring and no percent until it does.
      VoicePackStatus.downloading => (
        Icons.downloading_rounded,
        progress == null
            ? l.voicePackStarting
            : l.voicePackDownloading((progress * 100).round()),
      ),
      VoicePackStatus.installed => (
        Icons.record_voice_over_rounded,
        l.voicePackReady,
      ),
      VoicePackStatus.englishVoices => (
        Icons.record_voice_over_outlined,
        l.voicePackEnglish,
      ),
      VoicePackStatus.failed => (Icons.sync_problem_rounded, l.voicePackFailed),
    };
    if (text == null) return const SizedBox.shrink();
    final tappable =
        view.status == VoicePackStatus.available ||
        view.status == VoicePackStatus.failed;
    return Tooltip(
      message: text,
      child: InkWell(
        onTap: tappable
            ? () => ref.read(voicePackActionsProvider).badgeTapped(language)
            : null,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: view.status == VoicePackStatus.downloading
              // A ring in the icon's place: it fills with the download,
              // or spins while Play has no byte count (progress null).
              ? SizedBox.square(
                  key: ValueKey('voice-pack-ring-${language.slug}'),
                  dimension: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      color: SkyColors.muted,
                      backgroundColor: SkyColors.muted.withValues(alpha: .2),
                    ),
                  ),
                )
              : Icon(icon, size: 18, color: SkyColors.muted),
        ),
      ),
    );
  }
}

/// A sticker key: an ink-outlined face on a lip, as on the Settings screen.
class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.color,
    required this.onTap,
    required this.child,
    this.lip,
    this.padding = EdgeInsets.zero,
  });
  final Color color;
  final Color? lip;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: lip ?? Color.lerp(SkyColors.sand, SkyColors.ink, .2)!,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        position: DecorationPosition.background,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            hoverColor: SkyColors.white.withValues(alpha: .35),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: padding,
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: SkyColors.ink, width: 2),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
