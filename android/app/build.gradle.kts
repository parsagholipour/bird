import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val captureTrackingImages = providers.gradleProperty("dart-defines").orNull
    ?.split(",")?.any {
        String(Base64.getDecoder().decode(it)) == "TRACKING_CAPTURE_IMAGES=true"
    } ?: false

// Google Play Games: the project id lives with every other Play id in
// lib/data/play_games_ids.dart. Empty leaves Play Games asleep
// (PlayGamesGate.kt).
val playGamesAppId = Regex("""playGamesAppId\s*=\s*'(\d*)'""")
    .find(
        providers.fileContents(
            rootProject.layout.projectDirectory.file("../lib/data/play_games_ids.dart")
        ).asText.get()
    )?.groupValues?.get(1).orEmpty()

// Release guard for the voice packs: a Play app bundle must carry every
// language's pack (each android/voice_<slug> module) as a deferred component.
// Dev builds may list fewer (tool/l10n/dev_voice_packs.py --only/--none keeps
// the APK small); then `flutter build appbundle` stops here until
// `python3 tool/l10n/dev_voice_packs.py --all`.
if (gradle.startParameter.taskNames.any { it.substringAfterLast(':').startsWith("bundle") }) {
    val voiceModules = rootProject.projectDir.listFiles().orEmpty()
        .filter { it.name.startsWith("voice_") && it.resolve("build.gradle.kts").isFile }
        .map { it.name }
        .toSortedSet()
    val listed = providers.gradleProperty("deferred-component-names").orNull.orEmpty()
        .split(',').filter { it.isNotBlank() }.toSet()
    val missing = voiceModules - listed
    if (missing.isNotEmpty()) {
        throw GradleException(
            "Voice packs missing from this app bundle: ${missing.joinToString()}. " +
                "pubspec.yaml lists a dev subset (tool/l10n/dev_voice_packs.py); run " +
                "`python3 tool/l10n/dev_voice_packs.py --all` before `flutter build appbundle`."
        )
    }
}

android {
    namespace = "com.ravanix.push_up_bird"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildFeatures {
        buildConfig = true
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ravanix.push_up_bird"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "game_services_project_id", playGamesAppId)
    }

    buildTypes {
        release {
            // Flutter turns R8 off for any app with deferred components (the
            // voice packs); they hold no code, so the base keeps it on.
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
        configureEach {
            buildConfigField("boolean", "TRACKING_CAPTURE_IMAGES",
                (name != "release" && captureTrackingImages).toString())
        }
    }
}

dependencies {
    implementation("androidx.camera:camera-core:1.6.2")
    implementation("androidx.camera:camera-camera2:1.6.2")
    implementation("androidx.camera:camera-lifecycle:1.6.2")
    implementation("androidx.camera:camera-view:1.6.2")
    implementation("androidx.camera:camera-video:1.6.2")
    implementation("com.google.mediapipe:tasks-vision:0.10.35")
    // The games_services plugin's own SDK, started by PlayGamesGate.kt.
    implementation("com.google.android.gms:play-services-games-v2:21.0.0")
    // Play Feature Delivery for the voice packs, used by VoicePackDelivery.kt
    // (Flutter's own Play manager is built on Play Core 1.x).
    implementation("com.google.android.play:feature-delivery:2.1.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
