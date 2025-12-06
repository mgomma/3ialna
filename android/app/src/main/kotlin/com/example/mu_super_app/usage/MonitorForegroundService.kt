package com.example.mu_super_app.usage

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import android.content.pm.ServiceInfo
import androidx.core.content.ContextCompat
import com.example.mu_super_app.MainActivity
import com.example.mu_super_app.R
import java.util.Calendar
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import flutter.overlay.window.flutter_overlay_window.OverlayService
/**
 * Foreground service that periodically checks app usage in the background.
 *
 * This allows us to detect when a tracked social media app (e.g. TikTok)
 * has reached the configured daily time limit, even when the Flutter UI
 * is not in the foreground.
 *
 * NOTE: This service writes overlay data into the same SharedPreferences
 * that Flutter uses, so the existing Flutter overlay entrypoint can read
 * and display the blocking screen.
 */
class MonitorForegroundService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var usageStatsManager: UsageStatsManager

    // 30 seconds between checks
    private val pollIntervalMs = 30_000L
    
    // Track last toast time to avoid spamming
    private var lastPrayerLockToastTime = 0L
    private val toastCooldownMs = 60_000L // Show toast at most once per minute

    private val runnable = object : Runnable {
        override fun run() {
            try {
                Log.d(TAG, "Runnable: checking usage...")
                checkUsageAndMaybeBlock()
                checkPrayerLocksAndMaybeBlock()
            } catch (t: Throwable) {
                Log.e(TAG, "Error checking usage", t)
            } finally {
                handler.postDelayed(this, pollIntervalMs)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        startForegroundServiceWithNotification()
        handler.post(runnable)
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        if (!isMonitoringEnabled()) {
            Log.w(TAG, "Service started but monitoring disabled; stopping self")
            stopSelf()
            return START_NOT_STICKY
        }
        // Keep running until explicitly stopped.
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(runnable)
        Log.d(TAG, "MonitorForegroundService destroyed")
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "onTaskRemoved called")
        if (isMonitoringEnabled()) {
            Log.d(TAG, "Restarting monitoring service after task removal")
            val restartIntent = Intent(applicationContext, MonitorForegroundService::class.java)
            ContextCompat.startForegroundService(applicationContext, restartIntent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundServiceWithNotification() {
        val channelId = "social_limiter_monitor_channel"
        val channelName = "Social Media Monitoring"

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }

        val mainIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    PendingIntent.FLAG_IMMUTABLE
                else 0
        )

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("3ialna")
            .setContentText("Monitoring social media usage")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceCompat.startForeground(
                this,
                FOREGROUND_ID,
                notification,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                }
            )
        } else {
            startForeground(FOREGROUND_ID, notification)
        }
    }

    private fun checkUsageAndMaybeBlock() {
        // Respect the "isMonitoring" flag stored by Flutter.
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val isMonitoring =
            prefs.getBoolean("${PFX}$_PREF_IS_MONITORING", false)
        Log.d(TAG, "isMonitoring: $isMonitoring")
        if (!isMonitoring) return

        // Flutter stores ints as 64-bit; read defensively to avoid ClassCastException.
        val limitMinutes: Int = try {
            prefs.getInt("${PFX}$_PREF_TIME_LIMIT", 30)
        } catch (e: ClassCastException) {
            prefs.getLong("${PFX}$_PREF_TIME_LIMIT", 30L).toInt()
        }
        Log.d(TAG, "limitMinutes: $limitMinutes")

        val now = System.currentTimeMillis()
        val startOfDay = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

        val statsMap: Map<String, UsageStats> = try {
            usageStatsManager.queryAndAggregateUsageStats(
                startOfDay,
                now
            ) ?: emptyMap()
        } catch (e: SecurityException) {
            Log.w(TAG, "Usage access not granted", e)
            return
        }

        if (statsMap.isEmpty()) {
            Log.d(TAG, "No usage stats found. Permission granted?")
            return
        }
        Log.d(TAG, "Found ${statsMap.size} usage stats records")

        val trackedPackages = SOCIAL_APPS

        var totalMinutes = 0L
        var offending: UsageStats? = null
        for ((pkg, s) in statsMap) {
            val minutes = ((s.totalTimeInForeground / 1000L) + 59L) / 60L
            totalMinutes += minutes

            if (!trackedPackages.containsKey(pkg)) continue

            Log.d(TAG, "Checking $pkg: $minutes minutes (tracked)")
            if (minutes >= limitMinutes && offending == null) {
                offending = s
            }
        }

        Log.d(TAG, "Total device usage today: $totalMinutes minutes")

        if (offending != null) {
            val pkg = offending.packageName
            val appName = trackedPackages[pkg] ?: pkg
            val minutes = ((offending.totalTimeInForeground / 1000L) + 59L) / 60L
            Log.i(
                TAG,
                "App $appName exceeded limit: $minutes / $limitMinutes minutes"
            )
            saveOverlayDataAndRequestOverlay(appName, minutes.toInt(), limitMinutes)
            return
        }

        // If no single tracked app exceeded the limit, fall back to total usage.
        if (totalMinutes >= limitMinutes) {
            Log.i(
                TAG,
                "Total device usage exceeded limit: $totalMinutes / $limitMinutes minutes"
            )
            saveOverlayDataAndRequestOverlay(
                appName = "All Apps",
                usedMinutes = totalMinutes.toInt(),
                limitMinutes = limitMinutes
            )
        }
    }

    private fun saveOverlayDataAndRequestOverlay(
        appName: String,
        usedMinutes: Int,
        limitMinutes: Int
    ) {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putString("${PFX}$_PREF_OVERLAY_APP", appName)
            .putInt("${PFX}$_PREF_OVERLAY_USED", usedMinutes)
            .putInt("${PFX}$_PREF_OVERLAY_LIMIT", limitMinutes)
            .apply()

        // If we don't have overlay permission, we cannot show the blocker.
        if (!Settings.canDrawOverlays(this)) {
            Log.w(TAG, "Overlay permission not granted; cannot show overlay")
            return
        }

        // Start the plugin's OverlayService which will attach the cached Flutter
        // engine whose entrypoint is overlayMain (already configured by the plugin).
        val intent = Intent(this, OverlayService::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        try {
            startService(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start OverlayService", e)
        }
    }

    private fun isMonitoringEnabled(): Boolean {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("$PFX$_PREF_IS_MONITORING", false)
    }

    /**
     * Shows a toast message on the main thread.
     * Toasts from background services need to be shown on the main thread.
     */
    private fun showPrayerLockToast(message: String) {
        handler.post {
            try {
                val toast = Toast.makeText(
                    applicationContext,
                    message,
                    Toast.LENGTH_LONG
                )
                toast.show()
                Log.d(TAG, "Showed prayer lock toast: $message")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to show toast", e)
            }
        }
    }

    private fun checkPrayerLocksAndMaybeBlock() {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        
        // Check if prayer locks are enabled by reading the prayer lock settings JSON
        val prayerSettingsJson = prefs.getString("${PFX}prayer_lock_settings", null)
        if (prayerSettingsJson == null) {
            Log.d(TAG, "No prayer lock settings found")
            return
        }
        
        // Parse JSON to check if enabled (simple check for "enabled":true)
        val isEnabled = prayerSettingsJson.contains("\"enabled\":true")
        if (!isEnabled) {
            Log.d(TAG, "Prayer locks are disabled")
            return
        }
        
        // Check if there's an active prayer lock period
        // Flutter stores as string, so read as string and parse
        val lockStartStr = prefs.getString("${PFX}$_PREF_PRAYER_LOCK_ACTIVE_START", null)
        val lockEndStr = prefs.getString("${PFX}$_PREF_PRAYER_LOCK_ACTIVE_END", null)
        val prayerName = prefs.getString("${PFX}$_PREF_PRAYER_LOCK_ACTIVE_NAME", null)
        
        Log.d(TAG, "Prayer lock check - start: $lockStartStr, end: $lockEndStr, name: $prayerName")
        
        if (lockStartStr == null || lockEndStr == null || prayerName == null) {
            // No active prayer lock period
            Log.d(TAG, "No active prayer lock period found")
            return
        }
        
        val lockStart = try {
            lockStartStr.toLong()
        } catch (e: NumberFormatException) {
            Log.w(TAG, "Failed to parse lock start time: $lockStartStr", e)
            return
        }
        
        val lockEnd = try {
            lockEndStr.toLong()
        } catch (e: NumberFormatException) {
            Log.w(TAG, "Failed to parse lock end time: $lockEndStr", e)
            return
        }
        
        if (lockStart == 0L || lockEnd == 0L) {
            Log.d(TAG, "Invalid lock times: start=$lockStart, end=$lockEnd")
            return
        }
        
        val now = System.currentTimeMillis()
        Log.d(TAG, "Prayer lock check - now: $now, start: $lockStart, end: $lockEnd")
        
        // Check if current time is within the lock period
        if (now >= lockStart && now < lockEnd) {
            val remainingMs = lockEnd - now
            val remainingMinutes = ((remainingMs / 1000L) + 59L) / 60L
            
            Log.i(TAG, "In prayer lock period: $prayerName (${remainingMinutes} minutes remaining)")
            
            // Show toast warning (with cooldown to avoid spamming)
            if (now - lastPrayerLockToastTime > toastCooldownMs) {
                showPrayerLockToast("Prayer Time Lock: $prayerName\nDevice locked for ${remainingMinutes} more minutes")
                lastPrayerLockToastTime = now
            }
            
            // Show overlay for prayer lock
            saveOverlayDataAndRequestOverlay(
                appName = "Prayer Time Lock - $prayerName",
                usedMinutes = 0,
                limitMinutes = remainingMinutes.toInt()
            )
        } else if (now >= lockEnd) {
            // Lock period has ended, clear it
            Log.d(TAG, "Prayer lock period ended, clearing")
            prefs.edit()
                .remove("${PFX}$_PREF_PRAYER_LOCK_ACTIVE_NAME")
                .remove("${PFX}$_PREF_PRAYER_LOCK_ACTIVE_START")
                .remove("${PFX}$_PREF_PRAYER_LOCK_ACTIVE_END")
                .apply()
            lastPrayerLockToastTime = 0L // Reset toast cooldown
        } else {
            // Not yet in lock period - show warning 2 minutes before
            val minutesUntilStart = (lockStart - now) / 1000 / 60
            if (minutesUntilStart <= 2 && minutesUntilStart > 0) {
                // Show warning toast 2 minutes before prayer time
                if (now - lastPrayerLockToastTime > toastCooldownMs) {
                    showPrayerLockToast("Prayer Time Warning: $prayerName\nDevice will be locked in ${minutesUntilStart.toInt()} minute(s)")
                    lastPrayerLockToastTime = now
                }
            }
            Log.d(TAG, "Not yet in prayer lock period (${minutesUntilStart} minutes until start)")
        }
    }

    companion object {
        private const val TAG = "MonitorForegroundSvc"
        private const val FOREGROUND_ID = 1001

        // Flutter's shared prefs file and key prefix
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val PFX = "flutter."

        private const val _PREF_TIME_LIMIT = "time_limit_minutes"
        private const val _PREF_IS_MONITORING = "is_monitoring"
        private const val _PREF_OVERLAY_APP = "overlay_app_name"
        private const val _PREF_OVERLAY_USED = "overlay_used_minutes"
        private const val _PREF_OVERLAY_LIMIT = "overlay_limit_minutes"
        private const val _PREF_PRAYER_LOCK_ACTIVE_NAME = "prayer_lock_active_name"
        private const val _PREF_PRAYER_LOCK_ACTIVE_START = "prayer_lock_active_start"
        private const val _PREF_PRAYER_LOCK_ACTIVE_END = "prayer_lock_active_end"

        // Same package map as in core/constants/social_media_apps.dart
        private val SOCIAL_APPS = mapOf(
            "com.facebook.katana" to "Facebook",
            "com.instagram.android" to "Instagram",
            "com.twitter.android" to "Twitter",
            "com.snapchat.android" to "Snapchat",
            "com.zhiliaoapp.musically" to "TikTok",
            "com.ss.android.ugc.trill" to "TikTok",
            "com.reddit.frontpage" to "Reddit"
        )
    }
}


