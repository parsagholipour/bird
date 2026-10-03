import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Neferhoo, the Mummy Courier: his palette. Ported 1:1 from the approved
/// design (`egypt-ws/iter5/test/egypt/mummy_rig.dart`, `Mu`); every name is
/// the design's. The parts keep their own extra inks next to their art
/// (`NeferhooHeadInk`, `NeferhooBodyInk`, `NeferhooWingInk`,
/// `NeferhooPropInk`); the anchors live in `NeferhooLayout`.
abstract final class NeferhooPalette {
  // ink and light
  static const ink = Color(0xff201833);
  static const inkSoft = Color(0xff3a2f52);
  // linen (cool, moonlit: it must part from the warm sand and cream sky)
  static const linenHi = Color(0xfffffbf4);
  static const linenLit = Color(0xfff3eee8);
  static const linen = Color(0xffebe6f0);
  static const linenShade = Color(0xffc4bbd8);
  static const linenDeep = Color(0xff7d7499);
  static const linenBand = Color(0xff9d93b5);
  // gold
  static const goldHi = Color(0xfffff3b8);
  static const goldLit = Color(0xffffdc6e);
  static const gold = Color(0xfff2b63c);
  static const goldShade = Color(0xffc9852a);
  static const goldDeep = Color(0xff8a5520);
  // lapis
  static const lapisLit = Color(0xff7f9cff);
  static const lapis = Color(0xff3358d4);
  static const lapisShade = Color(0xff22399a);
  static const lapisDeep = Color(0xff152262);
  // turquoise (faience, and his magic)
  static const turqLit = Color(0xffa9f7e8);
  static const turq = Color(0xff35cbb8);
  static const turqShade = Color(0xff16908b);
  static const magic = Color(0xff6ff9e6);
  // carnelian (the satchel, seals)
  static const carnLit = Color(0xffff9c7c);
  static const carn = Color(0xffe0513f);
  static const carnShade = Color(0xffa8302e);
  static const carnDeep = Color(0xff6e1d24);
  // hoopoe plumage (under the wraps)
  static const cinnLit = Color(0xfffbc893);
  static const cinn = Color(0xffe8955a);
  static const cinnShade = Color(0xffb0653a);
  static const barBlack = Color(0xff2a2238);
  static const barWhite = Color(0xfff7f2e8);
  // papyrus letters
  static const papyrusHi = Color(0xfffff6dc);
  static const papyrus = Color(0xfff6e2ad);
  static const papyrusShade = Color(0xffd8b675);
  static const seal = Color(0xffd8443a);

  // shared light and tones every part needs (one copy; the parts alias them)
  /// The sun's warm rim light (behind-right).
  static const rim = Color(0xfffff0c8);

  /// Black plumage in the light (mid: barBlack, deep: ink).
  static const plumeLit = Color(0xff54476f);

  /// Gold's cool violet-brown shade (never black).
  static const goldCool = Color(0xff9c5f3f);

  /// Sand light bounced up under gold.
  static const goldBounce = Color(0xffeaa24a);

  /// The fight's night wash.
  static const night = Color(0xff171c39);

  /// Postal ink (RETURN TO SENDER, the postmark).
  static const stampInk = Color(0xffc93030);
}

/// Neferhoo's shared drawing kit: the design's helpers (`mummy_rig.dart`),
/// pure functions of their arguments, and the one place where his cached
/// pictures are recorded.
abstract final class NeferhooKit {
  /// A smooth closed (or open) path through [pts] (Catmull-Rom as cubics).
  static Path smoothPath(List<Offset> pts, {bool close = true, double k = 1 / 6}) {
    final p = Path();
    final n = pts.length;
    if (n < 2) return p;
    p.moveTo(pts[0].dx, pts[0].dy);
    final last = close ? n : n - 1;
    for (var i = 0; i < last; i++) {
      final p0 = pts[close ? (i - 1 + n) % n : math.max(0, i - 1)];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[close ? (i + 2) % n : math.min(n - 1, i + 2)];
      final c1 = p1 + (p2 - p0) * k;
      final c2 = p2 - (p3 - p1) * k;
      p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (close) p.close();
    return p;
  }

  /// The level of detail for a canvas from its scale (px per rig unit): 0
  /// quiet (< 11 px/unit: the HUD medallion, the 24 px keepsake), 1 mid (<
  /// 24), 2 play (< 60: the game's 41.4 px/unit at 360 px high, 50 at 432,
  /// 55 at 480), 3 full (close-ups, the story's hero shots). A canvas that
  /// cannot report its transform (a recorder, a test proxy) is painted full.
  static int lodOf(Canvas c) {
    try {
      final m = c.getTransform();
      return lodOfScale(math.sqrt(m[0] * m[0] + m[1] * m[1]));
    } catch (_) {
      return 3;
    }
  }

  /// [lodOf] for a known scale (px per rig unit).
  static int lodOfScale(double s) => s >= 60 ? 3 : (s >= 24 ? 2 : (s >= 11 ? 1 : 0));

  /// 0..1 smoothstep of [t] (clamped).
  static double smooth01(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  /// 0..1 where [v] lies between [a] and [b] (clamped).
  static double ramp(double v, double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);

  /// [p] turned by [a] radians about [about].
  static Offset rot(Offset p, double a, [Offset about = Offset.zero]) {
    final d = p - about;
    final c = math.cos(a), s = math.sin(a);
    return about + Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c);
  }

  /// Test hook (the budget test's counting proxy): wraps the recording
  /// canvas of each cached picture so a counted `drawPicture` can add what
  /// it replays. Null in the game.
  static Canvas Function(Canvas inner)? debugWrap;

  /// What a recorded picture holds (the wrapper that saw it), by identity;
  /// only filled while [debugWrap] is set.
  static final Expando<Object> debugInside = Expando<Object>('neferhoo picture');

  /// Records [draw] once into a picture (every cached piece of his art).
  static ui.Picture record(void Function(Canvas) draw) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final w = debugWrap?.call(c);
    draw(w ?? c);
    final pic = rec.endRecording();
    if (w != null) debugInside[pic] = w;
    return pic;
  }
}
