import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.improvy.improvy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required by flutter_local_notifications (java.time backport).
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.improvy.app"
        // RevenueCat Paywalls (purchases_ui_flutter) require Android API 24+.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // R8 renamed androidx.work's generated Room database, which Room then
            // could not find by name — the app died at launch on every device,
            // in release only, before any Dart ran:
            //
            //   Unable to get provider androidx.startup.InitializationProvider
            //   Caused by: Failed to create an instance of
            //              androidx.work.impl.WorkDatabase
            //
            // (WorkManager comes in with home_widget.) Shrinking buys a Flutter
            // app very little — the Dart is already AOT-compiled, so R8 only
            // touches the Java/Kotlin glue — and it puts every plugin that
            // resolves a class by name one missing keep rule away from the same
            // crash. Not worth the megabyte.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications (see isCoreLibraryDesugaringEnabled).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
