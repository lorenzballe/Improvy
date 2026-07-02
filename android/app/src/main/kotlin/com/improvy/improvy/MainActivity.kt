package com.improvy.improvy

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

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
}
