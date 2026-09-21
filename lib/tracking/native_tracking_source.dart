import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/tracking.dart';
import 'tracking_api.g.dart';
import 'tracking_diagnostics.dart';

const trackingDiagnosticsEnabled =
    !kReleaseMode && bool.fromEnvironment('TRACKING_DIAGNOSTICS');

class NativeTrackingSource implements TrackingSource, TrackingFlutterApi {
  NativeTrackingSource() {
    TrackingFlutterApi.setUp(this);
  }
  final _host = TrackingHostApi();
  final _samples = StreamController<TrackingSample>.broadcast(sync: true);
  final _issues = StreamController<TrackingIssue>.broadcast(sync: true);
  final _clock = Stopwatch()..start();
  int _session = 0;
  bool _active = false;
  PlayMode _mode = PlayMode.pushUp;
  double _nativeOffset = 0;
  TrackingDiagnostics? _diagnostics;
  void recordDiagnostic(String message) {
    if (!trackingDiagnosticsEnabled) return;
    debugPrintSynchronously(message);
    _diagnostics?.write(message);
  }

  CameraAccess? access;
  @override
  Stream<TrackingSample> get samples => _samples.stream;
  @override
  Stream<TrackingIssue> get issues => _issues.stream;
  @override
  double get nowMs => _clock.elapsedMicroseconds / 1000;
  @override
  Future<bool> requestPermission() async {
    access = await _host.requestCamera();
    return access == CameraAccess.granted;
  }

  Future<MicrophoneAccess> microphoneAccess() => _host.microphoneAccess();
  Future<MicrophoneAccess> requestMicrophone() => _host.requestMicrophone();
  Future<double> startRecording({bool withAudio = false}) async =>
      await _host.startRecording(withAudio) + _nativeOffset;
  Future<CameraClip?> stopRecording() => _host.stopRecording();
  double recordingTime(int nativeMs) => nativeMs + _nativeOffset;

  Future<void> openSettings() => _host.openAppSettings();
  @override
  Future<void> start(PlayMode mode, {bool frontCamera = true}) async {
    _active = false;
    final session = ++_session;
    if (trackingDiagnosticsEnabled) {
      try {
        final folder = await getApplicationSupportDirectory();
        _diagnostics ??= TrackingDiagnostics(
          Directory('${folder.path}/tracking_diagnostics'),
        );
        await _diagnostics!.start();
        recordDiagnostic(
          'PushUpBird session: ${DateTime.now().toIso8601String()} '
          'mode=${mode.name} session=$session front=$frontCamera',
        );
      } catch (error) {
        debugPrint('PushUpBird diagnostics unavailable: $error');
      }
    }
    // Lowest-RTT midpoint gives a monotonic host-to-Dart clock mapping.
    double best = double.infinity;
    for (var i = 0; i < 5; i++) {
      final before = nowMs;
      final native = await _host.monotonicTimeMs();
      final after = nowMs;
      if (after - before < best) {
        best = after - before;
        _nativeOffset = (before + after) / 2 - native;
      }
    }
    if (session != _session) return;
    _mode = mode;
    _active = true;
    try {
      await _host.start(DetectorKind.pose, frontCamera, session);
    } catch (_) {
      if (session == _session) _active = false;
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    _active = false;
    ++_session;
    await _host.stop();
    await _diagnostics?.flush();
  }

  @override
  void onSample(TrackingPacket packet) {
    if (!_active ||
        packet.session != _session ||
        packet.detector != DetectorKind.pose) {
      return;
    }
    final sample = TrackingSample(
      mode: _mode,
      timestampMs: packet.capturedAtMs + _nativeOffset,
      receivedMs: nowMs,
      joints: packet.landmarks
          .map((p) => Joint(p.x, p.y, p.z, p.confidence))
          .toList(growable: false),
      aspectRatio: packet.imageWidth / packet.imageHeight,
      detected: packet.detected,
      inferenceMs: packet.inferenceMs,
      sensorTimestamp: packet.sensorTimestamp,
    );
    _samples.add(sample);
    if (trackingDiagnosticsEnabled) {
      // Opt-in developer trace: landmarks and timing only, never camera frames.
      // Emit synchronously to avoid Flutter's throttled debug-log queue changing
      // the ordering of the capture used by the offline replay.
      final ids = [
        11,
        12,
        13,
        14,
        15,
        16,
        23,
        24,
        25,
        26,
        27,
        28,
        if (_mode == PlayMode.jump) ...[31, 32],
      ];
      recordDiagnostic(
        'PushUpBird trace: ${jsonEncode({
          't': sample.timestampMs,
          'now': sample.receivedMs,
          'nativeT': packet.capturedAtMs,
          'session': packet.session,
          'aspect': sample.aspectRatio,
          'detected': sample.detected,
          'mode': sample.mode.name,
          'ids': ids,
          'joints': sample.joints.length >= 33 ? ids.map((i) {
                  final p = sample.joints[i];
                  return [p.x, p.y, p.z, p.confidence].map((v) => v.isFinite ? v : null).toList();
                }).toList() : [],
        })}',
      );
    }
  }

  @override
  void onStatus(int session, String code, String message) {
    if (_active && session == _session) {
      _issues.add(TrackingIssue(code, message));
    }
  }

  Future<void> dispose() async {
    await stop();
    await _diagnostics?.close();
    TrackingFlutterApi.setUp(null);
    await _samples.close();
    await _issues.close();
  }
}

class TrackingMetrics {
  final List<double> _latencies = [], _arrivals = [];
  double inference = 0;
  bool sensorTimestamp = false;
  void add(TrackingSample s, double consumedAtMs) {
    _latencies.add((consumedAtMs - s.timestampMs).clamp(0, 10000));
    _arrivals.add(consumedAtMs);
    inference = s.inferenceMs;
    sensorTimestamp = s.sensorTimestamp;
    if (_latencies.length > 600) _latencies.removeAt(0);
    while (_arrivals.length > 1 && _arrivals.first < consumedAtMs - 5000) {
      _arrivals.removeAt(0);
    }
  }

  int get count => _latencies.length;
  double get hz => _arrivals.length < 2
      ? 0
      : (_arrivals.length - 1) * 1000 / (_arrivals.last - _arrivals.first);
  double get p95 {
    if (_latencies.isEmpty) return 0;
    final sorted = [..._latencies]..sort();
    return sorted[((sorted.length - 1) * 0.95).ceil()];
  }
}
