import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/game_rules.dart';
import '../domain/session_replay.dart';
import '../domain/tracking.dart';

class SessionClip {
  const SessionClip({
    required this.path,
    required this.startMs,
    required this.durationMs,
    this.hasAudio = false,
  });
  final bool hasAudio;
  final String path;
  final double startMs, durationMs;
  Map<String, dynamic> toJson() => {
    'path': p.basename(path),
    'startMs': startMs,
    'durationMs': durationMs,
    'hasAudio': hasAudio,
  };
}

class SavedSession {
  const SavedSession({
    required this.result,
    required this.tape,
    required this.clips,
  });
  final RunResult result;
  final ReplayTape tape;
  final List<SessionClip> clips;
}

/// Each session is committed by a directory rename after all clips and its
/// journal have been flushed. Failed saves retain the draft for retry.
class SessionRepository {
  SessionRepository([this.directory]);
  final Directory? directory;
  Future<Directory>? _opening;
  Future<Directory> _root() async {
    try {
      return await (_opening ??= _open());
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Directory> _open() async {
    final root =
        directory ??
        Directory(
          p.join((await getApplicationSupportDirectory()).path, 'sessions'),
        );
    await root.create(recursive: true);
    await for (final entity in root.list()) {
      if (entity is Directory &&
          p.basename(entity.path).startsWith('.') &&
          entity.path.endsWith('.pending')) {
        await entity.delete(recursive: true);
      }
    }
    return root;
  }

  Future<void> save(SavedSession session) async {
    final root = await _root();
    final id = session.result.id;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      throw ArgumentError('Invalid session ID');
    }
    final target = Directory(p.join(root.path, id));
    if (await target.exists()) return;
    final staging = Directory(p.join(root.path, '.$id.pending'));
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create();
    try {
      final clips = <Map<String, dynamic>>[];
      for (var i = 0; i < session.clips.length; i++) {
        final clip = session.clips[i];
        final filename = 'camera-$i.mp4';
        final copied = await File(
          clip.path,
        ).copy(p.join(staging.path, filename));
        final handle = await copied.open(mode: FileMode.append);
        try {
          await handle.flush();
        } finally {
          await handle.close();
        }
        clips.add({...clip.toJson(), 'path': filename});
      }
      final summary = _resultJson(session.result);
      await File(
        p.join(staging.path, 'summary.json'),
      ).writeAsString(jsonEncode(summary), flush: true);
      await File(p.join(staging.path, 'session.json')).writeAsString(
        jsonEncode({
          'result': summary,
          'tape': session.tape.toJson(),
          'clips': clips,
        }),
        flush: true,
      );
      await staging.rename(target.path);
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  Future<SavedSession> load(String id) async {
    if (p.basename(id) != id || id.startsWith('.')) {
      throw ArgumentError('Invalid session ID');
    }
    final folder = Directory(p.join((await _root()).path, id));
    final json =
        jsonDecode(
              await File(p.join(folder.path, 'session.json')).readAsString(),
            )
            as Map<String, dynamic>;
    final r = json['result'] as Map<String, dynamic>;
    return SavedSession(
      result: _readResult(r),
      tape: ReplayTape.fromJson(json['tape'] as Map<String, dynamic>),
      clips: (json['clips'] as List).map((value) {
        final c = value as Map<String, dynamic>;
        return SessionClip(
          path: p.join(folder.path, p.basename(c['path'] as String)),
          startMs: (c['startMs'] as num).toDouble(),
          durationMs: (c['durationMs'] as num).toDouble(),
          hasAudio: c['hasAudio'] == true,
        );
      }).toList(),
    );
  }

  Future<List<RunResult>> list() async {
    final sessions = <RunResult>[];
    await for (final entity in (await _root()).list()) {
      if (entity is! Directory || p.basename(entity.path).startsWith('.')) {
        continue;
      }
      try {
        final json =
            jsonDecode(
                  await File(
                    p.join(entity.path, 'summary.json'),
                  ).readAsString(),
                )
                as Map<String, dynamic>;
        sessions.add(_readResult(json));
      } catch (_) {
        // A damaged session must not hide the rest of the library.
      }
    }
    return sessions..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
  }

  Future<void> delete(String id) async {
    if (p.basename(id) != id || id.startsWith('.')) {
      throw ArgumentError('Invalid session ID');
    }
    final folder = Directory(p.join((await _root()).path, id));
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  Future<void> reset() async {
    final root = await _root();
    await root.delete(recursive: true);
    _opening = null;
  }
}

Map<String, dynamic> _resultJson(RunResult r) => {
  'id': r.id,
  'mode': r.mode.name,
  'course': r.course.name,
  'gates': r.gates,
  'stars': r.stars,
  'bestCombo': r.bestCombo,
  'perfectPasses': r.perfectPasses,
  'practice': r.practice,
  'score': r.score,
  'repetitions': r.repetitions,
  'flaps': r.flaps,
  'duration': r.durationSeconds,
  'reason': r.reason.name,
  'finishedAt': r.finishedAt.toIso8601String(),
};
RunResult _readResult(Map<String, dynamic> r) => RunResult(
  id: r['id'] as String,
  mode: PlayMode.fromName(r['mode'] as String),
  course: FlightCourse.named(r['course'] as String? ?? 'classic'),
  gates: r['gates'] as int?,
  stars: r['stars'] as int? ?? 0,
  bestCombo: r['bestCombo'] as int? ?? 0,
  perfectPasses: r['perfectPasses'] as int? ?? 0,
  practice: r['practice'] as bool,
  score: r['score'] as int,
  repetitions: r['repetitions'] as int,
  flaps: r['flaps'] as int,
  durationSeconds: (r['duration'] as num).toDouble(),
  reason: EndReason.values.byName(r['reason'] as String),
  finishedAt: DateTime.parse(r['finishedAt'] as String),
);
