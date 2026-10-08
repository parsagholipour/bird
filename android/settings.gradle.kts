pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("com.android.dynamic-feature") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
// The voice packs' feature modules (tool/l10n/prepare_localized_voices.py --wire).
// voice-packs:begin
include(":voice_es_419")
include(":voice_pt_br")
include(":voice_id")
include(":voice_fr")
include(":voice_de")
include(":voice_ja")
include(":voice_ko")
include(":voice_tr")
include(":voice_zh_hant")
include(":voice_ru")
include(":voice_ar")
// voice-packs:end
