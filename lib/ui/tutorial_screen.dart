import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/tutorial_story.dart';
import '../l10n/l10n.dart';
import 'story_scene.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// Whether a new player's first launch opens the language screen and
/// flight school (docs/tutorial.md). On in the game; widget tests boot a
/// fresh save into Home as they always have, and the tests of the first
/// launch turn it on.
final firstLaunchTutorialProvider = Provider<bool>(
  (ref) => !Platform.environment.containsKey('FLUTTER_TEST'),
);

/// Where a launch with [progress] begins instead of Home, or null for
/// Home: a player who has never flown and has not been through flight
/// school starts at the language screen.
String? firstLaunchRoute(ProgressSnapshot progress) =>
    progress.settings.tutorialDone || progress.flightsFlown > 0
    ? null
    : '/welcome';

/// Flight school (`/tutorial`): Postmaster Bill's word before the lesson
/// ([TutorialStory.intro]), over the menu music, then the lesson itself
/// (`/tutorial/fly`, a [PlayScreen] of the tutorial flight). Flying it
/// again (from the licence, Settings or the pause card) goes straight to
/// the lesson.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  Future<void> _skip() async {
    final l = context.l10n;
    final skip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('tutorial-skip-dialog'),
        title: Text(l.tutorialSkipTitle, style: heading(24)),
        content: Text(l.tutorialSkipBody, style: bodyText(16)),
        actions: [
          TextButton(
            key: const ValueKey('tutorial-skip-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.tutorialSkipCancel),
          ),
          FilledButton(
            key: const ValueKey('tutorial-skip-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.tutorialSkipConfirm),
          ),
        ],
      ),
    );
    if (skip != true || !mounted) return;
    try {
      await ref
          .read(progressProvider.notifier)
          .setting(SettingKey.tutorialDone, true);
    } catch (error) {
      debugPrint('Flight school: $error');
    }
    if (mounted) context.go('/campaign');
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(progressProvider).asData?.value.settings ??
        const GameSettings();
    return Scaffold(
      backgroundColor: SkyColors.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          StoryScenePlayer(
            key: const ValueKey('tutorial-intro'),
            scene: TutorialStory.intro,
            bird: settings.bird,
            voices: settings.voices,
            reducedMotion: settings.reducedMotion,
            onDone: () => context.go('/tutorial/fly'),
          ),
          // Skipping the scene is the scene's own key; skipping the whole
          // lesson is this one, up in the corner, asked once more.
          SafeArea(
            child: Align(
              // Clear of the scene's own skip key, top right in every
              // language.
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  key: const ValueKey('tutorial-skip'),
                  style: TextButton.styleFrom(
                    backgroundColor: SkyColors.night.withValues(alpha: .45),
                    foregroundColor: SkyColors.cream,
                  ),
                  onPressed: () {
                    UiSounds.effect(context);
                    _skip();
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(
                    context.l10n.tutorialSkip,
                    style: bodyText(
                      14,
                      color: SkyColors.cream,
                      weight: FontWeight.w800,
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
