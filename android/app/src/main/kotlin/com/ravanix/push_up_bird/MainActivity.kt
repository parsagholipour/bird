package com.ravanix.push_up_bird

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Matrix
import android.hardware.camera2.CameraCharacteristics
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Size
import android.view.View
import android.view.WindowManager
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.concurrent.Executors
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.cancel

class MainActivity : FlutterActivity(), TrackingHostApi {
    private val callbacks = MainScope()
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var flutterApi: TrackingFlutterApi? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var preview: Preview? = null
    private var previewView: PreviewView? = null
    // Detector ownership is confined to worker. Generation fences invalidate late callbacks.
    private var pose: PoseLandmarker? = null
    private var face: FaceLandmarker? = null
    @Volatile private var generation = 0
    @Volatile private var running = false
    private var session = 0L
    private var permissionResult: ((Result<CameraAccess>) -> Unit)? = null
    private val trackingCaptures by lazy {
        if (BuildConfig.TRACKING_CAPTURE_IMAGES)
            TrackingCaptures(java.io.File(filesDir, "tracking_captures")) else null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterApi = TrackingFlutterApi(flutterEngine.dartExecutor.binaryMessenger)
        TrackingHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "push_up_bird/camera", object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
                    val view = PreviewView(context).apply {
                        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                        scaleType = PreviewView.ScaleType.FIT_CENTER
                        setBackgroundColor(android.graphics.Color.rgb(17, 40, 54))
                    }
                    previewView = view
                    preview?.setSurfaceProvider(view.surfaceProvider)
                    return object : PlatformView {
                        override fun getView(): View = view
                        override fun dispose() {
                            if (previewView === view) {
                                preview?.setSurfaceProvider(null)
                                previewView = null
                            }
                        }
                    }
                }
            })
    }

    override fun requestCamera(callback: (Result<CameraAccess>) -> Unit) {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)) {
            callback(Result.success(CameraAccess.UNAVAILABLE)); return
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            callback(Result.success(CameraAccess.GRANTED)); return
        }
        if (permissionResult != null) {
            callback(Result.failure(FlutterError("busy", "A camera permission request is already open"))); return
        }
        permissionResult = callback
        requestPermissions(arrayOf(Manifest.permission.CAMERA), 8041)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 8041) {
            val access = if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) CameraAccess.GRANTED
                else if (shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)) CameraAccess.DENIED
                else CameraAccess.PERMANENTLY_DENIED
            permissionResult?.invoke(Result.success(access))
            permissionResult = null
        }
    }

    override fun monotonicTimeMs(): Long = SystemClock.elapsedRealtime()
    override fun openAppSettings() {
        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
    }

    override fun start(detector: DetectorKind, frontCamera: Boolean, session: Long, callback: (Result<Unit>) -> Unit) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            callback(Result.failure(FlutterError("permission", "Camera permission is required"))); return
        }
        val token = ++generation
        this.session = session
        running = false
        cameraProvider?.unbindAll()
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        worker.execute {
            try {
                closeDetectors()
                val model = if (detector == DetectorKind.POSE) "pose_landmarker_lite.task" else "face_landmarker.task"
                val base = BaseOptions.builder().setModelAssetPath(model).build()
                if (detector == DetectorKind.POSE) {
                    pose = PoseLandmarker.createFromOptions(this,
                        PoseLandmarker.PoseLandmarkerOptions.builder().setBaseOptions(base)
                            .setRunningMode(RunningMode.VIDEO).setNumPoses(1)
                            .setMinPoseDetectionConfidence(0.6f).setMinPosePresenceConfidence(0.6f)
                            .setMinTrackingConfidence(0.6f).build())
                } else {
                    face = FaceLandmarker.createFromOptions(this,
                        FaceLandmarker.FaceLandmarkerOptions.builder().setBaseOptions(base)
                            .setRunningMode(RunningMode.VIDEO).setNumFaces(1)
                            .setMinFaceDetectionConfidence(0.6f).setMinFacePresenceConfidence(0.6f)
                            .setMinTrackingConfidence(0.6f).setOutputFaceBlendshapes(true).build())
                }
                main.post {
                    if (token != generation || isFinishing) {
                        callback(Result.failure(FlutterError("cancelled", "Camera start was cancelled")))
                    } else {
                        bindCamera(detector, frontCamera, session, token, callback)
                    }
                }
            } catch (error: Throwable) {
                android.util.Log.e("PushUpBird", "Detector initialization failed", error)
                closeDetectors()
                main.post {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    callback(Result.failure(FlutterError("model", error.cause?.toString() ?: error.toString())))
                }
            }
        }
    }

    @androidx.camera.camera2.interop.ExperimentalCamera2Interop
    private fun bindCamera(detector: DetectorKind, front: Boolean, session: Long, token: Int, callback: (Result<Unit>) -> Unit) {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            try {
                if (token != generation) {
                    callback(Result.failure(FlutterError("cancelled", "Camera start was cancelled"))); return@addListener
                }
                val provider = future.get()
                cameraProvider = provider
                val selector = if (front) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
                if (!provider.hasCamera(selector)) throw IllegalStateException("Selected camera is unavailable. Try the other camera.")
                val rotation = windowManager.defaultDisplay.rotation
                val resolution = ResolutionSelector.Builder().setResolutionStrategy(
                    ResolutionStrategy(Size(640, 480), ResolutionStrategy.FALLBACK_RULE_CLOSEST_LOWER_THEN_HIGHER)).build()
                val displayPreview = Preview.Builder().setTargetRotation(rotation).setResolutionSelector(resolution).build()
                preview = displayPreview
                previewView?.let { displayPreview.setSurfaceProvider(it.surfaceProvider) }
                val analysis = ImageAnalysis.Builder().setTargetRotation(rotation).setResolutionSelector(resolution)
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888).build()
                provider.unbindAll()
                val camera = provider.bindToLifecycle(this, selector, displayPreview, analysis)
                val realtime = Camera2CameraInfo.from(camera.cameraInfo).getCameraCharacteristic(
                    CameraCharacteristics.SENSOR_INFO_TIMESTAMP_SOURCE) == CameraCharacteristics.SENSOR_INFO_TIMESTAMP_SOURCE_REALTIME
                running = true
                var lastTimestamp = -1L
                worker.execute { trackingCaptures?.start() }
                analysis.setAnalyzer(worker) { image ->
                    if (!running || token != generation) { image.close(); return@setAnalyzer }
                    val startNs = SystemClock.elapsedRealtimeNanos()
                    val capturedMs = if (realtime) image.imageInfo.timestamp / 1_000_000 else startNs / 1_000_000
                    // VIDEO requires strictly increasing input timestamps, even on unusual camera HALs.
                    val timestamp = maxOf(capturedMs, lastTimestamp + 1)
                    lastTimestamp = timestamp
                    var raw: android.graphics.Bitmap? = null
                    var rotated: android.graphics.Bitmap? = null
                    try {
                        raw = image.toBitmap()
                        rotated = if (image.imageInfo.rotationDegrees == 0) raw else android.graphics.Bitmap.createBitmap(
                            raw, 0, 0, raw.width, raw.height,
                            Matrix().apply { postRotate(image.imageInfo.rotationDegrees.toFloat()) }, true)
                        // MPImage.close() releases its bitmap. Read dimensions
                        // while it is alive, before sending the result packet.
                        val imageWidth = rotated.width.toLong()
                        val imageHeight = rotated.height.toLong()
                        val input = BitmapImageBuilder(rotated).build()
                        val landmarks: List<LandmarkPacket>
                        var smile = 0.0
                        try {
                            if (detector == DetectorKind.POSE) {
                                val result = pose!!.detectForVideo(input, timestamp)
                                landmarks = result.landmarks().firstOrNull()?.map {
                                    LandmarkPacket(it.x().toDouble(), it.y().toDouble(), it.z().toDouble(),
                                        minOf(it.visibility().orElse(0f), it.presence().orElse(0f)).toDouble())
                                } ?: emptyList()
                            } else {
                                val result = face!!.detectForVideo(input, timestamp)
                                landmarks = result.faceLandmarks().firstOrNull()?.let { points ->
                                    // Only outline/eye/mouth points for preview; no frames cross into Dart.
                                    listOf(10, 152, 234, 454, 33, 263, 61, 291).map { i ->
                                        val p = points[i]; LandmarkPacket(p.x().toDouble(), p.y().toDouble(), p.z().toDouble(), 1.0)
                                    }
                                } ?: emptyList()
                                val shapes = result.faceBlendshapes().orElse(emptyList()).firstOrNull().orEmpty()
                                val left = shapes.firstOrNull { it.categoryName() == "mouthSmileLeft" }?.score() ?: 0f
                                val right = shapes.firstOrNull { it.categoryName() == "mouthSmileRight" }?.score() ?: 0f
                                smile = (left + right).toDouble() / 2
                            }
                            if (landmarks.isNotEmpty()) {
                                trackingCaptures?.capture(rotated, capturedMs, session)
                            }
                        } finally { input.close() }
                        val inference = (SystemClock.elapsedRealtimeNanos() - startNs) / 1_000_000.0
                        val packet = TrackingPacket(session, detector, capturedMs, SystemClock.elapsedRealtime(), inference,
                            imageWidth, imageHeight, landmarks, smile, landmarks.isNotEmpty(), realtime)
                        main.post {
                            if (running && token == generation) sendSample(packet)
                        }
                    } catch (error: Throwable) {
                        main.post {
                            if (token == generation) sendStatus(session, "inference", error.message ?: "Tracking interrupted")
                        }
                    } finally {
                        if (rotated !== raw) rotated?.recycle()
                        raw?.recycle()
                        image.close()
                    }
                }
                camera.cameraInfo.cameraState.observe(this) { state ->
                    if (token == generation && state.error != null) {
                        sendStatus(session, "camera", "Camera interrupted. Check camera permission and try again.")
                    }
                }
                callback(Result.success(Unit))
            } catch (error: Throwable) {
                running = false
                providerCleanup()
                worker.execute { closeDetectors() }
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                callback(Result.failure(FlutterError("camera", error.message ?: "Camera unavailable")))
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun sendSample(packet: TrackingPacket) { callbacks.launch { runCatching { flutterApi?.onSample(packet) } } }
    private fun sendStatus(session: Long, code: String, message: String) { callbacks.launch { runCatching { flutterApi?.onStatus(session, code, message) } } }

    override fun stop(callback: (Result<Unit>) -> Unit) {
        ++generation
        running = false
        providerCleanup()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        worker.execute {
            closeDetectors()
            main.post { callback(Result.success(Unit)) }
        }
    }
    private fun providerCleanup() { cameraProvider?.unbindAll(); preview = null }
    private fun closeDetectors() { pose?.close(); pose = null; face?.close(); face = null }
    override fun onStop() {
        if (running) {
            sendStatus(session, "background", "Camera stopped while the app was away")
            stop { }
        }
        super.onStop()
    }
    override fun onDestroy() {
        ++generation; running = false
        providerCleanup()
        permissionResult?.invoke(Result.failure(FlutterError("cancelled", "Activity closed")))
        permissionResult = null
        worker.execute { closeDetectors() }
        worker.execute { trackingCaptures?.close() }
        worker.shutdown()
        callbacks.cancel()
        super.onDestroy()
    }
}
