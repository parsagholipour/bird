import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../data/built_level_repository.dart';
import '../../domain/built_draft.dart';
import '../../domain/built_level.dart';
import '../../domain/built_reach.dart';
import '../../domain/game_rules.dart';
import '../../domain/tracking.dart';

/// What a tap on the editor's sky does.
enum BuilderTool { select, gate, star, trio, heart, enemy, finish }

/// The level editor's state: the [draft] being built, its undo and redo,
/// what is selected, the tool in hand and where the view is scrolled. Every
/// change is saved shortly after it is made ([autosave]); [flush] saves at
/// once, before a test flight or leaving. A starter template is
/// [readOnly]: it can be looked at and flown, and remixed into a level of
/// one's own, but not changed.
class BuilderController extends ChangeNotifier {
  BuilderController({
    required BuiltLevel level,
    required this.store,
    this.autosave = const Duration(milliseconds: 600),
  }) : _level = level,
       draft = BuiltDraft.of(level.plan),
       readOnly = level.template;

  final BuiltLevelStore store;
  final Duration autosave;
  final bool readOnly;
  BuiltLevel _level;

  /// The level as last saved.
  BuiltLevel get level => _level;
  BuiltDraft draft;
  final List<BuiltDraft> _undo = [], _redo = [];
  static const maxUndo = 100;

  /// The selected item's key, or null.
  int? selected;
  BuilderTool tool = BuilderTool.select;

  /// The route position (viewport heights) at the view's left edge.
  double scroll = 0;
  bool _disposed = false;

  BuiltPlan get plan => draft.plan;
  PlayMode get mode => draft.mode;
  bool get canUndo => _undo.isNotEmpty && !readOnly;
  bool get canRedo => _redo.isNotEmpty && !readOnly;
  BuiltItem? get selection => selected == null ? null : draft[selected!];

  /// Plain-language problems (blocking first) and advice for the draft.
  List<BuiltIssue> get issues => _issues ??= BuiltReach.check(plan);
  List<BuiltIssue>? _issues;
  bool get flyable => !issues.any((i) => i.blocking);

  /// The draft's tools: enemies and the boss finale are Tap & Fly only.
  List<BuilderTool> get tools => [
    for (final tool in BuilderTool.values)
      if (tool != BuilderTool.enemy || plan.touch) tool,
  ];

  // -------------------------------------------------------------------
  // Saving.

  Timer? _saveTimer;
  Future<void>? _saving;
  bool _dirty = false;

  /// Whether the latest change is not saved yet, or saving failed.
  bool get unsaved => _dirty || saveError;
  bool saveError = false;

  void _changed() {
    _issues = null;
    if (readOnly) return;
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(autosave, () => unawaited(flush()));
    _notify();
  }

  /// Saves the draft now, if it changed. Editing the route makes a new
  /// revision of the level ([BuiltLevelStore.save]).
  Future<void> flush() async {
    _saveTimer?.cancel();
    await _saving;
    if (!_dirty || readOnly || _disposed) return;
    _dirty = false;
    final saving = store.save(plan).then(
      (saved) {
        _level = saved;
        saveError = false;
      },
      onError: (Object error) {
        _dirty = true;
        saveError = true;
        debugPrint('PushUpBird builder save: $error');
      },
    );
    _saving = saving;
    await saving;
    _saving = null;
    _notify();
  }

  // -------------------------------------------------------------------
  // Editing. Each edit is one undo step; a drag is one step from where it
  // began.

  void _apply(BuiltDraft next, {bool record = true}) {
    if (readOnly) return;
    if (record) {
      _undo.add(draft);
      if (_undo.length > maxUndo) _undo.removeAt(0);
      _redo.clear();
    }
    draft = next;
    if (selected != null && draft[selected!] == null) selected = null;
    _changed();
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(draft);
    draft = _undo.removeLast();
    if (selected != null && draft[selected!] == null) selected = null;
    _changed();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(draft);
    draft = _redo.removeLast();
    if (selected != null && draft[selected!] == null) selected = null;
    _changed();
  }

