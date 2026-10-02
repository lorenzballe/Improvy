package com.improvy.improvy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.text.style.SuperscriptSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Home-screen widgets — the same design as the iOS ones
 * (ios/ImprovyWidget/ImprovyKit.swift): a near-black surface lit from the
 * top-right in the widget's own accent, a small eyebrow header, keys as filled
 * badges in their own colour, round accent buttons, the app's mastery bars.
 *
 * These only ever *render*: every string arrives already formatted from
 * `lib/services/widget_service.dart`, which owns notation (C-D-E vs Do-Re-Mi),
 * accidental spelling and wording. Re-deriving any of that here would let the
 * widget and the app drift apart.
 *
 * The widgets must also survive days without the app launching, so the quiz
 * rotation is written a week ahead and indexed by the clock — see [currentSlot].
 *
 * Each widget is built by a function in [WidgetViews] from the payload alone,
 * so androidTest/WidgetRenderTest can draw exactly what a home screen shows.
 */

/** Days since 1970-01-01 for *today's local calendar date*.
 *
 * Deliberately built as a UTC instant from the local Y/M/D: plain
 * `millis / 86400000` would land on the previous day for anyone east of
 * Greenwich, and the Dart side (`DateTime.utc(y, m, d)`) does exactly this. The
 * two must agree or the widget reads the wrong hour of the rotation.
 */
private fun localEpochDay(): Long {
    val local = Calendar.getInstance()
    val utc = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
    utc.clear()
    utc.set(
        local.get(Calendar.YEAR),
        local.get(Calendar.MONTH),
        local.get(Calendar.DAY_OF_MONTH),
        0, 0, 0
    )
    return utc.timeInMillis / 86_400_000L
}

/** Absolute hour slot for right now — hours since the epoch, local calendar. */
private fun currentSlot(): Long =
    localEpochDay() * 24L + Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

/**
 * Reads a number the Dart side wrote, whatever primitive it actually landed as.
 *
 * `HomeWidget.saveWidgetData<int>` stores a Dart int with `putInt`, so reading
 * it back with `getLong` throws ClassCastException — and see [guarded] for what
 * a throw in here costs. The width is the plugin's business, not ours, so read
 * the raw value and coerce rather than betting on one type.
 */
private fun SharedPreferences.number(key: String, fallback: Long = 0L): Long =
    when (val v = all[key]) {
        is Long -> v
        is Int -> v.toLong()
        is Float -> v.toLong()
        is Double -> v.toLong()
        is String -> v.toLongOrNull() ?: fallback
        else -> fallback
    }

/** A `#rrggbb` from the payload, or [fallback] if it is missing or malformed. */
private fun SharedPreferences.color(key: String, fallback: Int): Int {
    val raw = try { getString(key, null) } catch (_: Exception) { null }
    if (raw.isNullOrEmpty()) return fallback
    return try { Color.parseColor(raw) } catch (_: Exception) { fallback }
}

/**
 * Runs a widget update, swallowing anything it throws.
 *
 * An exception escaping `onUpdate` does not merely break the widget: the system
 * kills the whole app process for it —
 *
 *   Unable to start receiver com.improvy.improvy.ImprovyDailyWidgetProvider:
 *   java.lang.ClassCastException: Integer cannot be cast to Long
 *
 * — and since a launch triggers an update, the app died a second after opening,
 * every single time, with no way back in. A home-screen widget is a nicety; it
 * must never be able to take the app down with it. Worst case here is a widget
 * that keeps its previous contents.
 */
private inline fun guarded(block: () -> Unit) {
    try {
        block()
    } catch (_: Throwable) {
    }
}

/** Opens the app at [path], e.g. `improvy://daily`. */
private fun RemoteViews.link(context: Context, viewId: Int, path: String) {
    setOnClickPendingIntent(
        viewId,
        HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse(path)
        )
    )
}

