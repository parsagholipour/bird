import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/gargoyle_story_art.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/domain/sky_boss.dart';

import 'gargoyle_stage_support.dart';

/// Review generators for the Gargoyle's fix round (G8): data and frames for
/// the evidence sheets. Skipped unless `GARGOYLE_FIX_REVIEW=<tag>` ("old" or
/// "new": run once with the constants the first reviewers saw, once with the
/// fix; the composer in the report puts them side by side).
final _tag = Platform.environment['GARGOYLE_FIX_REVIEW'];
final _folder = Directory('build/visual-review/g8-fix');

double _lin(int v) {
  final c = v / 255;
  return c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
}

Float64List _luminance(Uint8List px) {
  final o = Float64List(px.length ~/ 4);
  for (var i = 0; i < o.length; i++) {
    o[i] = .2126 * _lin(px[i * 4]) + .7152 * _lin(px[i * 4 + 1]) + .0722 * _lin(px[i * 4 + 2]);
  }
  return o;
}

SkyBoss _rapid(double t, double gap, {bool latch = true}) {
  final b = bossAt(t);
  final hits = [for (var k = 0; k < 8; k++) 7.0 + k * gap].where((h) => h <= t).toList();
  if (hits.isNotEmpty) {
    b.lastHitAt = b.age - (t - hits.last);
    b.lastDamage = 10;
    if (latch && hits.length > 1) b.previousHitAt = b.age - (t - hits[hits.length - 2]);
  }
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('fix review', skip: _tag == null ? 'set GARGOYLE_FIX_REVIEW=old|new' : false, () {
    testWidgets('flash rate: the area that brightens by .10 within .1 s over rapid fire, and four hit frames', (tester) async {
      await tester.runAsync(() async {
        _folder.createSync(recursive: true);
        final latch = _tag == 'new';
        final frames = <Float64List>[];
        const fps = 30.0;
        final times = <double>[];
        for (var t = 6.8; t < 9.4; t += 1 / fps) {
          final b = _rapid(t, .3, latch: latch);
          frames.add(_luminance(await raster((c) => encounter(c, b, 640), 640)));
          times.add(t);
        }
        final n = frames.first.length;
        final area = <double>[];
        for (var i = 0; i < frames.length; i++) {
          if (i < 3) {
            area.add(0);
            continue;
          }
          var cnt = 0;
          for (var p = 0; p < n; p++) {
            if (frames[i][p] - frames[i - 3][p] >= .10) cnt++;
          }
          area.add(cnt / n);
        }
        File('${_folder.path}/flash-$_tag.json').writeAsStringSync(jsonEncode({'t': times, 'area': area}));
        // Four hit frames in the real game over New York's night.
        final s = await stage(tester, 640);
        s.runTo(s.boss.arrivalDuration);
        final out = <ui.Image>[];
        for (final hit in const [7.0, 7.3, 7.6, 7.9]) {
          s.cycleTo(0, hit + .05);
          final b = s.boss;
          b.lastHitAt = b.age - .05;
          b.lastDamage = 10;
          b.previousHitAt = latch && hit > 7.0 ? b.age - .05 - .3 : double.negativeInfinity;
          final img = await s.render();
          out.add(img);
          File('${_folder.path}/flash-$_tag-${hit.toStringAsFixed(1)}.png').writeAsBytesSync(await png(img));
        }
        for (final i in out) {
          i.dispose();
        }
      });
    }, timeout: const Timeout(Duration(minutes: 6)));

    testWidgets('hand-off: frames around the beam\'s ignition in the real game', (tester) async {
      await tester.runAsync(() async {
        _folder.createSync(recursive: true);
        final s = await stage(tester, 640);
        s.runTo(s.boss.arrivalDuration);
        s.birdY = .5;
        s.cycleTo(0, 1.9);
        s.birdY = .28;
        s.cycleTo(0, 3.4);
        s.birdY = .8;
        for (final x in const [3.48, 3.52, 3.54, 3.58, 3.62, 3.68]) {
          s.cycleTo(0, x);
          final img = await s.render();
          File('${_folder.path}/handoff-$_tag-${x.toStringAsFixed(2)}.png').writeAsBytesSync(await png(img));
          img.dispose();
        }
      });
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('blade snap: every blade\'s stroke through a re-hit at 120 Hz', () {
      final latch = _tag == 'new';
      final rows = <List<double>>[];
      for (var t = 7.1; t < 7.7; t += 1 / 120) {
        final b = _rapid(t, .3, latch: latch);
        final p = GargoylePose(b, motion(b));
        rows.add([t, ...p.nearFan.strokes, ...p.farFan.strokes]);
      }
      _folder.createSync(recursive: true);
      File('${_folder.path}/blades-$_tag.json').writeAsStringSync(jsonEncode(rows));
    });

    testWidgets('the emblem at the map\'s, the route mark\'s and the keepsake\'s sizes, old and new', (tester) async {
      await tester.runAsync(() async {
        _folder.createSync(recursive: true);
        const k = 4.0;
        final rec = ui.PictureRecorder();
        final c = ui.Canvas(rec);
        c.scale(k);
        c.drawRect(const ui.Rect.fromLTWH(0, 0, 330, 340), ui.Paint()..color = const ui.Color(0xff101223));
        // Row 0: the old emblem on the old placeholder field; row 1: the new one on the indigo; row 2: the new with lensOnly; row 3: on the cream route plate.
        void old(ui.Canvas c) {
          const lens = ui.Offset(.28, .4);
          final ring = GargoyleKit.octagon(.4);
          c.save();
          c.translate(lens.dx, lens.dy);
          c.drawPath(ring, GargoyleKit.fill(GargoylePalette.brass));
          c.drawPath(ring, GargoyleKit.line(GargoylePalette.ink, .07));
          c.drawCircle(ui.Offset.zero, .27, GargoyleKit.fill(GargoylePalette.lampAmber));
          c.drawCircle(ui.Offset.zero, .27, GargoyleKit.line(GargoylePalette.ink, .045));
          c.drawCircle(const ui.Offset(-.04, -.04), .12, GargoyleKit.fill(GargoylePalette.lampCore));
          c.restore();
          GargoyleBossRig.visorPaint(c);
        }

        const oldReach = ui.Rect.fromLTRB(-.78, -.28, .88, .98);
        var y = 4.0;
        for (final (row, ground) in const [(0, ui.Color(0xff6f86a8)), (1, ui.Color(0xff2f3a6b)), (2, ui.Color(0xff2f3a6b)), (3, ui.Color(0xfffff2d6))]) {
          var x = 4.0;
          for (final (w, h) in const [(22.0, 17.0), (26.0, 20.0), (29.0, 22.0), (48.0, 36.0), (96.0, 72.0)]) {
            c.drawRect(ui.Rect.fromLTWH(x - 2, y - 2, w + 4, h + 4), ui.Paint()..color = ground);
            if (row == 0) {
              final sc = math.min(w / oldReach.width, h / oldReach.height);
              c.save();
              c.translate(x + w / 2, y + h / 2);
              c.scale(sc);
              c.translate(-oldReach.center.dx, -oldReach.center.dy);
              old(c);
              c.restore();
            } else if (row == 2) {
              final reach = GargoyleStoryArt.visorReach;
              final sc = math.min(w / reach.width, h / reach.height);
              c.save();
              c.translate(x + w / 2, y + h / 2);
              c.scale(sc);
              c.translate(-reach.center.dx, -reach.center.dy);
              GargoyleStoryArt.visor(c, const GargoyleTone(), true);
              c.restore();
            } else {
              CampaignHeadwear.paint(c, ui.Rect.fromLTWH(x, y, w, h), BossKind.searchlightGargoyle);
            }
            x += w + 8;
          }
          y += 80;
        }
        final pic = rec.endRecording();
        final image = await pic.toImage((330 * k).round(), (340 * k).round());
        File('${_folder.path}/emblem.png').writeAsBytesSync(await png(image));
      });
    });
  });
}
