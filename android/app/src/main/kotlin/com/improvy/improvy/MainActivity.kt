package com.improvy.improvy

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Fully transparent, edge-to-edge system bars. Some OEMs (Honor/EMUI,
        // Xiaomi…) otherwise keep an opaque/black scrim behind the 3-button
        // navigation bar even when Flutter requests edge-to-edge, so we clear
        // the colors and disable contrast enforcement natively.
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
    }

    /// Takes the user to this app's notification settings.
    ///
    /// Android asks for the notification permission once; after a refusal
    /// every later request returns false without showing anything, so this
    /// screen is the only way back. It cannot be expressed as a URL, which is
    /// why it is a channel rather than a url_launcher call. See
    /// lib/services/system_settings.dart.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "improvy/system_settings")
            .setMethodCallHandler { call, result ->
                if (call.method != "openNotificationSettings") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                result.success(openNotificationSettings())
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "improvy/store_diagnostics")
            .setMethodCallHandler { call, result ->
                if (call.method != "describe") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                result.success(describeStore())
            }
    }

    /// Where this copy of the app came from, and whether the Play Store is here
    /// at all.
    ///
    /// Play Billing answers `purchaseNotAllowedError` — no dialog, no detail —
    /// to an app it will not sell through, and the commonest reason by far is
    /// that the app was never installed from the Play Store. From inside the
    /// failure the two cases are indistinguishable, so we read the install
    /// source instead of guessing: "com.android.vending" is the Play Store,
    /// anything else is a sideload or another store, and null means even the
    /// installer is unknown. Attached to the purchase-failure event only.
    private fun describeStore(): Map<String, Any?> {
        val installer: String? = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                packageManager.getInstallSourceInfo(packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName)
            }
        } catch (_: Exception) {
            // getInstallSourceInfo throws for a package it cannot see. An
            // unreadable source is itself a signal, so report it as such
            // rather than letting the whole diagnostic fail.
            null
        }
        val playStore = try {
            packageManager.getPackageInfo("com.android.vending", 0)
        } catch (_: PackageManager.NameNotFoundException) {
            null
        } catch (_: Exception) {
            null
        }
        return mapOf(
            "installer" to installer,
            "from_play" to (installer == "com.android.vending"),
            "play_store_installed" to (playStore != null),
            "play_store_version" to playStore?.versionName,
            // A debuggable build cannot buy through Play either, and it is the
            // one case where the failure is expected rather than a bug.
            "debuggable" to
                ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0),
        )
    }

    private fun openNotificationSettings(): Boolean {
        // The per-app notification screen where it exists, and the plain app
        // details page on anything older — which is never empty-handed.
        val intents = mutableListOf<Intent>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intents.add(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            )
        }
        intents.add(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
        )
        for (intent in intents) {
            try {
                startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (_: Exception) {
                // Try the next one; an OEM that has removed the screen must
                // not crash the app for asking.
            }
        }
        return false
    }
}
