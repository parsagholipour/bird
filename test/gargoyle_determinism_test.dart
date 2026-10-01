import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/gargoyle_beam_art.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'proof/gargoyle_stage.dart';

/// Pixels depend only on the inputs: a state renders the same pixels whatever
/// was drawn before it, in whatever order, with the caches warm, cold or
/// flooded. Gradients are built once in the part's own frame and cached by part
/// id; every tone (flash, fury, stone, darkness) is a colour filter or a flat
/// colour computed from the pose, never a shader keyed by what came first, so
/// the paint a state meets never depends on the visiting order.
///
/// The test renders many states in one order, evicts every cache with a flood
/// of junk, then renders them all again in the opposite order: a state's pixels
/// must be IDENTICAL either way. A pixel that differs is named by state.
const _w = 400, _h = 400, _ppu = 24.0;

typedef _State = (String name, GargoylePose Function() pose);

List<_State> _states() {
  final rnd = math.Random(11);
  final out = <_State>[];
  for (var i = 0; i < 40; i++) {
    final t = rnd.nextDouble() * 22 - 1;
    final fury = i % 3 == 0, slit = fury && i % 2 == 0;
    out.add((
      'qa $i (t ${t.toStringAsFixed(2)})',
      () => poseOf(
        gBoss(t, fury: fury, slit: slit, side: i.isEven ? BeamSide.high : BeamSide.low, hitAgo: i % 5 == 0 ? .08 : null, glanceAgo: i % 7 == 0 ? .05 : null),
        reduced: i % 11 == 0,
      ),
    ));
  }
  for (final (name, t) in const [
    ('perch', 1.0),
    ('flick', 4.58),
    ('warning', 3.0),
    ('sweep', 4.8),
    ('vent', 7.0),
    ('arrival stone', -3.6),
    ('arrival roar', -1.6),
  ]) {
    for (final (look, fury, hit, dark) in const [
      ('calm', false, false, .8),
      ('hit', false, true, .8),
      ('fury', true, false, .8),
      ('fury hit', true, true, 1.0),
      ('dusk', false, false, .4),
      ('day', false, true, 0.0),
    ]) {
      out.add((
        '$name $look',
        () => poseOf(gBoss(t, fury: fury, hitAgo: hit ? .1 : null), light: GargoyleSkyLight(dark: dark, sky: const ui.Color(0xff8a70a8))),
      ));
    }
  }
  for (final d in const [.2, .5, .7, .9, 1.3]) {
    out.add(('defeat $d', () => poseOf(gBoss(1.0, deadFor: d))));
  }
  return out;
}

Future<Uint8List> _px(_State s) async {
  final pose = s.$2();
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.translate(_w / 2, _h / 2 - 10);
  c.scale(_ppu);
  GargoyleBossRig.paintPose(c, pose);
  final pic = rec.endRecording();
  final img = await pic.toImage(_w, _h);
  final bytes = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return Uint8List.fromList(bytes);
}

Future<Uint8List> _frame(SkyBoss boss) async {
  final size = const ui.Size(640, 360);
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  final pose = poseOf(boss);
  final centre = bossCentre(size, boss);
  GargoyleBeamArt.under(c, size, pose, centre);
  c.save();
  c.translate(centre.dx, centre.dy);
  c.scale(size.height * SkyBoss.radius);
  GargoyleBossRig.paintPose(c, pose);
  c.restore();
  GargoyleBeamArt.over(c, size, pose, centre);
  final pic = rec.endRecording();
  final img = await pic.toImage(640, 360);
  final bytes = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return Uint8List.fromList(bytes);
}

/// Floods every cache the kit and the parts keep with junk (other ids, other
/// colours, other tones), so a later render rebuilds every paint from scratch.
Future<void> _flood(int n) async {
  final rnd = math.Random(99);
  for (var i = 0; i < n; i++) {
    GargoyleKit.cached('junk$i', () => Paint0.make());
    GargoyleKit.glow(ui.Canvas(ui.PictureRecorder()), ui.Offset.zero, 1, ui.Color(0xff000000 | rnd.nextInt(0xffffff)), .5);
  }
  GargoyleKit.clearCaches();
  for (var i = 0; i < 30; i++) {
    final pose = poseOf(gBoss(rnd.nextDouble() * 20, fury: rnd.nextBool()));
    final tone = GargoyleTone(
      flash: rnd.nextDouble(), fury: rnd.nextDouble(), heat: rnd.nextDouble(), dark: rnd.nextDouble(), stone: rnd.nextDouble(),
    );
    GargoyleBossRig.paintPose(ui.Canvas(ui.PictureRecorder()), pose.withTone(tone));
  }
}

