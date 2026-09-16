import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/tracking/tracking_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/ravanix/push_up_bird/TrackingApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.ravanix.push_up_bird'),
    swiftOut: 'ios/Runner/TrackingApi.g.swift',
  ),
)
enum DetectorKind { pose, face }

enum CameraAccess { granted, denied, permanentlyDenied, unavailable }

enum MicrophoneAccess { granted, denied, permanentlyDenied, unavailable }

class LandmarkPacket {
  LandmarkPacket({
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
  });
  double x;
  double y;
  double z;
  double confidence;
}

class TrackingPacket {
  TrackingPacket({
    required this.session,
    required this.detector,
    required this.capturedAtMs,
    required this.sentAtMs,
    required this.inferenceMs,
    required this.imageWidth,
    required this.imageHeight,
    required this.landmarks,
    required this.smile,
    required this.detected,
    required this.sensorTimestamp,
  });
  int session;
  DetectorKind detector;
  int capturedAtMs;
  int sentAtMs;
  double inferenceMs;
  int imageWidth;
  int imageHeight;
  List<LandmarkPacket> landmarks;
  double smile;
  bool detected;
  bool sensorTimestamp;
}

class CameraClip {
  CameraClip({
    required this.path,
    required this.startedAtMs,
    required this.durationMs,
    this.hasAudio = false,
  });
  String path;
  int startedAtMs;
  int durationMs;
  bool hasAudio;
}

@HostApi()
abstract class TrackingHostApi {
  @asyncCallback
  CameraAccess requestCamera();
  MicrophoneAccess microphoneAccess();
  @asyncCallback
  MicrophoneAccess requestMicrophone();
  @asyncCallback
  void start(DetectorKind detector, bool frontCamera, int session);
  @asyncCallback
  void stop();
  @asyncCallback
  int startRecording(bool withAudio);
  @asyncCallback
  CameraClip? stopRecording();
  int monotonicTimeMs();
  void openAppSettings();
}

@FlutterApi()
abstract class TrackingFlutterApi {
  void onSample(TrackingPacket packet);
  void onStatus(int session, String code, String message);
}