/**
 * Paints one of the tinted shapes.
 *
 * RemoteViews cannot recolour a background drawable, but ImageView exposes both
 * `setColorFilter` and `setImageAlpha` as remotable methods — so every coloured
 * rounded shape in these widgets is one white drawable wearing a filter. This
 * is what makes per-key colour possible at minSdk 24, where tint lists are not
 * available from a RemoteViews.
 */
private fun RemoteViews.tint(viewId: Int, colour: Int, alpha: Int = 255) {
    setInt(viewId, "setColorFilter", colour)
    setInt(viewId, "setImageAlpha", alpha)
}


/** The design tokens, the same values as `Ink` in ImprovyKit.swift. */
private object Ink {
    val gold = Color.parseColor("#FCD34D")
    val indigo = Color.parseColor("#6366F1")
    val violet = Color.parseColor("#A855F7")
    val magenta = Color.parseColor("#D857EC")
    val mint = Color.parseColor("#34D399")
    val cyan = Color.parseColor("#22D3EE")
    val ember = Color.parseColor("#F97316")
    val rose = Color.parseColor("#FB7185")
    /** The ink that reads on a light key colour (the yellows and greens). */
    val dark = Color.parseColor("#140F1C")
    val quiet = Color.parseColor("#7AFFFFFF")
}

/**
 * White on deep colours, the dark ink on light ones — a yellow key tile with a
 * white "D" on it is a key nobody can read. Same weights and threshold as
 * `Color.onFill` on iOS.
 */
private fun onFill(colour: Int): Int {
    val l = 0.2126 * Color.red(colour) / 255 +
        0.7152 * Color.green(colour) / 255 +
        0.0722 * Color.blue(colour) / 255
    return if (l > 0.62) Ink.dark else Color.WHITE
}

/** [colour] at [alpha] (0–255). */
private fun withAlpha(colour: Int, alpha: Int): Int =
    Color.argb(alpha, Color.red(colour), Color.green(colour), Color.blue(colour))

/**
 * A note or degree with its accidental set the way music sets it: smaller and
 * raised, so "D♭" reads as D-flat rather than as "Db" in a heavy font.
 */
