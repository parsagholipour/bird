package com.ravanix.push_up_bird

import android.content.Context
import com.google.android.play.core.splitcompat.SplitCompat
import com.google.android.play.core.splitcompat.SplitCompatApplication
import com.google.android.play.core.splitinstall.SplitInstallException
import com.google.android.play.core.splitinstall.SplitInstallManager
import com.google.android.play.core.splitinstall.SplitInstallManagerFactory
import com.google.android.play.core.splitinstall.SplitInstallRequest
import com.google.android.play.core.splitinstall.SplitInstallSessionState
import com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
import com.google.android.play.core.splitinstall.model.SplitInstallSessionStatus
import io.flutter.FlutterInjector
import io.flutter.Log
import io.flutter.embedding.engine.FlutterJNI
import io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager
import io.flutter.embedding.engine.loader.ApplicationInfoLoader
import io.flutter.embedding.engine.systemchannels.DeferredComponentChannel

/**
 * The app. SplitCompat makes the voice packs (Play feature modules,
 * l10n-ws/VOICE-PLAN.md) installed earlier readable from launch, and
 * [VoicePackDelivery] serves Flutter's deferred components.
 */
class BeakboundApplication : SplitCompatApplication() {
    override fun onCreate() {
        super.onCreate()
        FlutterInjector.setInstance(
            FlutterInjector.Builder()
                .setDeferredComponentManager(VoicePackDelivery(this))
                .build(),
        )
    }
}

/**
 * Flutter's deferred components on Play Feature Delivery 2.x, for the voice
 * packs: asset-only components, so it installs modules and hands the engine
 * a fresh asset manager, and never loads Dart code.
 *
 * Flutter's own PlayStoreDeferredComponentManager (and so
 * FlutterPlayStoreSplitApplication) is compiled against Play Core 1.x, whose
 * `com.google.android.play.core.tasks.Task` Play Core 2.x replaced with GMS
 * tasks (R8: "Missing class com.google.android.play.core.tasks.Task"), and
 * Play Core 1.x itself crashes on Android 14 with a modern target SDK. It
 * also leaves Dart waiting forever when Play refuses to start an install.
 * This one answers every install, and reports download progress in its state
 * (`downloading:<bytes>/<total>`, read by lib/game/voice_packs.dart).
 */
class VoicePackDelivery(context: Context) : DeferredComponentManager {
    private val app: Context = context.applicationContext ?: context
    private val assetsDir = ApplicationInfoLoader.load(app).flutterAssetsDir
    private val play: SplitInstallManager = SplitInstallManagerFactory.create(app)
    private var jni: FlutterJNI? = null
    private var channel: DeferredComponentChannel? = null

    /** Each module's last state, as getDeferredComponentInstallState says it. */
    private val states = HashMap<String, String>()

    /** Play's install sessions, to the module each installs. */
    private val sessions = HashMap<Int, String>()

    private val listener = SplitInstallStateUpdatedListener { state -> update(state) }

    init {
        play.registerListener(listener)
    }

    override fun setJNI(flutterJNI: FlutterJNI) {
        jni = flutterJNI
    }

    override fun setDeferredComponentChannel(channel: DeferredComponentChannel) {
        this.channel = channel
    }

    override fun installDeferredComponent(loadingUnitId: Int, componentName: String?) {
        val name = componentName ?: run {
            Log.e(TAG, "Only named, asset-only components are delivered here")
            return
        }
        if (play.installedModules.contains(name)) {
            installed(name)
            return
        }
        states[name] = "requested"
        val request = SplitInstallRequest.newBuilder().addModule(name).build()
        play.startInstall(request)
            .addOnSuccessListener { session ->
                if (session == 0) installed(name) else sessions[session] = name
            }
            .addOnFailureListener { error ->
                val code = (error as? SplitInstallException)?.errorCode
                failed(name, "Play did not start the install (${code ?: error.message})")
            }
    }

    private fun update(state: SplitInstallSessionState) {
        val name = sessions[state.sessionId()]
            ?: state.moduleNames().firstOrNull { states.containsKey(it) }
            ?: return
        when (state.status()) {
            SplitInstallSessionStatus.PENDING -> states[name] = "pending"
            SplitInstallSessionStatus.DOWNLOADING ->
                states[name] = "downloading:${state.bytesDownloaded()}/${state.totalBytesToDownload()}"
            SplitInstallSessionStatus.DOWNLOADED -> states[name] = "downloaded"
            SplitInstallSessionStatus.INSTALLING -> states[name] = "installing"
            SplitInstallSessionStatus.INSTALLED -> {
                sessions.remove(state.sessionId())
                installed(name)
            }
            SplitInstallSessionStatus.FAILED -> {
                sessions.remove(state.sessionId())
                failed(name, "Play failed the install (${state.errorCode()})")
            }
            SplitInstallSessionStatus.CANCELED -> {
                sessions.remove(state.sessionId())
                failed(name, "The install was cancelled")
            }
            SplitInstallSessionStatus.CANCELING -> states[name] = "canceling"
            // Needs a dialog from an activity; the game reports it as failed.
            SplitInstallSessionStatus.REQUIRES_USER_CONFIRMATION ->
                states[name] = "requiresUserConfirmation"
            else -> Unit
        }
    }

    private fun installed(name: String) {
        loadAssets(-1, name)
        states[name] = "installed"
        channel?.completeInstallSuccess(name)
    }

    private fun failed(name: String, message: String) {
        Log.e(TAG, "$name: $message")
        states[name] = "failed"
        channel?.completeInstallError(name, message)
    }

    override fun getDeferredComponentInstallState(
        loadingUnitId: Int,
        componentName: String?,
    ): String {
        val name = componentName ?: return "unknown"
        return states[name]
            ?: if (play.installedModules.contains(name)) "installedPendingLoad" else "unknown"
    }

    override fun loadAssets(loadingUnitId: Int, componentName: String?) {
        val jni = jni ?: return
        // Adds a module installed in this session to the app's assets, then
        // gives the engine an asset manager that sees it (as Flutter's own
        // manager does).
        SplitCompat.install(app)
        val fresh = app.createPackageContext(app.packageName, 0)
        jni.updateJavaAssetManager(fresh.assets, assetsDir)
    }

    override fun loadDartLibrary(loadingUnitId: Int, componentName: String?) {
        // The voice packs hold no Dart code.
    }

    override fun uninstallDeferredComponent(loadingUnitId: Int, componentName: String?): Boolean {
        val name = componentName ?: return false
        play.deferredUninstall(listOf(name))
        states.remove(name)
        return true
    }

    override fun destroy() {
        play.unregisterListener(listener)
        channel = null
        jni = null
    }

    private companion object {
        const val TAG = "VoicePackDelivery"
    }
}
