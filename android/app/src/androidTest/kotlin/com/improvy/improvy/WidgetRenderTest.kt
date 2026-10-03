package com.improvy.improvy

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.graphics.Shader
import android.view.View
import android.widget.FrameLayout
import android.widget.RemoteViews
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.io.FileOutputStream

/**
 * Draws every home-screen widget exactly as a launcher would: the real
 * RemoteViews from [WidgetViews], applied and laid out at the widget's size,
 * with the payload the app really writes (test/widget_payload_test.dart,
 * copied into this test's assets by .github/workflows/android-widgets.yml).
 *
 * Writes one PNG per widget and state, and a gallery per state, into the app's
 * files dir, where the workflow pulls them from.
 */
@RunWith(AndroidJUnit4::class)
class WidgetRenderTest {

    private class Spec(val name: String, val wDp: Int, val hDp: Int, val build: (Context, SharedPreferences) -> RemoteViews)

    private val specs = listOf(
        Spec("quiz", 158, 158) { c, d -> WidgetViews.quiz(c, d, false) },
        Spec("level", 158, 158) { c, d -> WidgetViews.level(c, d) },
        Spec("streak", 158, 158) { c, d -> WidgetViews.streak(c, d, false) },
        Spec("weakest", 158, 158) { c, d -> WidgetViews.weakest(c, d) },
        Spec("pocket", 158, 158) { c, d -> WidgetViews.pocket(c, d) },
        Spec("daily", 338, 158) { c, d -> WidgetViews.daily(c, d) },
        Spec("quiz_wide", 338, 158) { c, d -> WidgetViews.quiz(c, d, true) },
        Spec("streak_wide", 338, 158) { c, d -> WidgetViews.streak(c, d, true) },
        Spec("map", 338, 158) { c, d -> WidgetViews.map(c, d, false) },
        Spec("launcher", 338, 158) { c, d -> WidgetViews.launcher(c, d) },
        Spec("theory", 338, 158) { c, d -> WidgetViews.theory(c, d) },
        Spec("map_tall", 338, 354) { c, d -> WidgetViews.map(c, d, true) },
    )

    @Test
    fun renderAll() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        // Drawn at 3x, the density the iOS renders use, whatever the
        // emulator's own screen is.
        val base = instrumentation.targetContext
        val config = Configuration(base.resources.configuration).apply { densityDpi = 480 }
        val context = base.createConfigurationContext(config)
        val out = File(context.filesDir, "renders").apply { deleteRecursively(); mkdirs() }
        val states = instrumentation.context.assets.list("")!!.filter { it.endsWith(".json") }
        for (asset in states) {
            val state = asset.removeSuffix(".json")
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val edit = prefs.edit().clear()
            val json = JSONObject(instrumentation.context.assets.open(asset).bufferedReader().readText())
            for (key in json.keys()) {
                when (val v = json.get(key)) {
                    is Boolean -> edit.putBoolean(key, v)
                    is Int -> edit.putInt(key, v)
                    is Long -> edit.putLong(key, v)
                    is Number -> edit.putLong(key, v.toLong())
                    else -> edit.putString(key, v.toString())
                }
            }
            edit.commit()

            val shots = mutableListOf<Pair<Spec, Bitmap>>()
            for (spec in specs) {
                lateinit var bmp: Bitmap
                instrumentation.runOnMainSync { bmp = draw(context, spec, prefs) }
                save(bmp, File(out, "${state}_${spec.name}.png"))
                shots += spec to bmp
            }
            save(gallery(context, shots), File(out, "gallery_$state.png"))
        }
    }

    private fun draw(context: Context, spec: Spec, prefs: SharedPreferences): Bitmap {
        val d = context.resources.displayMetrics.density
        val w = (spec.wDp * d).toInt()
        val h = (spec.hDp * d).toInt()
        val parent = FrameLayout(context)
        val view = spec.build(context, prefs).apply(context, parent)
        parent.addView(view, FrameLayout.LayoutParams(w, h))
        parent.measure(
            View.MeasureSpec.makeMeasureSpec(w, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(h, View.MeasureSpec.EXACTLY)
        )
        parent.layout(0, 0, w, h)
        val raw = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        parent.draw(Canvas(raw))
        // A launcher rounds the widget to the system radius, antialiased.
        val r = context.resources.getDimension(R.dimen.widget_radius)
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), r, r, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(raw, 0f, 0f, paint)
        return bmp
    }

    /** Two columns of small widgets, then the wide ones, on a wallpaper. */
    private fun gallery(context: Context, shots: List<Pair<Spec, Bitmap>>): Bitmap {
        val d = context.resources.displayMetrics.density
        val gap = (16 * d).toInt()
        val width = (338 * d).toInt() + gap * 2
        val placed = mutableListOf<Triple<Bitmap, Int, Int>>()
        var y = gap
        var x = gap
        var rowH = 0
        for ((spec, bmp) in shots) {
            if (spec.wDp < 300) {
                if (x + bmp.width > width - gap + 1) { x = gap; y += rowH + gap; rowH = 0 }
                placed += Triple(bmp, x, y)
                x += bmp.width + gap
                rowH = maxOf(rowH, bmp.height)
            } else {
                if (x != gap) { x = gap; y += rowH + gap; rowH = 0 }
                placed += Triple(bmp, x, y)
                y += bmp.height + gap
            }
        }
        if (x != gap) y += rowH + gap
        val out = Bitmap.createBitmap(width, y, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val paint = Paint().apply {
            shader = LinearGradient(0f, 0f, 0f, y.toFloat(),
                intArrayOf(0xFF3B3A6E.toInt(), 0xFF7A4E8E.toInt(), 0xFFD9917A.toInt()), null, Shader.TileMode.CLAMP)
        }
        canvas.drawRect(0f, 0f, width.toFloat(), y.toFloat(), paint)
        for ((bmp, px, py) in placed) canvas.drawBitmap(bmp, px.toFloat(), py.toFloat(), null)
        return out
    }

    private fun save(bmp: Bitmap, file: File) {
        FileOutputStream(file).use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }
}
