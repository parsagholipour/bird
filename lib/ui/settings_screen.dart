import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app_brand.dart';
import '../data/play_games.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import 'components.dart';
import 'mini_chrome.dart';
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
    // Whether this phone has ever synced, not whether it is connected now:
    // the next sync would otherwise restore what the reset cleared.
    final cloud = await ref
        .read(progressRepositoryProvider)
        .cloudSynced()
        .catchError((Object _) => false);
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ResetDialog(cloud: cloud),
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
    // Play Games has its strip only where it can work (play_games_ids.dart);
    // then the lab and About keys share one row to make room.
    final playGames = ref.watch(playGamesProvider).available;
    void lab() => context.go('/lab');
    void about() => showLicensePage(
      context: context,
      applicationName: AppBrand.name,
      applicationVersion: _version,
      applicationIcon: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            AppBrand.logo,
            width: 80,
            height: 80,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
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
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
            child: Column(
              children: [
                MiniHeader(
                  title: 'Make yourself at home.',
                  size: 34,
                  onBack: () => context.go('/'),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The toggles take a little more of the width so every
                      // subtitle stays on one line, and the privacy note
                      // still reads in two.
                      Expanded(
                        flex: 6,
                        child: MiniCard(
                          accent: SkyColors.skyDeep,
                          padding: const EdgeInsets.all(8),
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
                                    const _SectionLabel(
                                      'Sound',
                                      icon: Icons.graphic_eq_rounded,
                                    ),
                                    toggle(
                                      SettingKey.music,
                                      Icons.music_note_rounded,
                                      'Sky Club soundtrack',
                                      'Menu, adventure and boss themes.',
                                      SkyColors.lavender,
                                      s?.music,
                                    ),
                                    const SizedBox(height: 6),
                                    toggle(
                                      SettingKey.effects,
                                      Icons.volume_up_rounded,
                                      'Sound effects',
                                      'Flight, combat, pickups and menu feedback.',
                                      SkyColors.yellow,
                                      s?.effects,
                                    ),
                                    const SizedBox(height: 6),
                                    toggle(
                                      SettingKey.voices,
                                      Icons.record_voice_over_rounded,
                                      'Character voices',
                                      'Story scenes, thank-you notes and sprint calls.',
                                      SkyColors.mint,
                                      s?.voices,
                                    ),
                                    const SizedBox(height: 8),
                                    const _SectionLabel(
                                      'Comfort',
                                      icon: Icons.spa_rounded,
                                    ),
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
                            MiniCard(
                              accent: SkyColors.mint,
                              padding: const EdgeInsets.all(10),
                              child: _PanelBody(
                                children: [
                                  const _PrivacyCard(),
                                  if (playGames) ...[
                                    const SizedBox(height: 8),
                                    const _PlayGamesStrip(),
                                    const SizedBox(height: 6),
                                    // Both keys as tall as the taller.
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: _ActionRow(
                                              icon: Icons.camera_alt_rounded,
                                              label: 'Camera & tracking lab',
                                              compact: true,
                                              onTap: lab,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _ActionRow(
                                              icon: Icons.info_outline_rounded,
                                              label: 'About & licenses',
                                              detail: 'v$_version',
                                              semanticLabel:
                                                  'About & licenses, version $_version',
                                              compact: true,
                                              onTap: about,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ] else ...[
                                    const SizedBox(height: 12),
                                    _ActionRow(
                                      icon: Icons.camera_alt_rounded,
                                      label: 'Camera & tracking lab',
                                      onTap: lab,
                                    ),
                                    const SizedBox(height: 8),
                                    _ActionRow(
                                      icon: Icons.info_outline_rounded,
                                      label: 'About & licenses',
                                      detail: 'v$_version',
                                      semanticLabel:
                                          'About & licenses, version $_version',
                                      onTap: about,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
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
                              top: -70,
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
  const _SectionLabel(this.label, {required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
    child: Semantics(
      header: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: 15, color: SkyColors.ink),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: bodyText(
              12,
              weight: FontWeight.w900,
              // Capitals need no room for descenders, and the four rows below
              // need every point of height.
            ).copyWith(letterSpacing: 1.2, height: 1),
          ),
        ],
      ),
    ),
  );
}

/// A chunky sticker key: an ink-outlined face on a lip of [lip], that sinks
/// into it when pressed and shows a clear ring for keyboard focus. Callers
/// supply the fill and the content.
class _Keycap extends StatefulWidget {
  const _Keycap({
    required this.onTap,
    required this.color,
    required this.lip,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 12, 8),
    this.minHeight = 0,
    this.excludeSemantics = false,
  });
  final VoidCallback? onTap;
  final Color color, lip;
  final Widget child;
  final EdgeInsets padding;
  final double minHeight;
  final bool excludeSemantics;

  /// How far the face stands above its lip.
  static const depth = 3.0;

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
    final radius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.only(bottom: _Keycap.depth),
      child: AnimatedContainer(
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          pressed && !disableAnimations ? _Keycap.depth : 0,
          0,
        ),
        constraints: BoxConstraints(minHeight: widget.minHeight),
        // The outline is painted over the key, not around it, so the whole
        // key is one touch target.
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: SkyColors.ink, width: 2),
        ),
        decoration: BoxDecoration(
          color: pressed && disableAnimations
              ? Color.lerp(widget.color, SkyColors.ink, .08)
              : widget.color,
          borderRadius: radius,
          boxShadow: [
            if (focused) ...const [
              BoxShadow(color: SkyColors.ink, spreadRadius: 4),
              BoxShadow(color: SkyColors.gold, spreadRadius: 2),
            ],
            // The lip, solid like the title screen's keys.
            if (!pressed)
              BoxShadow(
                color: widget.lip,
                offset: const Offset(0, _Keycap.depth),
                spreadRadius: 0,
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
            hoverColor: SkyColors.white.withValues(alpha: .35),
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
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
              ? Color.lerp(SkyColors.cream, accent, .38)!
              : const Color(0xfff6efe1),
          lip: on
              ? Color.lerp(accent, SkyColors.ink, .4)!
              : SkyColors.ink.withValues(alpha: .3),
          child: Row(
            children: [
              AnimatedContainer(
                duration: duration,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: on ? accent : SkyColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on
                        ? SkyColors.ink
                        : SkyColors.ink.withValues(alpha: .4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 22,
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
                          ? SkyColors.white
                          : SkyColors.muted,
                    ),
                    trackColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? SkyColors.teal
                          : SkyColors.white,
                    ),
                    trackOutlineColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.disabled)
                          ? SkyColors.ink.withValues(alpha: .3)
                          : SkyColors.ink,
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

/// The privacy promise, as a mint sticker with a shield coin.
class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: _Keycap.depth),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: Color.lerp(SkyColors.cream, SkyColors.mint, .45),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: [
        BoxShadow(
          color: Color.lerp(SkyColors.mint, SkyColors.ink, .4)!,
          offset: const Offset(0, _Keycap.depth),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const MiniCoin(
              icon: Icons.verified_user_rounded,
              color: SkyColors.mint,
              size: 40,
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
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final String? detail, semanticLabel;
  final VoidCallback onTap;
  final bool danger;

  /// A half-width key: the label may take two lines, the [detail] sits
  /// under it and there is no chevron.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ink = danger ? _dangerInk : SkyColors.ink;
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticLabel ?? label,
        child: _Keycap(
          minHeight: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: danger
              ? Color.lerp(SkyColors.cream, SkyColors.coral, .22)!
              : SkyColors.white,
          lip: danger
              ? SkyColors.coralDeep
              : Color.lerp(SkyColors.sand, SkyColors.ink, .2)!,
          onTap: () {
            UiSounds.effect(context);
            onTap();
          },
          child: ExcludeSemantics(
            child: compact
                ? Row(
                    children: [
                      MiniCoin(icon: icon, size: 30, color: SkyColors.sky),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 2,
                              style: bodyText(
                                14,
                                color: ink,
                                weight: FontWeight.w900,
                              ).copyWith(height: 1.1),
                            ),
                            if (detail != null)
                              Text(
                                detail!,
                                style: bodyText(
                                  11.5,
                                  color: SkyColors.muted,
                                  weight: FontWeight.w800,
                                ).copyWith(height: 1.1),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      MiniCoin(
                        icon: icon,
                        size: 32,
                        color: danger ? SkyColors.coral : SkyColors.sky,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: bodyText(
                            15,
                            color: ink,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (detail != null) ...[
                        Text(
                          detail!,
                          style: bodyText(
                            12,
                            color: SkyColors.muted,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                      if (!danger)
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 26,
                          color: SkyColors.ink,
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Play Games in one strip: whether it is connected, the cloud save's
/// state, and Google's achievements screen (or Connect). Everything else
/// runs in the background (lib/data/play_games.dart).
class _PlayGamesStrip extends ConsumerStatefulWidget {
  const _PlayGamesStrip();

  @override
  ConsumerState<_PlayGamesStrip> createState() => _PlayGamesStripState();
}

class _PlayGamesStripState extends ConsumerState<_PlayGamesStrip> {
  /// Google's sign-in sheet is open; then it failed or was cancelled, which
  /// shows until the player leaves Settings.
  bool connecting = false, failed = false;

  Future<void> connect() async {
    setState(() {
      connecting = true;
      failed = false;
    });
    final ok = await ref.read(playGamesProvider.notifier).connect();
    if (!mounted) return;
    setState(() {
      connecting = false;
      failed = !ok;
    });
  }

  /// "2 min ago", "3 h ago".
  static String ago(DateTime at, DateTime now) {
    final d = now.difference(at);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(playGamesProvider);
    final now = ref.read(appClockProvider)();
    final saved = s.savedAt;
    final (IconData cloud, String line) = !s.connected
        ? connecting
              ? (Icons.cloud_sync_rounded, 'Connecting…')
              : failed
              ? (Icons.cloud_off_rounded, 'Couldn’t connect')
              : (Icons.cloud_outlined, 'Cloud save & achievements')
        : s.saving
        ? (Icons.cloud_sync_rounded, 'Saving to cloud…')
        : s.offline
        ? (
            Icons.cloud_off_rounded,
            saved == null
                ? 'Offline · not saved yet'
                : 'Offline · saved ${ago(saved, now)}',
          )
        : s.updateNeeded
        ? (Icons.system_update_rounded, 'Update Beakbound to sync')
        : s.unreadable
        ? (Icons.sync_problem_rounded, 'Cloud save can’t be read')
        : saved == null
        ? (Icons.cloud_outlined, 'Cloud save is on')
        : s.resetElsewhere
        ? (Icons.cloud_done_rounded, 'Reset on another phone')
        : (
            Icons.cloud_done_rounded,
            '${s.restored ? 'Cloud restored' : 'Saved to cloud'} · '
                '${ago(saved, now)}',
          );
    final ink = s.connected ? _tealInk : SkyColors.muted;
    return Container(
      margin: const EdgeInsets.only(bottom: _Keycap.depth),
      padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
      decoration: BoxDecoration(
        color: Color.lerp(SkyColors.cream, SkyColors.sky, .35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SkyColors.ink, width: 2),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(SkyColors.skyDeep, SkyColors.ink, .4)!,
            offset: const Offset(0, _Keycap.depth),
          ),
        ],
      ),
      child: Row(
        children: [
          const MiniCoin(
            icon: Icons.sports_esports_rounded,
            color: SkyColors.mint,
            size: 34,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Play Games',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: heading(17),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      s.connected
                          ? Icons.circle
                          : Icons.radio_button_unchecked_rounded,
                      size: 9,
                      color: ink,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      s.connected ? 'Connected' : 'Not connected',
                      style: bodyText(
                        11.5,
                        color: ink,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Icon(cloud, size: 14, color: SkyColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(
                          12,
                          color: SkyColors.muted,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          MergeSemantics(
            child: Semantics(
              button: true,
              label: s.connected
                  ? 'Play Games achievements'
                  : 'Connect Play Games',
              child: _Keycap(
                minHeight: 48,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                color: s.connected ? SkyColors.white : SkyColors.yellow,
                lip: s.connected
                    ? Color.lerp(SkyColors.sand, SkyColors.ink, .2)!
                    : SkyColors.gold,
                onTap: s.connected
                    ? () {
                        UiSounds.effect(context);
                        ref.read(playGamesProvider.notifier).showAchievements();
                      }
                    : connecting
                    ? null
                    : () {
                        UiSounds.effect(context);
                        connect();
                      },
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 48 - _Keycap.depth,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (connecting)
                          const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: SkyColors.ink,
                            ),
                          )
                        else
                          Icon(
                            s.connected
                                ? Icons.emoji_events_rounded
                                : Icons.login_rounded,
                            size: 18,
                            color: SkyColors.ink,
                          ),
                        const SizedBox(width: 5),
                        Text(
                          s.connected ? 'Achievements' : 'Connect',
                          style: bodyText(13.5, weight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetDialog extends StatelessWidget {
  const _ResetDialog({this.cloud = false});

  /// This phone has synced with Play Games, so the reset clears the cloud
  /// save too.
  final bool cloud;

  @override
  Widget build(BuildContext context) => AlertDialog(
    semanticLabel: 'Start a fresh adventure?',
    scrollable: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: SkyColors.ink, width: 2.5),
    ),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
    actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
    title: Row(
      children: [
        const MiniCoin(
          icon: Icons.restart_alt_rounded,
          color: SkyColors.coral,
          size: 48,
        ),
        const SizedBox(width: 14),
        Expanded(child: Text('Start a fresh adventure?', style: heading(26))),
      ],
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Text(
        cloud
            ? 'This deletes your saved videos, replays, scores, runs, built levels and settings from this phone, and your Play Games cloud save. It cannot be undone.'
            : 'This deletes your saved videos, replays, scores, runs, built levels and settings from this phone. It cannot be undone.',
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
              backgroundColor: Color.lerp(
                SkyColors.cream,
                SkyColors.coral,
                .16,
              ),
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
                    : const BorderSide(color: _dangerInk, width: 2),
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
