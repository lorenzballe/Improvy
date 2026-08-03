package com.improvy.improvy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.util.Calendar
import java.util.TimeZone

/**
 * Home-screen widgets — design 8.
 *
 * These only ever *render*: every string arrives already formatted from
 * `lib/services/widget_service.dart`, which owns notation (C-D-E vs Do-Re-Mi),
 * accidental spelling and wording. Re-deriving any of that here would let the
 * widget and the app drift apart.
 *
 * The widgets must also survive days without the app launching, so the quiz
 * rotation is written a week ahead and indexed by the clock — see [currentSlot].
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

// ─── ① Question 2×2 ──────────────────────────────────────────────────────────

/**
 * "The little question" — a flashcard on the home screen.
 *
 * The answer is withheld on purpose: the unresolved question is what makes the
 * widget worth keeping, and the tap that resolves it opens the app on the
 * reveal (`improvy://quiz?s=…`, carrying the absolute slot so the app rebuilds
 * exactly the question that was on screen).
 */
open class ImprovyQuizWidgetProvider : HomeWidgetProvider() {
    /** Overridden by the wide variant; everything else about the two is shared. */
    open val layout: Int get() = R.layout.widget_quiz
    open val rootId: Int get() = R.id.quiz_root
    open val degreeId: Int get() = R.id.quiz_degree
    open val ofId: Int get() = R.id.quiz_of

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, layout)

            var degree = context.getString(R.string.widget_quiz_degree_placeholder)
            var ofKey = context.getString(R.string.widget_quiz_of_placeholder)
            var slot = currentSlot()
            try {
                val raw = widgetData.getString("quiz_json", null)
                if (!raw.isNullOrEmpty()) {
                    val list = JSONArray(raw)
                    val length = list.length()
                    if (length > 0) {
                        val base = widgetData.number("quiz_base_slot")
                        // A phone left alone past the end of the written week
                        // wraps rather than going blank; the next launch
                        // rewrites the rotation anyway.
                        val offset = currentSlot() - base
                        val index = (((offset % length) + length) % length).toInt()
                        // Report the slot actually shown, not the wall clock —
                        // after a wrap they differ, and the app must reveal the
                        // question the user was looking at.
                        slot = base + index
                        val q = list.getJSONObject(index).optString("q", "")
                        if (q.isNotEmpty()) {
                            // The degree is the headline and the key is the
                            // quiet line under it, so the one string has to be
                            // split. " of " is what widget_service writes.
                            val cut = q.indexOf(" of ")
                            if (cut > 0) {
                                degree = q.substring(0, cut)
                                ofKey = context.getString(
                                    R.string.widget_quiz_of, q.substring(cut + 4)
                                )
                            } else {
                                degree = q
                                ofKey = ""
                            }
                        }
                    }
                }
            } catch (_: Exception) {
                // Malformed or missing payload: keep the placeholder rather
                // than showing an empty card.
            }

            views.setTextViewText(degreeId, degree)
            views.setTextViewText(ofId, ofKey)
            views.link(context, rootId, "improvy://quiz?s=$slot")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

// ─── ⑩ Question 4×2 ──────────────────────────────────────────────────────────

/** The same question with room to breathe. */
class ImprovyQuizWideWidgetProvider : ImprovyQuizWidgetProvider() {
    override val layout: Int get() = R.layout.widget_quiz_wide
    override val rootId: Int get() = R.id.quizw_root
    override val degreeId: Int get() = R.id.quizw_degree
    override val ofId: Int get() = R.id.quizw_of
}

// ─── ② Daily Challenge 4×2 ───────────────────────────────────────────────────

/**
 * Today's challenge: the key to play in, or the score once it's done — with the
 * streak always in sight, because the streak is what brings people back.
 */
class ImprovyDailyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily)

            val played = widgetData.getBoolean("daily_played", false)
            val key = widgetData.getString("daily_key", "") ?: ""
            val score = widgetData.getString("daily_score", "") ?: ""
            val grid = widgetData.getString("daily_grid", "") ?: ""
            val streak = widgetData.number("daily_streak")
            val keyColour = widgetData.color("daily_key_color", Color.parseColor("#FF4D94"))

            // The key's own tile, in the key's own colour — the same square the
            // app puts it in.
            views.tint(R.id.daily_key_bg, keyColour, 40)
            views.setTextColor(R.id.daily_key_letter, keyColour)
            views.setTextViewText(
                R.id.daily_key_letter,
                if (key.isEmpty()) context.getString(R.string.widget_daily_key_placeholder) else key
            )

            if (played) {
                views.setTextViewText(
                    R.id.daily_headline,
                    if (score.isEmpty()) context.getString(R.string.widget_daily_done) else score
                )
                views.setTextViewText(
                    R.id.daily_sub,
                    if (grid.isEmpty()) context.getString(R.string.widget_daily_done_sub) else grid
                )
                // Frame drops to neutral once there's nothing left to do today,
                // and the play button goes with it.
                views.setInt(R.id.daily_root, "setBackgroundResource", R.drawable.widget_bg)
                views.setViewVisibility(R.id.daily_play_bg, View.INVISIBLE)
                views.setViewVisibility(R.id.daily_play_glyph, View.INVISIBLE)
            } else {
                views.setTextViewText(
                    R.id.daily_headline,
                    if (key.isEmpty()) context.getString(R.string.widget_daily_placeholder)
                    else context.getString(R.string.widget_daily_key, key)
                )
                // The rule comes from the app (derived from the challenge
                // constants); the XML string is only the picker preview.
                val sub = widgetData.getString("daily_sub", null)
                views.setTextViewText(
                    R.id.daily_sub,
                    if (sub.isNullOrEmpty()) context.getString(R.string.widget_daily_sub_placeholder)
                    else sub
                )
                views.setInt(R.id.daily_root, "setBackgroundResource", R.drawable.widget_bg_gold)
                views.setViewVisibility(R.id.daily_play_bg, View.VISIBLE)
                views.setViewVisibility(R.id.daily_play_glyph, View.VISIBLE)
                views.tint(R.id.daily_play_bg, Color.parseColor("#FCD34D"))
            }
            views.setTextViewText(R.id.daily_streak, "🔥 $streak")

            views.link(context, R.id.daily_root, "improvy://daily")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

// ─── ③ Level & progress 2×2 ──────────────────────────────────────────────────

class ImprovyLevelWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_level)

            val colour = widgetData.color("animal_color", Color.parseColor("#A3E635"))
            val pct = widgetData.number("progress_pct").toInt().coerceIn(0, 100)
            val level = widgetData.number("animal_level", 1L).toInt()
            val total = widgetData.number("animal_levels_total", 8L).toInt()

            views.setTextViewText(
                R.id.level_emoji,
                widgetData.getString("animal_emoji", "🐌") ?: "🐌"
            )
            views.setTextViewText(
                R.id.level_name,
                widgetData.getString("animal_name", "Snail") ?: "Snail"
            )
            views.setTextColor(R.id.level_name, colour)
            views.setTextViewText(
                R.id.level_rank,
                context.getString(R.string.widget_level_rank, level, total)
            )
            views.setTextViewText(R.id.level_pct, "$pct%")
            views.setProgressBar(R.id.level_bar, 100, pct, false)
            views.setTextViewText(
                R.id.level_quote,
                widgetData.getString("animal_quote", "") ?: ""
            )

            views.link(context, R.id.level_root, "improvy://stats")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

// ─── ④ Key mastery map ───────────────────────────────────────────────────────

/**
 * Twelve keys, chromatic order, lit by how well they are known.
 *
 * A key never played is drawn hollow rather than at 0%: "not started" and
 * "started badly" are different facts and must not look the same.
 */
