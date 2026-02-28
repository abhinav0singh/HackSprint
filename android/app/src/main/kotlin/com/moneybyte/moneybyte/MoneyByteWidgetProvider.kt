package com.moneybyte.moneybyte

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.*
import android.content.SharedPreferences
import org.json.JSONObject
import kotlin.math.min

class MoneyByteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val snapshotJson = prefs.getString("flutter.moneybyte_widget_snapshot", null)

            // ── NEW: read savings rate for ring color ─────────────────────
            // Written by behavior_provider.dart via SharedPreferences.
            // Green  ≥ 20% | Yellow 10–20% | Red < 10%
            val savingsRate = prefs.getFloat("flutter.moneybyte_savings_rate", -1f)
            val ringColor = when {
                savingsRate < 0f    -> "#00E676" // default green (no data yet)
                savingsRate >= 0.20 -> "#00E676" // 🟢 on track
                savingsRate >= 0.10 -> "#FF9800" // 🟡 caution
                else                -> "#E53935" // 🔴 critical
            }
            // ─────────────────────────────────────────────────────────────

            var percent = 0.0f
            var savedText = "INR 0"
            var goalCount = 0

            if (snapshotJson != null) {
                try {
                    val json = JSONObject(snapshotJson)
                    percent = json.getDouble("totalPercent").toFloat()
                    val saved = json.getDouble("totalSaved")
                    goalCount = json.getInt("goalCount")
                    savedText = formatInr(saved)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            val ringBitmap = drawRing(percent, ringColor) // ← pass color

            val views = RemoteViews(context.packageName, R.layout.moneybyte_widget)
            views.setImageViewBitmap(R.id.widget_ring, ringBitmap)
            views.setTextViewText(R.id.widget_percent, "${(percent * 100).toInt()}%")
            views.setTextViewText(R.id.widget_saved, savedText)
            views.setTextViewText(R.id.widget_goals, "$goalCount goal${if (goalCount == 1) "" else "s"}")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        // ── drawRing now accepts a color string ───────────────────────────
        private fun drawRing(percent: Float, colorHex: String = "#00E676"): Bitmap {
            val size = 160
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            val strokeWidth = 18f
            val padding = strokeWidth / 2 + 4f
            val rect = RectF(padding, padding, size - padding, size - padding)

            // Background track
            val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#2A2D36")
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
                strokeCap = Paint.Cap.ROUND
            }
            canvas.drawOval(rect, trackPaint)

            // Progress arc — color reflects financial state
            if (percent > 0f) {
                val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.parseColor(colorHex)
                    style = Paint.Style.STROKE
                    this.strokeWidth = strokeWidth
                    strokeCap = Paint.Cap.ROUND
                }
                val sweep = min(360f * percent, 360f)
                canvas.drawArc(rect, -90f, sweep, false, progressPaint)
            }

            return bitmap
        }

        private fun formatInr(amount: Double): String {
            return when {
                amount >= 1_00_00_000 -> "₹${String.format("%.1f", amount / 1_00_00_000)}Cr"
                amount >= 1_00_000    -> "₹${String.format("%.1f", amount / 1_00_000)}L"
                else                  -> "₹${amount.toLong()}"
            }
        }
    }
}