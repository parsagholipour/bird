import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/boss_art.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/king_coo_encounter_ui.dart';
import 'package:push_up_bird/game/king_coo_staging_art.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';

import 'campaign_flight.dart' show flyLevel;
import 'king_coo_budget_test.dart' show Counting;
import 'king_coo_test_kit.dart' show rawPixels, regionLight;
import 'king_coo_helpers.dart' as rules;
import 'ny_plans.dart';

/// King Coo's staging (K8): where `BossEncounterArt` puts him in the world,
/// how he arrives, fights and falls, and that everything holds together in the
/// REAL game (`BirdGame.render` over New York's own backdrop, the catalog's
/// 3-2 flown by the shared bot, the rules' own clock).
///
/// Set `KING_COO_STAGING_REVIEW=1` to also write the review frames (arrival
/// beats, each attack beat, fury, hit, defeat; at 640 and 800 over New York at
/// night, Reduced Motion too) to `build/visual-review/king-coo-staging/`;
/// `KING_COO_STAGING_VIDEO=1` dumps a whole encounter, arrival to victory, as
/// 30 fps frames to `.../video/` (`ffmpeg -framerate 30 -i video/%04d.png
/// -pix_fmt yuv420p king-coo.mp4`).

final _review = Platform.environment['KING_COO_STAGING_REVIEW'] == '1';
final _video = Platform.environment['KING_COO_STAGING_VIDEO'] == '1';
final _folder = Directory('build/visual-review/king-coo-staging');

// ------------------------------------------------------------ the stage --

/// A real flight of the catalog's 3-2 with King Coo on stage, stepped at
/// 120 Hz with the bird hovering at [birdY] and never hurt.
class Stage {
  Stage(this.sim, this.game, this.width);
  final FlightSimulation sim;
  final BirdGame game;
  final double width;
  double birdY = .5;

  SkyBoss get boss => sim.boss!;
  double get aspect => width / 360;

  /// Runs [seconds] on (never past the end of the flight).
  void run(double seconds) => rules.run(
    sim,
    seconds,
    width: aspect,
    hold: birdY,
    protect: true,
  );

  /// Runs until the boss's age is [age] (to the 120 Hz tick).
  void toAge(double age) {
    if (boss.age >= age - 1e-9) return;
    rules.run(
      sim,
      1000,
      width: aspect,
      hold: birdY,
      protect: true,
      until: (s) => s.boss == null || s.boss!.age >= age - 1e-9,
    );
  }

  /// Runs until [combat] seconds into the fight (the arrival is 4.6 s).
  void toCombat(double combat) => toAge(boss.arrivalDuration + combat);

  /// A rock of [damage] on his chest, stepped in.
  void hit(int damage) {
    sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: damage));
    run(1 / 120);
  }

  /// One frame of the whole game.
  Future<ui.Image> frame() async {
    final recorder = ui.PictureRecorder();
    game.render(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }

  /// The frame as bytes (RGBA).
  Future<Uint8List> pixels() async {
    final image = await frame();
    final data = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();
    return Uint8List.fromList(data);
  }
}

/// The catalog's 3-2 flown to the instant King Coo's arrival begins.
Stage stage(
  double width, {
  bool reduced = false,
  int weapon = 10,
  void Function(FlightSimulation sim)? setup,
}) {
  final plan = Campaign.level('3-2')!.plan;
  final sim = nyFlight(plan, weaponDamage: weapon);
  setup?.call(sim);
  flyLevel(sim, viewportWidth: width / 360, until: (s) => s.boss != null);
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  )..onGameResize(Vector2(width, 360));
  return Stage(sim, game, width);
}

