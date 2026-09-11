import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import 'components.dart';
import 'theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  Future<void> change(
    BuildContext context,
    WidgetRef ref,
    SettingKey key,
    bool value,
  ) async {
    try {
      await ref.read(progressProvider.notifier).setting(key, value);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  Future<void> reset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Start a fresh adventure?', style: heading(26)),
        content: const Text(
          'This deletes your scores, runs, unlocked birds and settings from this phone. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep my progress'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(progressProvider.notifier).reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A fresh start. Pip is ready for you.')),
        );
      }
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider).asData?.value;
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
                    Text('Make yourself at home.', style: heading(36)),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Panel(
                          padding: const EdgeInsets.all(18),
                          child: p == null
                              ? const Center(child: CircularProgressIndicator())
                              : Column(
                                  children: [
                                    _toggle(
                                      Icons.music_note_rounded,
                                      'Sky Club soundtrack',
                                      'A little sunshine for your ears.',
                                      p.settings.music,
                                      (v) => change(
                                        context,
                                        ref,
                                        SettingKey.music,
                                        v,
                                      ),
                                    ),
                                    const Divider(height: 18),
                                    _toggle(
                                      Icons.volume_up_rounded,
                                      'Sound effects',
                                      'Flaps, points and happy little victories.',
                                      p.settings.effects,
                                      (v) => change(
                                        context,
                                        ref,
                                        SettingKey.effects,
                                        v,
                                      ),
                                    ),
                                    const Divider(height: 18),
                                    _toggle(
                                      Icons.motion_photos_off_rounded,
                                      'Reduced motion',
                                      'Quieter menus and fewer decorative effects.',
                                      p.settings.reducedMotion,
                                      (v) => change(
                                        context,
                                        ref,
                                        SettingKey.reducedMotion,
                                        v,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        flex: 2,
                        child: Panel(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Pill(
                                'ON-DEVICE. ALWAYS.',
                                icon: Icons.shield_outlined,
                                color: SkyColors.mint,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Your camera stays yours.',
                                style: heading(25),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No recordings, uploads, accounts or ads. Models, music and your personal bests live on this phone.',
                                style: bodyText(15, color: SkyColors.muted),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => context.go('/lab'),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Camera & tracking lab'),
                              ),
                              TextButton.icon(
                                onPressed: () => showLicensePage(
                                  context: context,
                                  applicationName: 'Push-Up Bird',
                                  applicationVersion: '1.0.0',
                                ),
                                icon: const Icon(Icons.info_outline),
                                label: const Text('About & licenses'),
                              ),
                              TextButton.icon(
                                onPressed: () => reset(context, ref),
                                icon: const Icon(
                                  Icons.restart_alt_rounded,
                                  color: SkyColors.coralDeep,
                                ),
                                label: Text(
                                  'Reset local progress',
                                  style: bodyText(
                                    14,
                                    color: SkyColors.coralDeep,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _toggle(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Expanded(
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SkyColors.yellow.withValues(alpha: .4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: SkyColors.ink),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: heading(21)),
              const SizedBox(height: 5),
              Text(subtitle, style: bodyText(13, color: SkyColors.muted)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: SkyColors.teal,
        ),
      ],
    ),
  );
}
