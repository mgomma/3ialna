package com.ialna.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import com.ialna.app.usage.MonitorForegroundService

/**
 * Restarts the monitoring foreground service after boots, device unlocks, or app updates
 * if the user previously enabled monitoring inside Flutter.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            if (isMonitoringEnabled(context)) {
                startMonitoringService(context)
            }
        }
    }

    private fun isMonitoringEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("$PFX$_PREF_IS_MONITORING", false)
    }

    private fun startMonitoringService(context: Context) {
        val intent = Intent(context, MonitorForegroundService::class.java)
        ContextCompat.startForegroundService(context, intent)
    }

    companion object {
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val PFX = "flutter."
        private const val _PREF_IS_MONITORING = "is_monitoring"
    }
}