class Paint0 {
  static ui.Paint make() => ui.Paint();
}

int _diff(Uint8List a, Uint8List b, void Function(int maxd) maxd) {
  var n = 0, m = 0;
  for (var p = 0; p < a.length; p++) {
    final d = (a[p] - b[p]).abs();
    if (d > 0) {
      if (p % 4 == 0) n++;
      m = math.max(m, d);
    }
  }
  maxd(m);
  return n;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
  });

  testWidgets('a state renders the same pixels whatever was drawn before it', (tester) async {
    await tester.runAsync(() async {
      final states = _states();
      expect(states.length, greaterThanOrEqualTo(80));
      GargoyleKit.clearCaches();
      final fwd = <int, Uint8List>{};
      for (var i = 0; i < states.length; i++) {
        fwd[i] = await _px(states[i]);
      }
      await _flood(600);
      final back = <int, Uint8List>{};
      for (var i = states.length - 1; i >= 0; i--) {
        back[i] = await _px(states[i]);
      }
      final bad = <String>[];
      for (var i = 0; i < states.length; i++) {
        var maxd = 0;
        final n = _diff(fwd[i]!, back[i]!, (m) => maxd = m);
        if (n > 0) bad.add('${states[i].$1}: $n px differ, max $maxd/255');
      }
      // ignore: avoid_print
      print('mismatching states: ${bad.length} of ${states.length}${bad.isEmpty ? '' : '\n${bad.join('\n')}'}');
      expect(bad, isEmpty, reason: 'pixels depended on the visiting order');
    });
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('beams, warning and flares render the same pixels in any order', (tester) async {
    await tester.runAsync(() async {
      final bosses = <(String, SkyBoss)>[
        ('warning HIGH', gBoss(3.2)),
        ('warning LOW', gBoss(3.3, side: BeamSide.low)),
        ('warning slit', gBoss(3.3, fury: true, slit: true)),
        ('ignite', gBoss(3.52)),
        ('sweep HIGH', gBoss(4.8)),
        ('sweep LOW', gBoss(5.5, side: BeamSide.low)),
        ('slit', gBoss(5.0, fury: true, slit: true)),
        ('fade', gBoss(6.45)),
      ];
      GargoyleKit.clearCaches();
      final fwd = [for (final b in bosses) await _frame(b.$2)];
      await _flood(400);
      final back = <Uint8List>[];
      for (final b in bosses.reversed) {
        back.insert(0, await _frame(b.$2));
      }
      for (var i = 0; i < bosses.length; i++) {
        var maxd = 0;
        final n = _diff(fwd[i], back[i], (m) => maxd = m);
        expect(n, 0, reason: '${bosses[i].$1}: $n px differ, max $maxd/255');
      }
    });
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('the same state twice in a row is the same picture', (tester) async {
    await tester.runAsync(() async {
      for (final s in _states().take(30)) {
        expect(await _px(s), await _px(s), reason: s.$1);
      }
    });
  });

  testWidgets('seeking: a pose at time t is the same whether reached forward, backward or cold', (tester) async {
    await tester.runAsync(() async {
      final times = [for (var i = 0; i < 24; i++) i * .77];
      final fwd = <Uint8List>[];
      for (final t in times) {
        fwd.add(await _px(('t$t', () => poseOf(gBoss(t)))));
      }
      GargoyleKit.clearCaches();
      for (var i = times.length - 1; i >= 0; i--) {
        final px = await _px(('t${times[i]}', () => poseOf(gBoss(times[i]))));
        expect(px, fwd[i], reason: 'seek to ${times[i]}');
      }
    });
  });
}