private fun music(s: String): CharSequence {
    val out = SpannableStringBuilder()
    var i = 0
    while (i < s.length) {
        val cp = s.codePointAt(i)
        val n = Character.charCount(cp)
        val start = out.length
        out.append(s, i, i + n)
        if (cp == 0x266D || cp == 0x266F || cp == 0x1D12B || cp == 0x1D12A) {
            out.setSpan(RelativeSizeSpan(0.62f), start, out.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            out.setSpan(SuperscriptSpan(), start, out.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        i += n
    }
    return out
}

/** The accent light: [lit] for the states worth interrupting someone for. */
private fun RemoteViews.glow(viewId: Int, accent: Int, lit: Boolean = false) =
    tint(viewId, accent, if (lit) 77 else 43)

/** An eyebrow's icon and label in the accent. */
private fun RemoteViews.eyebrow(icon: Int, label: Int, accent: Int) {
    tint(icon, accent)
    setTextColor(label, accent)
}

/** A key badge: the key's colour, filled, with ink that can always be read. */
private fun RemoteViews.badge(bg: Int, label: Int, key: String, colour: Int) {
    tint(bg, colour)
    setTextViewText(label, music(key.ifEmpty { "?" }))
    setTextColor(label, onFill(colour))
}

/** A filled round button: the accent, and the glyph in the ink that reads on it. */
private fun RemoteViews.glyphButton(bg: Int, glyph: Int, colour: Int) {
    tint(bg, colour)
    tint(glyph, onFill(colour))
}

/**
 * A mastery bar's fill colour. A progress tint is only remotable from
 * Android 12; before that the bar keeps its quiet white fill.
 */
private fun RemoteViews.barColour(viewId: Int, colour: Int) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        setColorStateList(viewId, "setProgressTintList", ColorStateList.valueOf(colour))
    }
}

/** The streak chip in an eyebrow: the drawn flame and the count. */
private fun RemoteViews.streakChip(flame: Int, count: Int, streak: Long, dim: Boolean) {
    setTextViewText(count, "$streak")
    setTextColor(count, if (dim) Color.parseColor("#99FFFFFF") else Color.parseColor("#F2FFFFFF"))
    setInt(flame, "setImageAlpha", if (dim) 153 else 255)
}

/** The last seven days, oldest first, today last. */
private fun SharedPreferences.week(): BooleanArray {
    val week = BooleanArray(7)
    try {
        val raw = getString("week_json", null)
        if (!raw.isNullOrEmpty()) {
            val list = JSONArray(raw)
            for (i in 0 until minOf(list.length(), 7)) week[i] = list.optBoolean(i, false)
        }
    } catch (_: Exception) {
        // A missing payload reads as a quiet week, never as a week of failures.
    }
    return week
}

/**
 * Lights the week, as WeekDots on iOS: played days in the accent, the rest
 * quiet, and today ringed in the accent while it is still to play.
 */
private fun RemoteViews.weekDots(dots: IntArray, week: BooleanArray, colour: Int, letters: IntArray? = null) {
    for (i in dots.indices) {
        val today = i == dots.size - 1
        when {
            week[i] -> {
                setImageViewResource(dots[i], R.drawable.w_dot)
                tint(dots[i], colour)
            }
            today -> {
                setImageViewResource(dots[i], R.drawable.w_ring_today)
                tint(dots[i], colour, 230)
            }
            else -> {
                setImageViewResource(dots[i], R.drawable.w_dot)
                tint(dots[i], Color.WHITE, 26)
            }
        }
    }
    if (letters != null) {
        // The weekday initials for the last seven days, ending today, in the
        // phone's language.
        val format = SimpleDateFormat("EEEEE", Locale.getDefault())
        val day = Calendar.getInstance()
        day.add(Calendar.DAY_OF_YEAR, -(letters.size - 1))
        for (i in letters.indices) {
            setTextViewText(letters[i], format.format(day.time))
            setTextColor(letters[i], if (i == letters.size - 1) Color.parseColor("#D9FFFFFF") else Color.parseColor("#59FFFFFF"))
            day.add(Calendar.DAY_OF_YEAR, 1)
        }
    }
}

/**
 * The daily's answers as a row of short bars, right and wrong — ResultBars on
 * iOS. Drawn as a bitmap at the view's exact size, because the number of bars
 * is the payload's and RemoteViews cannot add views.
 */
private fun resultBars(context: Context, grid: String, widthDp: Int, heightDp: Int): Bitmap? {
    val marks = mutableListOf<Boolean>()
    var i = 0
    while (i < grid.length) {
        val cp = grid.codePointAt(i)
        if (cp == 0x1F7E9) marks.add(true) else if (cp == 0x1F7E5) marks.add(false)
        i += Character.charCount(cp)
    }
    if (marks.isEmpty()) return null
    val d = context.resources.displayMetrics.density
    val w = (widthDp * d).toInt()
    val h = (heightDp * d).toInt()
    val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bmp)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    val gap = 2.5f * d
    val each = (w - gap * (marks.size - 1)) / marks.size
    marks.forEachIndexed { n, ok ->
        paint.color = if (ok) Ink.mint else Ink.rose
        val x = n * (each + gap)
        canvas.drawRoundRect(RectF(x, 0f, x + each, h.toFloat()), h / 2f, h / 2f, paint)
    }
    return bmp
}

/**
 * The eight level animals, in order, drawn from AnimalIcon's own paths — see
 * tool/gen_animal_drawables.py. Indexed by level (1-8) and clamped, so a
 * payload from a newer app can never crash an older widget.
 */
private val kAnimalDrawables = intArrayOf(
    R.drawable.ic_animal_snail,
    R.drawable.ic_animal_turtle,
    R.drawable.ic_animal_penguin,
    R.drawable.ic_animal_rabbit,
    R.drawable.ic_animal_fox,
    R.drawable.ic_animal_horse,
    R.drawable.ic_animal_falcon,
    R.drawable.ic_animal_cheetah
)

