// Test support for Neferhoo's rig and fight art (A1, integrated by M1): a
// courier boss in a REAL flight of level 2-6 at any width and stage (R1's
// rules latch everything the art reads: the mail calls, the letters' fates,
// the ankhs, the landings), stepped at 60 Hz to any fight second with the
// bird held where a test puts it; a real rock to send a letter back; and a
// counting canvas for the budget.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/neferhoo_kit.dart';

import 'gargoyle_pilot.dart' as pilot show frame;
import 'neferhoo_pilot.dart' show neferhooArena;

/// The flight each courier fights in.
final _flights = Expando<FlightSimulation>('neferhoo test flights');

/// The real flight [boss] fights in.
FlightSimulation flightOf(SkyBoss boss) => _flights[boss]!;

/// The screen width (screen heights) each flight is flown at.
final _widths = Expando<double>('neferhoo test widths');

/// Neferhoo in a real 2-6 flight on a screen [px] wide (360 high), as he
/// begins to fight (combat time about 0), staged as the campaign has him:
/// [stage] 0 the warm-up, 1 the full fight, 2 fury, reached by one blow on
/// the first frame (the rules raise the stage, roar and arm the ankh as in
/// any fight). [version]: the rules flown (the current ones by default).
SkyBoss courier({
  double px = 640,
  int stage = 1,
  int version = FlightSimulation.currentRulesVersion,
}) {
  final width = px / 360;
  final sim = neferhooArena(width: width, version: version);
  final boss = sim.boss!;
  _flights[boss] = sim;
  _widths[boss] = width;
  if (stage > 0) {
    final to = (boss.maxHp * (stage == 1 ? 2 / 3 : 1 / 3)).floor();
    if (boss.hp > to) boss.takeDamage(boss.hp - to);
    _step(boss, .46);
  }
  return boss;
}

void _step(SkyBoss boss, double birdY) {
  final sim = flightOf(boss);
  sim
    ..birdY = birdY
    ..velocity = 0
    ..hearts = 3;
  pilot.frame(sim, width: _widths[boss]!);
  sim
    ..birdY = birdY
    ..velocity = 0;
}

/// Flies [boss]'s real flight on to fight second [t] at 60 Hz, the bird held
/// at [birdY] (never knocked out: the hearts are topped up). A fight second
/// already passed changes nothing (a flight never runs backward); the loop
/// stops if the flight ends or he leaves.
void fightTo(SkyBoss boss, double t, {double birdY = .46}) {
  final sim = flightOf(boss);
  final target = boss.arrivalDuration + t;
  for (var guard = 0; guard < 60 * 600; guard++) {
    if (boss.age >= target - 1e-9 || sim.phase == RunPhase.ended || !identical(sim.boss, boss)) return;
    _step(boss, birdY);
  }
}

/// A real rock meets [letter] (in its lane, just left of it): the rules
/// catch it and send it home. Steps until they have.
void returnLetter(SkyBoss boss, NeferhooLetter letter, {double birdY = .46}) {
  final sim = flightOf(boss);
  final x = letter.xAt(boss.age, boss.handX);
  sim.rocks.add(BirdRock(x: x - Neferhoo.letterHalfWidth - .03, y: letter.yAt(boss.age)));
  for (var guard = 0; guard < 30 && !letter.returned; guard++) {
    _step(boss, birdY);
  }
  if (!letter.returned) throw StateError('the rock missed the letter');
}

/// Counts what a frame asks of the canvas: draw calls by kind, clips,
/// layers, shader draws and blurs; with [NeferhooKit.debugWrap] set before
/// the caches are built, a `drawPicture` also adds what the picture replays
/// (the design's `effective` ops: draws - picture calls + replayed ops).
class OpCounter implements Canvas {
  OpCounter(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;

  int get draws => counts.entries.where((e) => e.key.startsWith('draw') && !e.key.contains('.')).fold(0, (a, e) => a + e.value);
  int get clips => (counts['clipPath'] ?? 0) + (counts['clipRRect'] ?? 0) + (counts['clipRect'] ?? 0);
  int get shaderDraws => counts.entries.where((e) => e.key.endsWith('.shader')).fold(0, (a, e) => a + e.value);
  int get layers => counts['saveLayer'] ?? 0;
  int get blurs => counts['maskFilter'] ?? 0;
  int get pictures => counts['drawPicture'] ?? 0;
  int replayDraws = 0, replayClips = 0, replayShaders = 0, replayLayers = 0;

  /// Draw calls plus what the cached pictures replay (the honest raster cost).
  int get effective => draws - pictures + replayDraws;

  void _paint(String k, Paint p) {
    _n(k);
    if (p.shader != null) _n('$k.shader');
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
  void clipRect(Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
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
  void drawDRRect(RRect outer, RRect inner_, Paint paint) {
    _paint('drawDRRect', paint);
    inner.drawDRRect(outer, inner_, paint);
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
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {
    _paint('drawPoints', paint);
    inner.drawPoints(pointMode, points, paint);
  }

  @override
  void drawParagraph(ui.Paragraph p, Offset o) {
    _n('drawParagraph');
    inner.drawParagraph(p, o);
  }

  @override
  void drawPicture(ui.Picture picture) {
    _n('drawPicture');
    final held = NeferhooKit.debugInside[picture];
    if (held is OpCounter) {
      replayDraws += held.draws - held.pictures + held.replayDraws;
      replayClips += held.clips + held.replayClips;
      replayShaders += held.shaderDraws + held.replayShaders;
      replayLayers += held.layers + held.replayLayers;
    }
    inner.drawPicture(picture);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

/// [draw]'s cost, measured warm (the first call records the caches).
OpCounter measure(void Function(Canvas) draw) {
  final warm = ui.PictureRecorder();
  draw(Canvas(warm));
  warm.endRecording().dispose();
  final rec = ui.PictureRecorder();
  final k = OpCounter(Canvas(rec));
  draw(k);
  rec.endRecording().dispose();
  return k;
}
