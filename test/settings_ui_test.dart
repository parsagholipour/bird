import 'dart:ui' show Tristate;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/ui/settings_screen.dart';
import 'package:push_up_bird/ui/theme.dart';

class _CountingRepository extends SqliteProgressRepository {
  _CountingRepository() : super(ProgressDatabase(NativeDatabase.memory()));

  final changes = <(SettingKey, bool)>[];

  @override
  Future<void> setSetting(SettingKey key, bool value) async {
    changes.add((key, value));
    await super.setSetting(key, value);
  }
}

const _titles = [
  'Sky Club soundtrack',
  'Sound effects',
  'Character voices',
  'Reduced motion',
];
const _subtitles = [
  'Menu, adventure and boss themes.',
  'Flight, combat, pickups and menu feedback.',
  'Story scenes, thank-you notes and sprint calls.',
  'Quieter menus and fewer decorative effects.',
];
const _keys = [
  SettingKey.music,
  SettingKey.effects,
  SettingKey.voices,
  SettingKey.reducedMotion,
];

Future<_CountingRepository> _pumpSettings(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _CountingRepository();
  final container = ProviderContainer(
    overrides: [progressRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await repo.close();
  });
  await container.read(progressProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: skyTheme(), home: const SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });
  testWidgets('every toggle row tap target persists exactly one change', (
    tester,
  ) async {
    final repo = await _pumpSettings(tester);
    for (var i = 0; i < _titles.length; i++) {
      final control = find.byType(Switch).at(i);
      final row = find.ancestor(
        of: find.text(_titles[i]),
        matching: find.byType(InkWell),
      );
      final targets = [
        tester.getCenter(find.text(_titles[i])),
        tester.getCenter(find.text(_subtitles[i])),
        tester.getTopLeft(row) + const Offset(2, 2),
        tester.getBottomRight(row) - const Offset(2, 2),
        tester.getCenter(control),
      ];
      for (final target in targets) {
        final value = tester.widget<Switch>(control).value;
        repo.changes.clear();
        await tester.tapAt(target);
        await tester.pumpAndSettle();
        expect(repo.changes, [(_keys[i], !value)]);
        expect(tester.widget<Switch>(control).value, !value);
        final saved = (await repo.load()).settings;
        expect(
          [saved.music, saved.effects, saved.voices, saved.reducedMotion][i],
          !value,
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('rows have one switch semantic node and keyboard focus target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final repo = await _pumpSettings(tester);
      for (var i = 0; i < _titles.length; i++) {
        final label = '${_titles[i]}\n${_subtitles[i]}';
        final nodeFinder = find.bySemanticsLabel(label);
        expect(nodeFinder, findsOneWidget);
        // Reading-order traversal can include controls in the adjacent panel.
        for (var tabs = 0; tabs < 8; tabs++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          if (tester
                  .getSemantics(nodeFinder)
                  .getSemanticsData()
                  .flagsCollection
                  .isFocused ==
              Tristate.isTrue) {
            break;
          }
        }
        final node = tester.getSemantics(nodeFinder);
        final value = tester.widget<Switch>(find.byType(Switch).at(i)).value;
        final data = node.getSemanticsData();
        expect(data.flagsCollection.isToggled != Tristate.none, isTrue);
        expect(data.flagsCollection.isToggled == Tristate.isTrue, value);
        expect(data.flagsCollection.isFocused == Tristate.isTrue, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        void expectMergedChildren(SemanticsNode parent) {
          parent.visitChildren((child) {
            expect(child.isMergedIntoParent, isTrue);
            expectMergedChildren(child);
            return true;
          });
        }

        expectMergedChildren(node);
        repo.changes.clear();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(repo.changes, [(_keys[i], !value)]);
        expect(
          tester
                  .getSemantics(nodeFinder)
                  .getSemanticsData()
                  .flagsCollection
                  .isToggled ==
              Tristate.isTrue,
          !value,
        );
        repo.changes.clear();
        tester.semantics.performAction(
          find.semantics.byLabel(label),
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        expect(repo.changes, [(_keys[i], value)]);
        expect(tester.widget<Switch>(find.byType(Switch).at(i)).value, value);
      }
    } finally {
      semantics.dispose();
    }
  });
}
