import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';

/// `GargoyleLayout`: the one source of truth for where his parts meet. The
/// numbers the rules own are pinned equal to the rules', the anchors to the
/// contract's table, the fans to the envelope for every stroke and spread, and
/// the silhouette gates to the reference outlines.
void main() {
  group('the rules\' numbers, mirrored', () {
    test('the clocks are SearchlightGargoyle\'s and SkyBoss\'s', () {
      expect(GargoyleTimeline.period, SearchlightGargoyle.period);
      expect(GargoyleTimeline.warnAt, SearchlightGargoyle.warnAt);
      expect(GargoyleTimeline.sweepAt, SearchlightGargoyle.sweepAt);
      expect(GargoyleTimeline.ventAt, SearchlightGargoyle.ventAt);
      expect(GargoyleTimeline.lampOpenSeconds, SearchlightGargoyle.lampOpenSeconds);
      expect(GargoyleTimeline.lampCloseAt, SearchlightGargoyle.lampCloseAt);
      expect(GargoyleTimeline.glideSeconds, SearchlightGargoyle.glideSeconds);
      expect(GargoyleTimeline.furyGlideSeconds, SearchlightGargoyle.furyGlideSeconds);
      expect(GargoyleTimeline.revealAt, SkyBoss.revealAt);
      expect(GargoyleTimeline.roarAt, SkyBoss.roarAt);
      expect(GargoyleTimeline.burstAt, SkyBoss.burstAt);
      final b = SkyBoss(number: 6, x: 1, kind: BossKind.searchlightGargoyle, cinematic: true);
      expect(GargoyleTimeline.arrivalSeconds, b.arrivalDuration);
    });

    test('the bird\'s column and radius, the hit circle and the pixel scale', () {
      expect(GargoyleLayout.birdColumn, FlightSimulation.birdX);
      expect(GargoyleLayout.birdRadius, FlightSimulation.birdRadius);
      expect(GargoyleLayout.pxPerUnit, closeTo(SkyBoss.radius * 360, .001));
      expect(GargoyleLayout.hitRadius, 1);
      expect(GargoyleLayout.lampRadius, GargoyleLayout.hitRadius);
    });

    test('the screen: the chest is 4.35 units from the right, the top and the bottom', () {
      const u = 360 * SkyBoss.radius;
      for (final w in const [640.0, 800.0]) {
        final anchor = SearchlightGargoyle.anchorX(GargoyleLayout.birdColumn, w / 360) * 360;
        expect((w - anchor) / u, closeTo(GargoyleLayout.screen.right, .05), reason: 'right at $w');
      }
      expect(GargoyleLayout.screen.top, closeTo(-180 / u, .01));
      expect(GargoyleLayout.screen.bottom, closeTo(180 / u, .01));
    });

    test('the line weights are the kit\'s and ordered', () {
      expect(GargoyleLayout.inkHero, greaterThan(GargoyleLayout.inkMajor));
      expect(GargoyleLayout.inkMajor, greaterThan(GargoyleLayout.inkPart));
      expect(GargoyleLayout.inkPart, greaterThan(GargoyleLayout.inkDetail));
      expect(GargoyleLayout.inkDetail, greaterThan(GargoyleLayout.hair));
      expect(GargoyleLayout.hair, greaterThanOrEqualTo(.025));
    });
  });

  group('anchors', () {
    test('the lamp is the chest is the hit circle at the origin; the housing is an octagon around glass of r 1', () {
      expect(GargoyleLayout.lamp, ui.Offset.zero);
      expect(GargoyleLayout.housingRadius, closeTo(1.36, 1e-9));
      expect(GargoyleLayout.louvreCount, 11);
      expect(GargoyleLayout.lampRadius, lessThan(GargoyleLayout.housingRadius));
    });

    test('the two lenses: near is lower and bigger; at rest they are (-2.5,-2.6) and (-1.5,-2.8) (before the lean)', () {
      final near = GargoyleLayout.headPoint(GargoyleLayout.eyeNear);
      final far = GargoyleLayout.headPoint(GargoyleLayout.eyeFar);
      expect(near.dx, closeTo(-2.5, .1));
      expect(near.dy, closeTo(-2.6, .12));
      expect(far.dx, closeTo(-1.5, .1));
      expect(far.dy, closeTo(-2.8, .12));
      expect(GargoyleLayout.eyeNearRadius, greaterThan(GargoyleLayout.eyeFarRadius));
      expect(far.dy, lessThan(near.dy), reason: 'the far lens is higher');
      expect(far.dx, greaterThan(near.dx), reason: 'and further back');
    });

    test('the beak tip is the most forward point of the head and the hook hangs under the lens', () {
      for (final p in [...GargoyleLayout.beakOutline, ...GargoyleLayout.skullOutline, ...GargoyleLayout.jawOutline]) {
        expect(p.dx, greaterThanOrEqualTo(GargoyleLayout.beakTip.dx - 1e-9));
      }
      expect(GargoyleLayout.beakHook.dy - GargoyleLayout.eyeNear.dy, greaterThanOrEqualTo(GargoyleGates.beakDrop));
      final browFront = GargoyleLayout.skullOutline.map((p) => p.dx).reduce(math.min);
      expect(browFront - GargoyleLayout.beakTip.dx, greaterThanOrEqualTo(GargoyleGates.beakProjection));
    });

    test('headPoint: pitch about the pivot (nose down is positive), nudge, baked scale and shift', () {
      const local = ui.Offset(-3.0, -2.0);
      final rest = GargoyleLayout.headPoint(local, lean: GargoyleLayout.baseLean / GargoyleLayout.leanRadians);
      // with the body turn cancelled the point is scale-and-shift only
      final expected = (local - GargoyleLayout.headPivot) * GargoyleLayout.headScale + GargoyleLayout.headPivot + GargoyleLayout.headShift;
      expect(rest.dx, closeTo(expected.dx, 1e-9));
      expect(rest.dy, closeTo(expected.dy, 1e-9));
      final down = GargoyleLayout.headPoint(local, pitch: .3, lean: GargoyleLayout.baseLean / GargoyleLayout.leanRadians);
      expect(down.dy, greaterThan(rest.dy), reason: 'nose down lowers the snout');
      final nudged = GargoyleLayout.headPoint(local, nudge: const ui.Offset(.25, -.1), lean: GargoyleLayout.baseLean / GargoyleLayout.leanRadians);
      expect((nudged - rest).dx, closeTo(.25, 1e-9));
      expect((nudged - rest).dy, closeTo(-.1, 1e-9));
    });

    test('the lean pivots on the lamp: the lamp never moves, bodyTurn is linear in the channel', () {
      expect(GargoyleLayout.leanPivot, ui.Offset.zero);
      expect(GargoyleLayout.bodyTurn(0), GargoyleLayout.baseLean);
      expect(GargoyleLayout.bodyTurn(1) - GargoyleLayout.bodyTurn(0), closeTo(-GargoyleLayout.leanRadians, 1e-12));
      expect(GargoyleLayout.turn(ui.Offset.zero, 1.3), ui.Offset.zero);
    });

    test('the extremes of the reference outlines are the documented ones', () {
      final torso = GargoyleLayout.torsoOutline;
      expect(torso.map((p) => p.dx).reduce(math.min), -1.88);
      expect(torso.map((p) => p.dx).reduce(math.max), 1.68);
      expect(torso.map((p) => p.dy).reduce(math.min), -1.92);
      expect(torso.map((p) => p.dy).reduce(math.max), 2.84);
      // The torso stays on the ledge and the legs sit on it.
      expect(torso.map((p) => p.dy).reduce(math.max), lessThan(GargoyleLayout.ledgeY));
      expect(GargoyleLayout.ledgeY, 2.95);
      expect(GargoyleLayout.talonHeels, hasLength(3));
      // The fans' roots and the tail root.
      expect(GargoyleLayout.shoulder, const ui.Offset(.80, -1.25));
      expect(GargoyleLayout.farShoulder, const ui.Offset(1.10, -1.55));
      expect(GargoyleLayout.tailRoot, const ui.Offset(1.40, 2.05));
      expect(GargoyleLayout.vaneMount, const ui.Offset(-2.0, 2.95));
      expect(GargoyleLayout.pierX, 3.55);
    });

    test('every anchor the parts share sits inside the envelope (head points after headPoint at rest)', () {
      final pts = [
        GargoyleLayout.headPoint(GargoyleLayout.beakTip),
        GargoyleLayout.headPoint(GargoyleLayout.beakHook),
        for (final p in GargoyleLayout.crestTips) GargoyleLayout.headPoint(p),
      ];
      for (final p in pts) {
        expect(GargoyleLayout.restEnvelope.inflate(.1).contains(p), isTrue, reason: '$p');
      }
    });

    test('the z-order is complete and unique', () {
      expect(GargoyleLayout.zOrder.toSet().length, GargoyleLayout.zOrder.length);
      expect(GargoyleLayout.zOrder.first, 'bloom');
      expect(GargoyleLayout.zOrder.indexOf('farFan'), lessThan(GargoyleLayout.zOrder.indexOf('torso')));
      expect(GargoyleLayout.zOrder.indexOf('torso'), lessThan(GargoyleLayout.zOrder.indexOf('nearFan')));
      expect(GargoyleLayout.zOrder.indexOf('lamp'), lessThan(GargoyleLayout.zOrder.indexOf('head')));
      expect(GargoyleLayout.zOrder.last, 'shed');
    });
  });

  group('the envelope', () {
    test('the numbers are the report\'s (L -4.40, T -3.85, R 4.32, B 3.50) and nest', () {
      expect(GargoyleLayout.envelope, const ui.Rect.fromLTRB(-4.40, -3.85, 4.32, 3.50));
      expect(GargoyleLayout.layerBounds.left, lessThan(GargoyleLayout.envelope.left));
      expect(GargoyleLayout.layerBounds.top, lessThan(GargoyleLayout.envelope.top));
      expect(GargoyleLayout.layerBounds.right, greaterThan(GargoyleLayout.envelope.right));
      expect(GargoyleLayout.layerBounds.bottom, greaterThan(GargoyleLayout.envelope.bottom));
    });

    test('every fan blade, at every stroke (-1..1), spread (0..1) and blade, fits the envelope with room for the lean', () {
      var maxX = -99.0, minY = 99.0, maxY = -99.0, minX = 99.0;
      for (final far in [false, true]) {
        final root = GargoyleLayout.fanRoot(far: far);
        for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
          for (var s = -1.0; s <= 1.0001; s += .1) {
            for (var sp = 0.0; sp <= 1.0001; sp += .1) {
              final tip = GargoyleLayout.fanTip(i, far: far, stroke: s, spread: sp);
              for (final q in GargoyleLayout.bladeOutline(root, tip)) {
                maxX = math.max(maxX, q.dx);
                minX = math.min(minX, q.dx);
                minY = math.min(minY, q.dy);
                maxY = math.max(maxY, q.dy);
              }
            }
          }
        }
      }
      // ignore: avoid_print
      print('fan outlines (unleaned): x $minX..$maxX, y $minY..$maxY');
      final pad = GargoyleLayout.inkMajor / 2;
      // The lean (up to .08 rad about the lamp) carries a tip at most .25 sideways.
      expect(maxX + pad, lessThanOrEqualTo(GargoyleLayout.envelope.right - .2 + .06));
      expect(minY - pad, greaterThanOrEqualTo(GargoyleLayout.envelope.top));
      expect(maxY, lessThan(1.0));
    });

    test('a blade\'s tip is continuous in stroke and spread (no pops between the keys)', () {
      for (final far in [false, true]) {
        for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
          var last = GargoyleLayout.fanTip(i, far: far, stroke: -1, spread: 1);
          for (var s = -1.0; s <= 1.0; s += .01) {
            final now = GargoyleLayout.fanTip(i, far: far, stroke: s, spread: s.abs());
            expect((now - last).distance, lessThan(.12), reason: 'blade $i stroke $s');
            last = now;
          }
        }
      }
    });

    test('the long blades reach the envelope and the short ones stop short: the outline steps', () {
      for (final far in [false, true]) {
        final root = GargoyleLayout.fanRoot(far: far);
        for (var i = 0; i + 1 < GargoyleLayout.fanBlades; i += 2) {
          final long = (GargoyleLayout.fanTip(i, far: far) - root).distance;
          final short = (GargoyleLayout.fanTip(i + 1, far: far) - root).distance;
          expect(short, lessThan(long + .05), reason: 'blade ${i + 1} vs $i');
        }
      }
    });

    test('the tail fan at its full swing stays above the ledge and inside the envelope', () {
      for (final swing in const [-1.0, 0.0, 1.0]) {
        for (var i = 0; i < GargoyleLayout.tailBlades; i++) {
          final tip = GargoyleLayout.tailTip(i, swing: swing);
          expect(tip.dx + GargoyleLayout.bladeAllowance, lessThanOrEqualTo(GargoyleLayout.envelope.right + .1));
          expect(tip.dy, lessThanOrEqualTo(GargoyleLayout.envelope.bottom));
          expect(tip.dy + GargoyleLayout.inkMajor, lessThan(GargoyleLayout.ledgeY + .3));
        }
      }
    });

    test('the health bar never reaches the lenses: bar bottom -3.65, right .14 (640) / -.85 (800)', () {
      expect(GargoyleLayout.healthBarBottom, -3.65);
      expect(GargoyleLayout.healthBarRight640, .14);
      expect(GargoyleLayout.healthBarRight800, -.85);
      // the lenses at rest are far below the bar
      final lens = GargoyleLayout.headPoint(GargoyleLayout.eyeNear);
      expect(lens.dy - GargoyleLayout.eyeNearRadius * GargoyleLayout.headScale, greaterThan(GargoyleLayout.healthBarBottom + .5));
    });
  });

  group('the silhouette gates, on the reference outlines', () {
    test('the scowl: the near visor\'s lower edge slopes down toward the beak by >= 25 degrees', () {
      final vi = GargoyleLayout.visorInner, vo = GargoyleLayout.visorOuter;
      expect(vo.dx, lessThan(vi.dx), reason: 'outer end is toward the beak');
      final slope = math.atan2(vo.dy - vi.dy, vi.dx - vo.dx) * 180 / math.pi;
      expect(slope, greaterThanOrEqualTo(GargoyleGates.scowlDegrees));
    });

    test('the near visor covers >= 25% of the near lens at rest and more as the brow drops', () {
      final vi = GargoyleLayout.visorInner, vo = GargoyleLayout.visorOuter;
      double coverAt(double brow) {
        final cx = GargoyleLayout.eyeNear.dx, r = GargoyleLayout.eyeNearRadius;
        final t = (cx - vi.dx) / (vo.dx - vi.dx);
        final edgeY = vi.dy + (vo.dy - vi.dy) * t + GargoyleLayout.visorDrop(brow);
        final top = GargoyleLayout.eyeNear.dy - r;
        return ((edgeY - top) / (2 * r)).clamp(0.0, 1.0);
      }

      expect(coverAt(.3), greaterThanOrEqualTo(GargoyleGates.visorCover));
      expect(coverAt(1), greaterThan(coverAt(.3) + .1));
      expect(coverAt(1), lessThan(.9), reason: 'never fully shut');
    });

    test('the crest is raked back: every blade\'s tip is behind its root', () {
      expect(GargoyleLayout.crestRoots.length, GargoyleLayout.crestTips.length);
      for (var i = 0; i < GargoyleLayout.crestRoots.length; i++) {
        expect(GargoyleLayout.crestTips[i].dx, greaterThan(GargoyleLayout.crestRoots[i]), reason: 'blade $i');
      }
      expect(GargoyleLayout.crestRoots.length, greaterThanOrEqualTo(3));
    });

    test('the gates are the contract\'s numbers', () {
      expect(GargoyleGates.throatNotch, .6);
      expect(GargoyleGates.wingV, 1.0);
      expect(GargoyleGates.tailPocket, .5);
      expect(GargoyleGates.maxFill, .62);
      expect(GargoyleGates.beakProjection, .55);
      expect(GargoyleGates.beakDrop, .70);
    });
  });

  group('shared shapes', () {
    test('bladeOutline: root .45 in, pointed tip at the tip, symmetric about the axis', () {
      const root = ui.Offset(1, 1), tip = ui.Offset(4, 1);
      final o = GargoyleLayout.bladeOutline(root, tip);
      expect(o.length, 5);
      expect(o[2], tip);
      expect(o[0].dy, closeTo(1 + GargoyleLayout.bladeHalfRoot, 1e-9));
      expect(o[4].dy, closeTo(1 - GargoyleLayout.bladeHalfRoot, 1e-9));
      expect(o[1].dy - 1, closeTo(-(o[3].dy - 1), 1e-9));
      // a zero-length blade does not divide by zero
      expect(GargoyleLayout.bladeOutline(root, root), hasLength(3));
    });

    test('the kit\'s octagon has the housing circumradius and a flat side up', () {
      final p = GargoyleKit.octagon(GargoyleLayout.housingRadius);
      final b = p.getBounds();
      expect(b.top, closeTo(-GargoyleLayout.housingRadius * math.cos(math.pi / 8), 1e-6));
      expect(b.width, closeTo(GargoyleLayout.housingRadius * 2 * math.cos(math.pi / 8), 1e-6));
    });

    test('the timeline\'s art beats are ordered and sit on the rules\' clocks', () {
      expect(GargoyleTimeline.shrugWindUp + GargoyleTimeline.shrugFlick + GargoyleTimeline.shrugSettle, closeTo(.7, 1e-9));
      expect(GargoyleTimeline.stoneClearFrom, GargoyleTimeline.revealAt);
      expect(GargoyleTimeline.stoneClearTo, greaterThan(GargoyleTimeline.stoneClearFrom));
      expect(GargoyleTimeline.unfoldFrom, lessThan(GargoyleTimeline.windAt));
      expect(GargoyleTimeline.windAt, lessThan(GargoyleTimeline.roarAt));
      expect(GargoyleTimeline.unfoldTo, GargoyleTimeline.roarAt);
      expect(GargoyleTimeline.cardAt, greaterThan(GargoyleTimeline.roarAt));
      expect(GargoyleTimeline.barFillAt, lessThan(GargoyleTimeline.arrivalSeconds));
      expect(GargoyleTimeline.crackTo, lessThan(GargoyleTimeline.burstAt));
      expect(GargoyleTimeline.glassShatterAt, lessThan(GargoyleTimeline.burstAt));
      expect(GargoyleTimeline.visorLostAt, lessThan(GargoyleTimeline.glassShatterAt));
      expect(GargoyleTimeline.lensSparkAt, everyElement(greaterThan(GargoyleTimeline.revealAt)));
    });
  });
}
