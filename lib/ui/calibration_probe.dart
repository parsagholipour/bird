import '../domain/squat_tracking.dart';
import 'squat_setup_art.dart';
import 'jump_setup_art.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/tracking.dart';
import '../domain/jump_tracking.dart';
import '../tracking/native_tracking_source.dart';

class CalibrationProbe extends StatefulWidget {
  const CalibrationProbe({super.key});
  @override
  State<CalibrationProbe> createState() => _CalibrationProbeState();
}

class _CalibrationProbeState extends State<CalibrationProbe>
    with WidgetsBindingObserver {
  final source = NativeTrackingSource();
  final metrics = TrackingMetrics();
  BodyCalibrator body = BodyCalibrator();
  JumpCalibrator jump = JumpCalibrator();
  SquatCalibrator squat = SquatCalibrator();
  MovementInterpreter? interpreter;
  PlayMode mode = PlayMode.pushUp;
  TrackingSample? sample;
  StreamSubscription<TrackingSample>? sub;
  StreamSubscription<TrackingIssue>? errors;
  String message =
      'Prop your phone low in landscape, facing you or beside you.';
  bool started = false, busy = false, front = true;
  double height = 0.5;
  int flaps = 0, reps = 0;
  double lastDiagnosticMs = -10000;
  String diagnostic = '';
  Timer? refresh;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sub = source.samples.listen((s) {
      sample = s;
      metrics.add(s, source.nowMs);
      if (interpreter == null) {
        if (mode == PlayMode.pushUp) {
          body.add(s, source.nowMs);
          height = body.previewHeight;
          message = body.feedback;
          if (body.result == null &&
              body.step == BodyCalibrationStep.position &&
              s.joints.length >= 33) {
            final names = ['shoulder', 'elbow', 'wrist', 'hip'];
            final ids = [11, 13, 15, 23];
            final side =
                ids.where((i) => s.joints[i].confidence >= .3).length >=
                    ids.where((i) => s.joints[i + 1].confidence >= .3).length
                ? 0
                : 1;
            final missing = [
              for (var i = 0; i < ids.length; i++)
                if (s.joints[ids[i] + side].confidence < .3) names[i],
            ];
            if (missing.isNotEmpty) {
              message = 'Almost there · need a clearer ${missing.join(', ')}';
            }
          }
          if (body.result != null) {
            interpreter = PushUpInterpreter(body.result!);
          }
        } else if (mode == PlayMode.squat) {
          squat.add(s, source.nowMs);
          height = squat.previewHeight;
          message = squat.feedback;
          if (squat.result != null) {
            interpreter = SquatInterpreter(squat.result!);
          }
        } else {
          jump.add(s, source.nowMs);
          message = jump.feedback;
          if (jump.result != null) interpreter = JumpInterpreter(jump.result!);
        }
      } else {
        final input = interpreter!.add(s, source.nowMs);
        message = input.feedback;
        if (input.valid) {
          if (mode.controlsHeight) height = input.height;
          reps = input.repetitions;
          if (input.flap) {
            flaps++;
            height = 0.8;
          }
        }
      }
      if (mode == PlayMode.pushUp && source.nowMs - lastDiagnosticMs >= 1000) {
        lastDiagnosticMs = source.nowMs;
        diagnostic = bodyDiagnostics(
          s,
          source.nowMs,
          preferredSide: body.side,
          preferredPerspective: body.perspective,
        );
        source.recordDiagnostic(
          'PushUpBird pose: $diagnostic; '
          '$message; step=${body.step.name}; cycles=${body.cycles}; '
          'height=${height.toStringAsFixed(2)}',
        );
      }
    });
    errors = source.issues.listen((e) {
      if (mounted) setState(() => message = e.message);
    });
    refresh = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mode == PlayMode.jump) height = (height - 0.02).clamp(0.1, 1);
      if (mounted) setState(() {});
    });
  }

  Future<void> start() async {
    setState(() {
      busy = true;
      message = 'Starting camera…';
    });
    try {
      if (!await source.requestPermission()) {
        setState(
          () => message =
              'Camera access is off. Allow it in app settings, then try again.',
        );
        return;
      }
      await source.stop();
      body = BodyCalibrator();
      jump = JumpCalibrator();
      squat = SquatCalibrator();
      interpreter = null;
      flaps = 0;
      reps = 0;
      height = .5;
      await source.start(mode, frontCamera: front);
      setState(() => started = true);
    } catch (e) {
      setState(() => message = 'Camera could not start: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      source.stop();
      setState(() {
        started = false;
        message = 'Camera stopped. Tap Start to recalibrate.';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    refresh?.cancel();
    sub?.cancel();
    errors?.cancel();
    source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xffe8f5fb),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const AndroidView(viewType: 'push_up_bird/camera'),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: LandmarkPainter(sample, front, mode),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => context.go('/'),
                        child: Text(
                          'CAMERA LAB · Back to home',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            shadows: [Shadow(blurRadius: 8)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xdd123346),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$message${diagnostic.isEmpty || mode != PlayMode.pushUp ? '' : '\n$diagnostic'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interpreter != null
                        ? '3. Move your bird!'
                        : mode == PlayMode.squat
                        ? 'Find your squat range'
                        : mode == PlayMode.jump
                        ? 'Find your standing position'
                        : body.step == BodyCalibrationStep.position
                        ? '1. Show your arms & hip'
                        : '2. Do two push-ups',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mode == PlayMode.pushUp
                        ? 'Phone low, facing you or beside you.\nFacing it? Show both shoulders, an arm and hip.\nMove down and up twice at your own pace.'
                        : mode == PlayMode.squat
                        ? 'Stand still, squat comfortably and hold briefly, then stand back up. Squat to descend; stand to rise.'
                        : 'Stand facing the phone with your whole body and feet visible. Hold still, then make small jumps. One jump = one big boost.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(-0.5, 0.9 - height * 1.8),
                          child: const Icon(
                            Icons.flutter_dash,
                            color: Color(0xffef795e),
                            size: 56,
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Text(
                            interpreter == null
                                ? (mode == PlayMode.pushUp
                                      ? 'CALIBRATION\n${body.cycles} / 2 calibrated'
                                      : 'CALIBRATION\n${((mode == PlayMode.squat ? squat.progress : jump.progress) * 100).round()}% calibrated')
                                : 'CONTROL TEST\n${mode == PlayMode.pushUp
                                      ? '$reps push-ups'
                                      : mode == PlayMode.squat
                                      ? '$reps squats'
                                      : '$flaps jumps'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 4,
                          child: Text(
                            '${metrics.hz.toStringAsFixed(1)} Hz · ${metrics.p95.toStringAsFixed(0)} ms p95',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: busy ? null : start,
                          child: Text(
                            busy
                                ? 'Starting…'
                                : started
                                ? 'Recalibrate'
                                : 'Start camera',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: busy
                            ? null
                            : () async {
                                front = !front;
                                if (started) {
                                  await start();
                                } else {
                                  setState(() {});
                                }
                              },
                        icon: const Icon(Icons.cameraswitch_outlined),
                      ),
                      IconButton(
                        onPressed: source.openSettings,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            await source.stop();
                            setState(() {
                              mode = switch (mode) {
                                PlayMode.pushUp => PlayMode.jump,
                                PlayMode.jump => PlayMode.squat,
                                _ => PlayMode.pushUp,
                              };
                              started = false;
                              sample = null;
                              interpreter = null;
                              message = 'Tap Start camera';
                            });
                          },
                    child: Text(
                      'Try ${mode == PlayMode.pushUp
                          ? 'Jump & Fly'
                          : mode == PlayMode.jump
                          ? 'Squat & Fly'
                          : 'Push-Up Flight'}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LandmarkPainter extends CustomPainter {
  LandmarkPainter(this.sample, this.front, this.mode);
  final TrackingSample? sample;
  final bool front;
  final PlayMode mode;
  @override
  void paint(Canvas canvas, Size size) {
    final s = sample;
    final paint = Paint()
      ..color = const Color(0xffc9ef84)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (s == null ||
        !s.detected ||
        (mode == PlayMode.pushUp && !observeBody(s, s.receivedMs).valid) ||
        (mode == PlayMode.jump && !observeJump(s, s.receivedMs).valid) ||
        (mode == PlayMode.squat && !observeSquat(s, s.receivedMs).valid)) {
      paint.color = Colors.white.withValues(alpha: 0.45);
      paint.strokeWidth = 3;
      if (mode == PlayMode.squat) {
        SquatSetupArt(color: paint.color).paint(canvas, size);
      } else if (mode == PlayMode.jump) {
        JumpSetupArt(color: paint.color).paint(canvas, size);
      } else {
        final p = [
          Offset(size.width * .25, size.height * .45),
          Offset(size.width * .33, size.height * .58),
          Offset(size.width * .27, size.height * .79),
          Offset(size.width * .5, size.height * .54),
          Offset(size.width * .68, size.height * .67),
          Offset(size.width * .8, size.height * .79),
        ];
        for (final pair in [
          [0, 1],
          [1, 2],
          [0, 3],
          [3, 4],
          [4, 5],
        ]) {
          canvas.drawLine(p[pair[0]], p[pair[1]], paint);
        }
        canvas.drawCircle(
          Offset(size.width * .2, size.height * .36),
          15,
          paint,
        );
      }
      if (s == null || !s.detected) return;
    }
    final ratio = s.aspectRatio;
    final w = size.aspectRatio > ratio ? size.height * ratio : size.width;
    final h = w / ratio;
    final dx = (size.width - w) / 2, dy = (size.height - h) / 2;
    Offset pos(Joint p) =>
        Offset(dx + (front ? 1 - p.x : p.x) * w, dy + p.y * h);
    if (s.joints.length >= 33) {
      for (final side in [0, 1]) {
        for (final pair in [
          [11, 13],
          [13, 15],
          [11, 23],
          [23, 25],
          [25, 27],
          if (mode == PlayMode.jump) [27, 31],
        ]) {
          final a = s.joints[pair[0] + side], b = s.joints[pair[1] + side];
          if (a.confidence >= .3 && b.confidence >= .3) {
            canvas.drawLine(pos(a), pos(b), paint);
          }
        }
      }
    }
    paint.style = PaintingStyle.fill;
    for (var i = 11; i < s.joints.length; i++) {
      if (s.joints[i].confidence >= .3) {
        canvas.drawCircle(pos(s.joints[i]), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LandmarkPainter oldDelegate) => true;
}
