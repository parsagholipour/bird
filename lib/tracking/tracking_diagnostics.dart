import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Two bounded, rolling developer logs. The caller supplies app storage.
/// Camera images are never written here.
class TrackingDiagnostics {
  TrackingDiagnostics(this.directory, {this.byteLimit = 4 * 1024 * 1024});
  final Directory directory;
  final int byteLimit;
  IOSink? _sink;
  int _bytes = 0;
  bool _failed = false;
  Future<void> _pending = Future.value();

  Future<void> start() async {
    await close();
    _bytes = 0;
    _failed = false;
    try {
      await directory.create(recursive: true);
      await _rotate();
    } on FileSystemException {
      _failed = true;
    }
  }

  void write(String message) {
    if (_failed || _sink == null) return;
    final line = utf8.encode('$message\n');
    if (line.length > byteLimit) return;
    _pending = _pending.then((_) async {
      if (_failed) return;
      try {
        if (_bytes + line.length > byteLimit) await _rotate();
        _bytes += line.length;
        _sink!.add(line);
      } catch (_) {
        _failed = true;
      }
    });
  }

  Future<void> _rotate() async {
    await _sink?.flush();
    await _sink?.close();
    final latest = File('${directory.path}/latest.log');
    if (await latest.exists()) {
      await latest.rename('${directory.path}/previous.log');
    }
    final sink = latest.openWrite();
    _sink = sink;
    _bytes = 0;
    unawaited(
      sink.done.catchError((Object _) {
        _failed = true;
      }),
    );
  }

  Future<void> flush() async {
    try {
      await _pending;
      await _sink?.flush();
    } catch (_) {
      _failed = true;
    }
  }

  Future<void> close() async {
    await _pending;
    final sink = _sink;
    _sink = null;
    try {
      await sink?.flush();
      await sink?.close();
    } catch (_) {
      _failed = true;
    }
  }
}
