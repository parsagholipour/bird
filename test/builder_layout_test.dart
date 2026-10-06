import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/builder/builder_chrome.dart';
import 'package:push_up_bird/ui/builder/builder_pickers.dart' show PressCard;
import 'package:push_up_bird/ui/campaign_chrome.dart' show MapKey;
import 'package:push_up_bird/ui/home_keys.dart';
import 'package:push_up_bird/ui/mini_chrome.dart' show MiniPillKey;

import 'builder_ui_harness.dart';

/// The Level Builder's screens on the reference phone (792 × 360), the
/// common 800 × 360 and a 20:9 phone with a cutout and a gesture bar: no
/// overflow, every key at least the 48-unit touch target of the canvas the
/// app is drawn on, and nothing to press outside the safe area.
class _Phone {
  const _Phone(this.name, this.size, {this.dpr = 1, this.insets});
  final String name;
  final Size size;
  final double dpr;
  final EdgeInsets? insets;
}

const _phones = [
  _Phone('792', Size(792, 360)),
  _Phone('800', Size(800, 360)),
  _Phone(
    '915',
    Size(915, 412),
    dpr: 2.625,
    insets: EdgeInsets.only(left: 52, right: 24, bottom: 21),
  ),
];

void main() {
  setUpAll(loadBuilderFonts);

  /// Every key on screen is at least 48 units each way, and every key not
  /// in a scrolling list lies inside the safe area.
  void checkKeys(WidgetTester tester, _Phone phone, String where) {
    final insets = phone.insets ?? EdgeInsets.zero;
    final safe = Rect.fromLTRB(
      insets.left,
      insets.top,
      phone.size.width - insets.right,
      phone.size.height - insets.bottom,
    ).inflate(.5);
    var keys = 0;
    for (final type in [BuilderKey, MapKey, MiniPillKey, PressCard, HomeKey]) {
      for (final element in find.byType(type).evaluate()) {
        final box = element.renderObject! as RenderBox;
        if (!box.attached || !box.hasSize) continue;
        final label = '$where: $type ${element.widget.key ?? ''}';
        expect(box.size.width, greaterThanOrEqualTo(48), reason: label);
        expect(box.size.height, greaterThanOrEqualTo(48), reason: label);
        final scrolls = find
            .ancestor(
              of: find.byElementPredicate((e) => e == element),
              matching: find.byType(Scrollable),
            )
            .evaluate()
            .isNotEmpty;
        if (scrolls) continue;
        final rect = tester.getRect(
          find.byElementPredicate((e) => e == element),
        );
        expect(
          safe.contains(rect.topLeft) && safe.contains(rect.bottomRight),
          isTrue,
          reason: '$label at $rect leaves $safe',
        );
        keys++;
      }
    }
    expect(keys, greaterThan(3), reason: where);
    expect(tester.takeException(), isNull, reason: where);
  }

  for (final phone in _phones) {
    testWidgets('the builder fits ${phone.name}', (tester) async {
      await pumpBuilderApp(
        tester,
        at: '/',
        size: phone.size,
        dpr: phone.dpr,
        insets: phone.insets,
        levels: [
          builtLevel(PlayMode.touch, id: 'u-layoutlvl1', name: 'Canopy Dash'),
          builtLevel(
            PlayMode.pushUp,
            id: 'u-layoutlvl2',
            name: 'A rather long level name',
            region: WorldRegion.paris,
          ),
          builtLevel(
            PlayMode.squat,
            id: 'u-layoutlvl3',
            name: 'Half built',
            gates: 0,
            region: WorldRegion.egypt,
          ),
        ],
      );
      // Home's split row.
      final mini = tester.getRect(find.byKey(const ValueKey('mini-games')));
      final builder = tester.getRect(
        find.byKey(const ValueKey('level-builder')),
      );
      expect(mini.overlaps(builder), isFalse);
      expect(mini.width, closeTo(builder.width, .01));
      expect(mini.height, closeTo(builder.height, .01));
      expect(mini.top, closeTo(builder.top, .01));
      expect(builder.left, greaterThan(mini.right));
      await snap(tester, 'home-${phone.name}');

      appRouter.go('/builder');
      await settle(tester);
      checkKeys(tester, phone, 'shelf');
      await snap(tester, 'shelf-${phone.name}');

      await tester.tap(find.byKey(const ValueKey('new-level')));
      await settle(tester);
      checkKeys(tester, phone, 'new level mode');
      await tester.tap(find.byKey(const ValueKey('new-mode-touch')));
      await settle(tester);
      checkKeys(tester, phone, 'new level region');
      await tester.tap(find.byTooltip('Close new level'));
      await settle(tester);

      appRouter.go('/builder/edit/u-layoutlvl1?at=3600');
      await settle(tester);
      checkKeys(tester, phone, 'editor');
      final c = editorOf(tester);
      await tester.tapAt(skyPoint(tester, 3.05, .2));
      await settle(tester);
      expect(c.selection, isA<BuiltGate>());
      checkKeys(tester, phone, 'editor with a gate');
      await snap(tester, 'editor-${phone.name}');
      c.select(null);
      await tester.tapAt(skyPoint(tester, 3.55, .3));
      await settle(tester);
      expect(c.selection, isA<BuiltEnemy>());
      checkKeys(tester, phone, 'editor with an enemy');

      await tester.tap(find.byTooltip('Level settings'));
      await settle(tester);
      checkKeys(tester, phone, 'settings');
      await snap(tester, 'settings-${phone.name}');
      await tester.tap(find.byTooltip('Close settings'));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('editor-issues')));
      await settle(tester);
      checkKeys(tester, phone, 'issues');
      await tester.tap(find.byTooltip('Close problems and tips'));
      await settle(tester);

      appRouter.go('/builder/edit/u-layoutlvl2?at=4000');
      await settle(tester);
      checkKeys(tester, phone, 'push-up editor');
      appRouter.go('/builder/edit/t-tap-boss');
      await settle(tester);
      checkKeys(tester, phone, 'starter editor');
    });

    testWidgets('renaming stays above the keyboard on ${phone.name}', (
      tester,
    ) async {
      await pumpBuilderApp(
        tester,
        at: '/builder/edit/u-renamelvl1',
        size: phone.size,
        dpr: phone.dpr,
        insets: phone.insets,
        levels: [builtLevel(PlayMode.jump, id: 'u-renamelvl1')],
      );
      await tester.tap(find.byKey(const ValueKey('editor-name')));
      await settle(tester);
      // The keyboard covers most of a landscape phone.
      final keyboard = phone.size.height * .58;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard * phone.dpr);
      await settle(tester);
      expect(tester.takeException(), isNull);
      final top = phone.size.height - keyboard;
      for (final key in ['name-field', 'name-save', 'name-cancel']) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.bottom, lessThanOrEqualTo(top), reason: '$key $rect');
        expect(rect.top, greaterThanOrEqualTo(0), reason: key);
      }
      expect(
        tester.getSize(find.byKey(const ValueKey('name-save'))).height,
        greaterThanOrEqualTo(48),
      );
      await snap(tester, 'rename-${phone.name}');
      tester.view.resetViewInsets();
      await tester.tap(find.byKey(const ValueKey('name-cancel')));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large system text still fits the builder', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpBuilderApp(
      tester,
      levels: [
        builtLevel(PlayMode.squat, id: 'u-bigtextlvl', name: 'Big text squats'),
      ],
    );
    expect(tester.takeException(), isNull);
    await snap(tester, 'shelf-large-text');
    await tester.tap(find.byKey(const ValueKey('new-level')));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close new level'));
    await settle(tester);
    appRouter.go('/builder/edit/u-bigtextlvl?at=3600');
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tapAt(skyPoint(tester, 3.07, .2));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'editor-large-text');
    await tester.tap(find.byTooltip('Level settings'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await snap(tester, 'settings-large-text');
  });

  testWidgets('with Reduced Motion off the builder still settles', (
    tester,
  ) async {
    await pumpBuilderApp(
      tester,
      reduced: false,
      levels: [builtLevel(PlayMode.touch, id: 'u-motionlvl1')],
    );
    await tester.tap(find.byKey(const ValueKey('new-level')));
    await settle(tester);
    expect(find.text('What will it be?'), findsOneWidget);
    await tester.tap(find.byTooltip('Close new level'));
    await settle(tester);
    appRouter.go('/builder/edit/u-motionlvl1');
    await settle(tester);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
