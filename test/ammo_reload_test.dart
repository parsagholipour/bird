import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/ui/match_hud.dart';
import 'experience_ui_test.dart' show capture;
import 'power_shot_test.dart' show flight, hold;

Future<bool> hasHeldRock(
  FlightSimulation sim, {
  required bool reducedMotion,
}) async {
  final recorder = ui.PictureRecorder();
  CombatArt.paintCharge(
    Canvas(recorder),
    360,
    sim,
    reducedMotion: reducedMotion,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(640, 360);
  final bytes = await image.toByteData();
  image.dispose();
  picture.dispose();
  final pixels = bytes!.buffer.asUint8List();
  for (var i = 3; i < pixels.length; i += 4) {
    if (pixels[i] != 0) return true;
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Fredoka',
    )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
  });

  for (final reducedMotion in [false, true]) {
    test(
      'empty presses draw no held rock (reduced motion: $reducedMotion)',
      () async {
        final sim = flight()..ammo = .04;
        sim.lastShotAt = sim.elapsed;
        expect(sim.startCharge(), isTrue);
        expect(
          await hasHeldRock(sim, reducedMotion: reducedMotion),
          isFalse,
          reason: 'An unaffordable shot must never flash in front of the beak',
        );
        expect(sim.shoot(), isFalse);
        expect(sim.rocks, isEmpty);
        expect(sim.dryFires, 1);

        expect(sim.startCharge(), isTrue);
        hold(sim, PowerShot.refillDelay + .1);
        expect(sim.outOfAmmo, isTrue);
        expect(await hasHeldRock(sim, reducedMotion: reducedMotion), isFalse);
        hold(sim, .2);
        expect(sim.outOfAmmo, isFalse);
        expect(await hasHeldRock(sim, reducedMotion: reducedMotion), isTrue);
        expect(sim.shoot(), isTrue);
        expect(sim.rocks, hasLength(1));
      },
    );

    testWidgets('Reloading stays visible until a shot is affordable '
        '(reduced motion: $reducedMotion)', (tester) async {
      final sim = flight()..ammo = 0;
      sim.lastShotAt = sim.elapsed;
      final semantics = tester.ensureSemantics();
      try {
        late StateSetter refresh;
        var skyTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) => skyTaps++,
                    ),
                  ),
                  Center(
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        refresh = setState;
                        return RepaintBoundary(
                          key: const ValueKey('visual-capture'),
                          child: MatchShotButton(
                            key: const ValueKey('shoot'),
                            label: 'Shoot',
                            reserve: sim.ammo,
                            charge: sim.shotCharge,
                            spend: sim.charging && !sim.outOfAmmo
                                ? sim.shotCost
                                : 0,
                            charging: sim.charging,
                            empty: sim.outOfAmmo,
                            reducedMotion: reducedMotion,
                            onPress: () => setState(() {
                              sim.startCharge();
                            }),
                            onRelease: () => setState(() {
                              sim.shoot();
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        final shoot = find.byKey(const ValueKey('shoot'));
        void expectReloading() {
          expect(find.text('Reloading…'), findsOneWidget);
          expect(tester.getSemantics(shoot).value, 'Reloading…');
          expect(
            tester.widget<MatchIcon>(find.byType(MatchIcon)).muted,
            isTrue,
          );
        }

        expectReloading();
        await tester.tap(shoot);
        await tester.pump();
        expectReloading();
        expect(sim.rocks, isEmpty);
        final press = await tester.startGesture(tester.getCenter(shoot));
        await tester.pump();
        expectReloading();
        await capture(tester, 'ammo-reloading-$reducedMotion');
        refresh(() => hold(sim, PowerShot.refillDelay + .1));
        await tester.pump();
        expectReloading();
        refresh(() => hold(sim, .2));
        await tester.pump();
        expect(find.text('Reloading…'), findsNothing);
        expect(tester.getSemantics(shoot).value, startsWith('Charging '));
        expect(tester.widget<MatchIcon>(find.byType(MatchIcon)).muted, isFalse);
        await press.up();
        await tester.pump();
        expect(sim.rocks, hasLength(1));
        expect(skyTaps, 0);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
