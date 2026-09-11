package com.ravanix.push_up_bird

import android.graphics.Bitmap
import android.util.Log
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Opt-in development images, held privately and bounded to two camera sessions. */
internal class TrackingCaptures(private val root: File) {
    private val writer = Executors.newSingleThreadExecutor()
    private val busy = AtomicBoolean(false)
    private var lastCapture = Long.MIN_VALUE
    private var slot = 0

    // Called on the camera worker before any frames of a new session.
    fun start() {
        lastCapture = Long.MIN_VALUE
        slot = 0
        writer.execute {
            runCatching {
                val latest = File(root, "latest")
                File(root, "previous").deleteRecursively()
                if (latest.exists()) check(latest.renameTo(File(root, "previous")))
                check(latest.mkdirs())
            }.onFailure { Log.w("PushUpBird", "Developer image storage unavailable", it) }
        }
    }

    // Copy while MediaPipe still owns a live bitmap. Slow storage drops captures
    // rather than queueing camera frames or delaying inference with disk writes.
    fun capture(bitmap: Bitmap, nativeTime: Long, session: Long) {
        if (lastCapture != Long.MIN_VALUE && nativeTime - lastCapture < 1000) return
        if (!busy.compareAndSet(false, true)) return
        val copy = try {
            val scale = 320.0 / maxOf(bitmap.width, bitmap.height)
            Bitmap.createScaledBitmap(bitmap, (bitmap.width * scale).toInt().coerceAtLeast(1),
                (bitmap.height * scale).toInt().coerceAtLeast(1), true).let {
                if (it === bitmap) bitmap.copy(Bitmap.Config.ARGB_8888, false) else it
            }
        } catch (error: Exception) {
            busy.set(false)
            Log.w("PushUpBird", "Developer image copy unavailable", error)
            return
        }
        lastCapture = nativeTime
        val index = slot++ % 120
        writer.execute {
            try {
                val directory = File(root, "latest")
                val target = File(directory, "frame-$index.jpg")
                target.outputStream().use { check(copy.compress(Bitmap.CompressFormat.JPEG, 65, it)) }
                File(directory, "frame-$index.json").writeText(
                    "{\"nativeT\":$nativeTime,\"session\":$session,\"width\":${copy.width},\"height\":${copy.height}}")
            } catch (error: Exception) {
                Log.w("PushUpBird", "Developer image write unavailable", error)
            } finally {
                copy.recycle()
                busy.set(false)
            }
        }
    }

    fun close() { writer.shutdown() }
}
