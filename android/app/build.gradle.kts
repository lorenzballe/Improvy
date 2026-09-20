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

    // The upload keystore lives outside the repository (android/key.properties
    // points at it; both are gitignored). A checkout without it — a fresh
    // machine, a CI job that only compiles — used to die at Gradle
    // configuration on `null cannot be cast to non-null type kotlin.String`,
    // for every build type including `flutter run`. Now only the release
    // signing config depends on it.
    val hasReleaseKeystore = keyPropertiesFile.exists()
    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
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
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Signed with the debug key so the build still completes and
                // installs. Such a bundle can never go to Play — it would be
                // refused for the wrong signature — so say so, loudly.
                signingConfig = signingConfigs.getByName("debug")
                logger.warn(
                    "WARNING: android/key.properties not found — the release build is " +
                        "signed with the DEBUG key and cannot be uploaded to Play. " +
                        "Create key.properties pointing at the upload keystore first."
                )
            }
            // R8 is on: Play flags a release without it ("Enable app
            // optimization", Android vitals). It was off because a release
            // once died at launch, before any Dart ran, on
            //
            //   Unable to get provider androidx.startup.InitializationProvider
            //   Caused by: Failed to create an instance of
            //              androidx.work.impl.WorkDatabase
            //
            // WorkManager — in through home_widget's Glance — has a Room
            // database that Room instantiates by reflection, and R8 had
            // stripped its no-argument constructor. proguard-rules.pro keeps
            // it now, and names the few other things R8 must not touch. Two
            // belts besides: gradle.properties runs R8 in compatibility mode,
            // and res/raw/keep.xml pins the widgets' resources.
            //
            // A release build is the ONLY place this can fail, so before an
            // upload: `flutter build apk --release`, install it, open the app,
            // then a reminder, the widgets, sign-in, restore. If R8 stops the
            // build with "Missing class …", it prints the exact rule to add to
            // proguard-rules.pro. To retreat, set both flags to false.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
