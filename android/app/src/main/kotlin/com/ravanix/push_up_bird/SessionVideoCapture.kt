package com.ravanix.push_up_bird

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoRecordEvent
import androidx.core.content.ContextCompat
import java.io.File

/** Owns camera clips with optional microphone audio. Finalize is awaited before Flutter copies a file. */
class SessionVideoCapture(private val context: Context) {
    companion object {
        private val processDirectory = "${android.os.Process.myPid()}-${System.currentTimeMillis()}"
    }
    var recorder: Recorder? = null
    private var recording: Recording? = null
    private var finalized: CameraClip? = null
    private var failure: Throwable? = null
    private var starting: ((Result<Long>) -> Unit)? = null
    private val stopping = mutableListOf<(Result<CameraClip?>) -> Unit>()
    private val main = Handler(Looper.getMainLooper())
    private val directory = File(context.cacheDir, "session_videos").let { root ->
        root.mkdirs()
        // Drafts from a killed process were never saved. Do not retain them.
        root.listFiles()?.filter { it.name != processDirectory }?.forEach { it.deleteRecursively() }
        File(root, processDirectory).apply { mkdirs() }
    }

    fun start(withAudio: Boolean, callback: (Result<Long>) -> Unit) {
        val output = recorder
        if (output == null || recording != null) {
            callback(Result.failure(FlutterError("recording", "Camera recording is unavailable"))); return
        }
        finalized = null; failure = null; starting = callback
        val file = File(directory, "${System.currentTimeMillis()}-${System.nanoTime()}.mp4")
        var startedAt = 0L
        try {
            var pending = output.prepareRecording(context, FileOutputOptions.Builder(file).build())
            // Check again here: access may have been revoked since the setup switch.
            // A missing microphone must never prevent a camera-only recording.
            if (withAudio && ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                try { pending = pending.withAudioEnabled() }
                catch (_: SecurityException) { /* Continue without audio. */ }
            }
            recording = pending.start(ContextCompat.getMainExecutor(context)) { event ->
                    when (event) {
                        is VideoRecordEvent.Start -> {
                            startedAt = SystemClock.elapsedRealtime()
                            starting?.invoke(Result.success(startedAt)); starting = null
                        }
                        is VideoRecordEvent.Finalize -> {
                            recording = null
                            val duration = event.recordingStats.recordedDurationNanos / 1_000_000
                            // SOURCE_INACTIVE can finalize a usable clip on backgrounding.
                            if (duration > 0 && file.length() > 0 && startedAt > 0 &&
                                (!event.hasError() || event.error == VideoRecordEvent.Finalize.ERROR_SOURCE_INACTIVE)) {
                                finalized = CameraClip(file.absolutePath, startedAt, duration, hasAudio(file))
                            } else {
                                file.delete()
                                failure = FlutterError("recording", "The camera clip could not be finalized (${event.error})")
                            }
                            starting?.invoke(Result.failure(failure ?: FlutterError("recording", "Recording ended before start")))
                            starting = null
                            val waiters = stopping.toList(); stopping.clear()
                            if (waiters.isNotEmpty()) {
                                val result = result()
                                waiters.forEach { it(result) }
                            }
                        }
                    }
                }
            main.postDelayed({
                if (starting === callback) {
                    starting = null
                    callback(Result.failure(FlutterError("recording", "Camera recording timed out")))
                    requestStop()
                }
            }, 8000)
        } catch (error: Throwable) {
            starting = null; recording = null; file.delete()
            if (withAudio && error is SecurityException) start(false, callback)
            else callback(Result.failure(error))
        }
    }
    private fun hasAudio(file: File): Boolean {
        val metadata = MediaMetadataRetriever()
        return try {
            metadata.setDataSource(file.absolutePath)
            metadata.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO) == "yes"
        } catch (_: Exception) { false }
        finally { metadata.release() }
    }
    private fun result(): Result<CameraClip?> {
        val error = failure; val clip = finalized
        failure = null; finalized = null
        return if (error != null) Result.failure(error) else Result.success(clip)
    }
    fun stop(callback: (Result<CameraClip?>) -> Unit) {
        if (recording == null) { callback(result()); return }
        stopping.add(callback)
        requestStop()
    }
    fun requestStop() { recording?.stop() }
}
