package com.example.mu_super_app.usage

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.ActivityManager
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
                checkParentalControls()
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
            
            // Don't show overlay on this app itself
            if (pkg == this.packageName) {
                Log.d(TAG, "Skipping overlay for this app: $pkg")
                return
            }
            
            // Don't show overlay on system apps
            if (isSystemApp(pkg)) {
                Log.d(TAG, "Skipping overlay for system app: $pkg")
                return
            }
            
            // Check if overlay was already shown for this app in this session
            if (wasOverlayShown(pkg)) {
                Log.d(TAG, "Overlay already shown for $pkg this session")
                return
            }
            
            val appName = trackedPackages[pkg] ?: pkg
            val minutes = ((offending.totalTimeInForeground / 1000L) + 59L) / 60L
            Log.i(
                TAG,
                "App $appName exceeded limit: $minutes / $limitMinutes minutes"
            )
            
            // Mark overlay as shown
            markOverlayShown(pkg)
            
            saveOverlayDataAndRequestOverlay(appName, minutes.toInt(), limitMinutes, pkg)
            return
        }

        // If no single tracked app exceeded the limit, fall back to total usage.
        // Note: We don't show overlay for "All Apps" as it's not a specific app
        // The overlay should only show for specific apps that exceeded their limits
    }

    private fun saveOverlayDataAndRequestOverlay(
        appName: String,
        usedMinutes: Int,
        limitMinutes: Int,
        packageName: String? = null
    ) {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        editor.putString("${PFX}$_PREF_OVERLAY_APP", appName)
        editor.putInt("${PFX}$_PREF_OVERLAY_USED", usedMinutes)
        editor.putInt("${PFX}$_PREF_OVERLAY_LIMIT", limitMinutes)
        
        // Also save package name if available for blocking
        if (packageName != null) {
            editor.putString("${PFX}overlay_package_name", packageName)
        }
        editor.apply()
        
        Log.d(TAG, "Saved overlay data for $appName (package: $packageName)")

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

    /**
     * Checks parental control settings and enforces app blocking and time limits.
     */
    private fun checkParentalControls() {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        
        // Check if schedule is active
        val scheduleJson = prefs.getString("${PFX}$_PREF_SCHEDULE", null)
        if (scheduleJson != null) {
            val scheduleEnabled = scheduleJson.contains("\"enabled\":true")
            if (scheduleEnabled) {
                // Parse schedule and check if restrictions should be active
                // For now, we'll check if we're in the active time window
                // This is a simplified check - full implementation would parse JSON properly
                val isInActiveWindow = checkScheduleActive(scheduleJson)
                if (!isInActiveWindow) {
                    Log.d(TAG, "Schedule restrictions not active")
                    return
                }
            }
        }

        // IMPORTANT: We do NOT automatically close apps here!
        // We only show overlay when time limits are exceeded.
        // The user must click "Take a Break" button to close and block the app.
        // Permanently blocked apps are handled by AccessibilityService separately.

        // Check time limits for individual apps and show overlay (DO NOT close)
        val timeLimitsJson = prefs.getString("${PFX}$_PREF_TIME_LIMITS", null)
        if (timeLimitsJson != null && timeLimitsJson != "{}") {
            val timeLimits = parseTimeLimits(timeLimitsJson)
            checkAppTimeLimits(timeLimits)
        }
        
        // DO NOT check permanently blocked apps here - that's handled by AccessibilityService
        // We only show overlay for time limit violations, not for permanent blocks
    }

    /**
     * Checks if schedule restrictions are currently active.
     */
    private fun checkScheduleActive(scheduleJson: String): Boolean {
        // Simplified check - full implementation would parse JSON properly
        // For now, assume restrictions are active if schedule is enabled
        // In production, parse the JSON and check current time against start/end times
        return true
    }

    /**
     * Parses blocked apps from JSON string.
     */
    private fun parseBlockedApps(json: String): Set<String> {
        val apps = mutableSetOf<String>()
        try {
            // Simple parsing - remove brackets and quotes, split by comma
            val cleaned = json.replace("[", "").replace("]", "").replace("\"", "")
            if (cleaned.isNotEmpty()) {
                cleaned.split(",").forEach { app ->
                    val trimmed = app.trim()
                    if (trimmed.isNotEmpty()) {
                        apps.add(trimmed)
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse blocked apps", e)
        }
        return apps
    }

    /**
     * Parses time limits from JSON string.
     */
    private fun parseTimeLimits(json: String): Map<String, Int> {
        val limits = mutableMapOf<String, Int>()
        try {
            // Simple parsing - this is a simplified version
            // Full implementation would use proper JSON parsing
            // Format: {"package.name": minutes, ...}
            val cleaned = json.replace("{", "").replace("}", "").replace("\"", "")
            if (cleaned.isNotEmpty()) {
                cleaned.split(",").forEach { entry ->
                    val parts = entry.split(":")
                    if (parts.size == 2) {
                        val packageName = parts[0].trim()
                        val minutes = parts[1].trim().toIntOrNull()
                        if (minutes != null) {
                            limits[packageName] = minutes
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse time limits", e)
        }
        return limits
    }

    /**
     * Gets the current foreground app package name.
     * Uses UsageStatsManager to find the most recently used app.
     */
    private fun getCurrentForegroundApp(): String? {
        return try {
            val now = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                now - 10000, // Last 10 seconds (more accurate)
                now
            )
            // Get the app with the most recent lastTimeUsed
            val currentApp = stats?.maxByOrNull { it.lastTimeUsed }
            if (currentApp != null && (now - currentApp.lastTimeUsed) < 5000) {
                // Only return if app was used in last 5 seconds (likely in foreground)
                return currentApp.packageName
            }
            null
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get current foreground app", e)
            null
        }
    }

    /**
     * Closes the specified app and returns to home screen.
     */
    private fun closeAppAndGoHome(packageName: String) {
        try {
            // First, try to kill the app's processes
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                activityManager.killBackgroundProcesses(packageName)
                Log.d(TAG, "Killed background processes for: $packageName")
            }
            
            // Then send home intent
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            startActivity(homeIntent)
            Log.d(TAG, "Sent home intent after closing: $packageName")
            
            // Close overlay if it's showing
            try {
                val overlayIntent = Intent(this, OverlayService::class.java).apply {
                    action = "CLOSE_OVERLAY"
                }
                stopService(overlayIntent)
            } catch (e: Exception) {
                Log.w(TAG, "Could not close overlay service", e)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error closing app: $packageName", e)
        }
    }

    /**
     * Gets app name from package name.
     */
    private fun getAppName(packageName: String): String {
        return SOCIAL_APPS[packageName] ?: packageName
    }

    /**
     * Checks time limits for apps and shows overlay if exceeded.
     * Only shows overlay if the offending app is currently in foreground.
     * Automatically closes the app when limit is exceeded.
     */
    private fun checkAppTimeLimits(timeLimits: Map<String, Int>) {
        // Get current foreground app first
        val currentForegroundApp = getCurrentForegroundApp()
        
        // Don't check if this app itself is in foreground
        if (currentForegroundApp == this.packageName) {
            Log.d(TAG, "This app is in foreground, skipping time limit check")
            return
        }
        
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
            Log.w(TAG, "Usage access not granted for time limits check", e)
            return
        }

        for ((packageName, limitMinutes) in timeLimits) {
            val stats = statsMap[packageName] ?: continue
            val usedMinutes = ((stats.totalTimeInForeground / 1000L + 59L) / 60L).toInt()

            // Don't show overlay if app is already temporarily blocked
            val checkPrefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val tempBlockedJson = checkPrefs.getString("${PFX}blocked_apps_with_timestamps", null)
            if (tempBlockedJson != null && tempBlockedJson.contains(packageName)) {
                // App is already temporarily blocked, skip overlay
                continue
            }

            if (usedMinutes >= limitMinutes) {
                // IMPORTANT: Only show overlay if the offending app is currently in foreground
                if (currentForegroundApp != packageName) {
                    Log.d(TAG, "App $packageName exceeded limit but is not in foreground (current: $currentForegroundApp), skipping overlay")
                    continue
                }
                
                // Check if overlay was already shown for this app
                if (wasOverlayShown(packageName)) {
                    Log.d(TAG, "Overlay already shown for $packageName, closing app directly")
                    // Close app immediately if overlay was already shown
                    closeAppAndGoHome(packageName)
                    continue
                }

                val appName = getAppName(packageName)
                Log.i(
                    TAG,
                    "App $appName exceeded time limit: $usedMinutes / $limitMinutes minutes - showing overlay and closing app"
                )
                
                // Mark overlay as shown
                markOverlayShown(packageName)
                
                // Show overlay briefly, then automatically close the app
                saveOverlayDataAndRequestOverlay(appName, usedMinutes, limitMinutes, packageName)
                
                // Automatically close the app after a short delay (to show overlay)
                handler.postDelayed({
                    closeAppAndGoHome(packageName)
                }, 2000) // Show overlay for 2 seconds, then close
            }
        }
    }

    /**
     * Checks if an app is a system app.
     */
    private fun isSystemApp(packageName: String): Boolean {
        val systemApps = setOf(
            "com.android.settings",
            "com.android.dialer",
            "com.android.mms",
            "com.android.launcher",
            "com.google.android.apps.nexuslauncher",
            "com.android.launcher3"
        )
        return systemApps.contains(packageName) || 
               packageName.startsWith("com.android.") ||
               packageName.startsWith("com.google.android.apps.")
    }

    /**
     * Checks if overlay was already shown for an app in this session.
     */
    private fun wasOverlayShown(packageName: String): Boolean {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val shownList = prefs.getStringSet("${PFX}$_PREF_OVERLAY_SHOWN", emptySet()) ?: emptySet()
        return shownList.contains(packageName)
    }

    /**
     * Marks overlay as shown for an app in this session.
     */
    private fun markOverlayShown(packageName: String) {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val shownSet = prefs.getStringSet("${PFX}$_PREF_OVERLAY_SHOWN", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        shownSet.add(packageName)
        prefs.edit()
            .putStringSet("${PFX}$_PREF_OVERLAY_SHOWN", shownSet)
            .apply()
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
        private const val _PREF_BLOCKED_APPS = "parental_control_blocked_apps"
        private const val _PREF_TIME_LIMITS = "parental_control_time_limits"
        private const val _PREF_SCHEDULE = "parental_control_schedule"
        private const val _PREF_OVERLAY_SHOWN = "overlay_shown_sessions"

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


