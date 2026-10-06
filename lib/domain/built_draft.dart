import 'dart:math' as math;

import 'game_rules.dart';
import 'tracking.dart';

/// An item on the editor's canvas under a stable [key], which selection
/// and dragging hold on to while the item itself is replaced.
typedef DraftItem = ({int key, BuiltItem item});

/// A level being built: the plan's settings and its items under editor
/// keys. Every operation returns a new draft, so the editor's undo is a
/// stack of drafts. [plan] is what is saved and flown.
class BuiltDraft {
  const BuiltDraft._(this.base, this.items, this.nextKey, this.autoMarks);

  /// [autoMarks] keeps the marks at [BuiltPlan.suggestMarks] as stars come
  /// and go; by default a plan whose marks are the suggested ones keeps
  /// them so.
  factory BuiltDraft.of(BuiltPlan plan, {bool? autoMarks}) {
    final suggested = BuiltPlan.suggestMarks(plan.totalStars);
    return BuiltDraft._(
      plan.copyWith(items: const []),
      [for (final (i, item) in plan.items.indexed) (key: i, item: item)],
      plan.items.length,
      autoMarks ??
          (plan.marks.two == suggested.two &&
              plan.marks.three == suggested.three),
    );
  }

  /// A new, empty level of [mode] over [region]: only its finish line, a
  /// few screens on.
  factory BuiltDraft.blank({
    required String id,
    required String name,
    required PlayMode mode,
    required WorldRegion region,
  }) => BuiltDraft._(
    BuiltPlan(
      id: id,
      name: name,
      mode: mode,
      region: region,
      finish: blankFinish,
      marks: const StarMarks(1, 1),
      items: const [],
    ),
    const [],
    0,
    true,
  );

  static const blankFinish = 12000;

  /// The settings, with no items.
  final BuiltPlan base;
  final List<DraftItem> items;
  final int nextKey;
  final bool autoMarks;

  BuiltPlan get plan {
    final placed = [for (final entry in items) entry.item];
    final marks = autoMarks
        ? BuiltPlan.suggestMarks(base.copyWith(items: placed).totalStars)
        : base.marks;
    return base.copyWith(items: placed, marks: marks);
  }

  PlayMode get mode => base.mode;

  BuiltItem? operator [](int key) {
    for (final entry in items) {
      if (entry.key == key) return entry.item;
    }
    return null;
  }

  BuiltDraft _with(List<DraftItem> items, {int? nextKey}) => BuiltDraft._(
    base,
    List.unmodifiable(items),
    nextKey ?? this.nextKey,
    autoMarks,
  );

  /// Adds [item]; returns the new draft and the item's key.
  (BuiltDraft, int) place(BuiltItem item) => (
    _with([...items, (key: nextKey, item: item)], nextKey: nextKey + 1),
    nextKey,
  );

  BuiltDraft update(int key, BuiltItem item) => _with([
    for (final entry in items)
      entry.key == key ? (key: key, item: item) : entry,
  ]);

  BuiltDraft remove(int key) => _with([
    for (final entry in items)
      if (entry.key != key) entry,
  ]);

  /// A copy of [key]'s item just after it.
  (BuiltDraft, int)? duplicate(int key) {
    final item = this[key];
    if (item == null) return null;
    final step = math.max(item.right - item.left, 0) + 400;
    return place(item.movedTo(x: item.x + step));
  }

  BuiltDraft withSettings({
    String? name,
    WorldRegion? region,
    BuiltPace? pace,
    int? finish,
    BossKind? Function()? boss,
    bool? shoot,
    bool? sprint,
    StarMarks? marks,
    bool? autoMarks,
  }) {
    final next = base.copyWith(
      name: name,
      region: region,
      pace: pace,
      finish: finish,
      boss: boss,
      shoot: shoot,
      sprint: sprint,
      marks: marks,
    );
    // Without the Shoot control no stone door can be broken.
    final doors = next.shoot
        ? items
        : [
            for (final entry in items)
              switch (entry.item) {
                BuiltGate(door: true) && final BuiltGate gate => (
                  key: entry.key,
                  item: gate.copyWith(door: false),
                ),
                _ => entry,
              },
          ];
    return BuiltDraft._(
      next,
      List.unmodifiable(doors),
      nextKey,
      autoMarks ?? (marks == null && this.autoMarks),
    );
  }

  // -------------------------------------------------------------------
  // What the editor places, and where.

  /// Positions snap to a 50-thousandths grid along the route, and to 25
  /// up and down; a push-up or squat gate snaps to its lane.
  static int snapX(double worldX) =>
      ((worldX * BuiltPlan.unit) / 50).round() * 50;
  static int snapY(double worldY) =>
      _within(((worldY * BuiltPlan.unit) / 25).round(), 2, 38) * 25;
  static int _within(int value, int low, int high) =>
      math.min(high, math.max(low, value));
  static int _gateY(double worldY) =>
      _within(snapY(worldY), BuiltPlan.minGateY, BuiltPlan.maxGateY);
  static int lane(double worldY) =>
      worldY < .5 ? BuiltPlan.highLane : BuiltPlan.lowLane;

  /// The opening a new gate of [mode] gets.
  static int defaultGap(PlayMode mode) => switch (mode) {
    PlayMode.touch => 400,
    PlayMode.jump => 480,
    PlayMode.pushUp || PlayMode.squat => 440,
  };

  /// A new still garden gate of [mode] placed at ([worldX], [worldY]).
  static BuiltGate gateAt(PlayMode mode, double worldX, double worldY) =>
      BuiltGate(
        x: snapX(worldX),
        y: mode.controlsHeight ? lane(worldY) : _gateY(worldY),
        gap: defaultGap(mode),
      );

  /// [item] at ([worldX], [worldY]), snapped as its kind snaps.
  BuiltItem moved(BuiltItem item, double worldX, double worldY) {
    final x = snapX(worldX);
    return switch (item) {
      BuiltGate gate => gate.copyWith(
        x: x,
        y: mode.controlsHeight ? lane(worldY) : _gateY(worldY),
      ),
      _ => item.movedTo(x: x, y: snapY(worldY)),
    };
  }

  /// The item under ([worldX], [worldY]), within [reach] of it: a gate
  /// anywhere along its column, anything else near its centre. The
  /// nearest wins; the newest of equals.
  int? hit(double worldX, double worldY, {double reach = .09}) {
    int? best;
    var bestDistance = double.infinity;
    for (final entry in items) {
      final item = entry.item;
      final double distance;
      if (item is BuiltGate) {
        final left = item.x / BuiltPlan.unit,
            right = item.right / BuiltPlan.unit;
        final dx = worldX < left
            ? left - worldX
            : worldX > right
            ? worldX - right
            : 0.0;
        distance = dx;
      } else {
        final dx = worldX - item.worldX, dy = worldY - item.y / BuiltPlan.unit;
        distance = math.sqrt(dx * dx + dy * dy);
      }
      if (distance <= reach && distance <= bestDistance) {
        best = entry.key;
        bestDistance = distance;
      }
    }
    return best;
  }
}
