package com.ravanix.push_up_bird

import android.app.Activity
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.PlayGamesSdk
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Starts Google Play Games only when the build carries a project id
 * (lib/data/play_games_ids.dart) and the phone has Play services. Otherwise
 * the SDK never starts, so nothing Play Games runs; its own start-up
 * provider is removed in AndroidManifest.xml for that reason. Dart asks
 * [ready] before making any Play Games call.
 */
object PlayGamesGate {
    private var ready = false

    /** Before the activity is created, so the SDK sees it start. */
    fun start(activity: Activity) {
        if (ready || activity.getString(R.string.game_services_project_id).isEmpty()) return
        val services = GoogleApiAvailability.getInstance()
            .isGooglePlayServicesAvailable(activity) == ConnectionResult.SUCCESS
        if (!services) return
        PlayGamesSdk.initialize(activity.applicationContext)
        ready = true
    }

    fun attach(engine: FlutterEngine, activity: Activity) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "push_up_bird/play_games")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ready" -> result.success(ready)
                    "listed" -> listed(activity, call.argument<String>("name"), result)
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Whether Play's servers list the saved game [name]: true or false from
     * a fresh list, null when Play could answer only from its cache
     * (offline), which may predate a save made on another phone. The
     * games_services plugin drops that difference.
     */
    private fun listed(activity: Activity, name: String?, result: MethodChannel.Result) {
        if (!ready || name == null) return result.success(null)
        PlayGames.getSnapshotsClient(activity).load(true)
            .addOnSuccessListener { answer ->
                val saves = answer.get()
                val found = if (answer.isStale || saves == null) null
                    else saves.any { it.uniqueName == name }
                saves?.release()
                result.success(found)
            }
            .addOnFailureListener { result.error("failed_to_list", it.message, null) }
    }
}
