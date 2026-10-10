package com.sakuin.sakuin_app

import android.app.Notification
import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

class TransactionNotificationListener : NotificationListenerService() {
    companion object {
        var eventSink: EventChannel.EventSink? = null

        fun isPermissionGranted(context: Context): Boolean {
            val flat = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners"
            ) ?: ""
            return flat.contains(context.packageName)
        }

        // Recognized Indonesian bank and e-wallet application package names
        private val TARGET_PACKAGES = setOf(
            "com.bca",
            "com.bca.mybca",
            "com.gojek.app",
            "ovo.id",
            "id.dana",
            "com.shopee.id",
            "id.bmri.livin",
            "id.co.bri.brimo",
            "com.btpn.dc",
            "com.seabank.mobile",
            "com.grabtaxi.passenger"
        )

        // General mutation keywords to catch banking SMS or unlisted banks
        private val MUTATION_KEYWORDS = listOf(
            "berhasil",
            "transfer",
            "pembayaran",
            "qris",
            "rp",
            "idr",
            "top up",
            "debit",
            "kredit",
            "transaksi",
            "saldo"
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val pkg = sbn.packageName ?: ""
        val extras = sbn.notification?.extras ?: return

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: ""

        if (text.isBlank() && title.isBlank()) return

        val combined = "$title $text".lowercase()

        val isTargetApp = TARGET_PACKAGES.contains(pkg)
        val hasFinancialKeyword = MUTATION_KEYWORDS.any { combined.contains(it) }

        if (isTargetApp || hasFinancialKeyword) {
            val data = mapOf(
                "packageName" to pkg,
                "title" to title,
                "text" to text,
                "timestamp" to System.currentTimeMillis()
            )
            // Deliver event on main UI thread
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                eventSink?.success(data)
            }
        }
    }
}
