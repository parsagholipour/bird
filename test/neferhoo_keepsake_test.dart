import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart' show BossKind;
import 'package:push_up_bird/game/neferhoo_kit.dart';
import 'package:push_up_bird/game/neferhoo_story_art.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/campaign_map_art.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'neferhoo_stage_support.dart';

/// The golden mask Neferhoo loses (A2, design §5.7): the keepsake stamp, the
/// map's guardian shield and the route mark all draw it through
/// `CampaignHeadwear`, fitted by its reach; under 40 px it is the bold
/// emblem (the face, the kohl eye and the long beak), larger the rig's own
/// mask; on his lapis field.

/// Gold-ish pixels (the mask's face and beak) in an RGBA raster.
int _gold(Uint8List a) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    final r = a[i], g = a[i + 1], b = a[i + 2], al = a[i + 3];
    if (al > 200 && r > 190 && g > 130 && b < 120 && r > b + 90) n++;
  }
  return n;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('his field is lapis and his name is his own', () {
    expect(CampaignHeadwear.field(BossKind.neferhoo), const ui.Color(0xff2f56d0));
    expect(CampaignHeadwear.name(BossKind.neferhoo), 'Neferhoo');
    // The map plaque's accent reads on the ink (WCAG AA for small text).
    final accent = GuardianPlaqueLook.accent(BossKind.neferhoo);
    expect(GuardianPlaqueLook.contrast(accent, SkyColors.ink), greaterThanOrEqualTo(4.5));
  });

  for (final small in [false, true]) {
    test('the ${small ? 'emblem' : 'rig\'s mask'} fills its reach and stays inside it', () async {
      const unit = 60.0, w = 400.0, h = 240.0;
      const o = ui.Offset(260, 120);
      final bytes = await raster((c) {
        c.translate(o.dx, o.dy);
        c.scale(unit);
        NeferhooStoryArt.mask(c, small: small);
      }, w, h);
      final px = inked(bytes, w.toInt())!;
      final r = ui.Rect.fromLTRB((px.left - o.dx) / unit, (px.top - o.dy) / unit, (px.right - o.dx) / unit, (px.bottom - o.dy) / unit);
      // ignore: avoid_print
      print('mask ${small ? 'emblem' : 'rig'} reach $r');
      final reach = NeferhooStoryArt.maskReach.inflate(.03);
      expect(reach.contains(r.topLeft) && reach.contains(r.bottomRight - const ui.Offset(1e-6, 1e-6)), isTrue, reason: '$r in ${NeferhooStoryArt.maskReach}');
      // ... and fills most of it (a box fitted to the reach shows the mask big).
      expect(r.width, greaterThan(NeferhooStoryArt.maskReach.width * .8));
      expect(r.height, greaterThan(NeferhooStoryArt.maskReach.height * .7));
      expect(_gold(bytes), greaterThan(small ? 3000 : 1500), reason: 'gold face and beak');
    });
  }

  test('the headwear switches to the emblem under 40 px and reads at every size', () async {
    for (final s in const [24.0, 30.0, 39.0, 41.0, 72.0]) {
      final box = ui.Rect.fromLTWH(4, 4, s, s * .75);
      final bytes = await raster((c) {
        c.drawRect(box, ui.Paint()..color = CampaignHeadwear.field(BossKind.neferhoo));
        CampaignHeadwear.paint(c, box, BossKind.neferhoo);
      }, s + 8, s + 8);
      // The gold of the face and beak is a real share of the box, never an
      // ink blob.
      expect(_gold(bytes), greaterThan(s * s * .75 * .05), reason: '$s px');
      // Nothing reaches outside the box.
      final px = inked(bytes, (s + 8).toInt())!;
      expect(box.inflate(1.5).contains(px.topLeft) && box.inflate(1.5).contains(px.bottomRight - const ui.Offset(.5, .5)), isTrue, reason: '$s: $px');
    }
    expect(NeferhooStoryArt.emblemBelow, 40);
  });

  test('the keepsake stamp and the map shield draw his mask on lapis', () async {
    for (final s in const [48.0, 72.0, 96.0]) {
      final bytes = await raster((c) => CampaignStampPainter(BossKind.neferhoo, chapter: 2).paint(c, ui.Size(s, s * 1.2)), s, s * 1.2);
      expect(_gold(bytes), greaterThan(s * s * .02), reason: 'stamp $s');
    }
    for (final look in MapNodeLook.values) {
      final bytes = await raster((c) => MapGuardianPainter(look: look, radius: 28, boss: BossKind.neferhoo).paint(c, const ui.Size(68, 74)), 68, 74);
      if (look != MapNodeLook.locked) expect(_gold(bytes), greaterThan(60), reason: '$look');
    }
  });

  test('the mask is the rig\'s own gold (one palette)', () {
    expect(NeferhooPalette.gold, const ui.Color(0xfff2b63c));
    expect(NeferhooStoryArt.field, CampaignHeadwear.field(BossKind.neferhoo));
  });
}
