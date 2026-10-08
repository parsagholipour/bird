import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/voice_pack_seam_runtime.dart';
import 'package:push_up_bird/game/voice_packs.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/ui/language_picker.dart';

/// Voice packs whose states a test sets by hand; [ensure] only records.
class _Packs extends VoicePacks {
  final states = <AppLanguage, VoicePackInfo>{};
  final ensured = <AppLanguage>[];

  void put(VoicePackInfo info) {
    states[info.language] = info;
    notifyListeners();
  }

  @override
  VoicePackInfo status(AppLanguage language) =>
      states[language] ?? super.status(language);

  @override
  Future<void> ensure(AppLanguage language) async => ensured.add(language);
}

/// The language picker's voice-pack badge driven by the real voice packs
/// through the seam (`voicePackSeamOverrides`, as in the app's root
/// ProviderScope): every state, and a download Play has not sized yet.
void main() {
  tearDown(L10n.debugReset);

  Future<_Packs> pumpBadges(WidgetTester tester) async {
    final packs = _Packs();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voicePacksProvider.overrideWithValue(packs),
          ...voicePackSeamOverrides,
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Row(
              children: [
                for (final language in [
                  AppLanguage.en,
                  AppLanguage.de,
                  AppLanguage.ja,
                  AppLanguage.ar,
                ])
                  VoicePackBadge(language, key: ValueKey(language)),
              ],
            ),
          ),
        ),
      ),
    );
    return packs;
  }

  CircularProgressIndicator? ring(WidgetTester tester, AppLanguage language) {
    final found = find.descendant(
      of: find.byKey(ValueKey(language)),
      matching: find.byType(CircularProgressIndicator),
    );
    return found.evaluate().isEmpty
        ? null
        : tester.widget<CircularProgressIndicator>(found);
  }

  testWidgets('a download Play has not sized yet spins without a percent', (
    tester,
  ) async {
    final packs = await pumpBadges(tester);
    packs.put(VoicePackInfo(AppLanguage.de, VoicePackState.downloading));
    await tester.pump();
    expect(ring(tester, AppLanguage.de), isNotNull);
    expect(ring(tester, AppLanguage.de)!.value, isNull, reason: 'it spins');
    expect(find.byTooltip('Getting voices'), findsOneWidget);
    expect(find.byTooltip('Voices 0%'), findsNothing);
    // The ring takes the icon's place, not more room.
    expect(
      tester.getSize(find.byKey(const ValueKey('voice-pack-ring-de'))),
      const Size(18, 18),
    );

    // Play reports bytes: the ring fills and the percent shows.
    packs.put(
      VoicePackInfo(
        AppLanguage.de,
        VoicePackState.downloading,
        phase: 'downloading',
        progress: .42,
      ),
    );
    await tester.pump();
    expect(ring(tester, AppLanguage.de)!.value, .42);
    expect(find.byTooltip('Voices 42%'), findsOneWidget);
    expect(find.byTooltip('Getting voices'), findsNothing);

    packs.put(
      VoicePackInfo(AppLanguage.de, VoicePackState.installed, storyClips: 3),
    );
    await tester.pump();
    expect(ring(tester, AppLanguage.de), isNull);
    expect(find.byTooltip('Voices ready'), findsOneWidget);
  });

  testWidgets('every pack state shows its badge; taps download or retry', (
    tester,
  ) async {
    final packs = await pumpBadges(tester);
    packs
      ..put(VoicePackInfo(AppLanguage.de, VoicePackState.absent))
      ..put(VoicePackInfo(AppLanguage.ja, VoicePackState.unrecorded))
      ..put(VoicePackInfo(AppLanguage.ar, VoicePackState.failed, error: 'x'));
    await tester.pump();
    // English is built in: no badge.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey(AppLanguage.en)),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(find.byTooltip('Get voices'), findsOneWidget);
    expect(find.byTooltip('English voices'), findsOneWidget);
    expect(find.byTooltip('Voices failed'), findsOneWidget);

    await tester.tap(find.byTooltip('English voices'));
    await tester.tap(find.byTooltip('Get voices'));
    await tester.tap(find.byTooltip('Voices failed'));
    await tester.pump();
    expect(packs.ensured, [AppLanguage.de, AppLanguage.ar]);
  });
}
