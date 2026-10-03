import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app_brand.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import 'components.dart';
import 'theme.dart';
import 'ui_sounds.dart';

const _version = '1.0.0';

// coralDeep and teal are too light for small text on cream panels.
const _dangerInk = Color(0xffa9392c), _tealInk = Color(0xff1f6a5b);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  Future<void> change(
    BuildContext context,
    WidgetRef ref,
    SettingKey key,
    bool value,
  ) async {
    UiSounds.effect(context, 'ui_toggle');
    try {
      await ref.read(progressProvider.notifier).setting(key, value);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  Future<void> reset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ResetDialog(),
    );
    if (confirmed != true) return;
    try {
      await ref.read(progressProvider.notifier).reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: SkyColors.ink,
            width: math.min(380, MediaQuery.sizeOf(context).width - 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SkyLayout.button),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: SkyColors.yellow),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A fresh start. ${birdNames[firstBird]} is ready for you.',
                    style: bodyText(
                      15,
                      color: SkyColors.cream,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final s = progress.asData?.value.settings;
    final bird = s?.bird ?? 0;
    final failed = s == null && progress.hasError;
    Widget toggle(
      SettingKey key,
      IconData icon,
      String title,
      String subtitle,
      Color accent,
      bool? value,
    ) => Expanded(
      child: _SettingRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        accent: accent,
        value: value,
        onChanged: value == null ? null : (v) => change(context, ref, key, v),
      ),
    );
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                Row(
                  children: [
                    RoundButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Back home',
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 18),
                    Semantics(
                      header: true,
                      child: Text('Make yourself at home.', style: heading(36)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The toggles take a little more of the width so every
                      // subtitle stays on one line, and the privacy note
                      // still reads in two.
                      Expanded(
                        flex: 6,
                        child: Panel(
                          padding: const EdgeInsets.all(12),
                          child: failed
                              ? _PanelBody(
                                  children: [
                                    Expanded(
                                      child: _SettingsUnavailable(
                                        bird: bird,
                                        onRetry: () =>
                                            ref.invalidate(progressProvider),
                                      ),
                                    ),
                                  ],
                                )
                              : _PanelBody(
                                  children: [
                                    const _SectionLabel('Sound'),
                                    toggle(
                                      SettingKey.music,
                                      Icons.music_note_rounded,
                                      'Sky Club soundtrack',
                                      'Menu, adventure and boss themes.',
                                      SkyColors.lavender,
                                      s?.music,
                                    ),
                                    const SizedBox(height: 8),
                                    toggle(
                                      SettingKey.effects,
                                      Icons.volume_up_rounded,
                                      'Sound effects',
                                      'Flight, combat, pickups and menu feedback.',
                                      SkyColors.yellow,
                                      s?.effects,
                                    ),
                                    const SizedBox(height: 8),
                                    toggle(
                                      SettingKey.voices,
                                      Icons.record_voice_over_rounded,
                                      'Character voices',
                                      'Story scenes, thank-you notes and sprint calls.',
                                      SkyColors.mint,
                                      s?.voices,
                                    ),
                                    const SizedBox(height: 12),
                                    const _SectionLabel('Comfort'),
                                    toggle(
                                      SettingKey.reducedMotion,
                                      Icons.motion_photos_off_rounded,
                                      'Reduced motion',
                                      'Quieter menus and fewer decorative effects.',
                                      SkyColors.skyDeep,
                                      s?.reducedMotion,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        flex: 5,
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            Panel(
                              padding: const EdgeInsets.all(12),
                              child: _PanelBody(
                                children: [
                                  const _PrivacyCard(),
                                  const SizedBox(height: 12),
                                  _ActionRow(
                                    icon: Icons.camera_alt_rounded,
                                    label: 'Camera & tracking lab',
                                    onTap: () => context.go('/lab'),
                                  ),
                                  const SizedBox(height: 8),
                                  _ActionRow(
                                    icon: Icons.info_outline_rounded,
                                    label: 'About & licenses',
                                    detail: 'v$_version',
                                    semanticLabel:
                                        'About & licenses, version $_version',
                                    onTap: () => showLicensePage(
                                      context: context,
                                      applicationName: AppBrand.name,
                                      applicationVersion: _version,
                                      applicationIcon: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Image.asset(
                                            AppBrand.logo,
                                            width: 80,
                                            height: 80,
                                            excludeFromSemantics: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Spacer(),
                                  _ActionRow(
                                    icon: Icons.restart_alt_rounded,
                                    label: 'Reset local progress',
                                    danger: true,
                                    onTap: () => reset(context, ref),
                                  ),
                                ],
                              ),
                            ),
                            // The equipped bird perches on the panel, watching
                            // over the privacy note.
                            Positioned(
                              right: 34,
                              top: -68,
                              child: Transform.flip(
                                flipX: true,
                                child: BirdArt(
                                  bird: bird,
                                  size: 84,
                                  bob: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

/// Fills its panel at the design size and scrolls, rather than overflowing,
/// when large system text needs more room.
class _PanelBody extends StatelessWidget {
  const _PanelBody({required this.children});
  final List<Widget> children;

  // Keeps the keyboard focus ring of an edge row inside the scroll viewport.
  static const inset = 4.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      padding: const EdgeInsets.all(inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight - inset * 2),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 0, 6),
    child: Semantics(
      header: true,
      label: label,
      excludeSemantics: true,
      child: Text(
        label.toUpperCase(),
        style: bodyText(
          12,
          color: SkyColors.muted,
          weight: FontWeight.w900,
          // Capitals need no room for descenders, and the four rows below
          // need every point of height.
        ).copyWith(letterSpacing: 1.2, height: 1),
      ),
    ),
  );
}

/// A chunky key: lifts off the panel, sinks when pressed and shows a clear
/// ring for keyboard focus. Callers supply the fill and the content.
class _Keycap extends StatefulWidget {
  const _Keycap({
    required this.onTap,
    required this.color,
    required this.border,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 12, 8),
    this.minHeight = 0,
    this.excludeSemantics = false,
  });
  final VoidCallback? onTap;
  final Color color, border;
  final Widget child;
  final EdgeInsets padding;
  final double minHeight;
  final bool excludeSemantics;

  @override
  State<_Keycap> createState() => _KeycapState();
}

class _KeycapState extends State<_Keycap> {
  final states = WidgetStatesController();
  bool pressed = false, focused = false;

  @override
  void initState() {
    super.initState();
    states.addListener(sync);
  }

  @override
  void dispose() {
    states.dispose();
    super.dispose();
  }

  // InkWell also reports its disabled state while it builds, so a change that
  // lands mid-frame waits for the frame to finish.
  void sync() {
    final isPressed = states.value.contains(WidgetState.pressed);
    final isFocused = states.value.contains(WidgetState.focused);
    if (!mounted || (isPressed == pressed && isFocused == focused)) return;
    void apply() {
      if (!mounted) return;
      setState(() {
        pressed = isPressed;
        focused = isFocused;
      });
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(18);
    return AnimatedContainer(
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(
        0,
        pressed && !disableAnimations ? 2 : 0,
        0,
      ),
      constraints: BoxConstraints(minHeight: widget.minHeight),
      // The border is painted over the key, not around it, so the whole key
      // is one touch target.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: widget.border, width: 2),
      ),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: radius,
        boxShadow: [
          if (focused) ...const [
            BoxShadow(color: SkyColors.ink, spreadRadius: 4),
            BoxShadow(color: SkyColors.cream, spreadRadius: 2),
          ],
          if (!pressed)
            BoxShadow(
              color: SkyColors.ink.withValues(alpha: .08),
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          statesController: states,
          onTap: widget.onTap,
          excludeFromSemantics: widget.excludeSemantics,
          borderRadius: radius,
          hoverColor: SkyColors.ink.withValues(alpha: .05),
          highlightColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

/// One whole-row switch. [value] is null while settings are still loading.
///
/// Four rows share a panel, so each is one line of title over one line of
/// subtitle, with the ON/OFF word beside the switch rather than under it.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title, subtitle;
  final Color accent;
  final bool? value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final on = value ?? false;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Opacity(
      opacity: value == null ? .6 : 1,
      child: MergeSemantics(
        child: _Keycap(
          onTap: onChanged == null ? null : () => onChanged!(!on),
          excludeSemantics: true,
          color: on
              ? Color.alphaBlend(accent.withValues(alpha: .3), SkyColors.cream)
              : Color.alphaBlend(
                  SkyColors.ink.withValues(alpha: .04),
                  SkyColors.cream,
                ),
          border: on ? accent : SkyColors.ink.withValues(alpha: .12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: duration,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: on ? accent : SkyColors.ink.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: on ? SkyColors.ink : SkyColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: heading(21)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: bodyText(13.5, color: SkyColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // As wide as OFF either way, so a subtitle never rewraps when
              // its switch flips.
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 27),
                child: value == null
                    ? null
                    : ExcludeSemantics(
                        child: Text(
                          on ? 'ON' : 'OFF',
                          textAlign: TextAlign.right,
                          style: bodyText(
                            12,
                            color: on ? _tealInk : SkyColors.muted,
                            weight: FontWeight.w900,
                          ).copyWith(letterSpacing: 1),
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: ExcludeFocus(
                  child: Switch(
                    value: on,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    thumbColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.disabled)
                          ? SkyColors.ink.withValues(alpha: .25)
                          : s.contains(WidgetState.selected)
                          ? Colors.white
                          : SkyColors.muted,
                    ),
                    trackColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? SkyColors.teal
                          : SkyColors.ink.withValues(alpha: .06),
                    ),
                    trackOutlineColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.disabled)
                          ? SkyColors.ink.withValues(alpha: .2)
                          : s.contains(WidgetState.selected)
                          ? _tealInk
                          : SkyColors.ink.withValues(alpha: .55),
                    ),
                    trackOutlineWidth: const WidgetStatePropertyAll(2),
                    thumbIcon: WidgetStateProperty.resolveWith(
                      (s) => Icon(
                        s.contains(WidgetState.selected)
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 16,
                        color: s.contains(WidgetState.selected)
                            ? _tealInk
                            : SkyColors.cream,
                      ),
                    ),
                    overlayColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsUnavailable extends StatelessWidget {
  const _SettingsUnavailable({required this.bird, required this.onRetry});
  final int bird;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BirdArt(bird: bird == 1 ? 0 : 1, size: 92, bob: false),
        const SizedBox(height: 8),
        Text('Your settings need a moment.', style: heading(24)),
        const SizedBox(height: 14),
        SkyButton(label: 'Try again', onPressed: onRetry),
      ],
    ),
  );
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: SkyColors.mint.withValues(alpha: .3),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SkyColors.mint, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SkyColors.mint,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 22,
                color: SkyColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ON-DEVICE. ALWAYS.',
                    style: bodyText(
                      12,
                      color: _tealInk,
                      weight: FontWeight.w900,
                    ).copyWith(letterSpacing: 1),
                  ),
                  Text('Your camera stays yours.', style: heading(22)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Video and optional microphone audio stay on this phone. Unsaved clips are discarded. No uploads.',
          style: bodyText(14, color: SkyColors.muted),
        ),
      ],
    ),
  );
}

/// A full-width list action. [danger] marks the one destructive choice.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.semanticLabel,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final String? detail, semanticLabel;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ink = danger ? _dangerInk : SkyColors.ink;
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticLabel ?? label,
        child: _Keycap(
          minHeight: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: danger
              ? Color.alphaBlend(
                  SkyColors.coral.withValues(alpha: .14),
                  SkyColors.cream,
                )
              : Color.alphaBlend(
                  Colors.white.withValues(alpha: .6),
                  SkyColors.cream,
                ),
          border: danger
              ? SkyColors.coralDeep.withValues(alpha: .7)
              : SkyColors.ink.withValues(alpha: .12),
          onTap: () {
            UiSounds.effect(context);
            onTap();
          },
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: danger
                        ? SkyColors.coral.withValues(alpha: .24)
                        : SkyColors.ink.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: bodyText(15, color: ink, weight: FontWeight.w800),
                  ),
                ),
                if (detail != null) ...[
                  Text(detail!, style: bodyText(12, color: SkyColors.muted)),
                  const SizedBox(width: 2),
                ],
                if (!danger)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: SkyColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetDialog extends StatelessWidget {
  const _ResetDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    semanticLabel: 'Start a fresh adventure?',
    scrollable: true,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
    actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
    title: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: SkyColors.coral.withValues(alpha: .24),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.restart_alt_rounded,
            size: 28,
            color: _dangerInk,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text('Start a fresh adventure?', style: heading(26))),
      ],
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Text(
        'This deletes your saved videos, replays, scores, runs and settings from this phone. It cannot be undone.',
        style: bodyText(16),
      ),
    ),
    actions: [
      OutlinedButton(
        onPressed: () {
          UiSounds.effect(context);
          Navigator.pop(context, true);
        },
        style:
            OutlinedButton.styleFrom(
              foregroundColor: _dangerInk,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: bodyText(16, weight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SkyLayout.button),
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.focused)
                    ? const BorderSide(color: SkyColors.ink, width: 3)
                    : BorderSide(
                        color: SkyColors.coralDeep.withValues(alpha: .7),
                        width: 2,
                      ),
              ),
            ),
        child: const Text('Reset everything'),
      ),
      SkyButton(
        label: 'Keep my progress',
        color: SkyColors.yellow,
        icon: Icons.check_rounded,
        autofocus: true,
        onPressed: () => Navigator.pop(context, false),
      ),
    ],
  );
}