  void pick(BuilderTool next) {
    tool = next;
    if (next != BuilderTool.select) selected = null;
    _notify();
  }

  void select(int? key) {
    selected = key;
    _notify();
  }

  /// A tap on the sky at ([worldX], [worldY]): with a placing tool, a new
  /// item there (selected); with Select, the item under it, if any.
  /// Returns the key of what was placed or selected.
  int? tapAt(double worldX, double worldY, {double reach = .09}) {
    if (tool == BuilderTool.select || readOnly) {
      select(draft.hit(worldX, worldY, reach: reach));
      return selected;
    }
    if (tool == BuilderTool.finish) {
      setFinish(worldX);
      return null;
    }
    final x = BuiltDraft.snapX(worldX), y = BuiltDraft.snapY(worldY);
    final BuiltItem item = switch (tool) {
      BuilderTool.gate => BuiltDraft.gateAt(mode, worldX, worldY),
      BuilderTool.star => BuiltStar(x: x, y: y),
      BuilderTool.trio => BuiltTrio(x: x, y: y),
      BuilderTool.heart => BuiltHeart(x: x, y: y),
      BuilderTool.enemy => BuiltEnemy(x: x, y: y, kind: EnemyKind.simpleBat),
      BuilderTool.select || BuilderTool.finish => throw StateError('$tool'),
    };
    final (next, key) = draft.place(item);
    _apply(next);
    selected = key;
    _notify();
    return key;
  }

  /// The finish line (or a boss's mark) at [worldX], never inside the
  /// start zone.
  void setFinish(double worldX) {
    final x = math.max(
      BuiltPlan.firstX + BuiltPlan.unit,
      BuiltDraft.snapX(worldX),
    );
    _apply(draft.withSettings(finish: x));
  }

  BuiltDraft? _dragFrom;

  /// Starts dragging [key]: the whole drag is one undo step.
  void beginDrag(int key) {
    if (readOnly || draft[key] == null) return;
    _dragFrom = draft;
    selected = key;
    _notify();
  }

  /// Moves the dragged item to ([worldX], [worldY]), snapped.
  void dragTo(double worldX, double worldY) {
    final key = selected;
    final item = key == null ? null : draft[key];
    if (_dragFrom == null || key == null || item == null) return;
    final moved = draft.moved(item, worldX, worldY);
    if (moved.x == item.x && moved.y == item.y) return;
    _apply(draft.update(key, moved), record: false);
  }

  void endDrag() {
    final from = _dragFrom;
    _dragFrom = null;
    if (from == null || identical(from, draft)) return;
    _undo.add(from);
    if (_undo.length > maxUndo) _undo.removeAt(0);
    _redo.clear();
    _notify();
  }

  /// Replaces the selected item, as the inspector edits it.
  void updateSelected(BuiltItem item) {
    final key = selected;
    if (key == null) return;
    _apply(draft.update(key, item));
  }

  void deleteSelected() {
    final key = selected;
    if (key == null) return;
    _apply(draft.remove(key));
    selected = null;
    _notify();
  }

  void duplicateSelected() {
    final key = selected;
    if (key == null) return;
    final copy = draft.duplicate(key);
    if (copy == null) return;
    _apply(copy.$1);
    selected = copy.$2;
    _notify();
  }

  /// Changes the level's settings ([BuiltDraft.withSettings]).
  void settings({
    String? name,
    WorldRegion? region,
    BuiltPace? pace,
    BossKind? Function()? boss,
    bool? shoot,
    bool? sprint,
    StarMarks? marks,
    bool? autoMarks,
  }) => _apply(
    draft.withSettings(
      name: name,
      region: region,
      pace: pace,
      boss: boss,
      shoot: shoot,
      sprint: sprint,
      marks: marks,
      autoMarks: autoMarks,
    ),
  );

  void scrollTo(double worldX) {
    scroll = worldX.clamp(0.0, math.max(0.0, plan.finishX + 1));
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    // A change still waiting is saved on the way out.
    if (_dirty && !readOnly) unawaited(store.save(plan).then((_) {}, onError: (_) {}));
    super.dispose();
  }
}
