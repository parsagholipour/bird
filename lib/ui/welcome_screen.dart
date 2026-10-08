import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../l10n/l10n.dart';
import '../l10n/language_providers.dart';
import '../l10n/voice_pack_seam.dart';
import 'components.dart';
import 'home_parts.dart';
import 'home_world.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// The very first screen of a new player (`/welcome`): Home's sky with the
/// bird flying in it, the game's title, and every language in its own
/// name. The phone's language is chosen to begin with and marked as the
/// phone's; a tap on another switches the whole screen to it at once, so
/// the player sees the game speak it before going on. The title asks in
/// each language in turn, so anyone can find theirs. "Let's fly!" goes on
/// to flight school.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// The language the title asks in now, while it cycles.
  int _asking = 0;
  Timer? _cycle;
  bool _going = false;

  @override
  void initState() {
    super.initState();
    _cycle = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (mounted) {
        setState(() => _asking = (_asking + 1) % AppLanguage.values.length);
      }
    });
  }

  @override
  void dispose() {
    _cycle?.cancel();
    super.dispose();
  }

  Future<void> _choose(AppLanguage language) async {
    UiSounds.effect(context, 'ui_toggle');
    try {
      await ref.read(progressProvider.notifier).setLanguage(language);
      ref
          .read(voicePackActionsProvider)
          .languageChosen(language, ref.read(appLanguageProvider));
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _go() async {
    if (_going) return;
    _going = true;
    // The language shown is the one kept: the phone's, unless another was
    // tapped (which saved itself).
    if (ref.read(languageChoiceProvider) == null) {
      await _choose(ref.read(appLanguageProvider));
    }
    if (mounted) context.go('/tutorial');
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider).asData?.value;
    final current = ref.watch(appLanguageProvider);
    final device = AppLanguage.forDevice(ref.watch(deviceLocalesProvider));
    final still =
        (progress?.settings.reducedMotion ?? false) ||
        MediaQuery.disableAnimationsOf(context);
    final asking = AppLanguage.values[_asking];
    final l = context.l10n;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff7dcddd), Color(0xffb9e5de), Color(0xffedf3d9)],
          ),
        ),
        child: HomeStage(
          reducedMotion: still,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: SceneLayout(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: HomeWorld(bird: progress?.settings.bird ?? 2),
                  ),
                  const Positioned.fill(child: HomeTitleSparkles()),
                  const Positioned(
                    left: 40,
                    top: 0,
                    width: 400,
                    child: HomeTitle(),
                  ),
                  Positioned(
                    right: 22,
                    top: 18,
                    bottom: 18,
                    width: 540,
                    child: _Card(
                      title: _AskingTitle(language: asking, still: still),
                      grid: _grid(current, device),
                      hint: l.welcomeHint,
                      go: SkyButton(
                        key: const ValueKey('welcome-go'),
                        label: l.welcomeContinue,
                        icon: Icons.flight_takeoff_rounded,
                        color: SkyColors.coral,
                        autofocus: true,
                        onPressed: _go,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid(AppLanguage current, AppLanguage device) {
    const columns = 3;
    final languages = AppLanguage.values;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row * columns < languages.length; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: 9),
                  Expanded(
                    child: row * columns + c < languages.length
                        ? _Tile(
                            language: languages[row * columns + c],
                            selected: languages[row * columns + c] == current,
                            device: languages[row * columns + c] == device,
                            onTap: () => _choose(languages[row * columns + c]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// "Choose your language", asked in [language] in that language's own
/// words and fonts, crossfading as the languages take turns.
class _AskingTitle extends StatelessWidget {
  const _AskingTitle({required this.language, required this.still});
  final AppLanguage language;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final words = lookupAppLocalizations(language.locale).welcomeTitle;
    return SizedBox(
      height: 40,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: still ? 0 : 450),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .35),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Semantics(
          key: ValueKey(language),
          header: true,
          child: Directionality(
            textDirection: language.textDirection,
            child: Row(
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 28,
                  color: SkyColors.ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      words,
                      key: const ValueKey('welcome-title'),
                      maxLines: 1,
                      style: heading(28, weight: FontWeight.w700).copyWith(
                        fontFamilyFallback: LanguageFonts.of(
                          language,
                        ).bodyFallback,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The welcome card: the asking title, the languages, a hint and the key
/// that goes on.
class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.grid,
    required this.hint,
    required this.go,
  });
  final Widget title, grid, go;
  final String hint;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: SkyColors.cream.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: SkyColors.ink, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: Color.lerp(SkyColors.sand, SkyColors.ink, .2)!,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 10),
          Expanded(child: SingleChildScrollView(child: grid)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bodyText(12.5, color: SkyColors.muted),
                ),
              ),
              const SizedBox(width: 10),
              go,
            ],
          ),
        ],
      ),
    ),
  );
}

/// One language: its own name in its own fonts, its name in the current
/// language under it, ticked when chosen and badged when it is the phone's.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.language,
    required this.selected,
    required this.device,
    required this.onTap,
  });
  final AppLanguage language;
  final bool selected, device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final radius = BorderRadius.circular(14);
    final detail = device ? l.welcomeDevice : l.languageName(language);
    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? '${language.nativeName}, $detail. ${l.languageCurrent}'
          : '${language.nativeName}, $detail',
      excludeSemantics: true,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: const Duration(milliseconds: 160),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? Color.lerp(SkyColors.cream, SkyColors.yellow, .75)
                : SkyColors.white,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: selected
                    ? SkyColors.gold
                    : Color.lerp(SkyColors.sand, SkyColors.ink, .2)!,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: ValueKey('welcome-${language.slug}'),
              onTap: onTap,
              borderRadius: radius,
              child: Container(
                constraints: const BoxConstraints(minHeight: 62),
                padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
                foregroundDecoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: SkyColors.ink,
                    width: selected ? 2.5 : 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              language.nativeName,
                              maxLines: 1,
                              style: bodyText(17, weight: FontWeight.w900)
                                  .copyWith(
                                    height: 1.15,
                                    fontFamilyFallback: LanguageFonts.of(
                                      language,
                                    ).bodyFallback,
                                  ),
                            ),
                          ),
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyText(
                              11.5,
                              color: device ? SkyColors.teal : SkyColors.muted,
                              weight: FontWeight.w800,
                            ).copyWith(height: 1.15),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: SkyColors.ink,
                      )
                    else if (device)
                      Transform.rotate(
                        angle: math.pi / 16,
                        child: const Icon(
                          Icons.smartphone_rounded,
                          size: 18,
                          color: SkyColors.teal,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