private fun animalDrawable(level: Int): Int =
    kAnimalDrawables[(level - 1).coerceIn(0, kAnimalDrawables.size - 1)]

/** Every widget, built from the payload alone. */
object WidgetViews {

    // ─── ① Question 2×2 · ⑩ Question 4×2 ───────────────────────────────────

    /**
     * "The little question" — a flashcard on the home screen. The answer is
     * withheld on purpose: the unresolved question is what makes the widget
     * worth keeping, and the tap that resolves it opens the app on the reveal
     * (`improvy://quiz?s=…`, carrying the absolute slot so the app rebuilds
     * exactly the question that was on screen).
     */
    fun quiz(context: Context, data: SharedPreferences, wide: Boolean): RemoteViews {
        val views = RemoteViews(
            context.packageName, if (wide) R.layout.widget_quiz_wide else R.layout.widget_quiz
        )
        var degree = context.getString(R.string.widget_quiz_degree_placeholder)
        var ofKey = context.getString(R.string.widget_quiz_of_placeholder)
        var slot = currentSlot()
        try {
            val raw = data.getString("quiz_json", null)
            if (!raw.isNullOrEmpty()) {
                val list = JSONArray(raw)
                val length = list.length()
                if (length > 0) {
                    val base = data.number("quiz_base_slot")
                    // A phone left alone past the end of the written week wraps
                    // rather than going blank; the next launch rewrites it.
                    val offset = currentSlot() - base
                    val index = (((offset % length) + length) % length).toInt()
                    // Report the slot actually shown, not the wall clock —
                    // after a wrap they differ.
                    slot = base + index
                    val q = list.getJSONObject(index).optString("q", "")
                    if (q.isNotEmpty()) {
                        // The degree is the headline and the key the quiet line
                        // under it. " of " is what widget_service writes.
                        val cut = q.indexOf(" of ")
                        if (cut > 0) {
                            degree = q.substring(0, cut)
                            ofKey = context.getString(R.string.widget_quiz_of, q.substring(cut + 4))
                        } else {
                            degree = q
                            ofKey = ""
                        }
                    }
                }
            }
        } catch (_: Exception) {
            // Malformed or missing payload: keep the placeholder.
        }
        if (wide) {
            views.setTextViewText(R.id.quizw_degree, music(degree))
            views.setTextViewText(R.id.quizw_of, music(ofKey))
            views.glyphButton(R.id.quizw_glyph_bg, R.id.quizw_glyph, Ink.gold)
            views.link(context, R.id.quizw_root, "improvy://quiz?s=$slot")
        } else {
            views.setTextViewText(R.id.quiz_degree, music(degree))
            views.setTextViewText(R.id.quiz_of, music(ofKey))
            views.link(context, R.id.quiz_root, "improvy://quiz?s=$slot")
        }
        return views
    }

    // ─── ② Daily Challenge 4×2 ─────────────────────────────────────────────

    /**
     * Today's challenge: the key to play in, or the score once it is done —
     * with the streak always in sight. The gold light only while there is
     * still something to do today.
     */
    fun daily(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_daily)
        val played = data.getBoolean("daily_played", false)
        val key = data.getString("daily_key", "") ?: ""
        val colour = data.color("daily_key_color", Ink.gold)
        val accent = if (played) Ink.mint else Ink.gold

        views.glow(R.id.daily_glow, accent, lit = !played)
        views.eyebrow(R.id.daily_eb_icon, R.id.daily_eb_text, accent)
        views.setImageViewResource(
            R.id.daily_eb_icon, if (played) R.drawable.w_ic_check else R.drawable.w_ic_calendar
        )
        views.streakChip(R.id.daily_chip_flame, R.id.daily_chip_count, data.number("daily_streak"), played)
        views.badge(R.id.daily_badge, R.id.daily_badge_text, key, colour)

