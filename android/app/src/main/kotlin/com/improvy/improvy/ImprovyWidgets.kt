package com.improvy.improvy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.util.Calendar
import java.util.TimeZone

/**
 * Home-screen widgets.
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

/**
 * "The little question" — a flashcard on the home screen.
 *
 * The answer is withheld on purpose: the unresolved question is what makes the
 * widget worth keeping, and the tap that resolves it opens the app on the
 * reveal (`improvy://quiz?s=…`, carrying the absolute slot so the app rebuilds
 * exactly the question that was on screen).
 */
class ImprovyQuizWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) = guarded {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_quiz)

            // The degree and its key are drawn separately now: the degree is the
            // headline, in the key's own colour, and "of X" is the quiet line
            // under it. The payload still carries one string, so split on the
            // first " of " and fall back to putting it all in the headline.
            var question = context.getString(R.string.widget_quiz_degree_placeholder)
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
                        val raw2 = list.getJSONObject(index).optString("q", "")
                        if (raw2.isNotEmpty()) {
                            val cut = raw2.indexOf(" of ")
                            if (cut > 0) {
                                question = raw2.substring(0, cut)
                                ofKey = context.getString(
                                    R.string.widget_quiz_of, raw2.substring(cut + 4)
                                )
                            } else {
                                question = raw2
                                ofKey = ""
                            }
                        }
                    }
                }
            } catch (_: Exception) {
                // Malformed or missing payload: keep the placeholder rather
                // than crashing the launcher's widget host.
            }

            views.setTextViewText(R.id.quiz_degree, question)
            views.setTextViewText(R.id.quiz_of, ofKey)
            views.setOnClickPendingIntent(
                R.id.quiz_root,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("improvy://quiz?s=$slot")
                )
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

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

            if (played) {
                views.setTextViewText(R.id.daily_headline,
                    if (score.isEmpty()) context.getString(R.string.widget_daily_done) else score)
                views.setTextViewText(R.id.daily_sub,
                    if (grid.isEmpty()) context.getString(R.string.widget_daily_done_sub) else grid)
                // Frame drops to neutral once there's nothing left to do today.
                views.setInt(R.id.daily_root, "setBackgroundResource", R.drawable.widget_bg)
            } else {
                views.setTextViewText(
                    R.id.daily_headline,
                    if (key.isEmpty()) context.getString(R.string.widget_daily_placeholder)
                    else context.getString(R.string.widget_daily_key, key)
                )
                // The rule comes from the app (derived from the challenge
                // constants); the XML string is only the picker preview.
                val sub = widgetData.getString("daily_sub", null)
                views.setTextViewText(R.id.daily_sub,
                    if (sub.isNullOrEmpty()) context.getString(R.string.widget_daily_sub_placeholder)
                    else sub)
                views.setInt(R.id.daily_root, "setBackgroundResource", R.drawable.widget_bg_gold)
            }
            views.setTextViewText(R.id.daily_streak, "🔥 $streak")

            views.setOnClickPendingIntent(
                R.id.daily_root,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("improvy://daily")
                )
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
