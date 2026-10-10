package com.sakuin.sakuin_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickActionBarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_action_bar).apply {
                val totalBalance = widgetData.getString("total_balance", "Rp 0") ?: "Rp 0"
                val remainingBudget = widgetData.getString("remaining_budget", "Rp 0") ?: "Rp 0"

                setTextViewText(R.id.widget_total_balance, totalBalance)
                setTextViewText(R.id.widget_remaining_budget, "Sisa: $remainingBudget")

                // PendingIntent for Quick Entry (+)
                val quickEntryIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("sakuin://quick_entry")
                )
                setOnClickPendingIntent(R.id.btn_quick_entry, quickEntryIntent)

                // PendingIntent for Voice (Mic)
                val voiceIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("sakuin://voice")
                )
                setOnClickPendingIntent(R.id.btn_voice, voiceIntent)

                // PendingIntent for Scan OCR (Camera)
                val scanIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("sakuin://scan")
                )
                setOnClickPendingIntent(R.id.btn_scan, scanIntent)

                // Whole widget tap opens home screen
                val appIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("sakuin://home")
                )
                setOnClickPendingIntent(R.id.widget_container, appIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