open class ImprovyMapWidgetProvider : HomeWidgetProvider() {
    open val layout: Int get() = R.layout.widget_map
    open val showsTotal: Boolean get() = false

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        val tiles = intArrayOf(
            R.id.map_tile_0, R.id.map_tile_1, R.id.map_tile_2, R.id.map_tile_3,
            R.id.map_tile_4, R.id.map_tile_5, R.id.map_tile_6, R.id.map_tile_7,
            R.id.map_tile_8, R.id.map_tile_9, R.id.map_tile_10, R.id.map_tile_11
        )
        val keys = intArrayOf(
            R.id.map_key_0, R.id.map_key_1, R.id.map_key_2, R.id.map_key_3,
            R.id.map_key_4, R.id.map_key_5, R.id.map_key_6, R.id.map_key_7,
            R.id.map_key_8, R.id.map_key_9, R.id.map_key_10, R.id.map_key_11
        )
        val pcts = intArrayOf(
            R.id.map_pct_0, R.id.map_pct_1, R.id.map_pct_2, R.id.map_pct_3,
            R.id.map_pct_4, R.id.map_pct_5, R.id.map_pct_6, R.id.map_pct_7,
            R.id.map_pct_8, R.id.map_pct_9, R.id.map_pct_10, R.id.map_pct_11
        )

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, layout)
            val raw = widgetData.getString("keys_json", null)
            val list = try {
                if (raw.isNullOrEmpty()) JSONArray() else JSONArray(raw)
            } catch (_: Exception) {
                JSONArray()
            }

            for (i in tiles.indices) {
                val o = if (i < list.length()) list.optJSONObject(i) else null
                val name = o?.optString("k", "") ?: ""
                val pct = o?.optInt("p", 0) ?: 0
                val everPlayed = o?.optBoolean("played", false) ?: false
                val colour = try {
                    Color.parseColor(o?.optString("c", "#FFFFFF") ?: "#FFFFFF")
                } catch (_: Exception) {
                    Color.WHITE
                }

                views.setTextViewText(keys[i], if (name.isEmpty()) "—" else name)

                if (!everPlayed) {
                    views.setImageViewResource(tiles[i], R.drawable.widget_tile_empty)
                    views.tint(tiles[i], Color.WHITE, 255)
                    views.setTextColor(keys[i], Color.parseColor("#52FFFFFF"))
                    views.setTextViewText(pcts[i], "—")
                    views.setTextColor(pcts[i], Color.parseColor("#47FFFFFF"))
                } else {
                    views.setImageViewResource(tiles[i], R.drawable.widget_tile_white)
                    // Opacity carries the mastery, so the grid reads at a glance
                    // before any number is.
                    val alpha = (0.18f + pct / 100f * 0.78f).coerceIn(0f, 1f)
                    views.tint(tiles[i], colour, (alpha * 255).toInt())
                    // Past roughly 60% the tile is bright enough that white type
                    // stops being legible on it, so the text flips to the dark ink.
                    val dark = pct >= 60
                    views.setTextColor(keys[i], if (dark) Color.parseColor("#160D22") else colour)
                    views.setTextViewText(pcts[i], "$pct%")
                    views.setTextColor(
                        pcts[i],
                        if (dark) Color.parseColor("#B3160D22") else Color.parseColor("#8CFFFFFF")
                    )
                }
            }

            if (showsTotal) {
                views.setTextViewText(
                    R.id.map_total,
                    "${widgetData.number("progress_pct").toInt()}%"
                )
            }

            views.link(context, R.id.map_root, "improvy://stats")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** The same grid with room for the running total. */
class ImprovyMapTallWidgetProvider : ImprovyMapWidgetProvider() {
    override val layout: Int get() = R.layout.widget_map_tall
    override val showsTotal: Boolean get() = true
}

// ─── ⑤ Streak ────────────────────────────────────────────────────────────────

class ImprovyStreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_streak)
            views.setTextViewText(R.id.streak_count, "${widgetData.number("daily_streak")}")
            views.setTextViewText(R.id.streak_caption, streakCaption(context, widgetData))
            views.link(context, R.id.streak_root, "improvy://daily")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** The 2×2, which has the room to say the streak is in danger. */
class ImprovyStreakTallWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_streak_tall)
            val streak = widgetData.number("daily_streak")
            views.setTextViewText(R.id.streakt_count, "$streak")
            views.setTextViewText(R.id.streakt_caption, streakCaption(context, widgetData))
            // Only warn when there is actually something to lose.
            val atRisk = streak > 0 && !widgetData.getBoolean("played_today", false)
            views.setTextColor(
                R.id.streakt_caption,
                if (atRisk) Color.parseColor("#FCD34D") else Color.parseColor("#73FFFFFF")
            )
            views.link(context, R.id.streakt_root, "improvy://daily")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

private fun streakCaption(context: Context, data: SharedPreferences): String {
    val streak = data.number("daily_streak")
    val atRisk = streak > 0 && !data.getBoolean("played_today", false)
    return context.getString(
        if (atRisk) R.string.widget_streak_at_risk else R.string.widget_streak_caption
    )
}

// ─── ⑥ Weakest key 2×2 ───────────────────────────────────────────────────────

class ImprovyWeakestWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_weakest)
            val key = widgetData.getString("weak_key", "") ?: ""
            val pct = widgetData.number("weak_pct").toInt()
            val colour = widgetData.color("weak_color", Color.parseColor("#FF4D94"))

            if (key.isEmpty()) {
                // "Weakest" means nothing until there is something to compare,
                // so an untouched profile gets an invitation, not a arbitrary C.
                views.setTextViewText(R.id.weak_key_letter, "?")
                views.setTextViewText(R.id.weak_pct, "—")
                views.setTextViewText(
                    R.id.weak_sub, context.getString(R.string.widget_weak_empty)
                )
            } else {
                views.setTextViewText(R.id.weak_key_letter, key)
                views.setTextViewText(R.id.weak_pct, "$pct%")
                views.setTextViewText(
                    R.id.weak_sub, context.getString(R.string.widget_weak_sub_placeholder)
                )
            }
            views.tint(R.id.weak_key_bg, colour, 40)
            views.setTextColor(R.id.weak_key_letter, colour)
            views.setTextColor(R.id.weak_pct, colour)

            views.link(
                context, R.id.weak_root,
                if (key.isEmpty()) "improvy://train" else "improvy://key?k=${Uri.encode(key)}"
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

// ─── ⑦ Quick launch 4×1 ──────────────────────────────────────────────────────

class ImprovyLauncherWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        // Each mode wears its own accent from home_screen.dart — the widget
        // must not invent colours the app does not use.
        val modes = listOf(
            Triple(R.id.launch_daily, R.id.launch_daily_bg, "#FCD34D" to "improvy://daily"),
            Triple(R.id.launch_pocket, R.id.launch_pocket_bg, "#6366F1" to "improvy://pocket"),
            Triple(R.id.launch_chromatic, R.id.launch_chromatic_bg, "#A855F7" to "improvy://chromatic"),
            Triple(R.id.launch_custom, R.id.launch_custom_bg, "#D857EC" to "improvy://custom")
        )
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_launcher)
            for ((cell, bg, spec) in modes) {
                val (hex, uri) = spec
                views.tint(bg, Color.parseColor(hex), 46)
                views.link(context, cell, uri)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

// ─── ⑧ Pocket Mode 2×1 ───────────────────────────────────────────────────────

class ImprovyPocketWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_pocket)
            views.link(context, R.id.pocket_root, "improvy://pocket")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

// ─── ⑨ Theory of the day 4×2 ─────────────────────────────────────────────────

class ImprovyTheoryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_theory)
            val degree = widgetData.getString("theory_degree", null)
            val text = widgetData.getString("theory_text", null)
            val colour = widgetData.color("theory_color", Color.parseColor("#FF4D94"))

            if (!degree.isNullOrEmpty()) views.setTextViewText(R.id.theory_degree, degree)
            if (!text.isNullOrEmpty()) views.setTextViewText(R.id.theory_text, text)
            views.setTextColor(R.id.theory_degree, colour)

            views.link(context, R.id.theory_root, "improvy://theory")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