        if (played) {
            val score = data.getString("daily_score", "") ?: ""
            views.setTextViewText(
                R.id.daily_score, score.ifEmpty { context.getString(R.string.widget_daily_done) }
            )
            views.setViewVisibility(R.id.daily_score, View.VISIBLE)
            views.setViewVisibility(R.id.daily_headline, View.GONE)
            views.setViewVisibility(R.id.daily_mode, View.GONE)
            val bars = resultBars(context, data.getString("daily_grid", "") ?: "", 150, 5)
            if (bars != null) {
                views.setImageViewBitmap(R.id.daily_bars, bars)
                views.setViewVisibility(R.id.daily_bars, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.daily_bars, View.GONE)
            }
            views.setTextViewText(R.id.daily_sub, context.getString(R.string.widget_daily_done_sub))
            views.setViewVisibility(R.id.daily_play, View.GONE)
        } else {
            val headline = SpannableStringBuilder(context.getString(R.string.widget_daily_key, ""))
                .append(music(key.ifEmpty { "?" }))
            views.setTextViewText(R.id.daily_headline, headline)
            views.setViewVisibility(R.id.daily_headline, View.VISIBLE)
            views.setViewVisibility(R.id.daily_score, View.GONE)
            views.setViewVisibility(R.id.daily_bars, View.GONE)
            val mode = data.getString("daily_mode", "") ?: ""
            views.setTextViewText(R.id.daily_mode, mode)
            views.setTextColor(R.id.daily_mode, colour)
            views.setViewVisibility(R.id.daily_mode, if (mode.isEmpty()) View.GONE else View.VISIBLE)
            // The rule comes from the app (derived from the challenge
            // constants); the XML string is only the picker preview.
            val sub = data.getString("daily_sub", null)
            views.setTextViewText(
                R.id.daily_sub,
                if (sub.isNullOrEmpty()) context.getString(R.string.widget_daily_sub_placeholder) else sub
            )
            views.setViewVisibility(R.id.daily_play, View.VISIBLE)
            views.glyphButton(R.id.daily_glyph_bg, R.id.daily_glyph, Ink.gold)
        }
        views.link(context, R.id.daily_root, "improvy://daily")
        return views
    }

    // ─── ③ Level 2×2 ───────────────────────────────────────────────────────

    fun level(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_level)
        val colour = data.color("animal_color", Ink.mint)
        val pct = data.number("progress_pct").toInt().coerceIn(0, 100)
        val level = data.number("animal_level", 1L).toInt()
        val total = data.number("animal_levels_total", 8L).toInt()

        views.glow(R.id.level_glow, colour)
        views.eyebrow(R.id.level_eb_icon, R.id.level_eb_text, colour)
        views.setTextViewText(R.id.level_rank, "$level/$total")
        // The animal the app draws, not an emoji: the same line art, in the
        // level's own colour. Indexed by level — the name is a word.
        views.setImageViewResource(R.id.level_animal, animalDrawable(level))
        views.tint(R.id.level_animal, colour)
        views.tint(R.id.level_circle, colour, 46)
        views.setTextViewText(R.id.level_name, data.getString("animal_name", null) ?: "Snail")
        views.setTextViewText(R.id.level_quote, data.getString("animal_quote", "") ?: "")
        views.setTextViewText(R.id.level_pct, "$pct")
        views.setProgressBar(R.id.level_bar, 100, pct, false)
        views.barColour(R.id.level_bar, colour)
        views.link(context, R.id.level_root, "improvy://stats")
        return views
    }

    // ─── ④ Key mastery 4×2 · 4×4 ───────────────────────────────────────────

    private val kKeyIds = intArrayOf(
        R.id.map_key_0, R.id.map_key_1, R.id.map_key_2, R.id.map_key_3,
        R.id.map_key_4, R.id.map_key_5, R.id.map_key_6, R.id.map_key_7,
        R.id.map_key_8, R.id.map_key_9, R.id.map_key_10, R.id.map_key_11
    )
    private val kTileIds = intArrayOf(
        R.id.map_tile_0, R.id.map_tile_1, R.id.map_tile_2, R.id.map_tile_3,
        R.id.map_tile_4, R.id.map_tile_5, R.id.map_tile_6, R.id.map_tile_7,
        R.id.map_tile_8, R.id.map_tile_9, R.id.map_tile_10, R.id.map_tile_11
    )
    private val kBarIds = intArrayOf(
        R.id.map_bar_0, R.id.map_bar_1, R.id.map_bar_2, R.id.map_bar_3,
        R.id.map_bar_4, R.id.map_bar_5, R.id.map_bar_6, R.id.map_bar_7,
        R.id.map_bar_8, R.id.map_bar_9, R.id.map_bar_10, R.id.map_bar_11
    )
    private val kPctIds = intArrayOf(
        R.id.map_pct_0, R.id.map_pct_1, R.id.map_pct_2, R.id.map_pct_3,
        R.id.map_pct_4, R.id.map_pct_5, R.id.map_pct_6, R.id.map_pct_7,
        R.id.map_pct_8, R.id.map_pct_9, R.id.map_pct_10, R.id.map_pct_11
    )

    /**
     * Twelve keys, chromatic order, each with a bar as long as it is known. A
     * key never played is drawn quiet, with no bar, rather than at 0%: "not
     * started" and "started badly" are different facts.
     */
    fun map(context: Context, data: SharedPreferences, large: Boolean): RemoteViews {
        val views = RemoteViews(
            context.packageName, if (large) R.layout.widget_map_tall else R.layout.widget_map
        )
        val list = try {
            val raw = data.getString("keys_json", null)
            if (raw.isNullOrEmpty()) JSONArray() else JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
        views.glow(R.id.map_glow, Ink.cyan)
        views.setTextViewText(R.id.map_total, "${data.number("progress_pct").toInt()}%")

        for (i in kKeyIds.indices) {
            val o = if (i < list.length()) list.optJSONObject(i) else null
            val name = o?.optString("k", "") ?: ""
            val pct = (o?.optInt("p", 0) ?: 0).coerceIn(0, 100)
            val played = o?.optBoolean("played", false) ?: false
            val colour = try {
                Color.parseColor(o?.optString("c", "#FFFFFF") ?: "#FFFFFF")
            } catch (_: Exception) {
                Color.WHITE
            }
            views.setTextViewText(kKeyIds[i], music(name.ifEmpty { "—" }))
            views.setTextColor(kKeyIds[i], if (played) Color.WHITE else Color.parseColor("#52FFFFFF"))
            views.tint(kTileIds[i], Color.WHITE, if (played) 18 else 9)
            // Never shorter than a dot once played: 2% would vanish.
            views.setProgressBar(kBarIds[i], 100, if (played) maxOf(pct, 6) else 0, false)
            views.barColour(kBarIds[i], colour)
            if (large) {
                views.setTextViewText(kPctIds[i], if (played) "$pct%" else "—")
                views.setTextColor(kPctIds[i], if (played) colour else Color.parseColor("#40FFFFFF"))
            }
        }
        if (large) {
            val animal = data.color("animal_color", Ink.mint)
            views.setImageViewResource(R.id.map_animal, animalDrawable(data.number("animal_level", 1L).toInt()))
            views.tint(R.id.map_animal, animal)
            views.setTextViewText(R.id.map_animal_name, data.getString("animal_name", null) ?: "Snail")
            views.setTextColor(R.id.map_animal_name, animal)
            views.setProgressBar(R.id.map_progress, 100, data.number("progress_pct").toInt().coerceIn(0, 100), false)
            views.barColour(R.id.map_progress, Ink.cyan)
        }
        views.link(context, R.id.map_root, "improvy://stats")
        return views
    }

    // ─── ⑤ Streak 2×2 · 4×2 ────────────────────────────────────────────────

    private val kSmallDots = intArrayOf(
        R.id.streak_d0, R.id.streak_d1, R.id.streak_d2, R.id.streak_d3,
        R.id.streak_d4, R.id.streak_d5, R.id.streak_d6
    )
    private val kWideDots = intArrayOf(
        R.id.streakt_d0, R.id.streakt_d1, R.id.streakt_d2, R.id.streakt_d3,
        R.id.streakt_d4, R.id.streakt_d5, R.id.streakt_d6
    )
    private val kWideLetters = intArrayOf(
        R.id.streakt_l0, R.id.streakt_l1, R.id.streakt_l2, R.id.streakt_l3,
        R.id.streakt_l4, R.id.streakt_l5, R.id.streakt_l6
    )

    /** Days in a row — and a warning, in gold, on the day it is about to break. */
    fun streak(context: Context, data: SharedPreferences, wide: Boolean): RemoteViews {
        val streak = data.number("daily_streak")
        // Only warn when there is actually something to lose.
        val atRisk = streak > 0 && !data.getBoolean("played_today", false)
        val colour = if (atRisk) Ink.gold else Ink.ember
        val caption = context.getString(
            when {
                atRisk -> R.string.widget_streak_at_risk
                wide -> R.string.widget_streak_day_streak
                else -> R.string.widget_streak_caption
            }
        )
        val captionColour = if (atRisk) Ink.gold else Ink.quiet
        val views: RemoteViews
        if (wide) {
            views = RemoteViews(context.packageName, R.layout.widget_streak_tall)
            views.glow(R.id.streakt_glow, colour, lit = atRisk)
            views.setTextViewText(R.id.streakt_count, "$streak")
            views.setTextViewText(R.id.streakt_caption, caption)
            views.setTextColor(R.id.streakt_caption, captionColour)
            views.weekDots(kWideDots, data.week(), colour, kWideLetters)
            views.setViewVisibility(R.id.streakt_play, if (atRisk) View.VISIBLE else View.GONE)
            views.glyphButton(R.id.streakt_glyph_bg, R.id.streakt_glyph, Ink.gold)
            views.link(context, R.id.streakt_root, "improvy://daily")
        } else {
            views = RemoteViews(context.packageName, R.layout.widget_streak)
            views.glow(R.id.streak_glow, colour, lit = atRisk)
            views.eyebrow(R.id.streak_eb_icon, R.id.streak_eb_text, colour)
            views.setTextViewText(R.id.streak_count, "$streak")
            views.setTextViewText(R.id.streak_caption, caption)
            views.setTextColor(R.id.streak_caption, captionColour)
            views.weekDots(kSmallDots, data.week(), colour)
            views.link(context, R.id.streak_root, "improvy://daily")
        }
        return views
    }

    // ─── ⑥ Weakest key 2×2 ─────────────────────────────────────────────────

    /**
     * "Weakest" means nothing until there is something to compare, so an
     * untouched profile gets an invitation rather than an arbitrary C.
     */
    fun weakest(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_weakest)
        val key = data.getString("weak_key", "") ?: ""
        val colour = data.color("weak_color", Ink.rose)
        views.glow(R.id.weak_glow, Ink.rose)
        views.badge(R.id.weak_badge, R.id.weak_badge_text, key, colour)
        if (key.isEmpty()) {
            views.setTextViewText(R.id.weak_pct, "—")
            views.setViewVisibility(R.id.weak_pct_sign, View.GONE)
            views.setTextViewText(R.id.weak_sub, context.getString(R.string.widget_weak_empty))
            views.setTextViewText(R.id.weak_hint, context.getString(R.string.widget_weak_empty_hint))
        } else {
            views.setTextViewText(R.id.weak_pct, "${data.number("weak_pct")}")
            views.setViewVisibility(R.id.weak_pct_sign, View.VISIBLE)
            views.setTextViewText(R.id.weak_sub, context.getString(R.string.widget_weak_mastered))
            views.setTextViewText(R.id.weak_hint, context.getString(R.string.widget_weak_hint))
        }
        views.link(
            context, R.id.weak_root,
            if (key.isEmpty()) "improvy://train" else "improvy://key?k=${Uri.encode(key)}"
        )
        return views
    }

    // ─── ⑦ Quick start 4×2 ─────────────────────────────────────────────────

    /**
     * Four modes, one tap each. Each wears its own accent from
     * home_screen.dart — the widget must not invent colours the app does not use.
     */
    fun launcher(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_launcher)
        views.glow(R.id.launcher_glow, Ink.indigo)
        class Mode(val cell: Int, val bg: Int, val glyph: Int, val colour: Int, val uri: String)
        val modes = listOf(
            Mode(R.id.launch_daily, R.id.launch_daily_glyph_bg, R.id.launch_daily_glyph, Ink.gold, "improvy://daily"),
            Mode(R.id.launch_pocket, R.id.launch_pocket_glyph_bg, R.id.launch_pocket_glyph, Ink.indigo, "improvy://pocket"),
            Mode(R.id.launch_chromatic, R.id.launch_chromatic_glyph_bg, R.id.launch_chromatic_glyph, Ink.violet, "improvy://chromatic"),
            Mode(R.id.launch_custom, R.id.launch_custom_glyph_bg, R.id.launch_custom_glyph, Ink.magenta, "improvy://custom")
        )
        for (m in modes) {
            views.glyphButton(m.bg, m.glyph, m.colour)
            views.link(context, m.cell, m.uri)
        }
        return views
    }

    // ─── ⑧ Pocket Mode 2×2 ─────────────────────────────────────────────────

    fun pocket(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_pocket)
        views.glow(R.id.pocket_glow, Ink.indigo)
        views.glyphButton(R.id.pocket_glyph_bg, R.id.pocket_glyph, Ink.indigo)
        views.link(context, R.id.pocket_root, "improvy://pocket")
        return views
    }

    // ─── ⑨ Degree of the day 4×2 ───────────────────────────────────────────

    fun theory(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_theory)
        val colour = data.color("theory_color", Ink.rose)
        val degree = data.getString("theory_degree", null)
        val text = data.getString("theory_text", null)
        views.glow(R.id.theory_glow, colour)
        views.eyebrow(R.id.theory_eb_icon, R.id.theory_eb_text, colour)
        views.tint(R.id.theory_circle, colour, 36)
        views.tint(R.id.theory_ring, colour, 77)
        if (!degree.isNullOrEmpty()) views.setTextViewText(R.id.theory_degree, music(degree))
        views.setTextColor(R.id.theory_degree, colour)
        if (!text.isNullOrEmpty()) views.setTextViewText(R.id.theory_text, text)
        views.link(context, R.id.theory_root, "improvy://theory")
        return views
    }
}

/**
 * One provider per widget. The view does not depend on the instance, so it
 * is built once and handed to every copy on the home screen.
 */
abstract class ImprovyWidgetProvider : HomeWidgetProvider() {
    abstract fun build(context: Context, data: SharedPreferences): RemoteViews

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        val views = build(context, widgetData)
        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
    }
}

class ImprovyQuizWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.quiz(context, data, false)
}

class ImprovyQuizWideWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.quiz(context, data, true)
}

class ImprovyDailyWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.daily(context, data)
}

class ImprovyLevelWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.level(context, data)
}

class ImprovyMapWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.map(context, data, false)
}

class ImprovyMapTallWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.map(context, data, true)
}

class ImprovyStreakWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.streak(context, data, false)
}

class ImprovyStreakTallWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.streak(context, data, true)
}

class ImprovyWeakestWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.weakest(context, data)
}

class ImprovyLauncherWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.launcher(context, data)
}

class ImprovyPocketWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.pocket(context, data)
}

class ImprovyTheoryWidgetProvider : ImprovyWidgetProvider() {
    override fun build(context: Context, data: SharedPreferences) = WidgetViews.theory(context, data)
}
