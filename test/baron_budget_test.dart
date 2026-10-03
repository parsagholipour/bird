import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign_story.dart' show StoryMood;
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/baron_storm_pose.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/boss_rig.dart';
import 'package:push_up_bird/game/flight_voices.dart' show FlightSpeech;

/// Baron Bat's per-frame budget (the detailed redesign of 2026-10-02 measured
/// debut 127-129 ops and storm 142; the Ember Dragon's ceiling is 350).
///
/// In every state the rig (`BossRig.paint` / `BaronStormRig.paint`) makes at
/// most [maxDebutOps] / [maxStormOps] draw calls, at most [maxClips] clips,
/// at most one saveLayer (the hit flash's tint) and never a blur mask.
const maxDebutOps = 160, maxStormOps = 180, maxClips = 3;

/// Counts what a frame asks of the canvas.
class _Counting implements Canvas {
  _Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get clips =>
      (counts['clipPath'] ?? 0) +
      (counts['clipRRect'] ?? 0) +
      (counts['clipRect'] ?? 0);

  void _paint(String k, Paint p) {
    _n(k);
    if (p.maskFilter != null) _n('maskFilter');
  }

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  int getSaveCount() => inner.getSaveCount();
  @override
  void restoreToCount(int count) => inner.restoreToCount(count);
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    _n('saveLayer');
    inner.saveLayer(bounds, paint);
  }

  @override
  void translate(double dx, double dy) => inner.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => inner.scale(sx, sy);
  @override
  void rotate(double r) => inner.rotate(r);
  @override
  void skew(double sx, double sy) => inner.skew(sx, sy);
  @override
  void transform(Float64List m) => inner.transform(m);
  @override
  Float64List getTransform() => inner.getTransform();
  @override
  void clipPath(Path p, {bool doAntiAlias = true}) {
    _n('clipPath');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    _n('clipRRect');
    inner.clipRRect(rrect, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    _n('clipRect');
    inner.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void drawPath(Path p, Paint paint) {
    _paint('drawPath', paint);
    inner.drawPath(p, paint);
  }

  @override
  void drawCircle(Offset c, double r, Paint paint) {
    _paint('drawCircle', paint);
    inner.drawCircle(c, r, paint);
  }

  @override
  void drawRect(Rect r, Paint paint) {
    _paint('drawRect', paint);
    inner.drawRect(r, paint);
  }

  @override
  void drawRRect(RRect r, Paint paint) {
    _paint('drawRRect', paint);
    inner.drawRRect(r, paint);
  }

  @override
  void drawOval(Rect r, Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
  }

  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) {
    _paint('drawArc', paint);
    inner.drawArc(r, a, b, c, paint);
  }

  @override
  void drawLine(Offset a, Offset b, Paint paint) {
    _paint('drawLine', paint);
    inner.drawLine(a, b, paint);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

/// A Baron [t] seconds into the fight, built from real encounter state.
SkyBoss _baron({double t = 1.2, bool fury = false, bool storm = false}) {
  final boss =
      SkyBoss(
          number: storm ? 6 : 1,
          x: 1.5,
          cinematic: true,
          upgraded: storm,
          debut: !storm,
        )
        ..fireIn = 2
        ..y = .47;
  boss.age = boss.arrivalDuration + t;
  if (fury) {
    boss.hp = boss.maxHp ~/ 3;
    boss.enragedAt = boss.age - 3;
  }
  return boss;
}

void main() {
  final angry = FlightSpeech(
    boss: BossKind.baronBat,
    mood: StoryMood.angry,
    mouth: 3,
    age: .5,
    length: 2,
  );
  final states = <(String, SkyBoss, FlightSpeech?)>[
    ('calm idle', _baron(), null),
    ('calm idle, other phase', _baron(t: 1.4), null),
    ('blink', _baron(t: 3.68), null),
    ('charging', _baron()..fireIn = .1, null),
    ('volley', _baron()..lastVolleyAt = _baron().age - .12, null),
    ('hit flash', _baron()..lastHitAt = _baron().age - .1, null),
    ('fury', _baron(fury: true), null),
    (
      'fury charge + hit + speaking',
      _baron(fury: true)
        ..fireIn = .1
        ..lastHitAt = _baron().age - .05,
      angry,
    ),
    ('arrival folded', _baron()..age = 1.2, null),
    ('arrival roar', _baron()..age = 3.0, null),
    (
      'defeat',
      () {
        final b = _baron(t: 4, fury: true);
        return b..defeatedAt = b.age - .15;
      }(),
      null,
    ),
    ('storm idle', _baron(storm: true), null),
    ('storm screech', _baron(storm: true, t: 7.1), null),
    ('storm fury screech', _baron(storm: true, fury: true, t: 6.62), null),
    (
      'storm fury charge + hit',
      _baron(storm: true, fury: true)
        ..fireIn = .1
        ..lastHitAt = _baron().age - .05,
      null,
    ),
  ];

  for (final (name, boss, speech) in states) {
    test('$name stays inside the budget', () {
      final recorder = ui.PictureRecorder();
      final c = _Counting(Canvas(recorder))
        ..translate(500, 180)
        ..scale(.115 * 360);
      final motion = BossMotion(boss, reducedMotion: false, speech: speech);
      if (boss.screeches) {
        BaronStormRig.paint(c, boss, motion);
      } else {
        BossRig.paint(c, boss, motion);
      }
      recorder.endRecording().dispose();
      final max = boss.screeches ? maxStormOps : maxDebutOps;
      expect(c.counts.keys.where((k) => k.startsWith('UNFORWARDED')), isEmpty);
      expect(c.draws, inInclusiveRange(1, max), reason: name);
      expect(c.clips, lessThanOrEqualTo(maxClips), reason: name);
      expect(c.counts['saveLayer'] ?? 0, lessThanOrEqualTo(1), reason: name);
      expect(c.counts['maskFilter'] ?? 0, 0, reason: name);
    });
  }
}