Future<Uint8List> png(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();

Future<void> fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

void label(Canvas c, String text, Offset at, double size, Color color) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

/// Frames in a labelled contact sheet, [cols] wide, each at [scale].
Future<void> sheet(
  String name,
  List<(String, ui.Image)> frames, {
  int cols = 3,
  double scale = 1,
}) async {
  final fw = frames.first.$2.width * scale, fh = 360 * scale;
  final rows = (frames.length / cols).ceil();
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.drawRect(
    Rect.fromLTWH(0, 0, fw * cols, (fh + 16) * rows),
    Paint()..color = const Color(0xff101223),
  );
  for (var i = 0; i < frames.length; i++) {
    final (text, image) = frames[i];
    final at = Offset(i % cols * fw, (i ~/ cols) * (fh + 16));
    c.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(at.dx + 1, at.dy + 16, fw - 2, fh - 1),
      Paint()..filterQuality = FilterQuality.medium,
    );
    label(c, text, at + const Offset(4, 1), 12, const Color(0xffffffff));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (fw * cols).toInt(),
    ((fh + 16) * rows).toInt(),
  );
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(await png(image));
  image.dispose();
  picture.dispose();
  for (final f in frames) {
    f.$2.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------- helpers --

  const h = 360.0;

  BossMotion motion(Stage s, {bool reduced = false}) =>
      BossMotion(s.boss, reducedMotion: reduced);

  /// The staging's own pass alone, on a transparent canvas.
  Future<Uint8List> stagePass(Stage s, {bool reduced = false}) =>
      rawPixels(s.width.toInt(), 360, (c) {
        KingCooStaging.paint(
          c,
          Size(s.width, 360),
          s.sim,
          motion(s, reduced: reduced),
        );
      });

  int differing(Uint8List a, Uint8List b, [int tolerance = 40]) {
    var n = 0;
    for (var i = 0; i < a.length; i += 4) {
      if ((a[i] - b[i]).abs() +
              (a[i + 1] - b[i + 1]).abs() +
              (a[i + 2] - b[i + 2]).abs() +
              (a[i + 3] - b[i + 3]).abs() >
          tolerance) {
        n++;
      }
    }
    return n;
  }

  /// The solid-pixel bounds of an RGBA picture [w] wide (alpha above [min]).
  Rect boundsOf(Uint8List px, int w, int hh, {int min = 100}) {
    var l = w, t = hh, r = -1, b = -1;
    for (var y = 0; y < hh; y++) {
      for (var x = 0; x < w; x++) {
        if (px[(y * w + x) * 4 + 3] > min) {
          if (x < l) l = x;
          if (x > r) r = x;
          if (y < t) t = y;
          if (y > b) b = y;
        }
      }
    }
    return r < 0
        ? Rect.zero
        : Rect.fromLTRB(l * 1.0, t * 1.0, r + 1.0, b + 1.0);
  }

  /// The figure alone (the rig, as the stage places it) on a padded canvas:
  /// its solid pixels' bounds in screen pixels, and in rig units about the
  /// chest.
  Future<({Rect screen, Rect rig, double focus})> figure(
    Stage s, {
    bool reduced = false,
  }) async {
    const pad = 220;
    final m = motion(s, reduced: reduced);
    final pose = KingCooStaging.poseOf(s.sim, m, h);
    final body = KingCooStaging.heart(m, h) + KingCooStaging.rumble(pose, m, h);
    const unit = h * SkyBoss.radius;
    final w = s.width.toInt();
    final data = await rawPixels(w + 2 * pad, 360 + 2 * pad, (c) {
      c.translate(pad + body.dx, pad + body.dy);
      c.scale(unit);
      KingCooBossRig.paintPose(c, pose, cap: !pose.capOff);
    });
    final box = boundsOf(data, w + 2 * pad, 360 + 2 * pad, min: 199);
    final screen = box.shift(const Offset(-pad * 1.0, -pad * 1.0));
    final rig = Rect.fromLTRB(
      (screen.left - body.dx) / unit,
      (screen.top - body.dy) / unit,
      (screen.right - body.dx) / unit,
      (screen.bottom - body.dy) / unit,
    );
    return (screen: screen, rig: rig, focus: KingCooStaging.focus(m));
  }

  /// One whole fight on stage, in the rules' own time: the arrival, two calm
  /// cycles with the whistle and a squadron, a pop before the whistle, the
  /// fury, and the killing blow with the whole defeat. [each] sees every
  /// state with its phase label.
  Future<void> script(
    Stage s,
    Future<void> Function(String label) each, {
    double arrivalStep = .1,
    double combatStep = 1 / 6,
    double defeatStep = .05,
  }) async {
    for (var a = arrivalStep; a < 4.6; a += arrivalStep) {
      s.toAge(a);
      await each('arrival');
    }
    var popped = false, furious = false;
    for (var t = 0.0; t < 40; t += combatStep) {
      s.toCombat(t);
      if (!popped && t >= 8.2) {
        popped = true;
        s.hit(30);
      }
      if (!furious && t >= 16) {
        furious = true;
        s.hit(150);
      }
      await each('combat');
    }
    s.hit(1000);
    final at = s.boss.defeatedAt!;
    for (var d = defeatStep; d < 3.75; d += defeatStep) {
      s.toAge(at + d);
      await each('defeat');
    }
  }

  // ------------------------------------------------------------- the frame --

  group('where he stands', () {
    test(
      'the heart is the rules\' own in combat, half the entrance arc in the arrival',
      () {
        for (final width in [640.0, 800.0]) {
          final s = stage(width);
          s.toAge(1.2);
          final m = motion(s);
          final arc = KingCooStaging.heart(m, h);
          expect(arc.dx, s.boss.x * h);
          expect(
            arc.dy,
            closeTo((.5 + (s.boss.y - .5) * KingCooStaging.arcKept) * h, 1e-9),
          );
          s.toCombat(3.3);
          final mc = motion(s);
          expect(
            KingCooStaging.heart(mc, h),
            Offset(s.boss.x * h, s.boss.y * h),
          );
          // The rules' anchor (the layout pins the same numbers).
          expect(
            s.boss.x,
            closeTo(math.max(.47 + .70, width / 360 - .55), 1e-6),
          );
        }
      },
    );

    test('the generic mascot offset, rotation and stretch never move him', () {
      final s = stage(800);
      s.toCombat(1.4);
      s.hit(10);
      s.run(.05);
      expect(motion(s).hit, greaterThan(0));
      expect(motion(s).offset.dx, greaterThan(0));
      expect(
        KingCooStaging.heart(motion(s), h),
        Offset(s.boss.x * h, s.boss.y * h),
      );
    });

    testWidgets('a boss the clock has broken draws nothing and throws nothing', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final poison in <void Function(SkyBoss)>[
          (b) => b.age = double.nan,
          (b) => b.age = double.infinity,
          (b) => b.x = double.nan,
          (b) => b.y = double.infinity,
        ]) {
          final t = stage(800);
          t.toCombat(3.0);
          poison(t.boss);
          final px = await stagePass(t);
          expect(px.any((v) => v != 0), isFalse);
        }
        for (final poison in <void Function(SkyBoss)>[
          (b) => b.lastHitAt = double.nan,
          (b) => b.enragedAt = double.nan,
        ]) {
          final t = stage(800);
          t.toCombat(3.0);
          poison(t.boss);
          await stagePass(t);
        }
        final t = stage(640);
        t.toCombat(2.0);
        t.sim.birdY = double.nan;
        await stagePass(t);
      });
    });
  });

  // ----------------------------------------------------------- the letterbox --

  group('the letterbox', () {
    test(
      'is the dragon\'s and the Gargoyle\'s rule exactly: open for the COO!, out 0.2 s early, in behind the dying figure',
      () {
        final s = stage(800);
        double focusAt(double age) {
          s.boss.age = age;
          return KingCooStaging.focus(motion(s));
        }

        double shared(double age) {
          s.boss.age = age;
          return motion(s).focus;
        }

        expect(
          focusAt(.3),
          closeTo(shared(.3), 1e-9),
          reason: 'in is the shared one',
        );
        expect(focusAt(2.0), 1);
        expect(focusAt(2.4), 1);
        // Open to 30% for the COO! (2.75 to 3.2 s), shut again by 3.6 s.
        expect(focusAt(2.75), closeTo(.3, 1e-9));
        expect(focusAt(3.0), closeTo(.3, 1e-9));
        expect(focusAt(3.2), closeTo(.3, 1e-9));
        expect(focusAt(3.4), allOf(greaterThan(.3), lessThan(1)));
        expect(focusAt(3.6), closeTo(1, 1e-9));
        expect(focusAt(3.8), 1);
        expect(focusAt(4.1), lessThan(shared(4.1)), reason: '0.2 s earlier out');
        expect(focusAt(4.4), closeTo(0, 1e-9));
        expect(shared(4.4), greaterThan(.2), reason: 'the shared bars are still there');
        s.toCombat(3.0);
        expect(KingCooStaging.focus(motion(s)), 0);
        s.hit(1000);
        final at = s.boss.defeatedAt!;
        double dead(double d) {
          s.boss.age = at + d;
          return KingCooStaging.focus(motion(s));
        }

        expect(dead(.3), 0);
        expect(dead(.4), 0, reason: 'they start to slide in at 0.4 s');
        expect(dead(.75), allOf(greaterThan(.1), lessThan(.9)));
        expect(dead(1.1), 1);
        expect(dead(3.9), closeTo(0, 1e-9));
      },
    );

    test('equals the dragon\'s rule at every age, in both motion modes', () {
      // BossEncounterArt.dragonFocus reads only the boss's clock and phase, so
      // it is the rule itself: the king's must be the same function.
      for (final reduced in [false, true]) {
        final s = stage(800, reduced: reduced);
        for (var a = 0.0; a < 4.6; a += .05) {
          s.boss.age = a;
          final m = motion(s, reduced: reduced);
          expect(
            KingCooStaging.focus(m),
            closeTo(BossEncounterArt.dragonFocus(m), 1e-12),
            reason: 'arrival $a reduced $reduced',
          );
        }
        s.toCombat(3.0);
        s.hit(1000);
        final at = s.boss.defeatedAt!;
        for (var d = 0.0; d < 3.8; d += .05) {
          s.boss.age = at + d;
          final m = motion(s, reduced: reduced);
          expect(
            KingCooStaging.focus(m),
            closeTo(BossEncounterArt.dragonFocus(m), 1e-12),
            reason: 'defeat $d reduced $reduced',
          );
        }
      }
    });

    testWidgets('the foreground draws exactly that letterbox', (tester) async {
      await tester.runAsync(() async {
        final s = stage(800);
        Future<int> barRows(double age) async {
          s.boss.age = age;
          final px = await rawPixels(800, 360, (c) {
            BossEncounterArt.foreground(
              c,
              const Size(800, 360),
              s.sim,
              motion(s),
            );
          });
          var n = 0;
          for (var y = 0; y < 60; y++) {
            if (px[(y * 800 + 400) * 4 + 3] > 230) {
              n++;
            } else {
              break;
            }
          }
          return n;
        }

        final full = (360 * .082).round();
        expect(await barRows(2.0), closeTo(full, 1.5));
        expect(await barRows(4.45), 0, reason: 'gone 0.2 s before the shared bars');
      });
    });
  });

  // -------------------------------------------- nothing clipped, any state --

  group('he stays on screen, between the bars and inside his layer', () {
    for (final width in [640.0, 800.0]) {
      for (final reduced in [false, true]) {
        testWidgets(
          'a whole fight at ${width.toInt()}${reduced ? ' (Reduced Motion)' : ''}',
          (tester) async {
            await tester.runAsync(() async {
              final s = stage(width, reduced: reduced);
              final problems = <String>[];
              var states = 0;
              var rightMost = 0.0;
              await script(s, (label) async {
                final f = await figure(s, reduced: reduced);
                states++;
                final age = s.boss.age;
                final tag = '$label age ${age.toStringAsFixed(2)}';
                final bar = h * .082 * f.focus;
                if (f.screen.top < bar - .5) {
                  problems.add(
                    '$tag: top ${f.screen.top.toStringAsFixed(1)} under the letterbox ($bar)',
                  );
                }
                if (f.screen.bottom > h - bar + .5) {
                  problems.add(
                    '$tag: bottom ${f.screen.bottom.toStringAsFixed(1)} under the lower bar',
                  );
                }
                final slides = label == 'arrival' && age < 2.6;
                if (!slides) {
                  if (f.screen.left < -.5) {
                    problems.add('$tag: left ${f.screen.left}');
                  }
                  if (f.screen.right > width + .5) {
                    problems.add('$tag: right ${f.screen.right} of $width');
                  }
                  rightMost = math.max(rightMost, f.screen.right);
                }
                final layer = KingCooBossRig.bounds.inflate(
                  1 / (h * SkyBoss.radius),
                );
                if (!layer.contains(f.rig.topLeft) ||
                    !layer.contains(f.rig.bottomRight)) {
                  problems.add(
                    '$tag: ${f.rig} leaves the layer ${KingCooBossRig.bounds}',
                  );
                }
              });
              // ignore: avoid_print
              print(
                '${width.toInt()}${reduced ? ' RM' : ''}: $states states, worst right $rightMost of $width',
              );
              expect(problems, isEmpty, reason: problems.take(12).join('\n'));
            });
          },
          timeout: const Timeout(Duration(minutes: 8)),
        );
      }
    }
  });

  // ------------------------------------------- the real fight, every phase --

  group('a real-rules fight renders every phase', () {
    testWidgets('frames of the whole game, phase by phase', (tester) async {
      await tester.runAsync(() async {
        await fonts();
        final s = stage(800);
        final seen = <String, Uint8List>{};
        var n = 0;
        final problems = <String>[];
        String phase(Stage st) {
          final b = st.boss;
          if (b.phase == BossPhase.arriving) {
            return b.age < 1.9
                ? 'arrival: silhouette'
                : b.age < 2.65
                ? 'arrival: reveal and rear'
                : 'arrival: roar and card';
          }
          if (b.phase == BossPhase.defeated) {
            final d = b.age - b.defeatedAt!;
            return d < .12
                ? 'defeat: hit-stop'
                : d < .85
                ? 'defeat: inflate'
                : d < 1.6
                ? 'defeat: burst'
                : 'defeat: victory';
          }
          if (b.poppedAt != null && b.age - b.poppedAt! < 1.5) return 'pop';
          if (b.enraged && b.age - b.enragedAt < 1.2) return 'fury onset';
          final lob = b.liveLobs.isEmpty ? null : b.liveLobs.first;
          if (lob != null) {
            if (b.age < lob.launchAt) return 'wind-up';
            if (b.age < lob.burstAt) return 'bomb in flight';
            if (b.age < lob.cloudEndsAt) return 'cloud';
          }
          if (b.puffWindow) {
            return b.squadCalled ? 'whistle blown' : 'puffed, inhale';
          }
          return 'calm';
        }

        await script(s, (label) async {
          n++;
          final name = phase(s);
          if (seen.containsKey(name) && n % 9 != 0) return;
          final image = await s.frame();
          final data = (await image.toByteData())!.buffer.asUint8List();
          image.dispose();
          if (data.every((v) => v == 0)) problems.add('$name: an empty frame');
          seen.putIfAbsent(name, () => Uint8List.fromList(data));
        }, combatStep: 1 / 4);
        expect(problems, isEmpty);
        // ignore: avoid_print
        print('phases seen: ${seen.keys.toList()}');
        for (final name in const [
          'arrival: silhouette',
          'arrival: reveal and rear',
          'arrival: roar and card',
          'wind-up',
          'bomb in flight',
          'cloud',
          'calm',
          'puffed, inhale',
          'whistle blown',
          'pop',
          'fury onset',
          'defeat: inflate',
          'defeat: burst',
          'defeat: victory',
        ]) {
          expect(seen.keys, contains(name), reason: 'a frame of "$name"');
        }
        final names = seen.keys.toList();
        for (var i = 0; i < names.length; i++) {
          for (var j = i + 1; j < names.length; j++) {
            expect(
              differing(seen[names[i]]!, seen[names[j]]!),
              greaterThan(300),
              reason: '${names[i]} and ${names[j]} look the same',
            );
          }
        }
      });
    }, timeout: const Timeout(Duration(minutes: 8)));

    testWidgets(
      'the same fight twice draws the same frames, with every cache emptied between',
      (tester) async {
        await tester.runAsync(() async {
          await fonts();
          Future<List<Uint8List>> run() async {
            final s = stage(640);
            final frames = <Uint8List>[];
            for (final age in [1.0, 1.95, 2.8, 3.4]) {
              s.toAge(age);
              frames.add(await s.pixels());
            }
            for (final t in [.9, 1.45, 2.9, 8.9, 9.4, 10.2]) {
              s.toCombat(t);
              frames.add(await s.pixels());
            }
            return frames;
          }

          final a = await run(), b = await run();
          for (var i = 0; i < a.length; i++) {
            expect(b[i], equals(a[i]), reason: 'frame $i');
          }
          KingCooKit.clearCaches();
          final c = await run();
          for (var i = 0; i < a.length; i++) {
            expect(c[i], equals(a[i]), reason: 'frame $i, cold caches');
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 6)),
    );
  });

  // ------------------------------------------------------ the cap's fall --

  group('the cap that falls off', () {
    for (final reduced in [false, true]) {
      for (final fury in [false, true]) {
        testWidgets(
          'leaves the head with no pop${reduced ? ' (Reduced Motion)' : ''}${fury ? ' in fury' : ''}',
          (tester) async {
            await tester.runAsync(() async {
              final s = stage(800, reduced: reduced);
              s.toCombat(3.0);
              if (fury) s.hit(150);
              s.toCombat(fury ? 6.0 : 5.0);
              s.hit(1000);
              final at = s.boss.defeatedAt!;
              // The last instant the rig wears it, and the first without.
              s.boss.age = at + .2999;
              final before = await stagePass(s, reduced: reduced);
              s.boss.age = at + .3;
              final after = await stagePass(s, reduced: reduced);
              final moved = differing(before, after);
              // The cap alone: the navy pixels (nothing else of his is navy)
              // do not move between the last frame the rig wears it and the
              // first the stage falls it.
              int navyMoved() {
                var n = 0;
                for (var i = 0; i < before.length; i += 4) {
                  bool navy(Uint8List p) =>
                      p[i + 3] > 200 && p[i + 2] > p[i] + 25 && p[i] < 110;
                  if (navy(before) != navy(after)) n++;
                }
                return n;
              }

              final capMoved = navyMoved();
              // ignore: avoid_print
              print(
                'cap hand-off ${reduced ? 'RM ' : ''}${fury ? 'fury ' : ''}: $capMoved cap pixels and $moved pixels in all differ over .0001 s',
              );
              expect(
                capMoved,
                lessThan(60),
                reason: 'the cap carries on from exactly where it sat',
              );
              expect(moved, lessThan(400));
              final m = motion(s, reduced: reduced);
              final leave = KingCooPose(s.boss, m, at: at + .3);
              final wore = KingCooPose(s.boss, m, at: at + .2999);
              final a = KingCooBossRig.capAt(leave);
              final b = KingCooBossRig.capAt(wore);
              expect((a.at - b.at).distance, lessThan(.01));
              expect((a.angle - b.angle).abs(), lessThan(.01));
              expect(wore.capOff, isFalse);
              expect(leave.capOff, isTrue);
            });
          },
        );
      }
    }

    testWidgets(
      'lands on the ground line, settles, and clears with the title',
      (tester) async {
        await tester.runAsync(() async {
          final s = stage(800);
          s.toCombat(3.0);
          s.hit(1000);
          final at = s.boss.defeatedAt!;
          Future<Rect> capBox(double d, {bool reduced = false}) async {
            s.boss.age = at + d;
            // The cap lies in the middle of the screen (the fix round): its
            // navy crown, in the ground band and the columns round x .5 w (the
            // pigeons at its sides and the badge above it are elsewhere).
            final px = await stagePass(s, reduced: reduced);
            final navy = Uint8List(px.length);
            for (var y = 262; y < 340; y++) {
              for (var x = 320; x < 480; x++) {
                final i = (y * 800 + x) * 4;
                navy[i + 3] =
                    px[i + 3] > 220 &&
                        px[i + 2] > px[i] + 25 &&
                        px[i] < 110 &&
                        px[i + 2] < 200
                    ? 255
                    : 0;
              }
            }
            return boundsOf(navy, 800, 360, min: 100);
          }

          // (The badge K7 floats up is navy too, but it floats above this band.)
          final landed = await capBox(3.05);
          expect(landed, isNot(Rect.zero));
          expect(landed.bottom, lessThan(360 * .865 + 6));
          expect(landed.bottom, greaterThan(360 * .865 - 30));
          expect((landed.center.dx - 400).abs(), lessThan(30), reason: 'in the middle');
          final later = await capBox(3.09);
          expect((later.center - landed.center).distance, lessThan(12));
          // Reduced Motion shows it on the ground as well (a cross-fade).
          final grounded = await capBox(2.4, reduced: true);
          expect(grounded, isNot(Rect.zero));
          // When it shows: from the instant it leaves, until the title.
          double fadeAt(double d, bool reduced) {
            s.boss.age = at + d;
            return KingCooStaging.capFade(motion(s, reduced: reduced));
          }

          expect(fadeAt(.29, false), 0);
          expect(fadeAt(.31, false), 1);
          expect(fadeAt(3.0, false), 1);
          expect(fadeAt(3.35, false), allOf(greaterThan(0), lessThan(1)));
          expect(fadeAt(3.7, false), 0);
          expect(fadeAt(.29, true), 0);
          expect(fadeAt(1.0, true), 1);
          expect(
            fadeAt(2.0, true),
            1,
            reason: 'Reduced Motion shows it on the ground too (the payoff)',
          );
          expect(fadeAt(3.7, true), 0);
          expect(KingCooStaging.capFade(motion(stage(800))), 0);
        });
      },
    );
  });

  // ------------------------------------------------ hooks and budgets --

  group('layers, hooks and budgets', () {
    testWidgets('his stage is the encounter\'s: early dispatch, never the Baron\'s', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final s = stage(800);
        for (final t in [2.0, 8.9]) {
          s.toCombat(t);
          final whole = await rawPixels(800, 360, (c) {
            BossArt.paint(c, const Size(800, 360), s.sim, reducedMotion: false);
          });
          final direct = await stagePass(s);
          expect(
            whole,
            equals(direct),
            reason: 'BossEncounterArt.paint is KingCooStaging.paint at $t',
          );
        }
        // The Gargoyle's branch is untouched: still its own stub, not his.
        final gargoyle = SkyBoss(
          number: 7,
          x: 1.4,
          kind: BossKind.searchlightGargoyle,
          cinematic: true,
        )..age = 8;
        final sim = stage(800).sim..boss = gargoyle;
        final px = await rawPixels(800, 360, (c) {
          BossEncounterArt.paint(
            c,
            const Size(800, 360),
            sim,
            BossMotion(gargoyle, reducedMotion: false),
          );
        });
        expect(px.any((v) => v != 0), isTrue);
      });
    });

    testWidgets('the sky\'s own light reaches him', (tester) async {
      await tester.runAsync(() async {
        final s = stage(800);
        s.toCombat(2.0);
        final lit = KingCooStaging.poseOf(s.sim, motion(s), h).light;
        expect(lit.dark, greaterThan(.5), reason: 'New York at night is dark');
        Future<Uint8List> under(KingCooSkyLight light) => rawPixels(800, 360, (
          c,
        ) {
          final m = motion(s);
          final pose = KingCooPose(s.boss, m, light: light);
          final body = KingCooStaging.heart(m, h);
          c.translate(body.dx, body.dy);
          c.scale(h * SkyBoss.radius);
          KingCooBossRig.paintPose(c, pose);
        });
        expect(
          differing(
            await under(lit),
            await under(regionLight(WorldRegion.egypt)),
          ),
          greaterThan(500),
        );
      });
    });

    testWidgets('the name card is his own, carries the campaign quote, and says GUARDIAN', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await fonts();
        final s = stage(800);
        s.toAge(3.6);
        expect(
          BossEncounterArt.bossLine(s.sim),
          '“Nobody flies till the bread cart is found!”',
        );
        expect(BossEncounterArt.nameCardEyebrow(s.boss), 'GUARDIAN');
        final withQuote = await rawPixels(800, 360, (c) {
          BossEncounterArt.foreground(
            c,
            const Size(800, 360),
            s.sim,
            motion(s),
          );
        });
        // Endless has no level and no quote: his own card then says the very
        // same words (K7 pins them equal to the catalog's line).
        final fresh = FlightSimulation(
          rules: TapFlyMode(),
          practice: true,
          course: FlightCourse.starTrail,
        )..boss = s.boss;
        expect(BossEncounterArt.bossLine(fresh), isNull);
        final without = await rawPixels(800, 360, (c) {
          BossEncounterArt.foreground(
            c,
            const Size(800, 360),
            fresh,
            motion(s),
          );
        });
        expect(differing(withQuote, without), 0);
        // The line the foreground hands the card is exactly the campaign's:
        // the card drawn directly with it is the foreground's card, and with
        // another line it is not.
        Future<Uint8List> card(String? line) => rawPixels(800, 360, (c) {
          KingCooEncounterUi.nameCard(
            c,
            const Size(800, 360),
            s.boss,
            motion(s),
            birdY: s.sim.birdY,
            line: line,
          );
        });
        final direct = await card(BossEncounterArt.bossLine(s.sim));
        final other = await card('“Move along, nothing to see.”');
        expect(differing(direct, other), greaterThan(300));
        expect(
          differing(direct, await card(null)),
          0,
          reason: 'the campaign quote is the entrance line',
        );
        // And the foreground carries that card (and the letterbox).
        expect(differing(withQuote, direct), greaterThan(1000));
        // The shared card never stands in: before the COO! there is none.
        final before = stage(800)..toAge(2.0);
        final early = await rawPixels(800, 360, (c) {
          BossEncounterArt.foreground(
            c,
            const Size(800, 360),
            before.sim,
            motion(before),
          );
        });
        var cardPixels = 0;
        for (var y = 60; y < 200; y++) {
          for (var x = 60; x < 330; x++) {
            if (early[(y * 800 + x) * 4 + 3] > 0) cardPixels++;
          }
        }
        expect(cardPixels, lessThan(60), reason: 'no card before the COO!');
      });
    });

    testWidgets(
      'at most two bounded layers, no blur, and a whole fight builds no shader after the first frame',
      (tester) async {
        await tester.runAsync(() async {
          // From cold: the arrival warms every cache of his.
          KingCooKit.clearCaches();
          KingCooStaging.forgetWarmth();
          final s = stage(800);
          var worstLayers = 0, worstDraws = 0, blurs = 0, combatLayers = 0;
          var worstAt = '';
          int? built;
          var lastBuilt = 0;
          await script(
            s,
            (label) async {
              final rec = ui.PictureRecorder();
              final counting = Counting(Canvas(rec));
              KingCooStaging.paint(
                counting,
                const Size(800, 360),
                s.sim,
                motion(s),
              );
              rec.endRecording().dispose();
              if (built != null && KingCooKit.shadersBuilt > lastBuilt) {
                // ignore: avoid_print
                print('  shader built at $label ${s.boss.age.toStringAsFixed(2)}');
              }
              lastBuilt = KingCooKit.shadersBuilt;
              built ??= KingCooKit.shadersBuilt;
              final layers = counting.counts['saveLayer'] ?? 0;
              if (layers > worstLayers) worstLayers = layers;
              if (label == 'combat') combatLayers += layers;
              blurs += counting.counts['maskFilter'] ?? 0;
              if (counting.draws > worstDraws) {
                worstDraws = counting.draws;
                worstAt = '$label ${s.boss.age.toStringAsFixed(2)}';
              }
            },
            arrivalStep: .2,
            combatStep: .25,
            defeatStep: .1,
          );
          final late = KingCooKit.shadersBuilt - built!;
          // ignore: avoid_print
          print(
            'staging pass: worst $worstDraws draws at $worstAt, $worstLayers layers, shaders built after the first frame: $late',
          );
          expect(worstLayers, lessThanOrEqualTo(2));
          expect(combatLayers, 0, reason: 'no layer in combat');
          expect(blurs, 0);
          expect(worstDraws, lessThanOrEqualTo(400));
          expect(late, 0, reason: 'prewarmed as the arrival began');
        });
      },
      timeout: const Timeout(Duration(minutes: 8)),
    );

    testWidgets(
      'Reduced Motion: idle frames identical across ages, every state distinguishable',
      (tester) async {
        await tester.runAsync(() async {
          final s = stage(800, reduced: true);
          // (The hover's height is the rules': it moves with the clock even
          // when the figure does not.)
          s.toCombat(5.9);
          s.boss.y = .5;
          final a = await stagePass(s, reduced: true);
          s.toCombat(7.2);
          s.boss.y = .5;
          final b = await stagePass(s, reduced: true);
          expect(differing(a, b), 0, reason: 'a calm figure holds still');
          final states = <String, Uint8List>{'idle': a};
          s.toCombat(8.7);
          states['inhale'] = await stagePass(s, reduced: true);
          s.toCombat(9.3);
          states['whistle'] = await stagePass(s, reduced: true);
          final t = stage(800, reduced: true)..toCombat(1.25);
          states['wind-up'] = await stagePass(t, reduced: true);
          final u = stage(800, reduced: true)..toCombat(3.0);
          u.hit(10);
          states['hit'] = await stagePass(u, reduced: true);
          final names = states.keys.toList();
          for (var i = 0; i < names.length; i++) {
            for (var j = i + 1; j < names.length; j++) {
              expect(
                differing(states[names[i]]!, states[names[j]]!),
                greaterThan(100),
                reason: '${names[i]} vs ${names[j]}',
              );
            }
          }
          // The arrival: no flash, a 0.25 s cross-fade, no jolt.
          final r = stage(640, reduced: true);
          r.toAge(1.95);
          final early = await stagePass(r, reduced: true);
          r.toAge(2.4);
          final late = await stagePass(r, reduced: true);
          expect(differing(early, late), greaterThan(300));
          r.toAge(2.7);
          final m = motion(r, reduced: true);
          expect(
            KingCooStaging.rumble(KingCooStaging.poseOf(r.sim, m, h), m, h),
            Offset.zero,
          );
        });
      },
    );

    testWidgets(
      'his squadron comes out from behind him, and CombatArt takes over where they are clear',
      (tester) async {
        await tester.runAsync(() async {
          final s = stage(800);
          s.toCombat(9.35);
          final pigeons = s.sim.enemies.where((e) => e.squad).toList();
          expect(pigeons, isNotEmpty, reason: 'the whistle released a squadron');
          final boss = s.boss;
          expect(KingCooStaging.squadBehind(boss, pigeons.first, h), isTrue);
          expect(KingCooStaging.squadBehind(null, pigeons.first, h), isFalse);
          final over = await rawPixels(800, 360, (c) {
            CombatArt.paint(c, h, s.sim, reducedMotion: false);
          });
          var behindPx = 0;
          for (var y = 0; y < 360; y++) {
            for (var x = (boss.x * h - 20).round(); x < 800; x++) {
              if (over[(y * 800 + x) * 4 + 3] > 0) behindPx++;
            }
          }
          expect(behindPx, 0, reason: 'CombatArt skips the pigeons at his back');
          final under = await stagePass(s);
          expect(under.any((v) => v != 0), isTrue);
          s.toCombat(10.9);
          final far = s.sim.enemies.where((e) => e.squad).toList();
          expect(far, isNotEmpty);
          expect(
            far.any((e) => !KingCooStaging.squadBehind(boss, e, h)),
            isTrue,
            reason: 'the ones that have flown clear are CombatArt\'s again',
          );
          final drawn = await rawPixels(800, 360, (c) {
            CombatArt.paint(c, h, s.sim, reducedMotion: false);
          });
          expect(drawn.any((v) => v != 0), isTrue);
        });
      },
    );

    testWidgets('the keepsake is the police cap he loses, fitted to any box', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final box in [
          const Rect.fromLTWH(20, 20, 200, 120),
          const Rect.fromLTWH(10, 10, 90, 90),
        ]) {
          final px = await rawPixels(260, 160, (c) {
            CampaignHeadwear.paint(c, box, BossKind.kingCoo);
          });
          var navy = 0;
          for (var i = 0; i < px.length; i += 4) {
            if (px[i + 3] > 40 && px[i + 2] > px[i] + 30 && px[i + 2] < 190) {
              navy++;
            }
          }
          final got = boundsOf(px, 260, 160, min: 40);
          expect(got, isNot(Rect.zero));
          expect(
            box.inflate(2).contains(got.topLeft) &&
                box.inflate(2).contains(got.bottomRight),
            isTrue,
            reason: 'inside its box: $got vs $box',
          );
          expect(got.width, greaterThan(box.width * .6));
          expect(navy, greaterThan(150), reason: 'a navy cap');
        }
      });
    });
  });

  // ------------------------------------------------------- audio sync --

  group('visual strikes against the audio cues', () {
    test('every cue lands on the beat it sounds for (offsets printed)', () {
      final s = stage(800);
      final cues = BossAudioCues();
      final fired = <String, List<double>>{};
      const dt = 1 / 120;
      var guard = 0;
      void watch() {
        for (final cue in cues.advance(s.sim.boss)) {
          fired.putIfAbsent(cue, () => []).add(s.sim.boss!.age);
        }
      }

      watch();
      void until(bool Function() done) {
        while (!done() && guard++ < 400000) {
          s.run(dt);
          watch();
        }
      }

      until(
        () => s.boss.phase == BossPhase.attacking && s.boss.combatTime > 4.0,
      );
      final boss = s.boss;
      final lob = boss.lobs.first;
      const tick = 1.5 * dt;
      KingCooPose at(double age) =>
          KingCooPose(boss, BossMotion(boss, reducedMotion: false), at: age);
      final reveal = fired['boss_reveal']!.first;
      final roar = fired['coo_shout']!.first;
      // The reveal cue rings 0.03 s ahead of the flash (it was 0.25 s early,
      // at SkyBoss.revealAt: the audio fix round).
      expect(reveal, closeTo(KingCooTimeline.flashAt - .03, tick));
      expect(
        roar,
        closeTo(KingCooTimeline.cooAt, tick),
        reason: 'the COO! and its sound are one beat',
      );
      expect(fired['boss_charge']!.first, closeTo(lob.lockedAt, tick));
      expect(fired['crumb_throw']!.first, closeTo(lob.launchAt, tick));
      expect(fired['crumb_splat']!.first, closeTo(lob.burstAt, tick));
      expect(at(lob.lockedAt - .02).windup, 0);
      expect(at(lob.lockedAt + .1).windup, greaterThan(0));
      expect(
        (KingCooBossRig.bombOrigin(at(lob.launchAt)) -
                KingCooBossRig.lobReleaseAt(at(lob.launchAt)))
            .distance,
        lessThan(KingCooLayout.lobReleaseTolerance + .001),
        reason: 'the bomb leaves the wing tip on the throw cue',
      );
      until(() => boss.combatTime > 10.6);
      final puff = fired['coo_puff']!.first;
      final whistle = fired['coo_whistle']!.first;
      expect(puff, closeTo(boss.arrivalDuration + KingCoo.puffAt, tick));
      expect(at(puff - .05).puff, lessThan(.02));
      expect(at(puff + .15).puff, greaterThan(.1));
      expect(whistle, closeTo(boss.arrivalDuration + KingCoo.whistleAt, tick));
      expect(at(whistle - .05).blast, 0);
      expect(at(whistle + .05).blast, greaterThan(0));
      expect(fired['squad_flutter']!.first, closeTo(whistle, tick));
      s.hit(10);
      watch();
      expect(fired['boss_hit']!.last, closeTo(boss.lastHitAt, tick));
      expect(at(boss.lastHitAt + .03).flash, greaterThan(.3));
      // A pop before the next whistle.
      final next = 14 * ((boss.combatTime ~/ 14) + 1) + 8.2;
      s.toCombat(next);
      watch();
      s.hit(30);
      watch();
      final pop = fired['coo_pop']!.first;
      expect(pop, closeTo(boss.poppedAt!, tick));
      expect(at(boss.poppedAt! - .02).deflate, lessThan(.05));
      expect(at(boss.poppedAt! + .1).deflate, greaterThan(.1));
      s.hit(1000);
      watch();
      final dead = boss.defeatedAt!;
      for (var i = 0; i < 240 + 8; i++) {
        s.run(dt);
        watch();
      }
      expect(fired['boss_break']!.first, closeTo(dead, tick));
      expect(
        fired['coo_inflate']!.first - dead,
        closeTo(KingCooTimeline.hitStop, 2 * tick),
        reason: 'the chest inflates when the hit-stop ends',
      );
      expect(
        fired['coo_defeat']!.first - dead,
        closeTo(SkyBoss.burstAt, 2 * tick),
      );
      // ignore: avoid_print
      print(
        'AUDIO SYNC (cue age vs the beat it sounds for; rules at 120 Hz)\n'
        '  boss_reveal  ${reveal.toStringAsFixed(3)} s vs the flash ${KingCooTimeline.flashAt} s: '
        'cue ${(KingCooTimeline.flashAt - reveal).toStringAsFixed(2)} s ahead (was 0.25 s early)\n'
        '  coo_shout    ${roar.toStringAsFixed(3)} s vs the COO! ${KingCooTimeline.cooAt} s: in sync, 0.85 s to his beak\'s 0.8 s swell\n'
        '  boss_charge / crumb_throw / crumb_splat: in sync with the lock, the toss, the burst\n'
        '  coo_puff / coo_whistle: in sync with the swell and the blast; squad_flutter shares the whistle tick, its file is silent for 0.10 s (the spec\'s +0.10 s)\n'
        '  coo_pop ${pop.toStringAsFixed(3)} s: in sync with the squash; coo_defeat at the pop (0.85 s)',
      );
    });
  });

  if (_video) {
    for (final width in [800.0, 640.0]) {
      testWidgets('a whole encounter as frames ${width.toInt()}', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final s = stage(width);
          final dir = Directory('${_folder.path}/video-${width.toInt()}')
            ..createSync(recursive: true);
          for (final f in dir.listSync()) {
            f.deleteSync();
          }
          var n = 0;
          Future<void> shot() async {
            final image = await s.frame();
            File('${dir.path}/${(n++).toString().padLeft(4, '0')}.png')
                .writeAsBytesSync(await png(image));
            image.dispose();
          }

          // The bird wanders up and down, never hurt, so the rings lock at
          // different heights and the lanes read.
          void bird() => s.birdY = .5 + .2 * math.sin(s.sim.elapsed * .8);
          final events = <double, void Function()>{
            4.0: () => s.hit(10),
            5.5: () => s.hit(10),
            21.95: () => s.hit(10),
            22.15: () => s.hit(10),
            22.35: () => s.hit(10),
            30.0: () => s.hit(100),
            52.0: () => s.hit(1000),
          };
          final fired = <double>{};
          while (true) {
            bird();
            s.run(1 / 30);
            final c = s.boss.combatTime;
            for (final e in events.entries) {
              if (c >= e.key && fired.add(e.key)) e.value();
            }
            await shot();
            // (The rules clear the boss as its departure ends.)
            if (s.sim.boss == null) break;
            if (n > 30 * 90) break;
          }
        });
      }, timeout: const Timeout(Duration(minutes: 20)));
    }
  }

  final fixTag = Platform.environment['KING_COO_FIX'];
  if (fixTag != null) {
    // The fix round's before/after frames (KING_COO_FIX=before|after).
    for (final width in [640.0, 800.0]) {
      final w = width.toInt();
      testWidgets('fix frames $fixTag $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final dir = Directory('build/visual-review/king-coo-fix/$fixTag')
            ..createSync(recursive: true);
          Future<void> save(String name, Stage s) async {
            final image = await s.frame();
            File('${dir.path}/$name-$w.png').writeAsBytesSync(await png(image));
            image.dispose();
          }

          var s = stage(width);
          for (final a in [2.9, 3.1, 3.3, 3.5, 3.8]) {
            s.toAge(a);
            await save('card-${a.toStringAsFixed(2)}', s);
          }
          s = stage(width);
          for (final t in [7.4, 7.9, 8.3, 8.7, 9.0, 9.3]) {
            s.toCombat(t);
            await save('puff-${t.toStringAsFixed(2)}', s);
          }
          for (final t in [9.5, 9.8, 10.3, 10.9]) {
            s.toCombat(t);
            await save('squad-${t.toStringAsFixed(2)}', s);
          }
          s = stage(width);
          s.toCombat(3.0);
          s.hit(150);
          s.toCombat(5.0);
          s.hit(1000);
          final at = s.boss.defeatedAt!;
          for (final d in [.6, .9, 1.0, 1.2, 1.5, 1.8, 2.2, 2.6, 3.0, 3.4]) {
            s.toAge(at + d);
            await save('victory-${d.toStringAsFixed(2)}', s);
          }
        });
      }, timeout: const Timeout(Duration(minutes: 6)));
    }
  }

  if (_review) {
    for (final width in [640.0, 800.0]) {
      final w = width.toInt();
      testWidgets('review arrival $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final s = stage(width);
          final frames = <(String, ui.Image)>[];
          for (final age in [
            .6, 1.2, 1.6, 1.85, 1.95, 2.05, //
            2.3, 2.55, 2.75, 3.0, 3.6, 4.4,
          ]) {
            s.toAge(age);
            frames.add(('arrival ${age.toStringAsFixed(2)} s', await s.frame()));
          }
          await sheet('arrival-$w', frames, cols: 3);
        });
      }, timeout: const Timeout(Duration(minutes: 6)));

      testWidgets('review after frames $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final dir = Directory('${_folder.path}/after')
            ..createSync(recursive: true);
          final s = stage(width);
          Future<void> save(String name) async {
            final image = await s.frame();
            File('${dir.path}/$name-$w.png').writeAsBytesSync(await png(image));
            image.dispose();
          }

          for (final a in [1.85, 2.75, 3.4]) {
            s.toAge(a);
            await save('arrival-$a');
          }
          for (final t in [2.4, 8.9, 9.35]) {
            s.toCombat(t);
            await save('combat-$t');
          }
        });
      }, timeout: const Timeout(Duration(minutes: 4)));

      testWidgets('review close-ups $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final dir = Directory('${_folder.path}/close')
            ..createSync(recursive: true);
          Future<void> save(String name, Stage s) async {
            final image = await s.frame();
            File('${dir.path}/$name-$w.png').writeAsBytesSync(await png(image));
            image.dispose();
          }

          var s = stage(width);
          for (final a in [1.2, 1.5, 1.85, 1.93, 1.97, 2.02, 2.1, 2.3, 2.5, 2.7, 2.85, 3.1]) {
            s.toAge(a);
            await save('arrival-${a.toStringAsFixed(2)}', s);
          }
          s = stage(width);
          for (final t in [1.3, 1.45, 1.55]) {
            s.toCombat(t);
            await save('lob-${t.toStringAsFixed(2)}', s);
          }
          for (final t in [8.3, 9.3, 9.45, 9.6, 9.8, 10.5]) {
            s.toCombat(t);
            await save('whistle-${t.toStringAsFixed(2)}', s);
          }
          s.toCombat(24.0);
          await save('fury-picket-24.00', s);

          s = stage(width);
          s.toCombat(3.0);
          s.hit(150);
          s.toCombat(5.0);
          s.hit(1000);
          final at = s.boss.defeatedAt!;
          for (final d in [.06, .3, .6, .86, .95, 1.1, 1.4, 1.7, 2.1, 2.5, 3.2]) {
            s.toAge(at + d);
            await save('defeat-${d.toStringAsFixed(2)}', s);
          }
        });
      }, timeout: const Timeout(Duration(minutes: 6)));

      testWidgets('review lob $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final s = stage(width);
          final frames = <(String, ui.Image)>[];
          for (final t in [
            .15, .62, .9, 1.25, 1.42, 1.5, //
            1.9, 2.5, 2.75, 2.95, 3.4, 3.9,
          ]) {
            s.toCombat(t);
            frames.add(('combat ${t.toStringAsFixed(2)} s', await s.frame()));
          }
          await sheet('lob-$w', frames, cols: 3);
        });
      }, timeout: const Timeout(Duration(minutes: 6)));

      testWidgets('review whistle $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final s = stage(width);
          final frames = <(String, ui.Image)>[];
          for (final t in [
            7.7, 8.3, 8.9, 9.25, 9.5, 9.9, //
            10.4, 10.9, 11.4, 12.0, 12.8, 13.6,
          ]) {
            s.toCombat(t);
            frames.add(('combat ${t.toStringAsFixed(2)} s', await s.frame()));
          }
          await sheet('whistle-$w', frames, cols: 3);
        });
      }, timeout: const Timeout(Duration(minutes: 6)));

      testWidgets('review picket $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final s = stage(width);
          final frames = <(String, ui.Image)>[];
          const base = 14.0;
          for (final t in [7.7, 8.9, 9.3, 9.9, 10.5, 11.2]) {
            s.toCombat(base + t);
            frames.add(('cycle 1 +${t.toStringAsFixed(2)} s', await s.frame()));
          }
          await sheet('picket-$w', frames, cols: 3);
        });
      }, timeout: const Timeout(Duration(minutes: 6)));

      testWidgets('review pop and cancel $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final s = stage(width);
          s.toCombat(8.2);
          s.hit(30);
          final frames = <(String, ui.Image)>[];
          final at = s.boss.age;
          for (final dt in [.05, .15, .3, .5, .8, 1.2, 1.6, 2.2]) {
            s.toAge(at + dt);
            frames.add(('pop +${dt.toStringAsFixed(2)} s', await s.frame()));
          }
          await sheet('pop-$w', frames, cols: 4);
        });
      }, timeout: const Timeout(Duration(minutes: 6)));

      testWidgets('review hit and fury $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final s = stage(width);
          s.toCombat(4.0);
          s.hit(10);
          final frames = <(String, ui.Image)>[];
          var at = s.boss.age;
          for (final dt in [.03, .08, .2, .4]) {
            s.toAge(at + dt);
            frames.add(('hit +${dt.toStringAsFixed(2)} s', await s.frame()));
          }
          s.toCombat(6.0);
          s.hit(150);
          at = s.boss.age;
          for (final dt in [.05, .15, .3, .6, 1.0, 2.0]) {
            s.toAge(at + dt);
            frames.add(('fury +${dt.toStringAsFixed(2)} s', await s.frame()));
          }
          s.toCombat(14.0 + 8.3);
          frames.add(('fury inhale', await s.frame()));
          s.toCombat(14.0 + 1.2);
          s.toCombat(14.0 + 1.4);
          frames.add(('fury toss', await s.frame()));
          s.toCombat(14.0 + 2.6);
          frames.add(('fury bracket', await s.frame()));
          await sheet('hit-fury-$w', frames, cols: 4);
        });
      }, timeout: const Timeout(Duration(minutes: 6)));

      testWidgets('review defeat $w', (tester) async {
        await tester.runAsync(() async {
          await fonts();
          final s = stage(width);
          s.toCombat(3.0);
          s.hit(150);
          s.toCombat(5.0);
          s.hit(1000);
          expect(s.boss.phase, BossPhase.defeated);
          final at = s.boss.defeatedAt!;
          final frames = <(String, ui.Image)>[];
          for (final d in [
            .05, .2, .3, .5, .7, .84, //
            .9, 1.0, 1.2, 1.5, 1.8, 2.2,
            2.6, 3.0, 3.5, 4.0,
          ]) {
            s.toAge(at + d);
            frames.add(('defeat +${d.toStringAsFixed(2)} s', await s.frame()));
          }
          await sheet('defeat-$w', frames, cols: 4);
        });
      }, timeout: const Timeout(Duration(minutes: 6)));
    }
  }
}
