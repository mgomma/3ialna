package com.ialna.app.usage

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
import com.ialna.app.MainActivity
import com.ialna.app.R
import com.ialna.app.diagnostics.CrashReportRecorder
import java.util.Calendar
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.pm.PackageManager
import flutter.overlay.window.flutter_overlay_window.OverlayService
import org.json.JSONObject
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

    // 10 seconds between checks for better responsiveness
    private val pollIntervalMs = 10_000L
    
    // Track last toast time to avoid spamming
    private var lastPrayerLockToastTime = 0L
    private val toastCooldownMs = 60_000L // Show toast at most once per minute

    private val runnable = object : Runnable {
        override fun run() {
            try {
                Log.d(TAG, "Runnable: checking usage...")
                checkUsageAndMaybeBlock()
                checkPrayerLocksAndMaybeBlock()
                checkSleepLockAndMaybeBlock()
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
        try {
            usageStatsManager =
                getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            startForegroundServiceWithNotification()
            handler.post(runnable)
            showDebugToast("3ialna: Monitoring Service Active")
        } catch (error: Exception) {
            CrashReportRecorder.record(this, "monitoring_service_foreground", error)
            Log.e(TAG, "Could not start monitoring foreground service", error)
            stopSelf()
        }
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        if (!isMonitoringEnabled()) {
            Log.w(TAG, "Service started but monitoring disabled; stopping self")
            showDebugToast("3ialna: Monitoring disabled")
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
            try {
                val restartIntent = Intent(applicationContext, MonitorForegroundService::class.java)
                ContextCompat.startForegroundService(applicationContext, restartIntent)
            } catch (error: Exception) {
                CrashReportRecorder.record(this, "monitoring_service_restart", error)
                Log.w(TAG, "Could not restart monitoring service", error)
            }
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
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                }
            )
        } else {
            startForeground(FOREGROUND_ID, notification)
        }
    }

    private fun checkUsageAndMaybeBlock() {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("${PFX}$_PREF_IS_MONITORING", false)) return

        val socialLimit = readIntPreference(prefs, _PREF_ACTIVE_SOCIAL_LIMIT, 0)
        val gamesLimit = readIntPreference(prefs, _PREF_ACTIVE_GAMES_LIMIT, 0)
        val assignedCategories = readAssignedCategories(prefs)

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
        val categoryTotals = mutableMapOf("socialMedia" to 0L, "games" to 0L)
        for ((pkg, s) in statsMap) {
            val minutes = ((s.totalTimeInForeground / 1000L) + 59L) / 60L
            val category = categoryForPackage(pkg, assignedCategories) ?: continue
            categoryTotals[category] = (categoryTotals[category] ?: 0L) + minutes
        }

        val activeCategoryUsage = categoryTotals.mapValues { (category, total) ->
            allocateUsageToActiveChild(prefs, category, total)
        }

        val currentPackage = getCurrentForegroundApp() ?: return
        if (currentPackage == packageName || isSystemApp(currentPackage) || isSnoozed(currentPackage)) return
        val category = categoryForPackage(currentPackage, assignedCategories) ?: return
        val limit = if (category == "socialMedia") socialLimit else gamesLimit
        val used = activeCategoryUsage[category] ?: 0L
        if (used < limit) return

        val categoryName = if (category == "socialMedia") "Social media" else "Games"
        val overlayKey = "category_$category"
        val isStrictMode = prefs.getBoolean("${PFX}is_strict_mode", false)
        if (!isStrictMode && wasRecentlyShown(overlayKey)) return
        markOverlayShown(overlayKey)
        Log.i(TAG, "$categoryName category exceeded: $used / $limit minutes; foreground=$currentPackage")
        if (isStrictMode) {
            showDebugToast("Locking Device: $categoryName limit reached")
            triggerHardLock(categoryName, used.toInt(), limit, currentPackage)
        } else {
            showDebugToast("Time limit: $categoryName")
            saveOverlayDataAndRequestOverlay(categoryName, used.toInt(), limit, currentPackage)
        }
    }

    private fun readIntPreference(prefs: android.content.SharedPreferences, key: String, fallback: Int): Int {
        return try {
            prefs.getInt("${PFX}$key", fallback)
        } catch (_: ClassCastException) {
            prefs.getLong("${PFX}$key", fallback.toLong()).toInt()
        }
    }

    private fun readAssignedCategories(prefs: android.content.SharedPreferences): Map<String, String> {
        val raw = prefs.getString("${PFX}$_PREF_APP_CATEGORIES", "{}") ?: "{}"
        return try {
            val json = JSONObject(raw)
            val values = mutableMapOf<String, String>()
            val keys = json.keys()
            while (keys.hasNext()) {
                val packageName = keys.next()
                val category = json.optString(packageName)
                if (category == "socialMedia" || category == "games") values[packageName] = category
            }
            values
        } catch (_: Exception) {
            emptyMap()
        }
    }

    private fun categoryForPackage(packageName: String, assigned: Map<String, String>): String? {
        return assigned[packageName] ?: when {
            SOCIAL_APPS.containsKey(packageName) -> "socialMedia"
            GAMES_APPS.containsKey(packageName) -> "games"
            else -> null
        }
    }

    /**
     * UsageStats is device-wide, so we persist category deltas under the child
     * selected when those deltas are observed. This makes shared-device budgets
     * independent after parents switch the active child from the app or launcher.
     */
    private fun allocateUsageToActiveChild(
        prefs: android.content.SharedPreferences,
        category: String,
        deviceTotalMinutes: Long
    ): Long {
        val calendar = Calendar.getInstance()
        val dayKey = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.DAY_OF_YEAR)}"
        val storedDay = prefs.getString("${PFX}$_PREF_CHILD_USAGE_DAY", "")
        val usageJson = if (storedDay == dayKey) {
            prefs.getString("${PFX}$_PREF_CHILD_CATEGORY_USAGE", "{}") ?: "{}"
        } else "{}"
        val totalsJson = if (storedDay == dayKey) {
            prefs.getString("${PFX}$_PREF_CHILD_LAST_TOTALS", "{}") ?: "{}"
        } else "{}"
        val usage = try { JSONObject(usageJson) } catch (_: Exception) { JSONObject() }
        val totals = try { JSONObject(totalsJson) } catch (_: Exception) { JSONObject() }
        val previousTotal = totals.optLong(category, deviceTotalMinutes)
        val delta = (deviceTotalMinutes - previousTotal).coerceAtLeast(0L)
        totals.put(category, deviceTotalMinutes)

        val activeChildId = prefs.getString("${PFX}$_PREF_ACTIVE_CHILD", "default") ?: "default"
        val usageKey = "$activeChildId:$category"
        val updatedUsage = usage.optLong(usageKey, 0L) + delta
        usage.put(usageKey, updatedUsage)
        prefs.edit()
            .putString("${PFX}$_PREF_CHILD_USAGE_DAY", dayKey)
            .putString("${PFX}$_PREF_CHILD_CATEGORY_USAGE", usage.toString())
            .putString("${PFX}$_PREF_CHILD_LAST_TOTALS", totals.toString())
            .apply()
        return updatedUsage
    }

    /**
     * Triggers a hard lock by launching MainActivity with the lock flag.
     */
    private fun triggerHardLock(appName: String, usedMinutes: Int, limitMinutes: Int, pkg: String? = null) {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        
        // Save overlay data so MainActivity/Flutter can display the correct message
        // Use commit() for critical state to ensures it's readable when MainActivity launches
        prefs.edit()
            .putString("${PFX}overlay_app_name", appName)
            .putInt("${PFX}overlay_used_minutes", usedMinutes)
            .putInt("${PFX}overlay_limit_minutes", limitMinutes)
            .putString("${PFX}overlay_package_name", pkg ?: "")
            .putBoolean("${PFX}is_device_locked", true)
            .commit()

        Log.d(TAG, "Triggering Hard Lock for $appName (package: $pkg)")

        // Launch MainActivity with the lock flag
        val lockIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("EXTRA_HARD_LOCK", true)
        }
        startActivity(lockIntent)

        // Physical Lock (Screen Off)
        lockDeviceNow()
    }

    /**
     * Physically locks the device (turns screen off) using DevicePolicyManager.
     * Requires Device Admin permission to be active.
     */
    private fun lockDeviceNow() {
        try {
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
            val adminComponent = android.content.ComponentName(this, com.ialna.app.DeviceAdminReceiver::class.java)
            if (dpm.isAdminActive(adminComponent)) {
                dpm.lockNow()
                Log.d(TAG, "Device physically locked via DevicePolicyManager")
            } else {
                Log.w(TAG, "Cannot lock device: Admin not active")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error trying to lock device", e)
        }
    }

    private fun saveOverlayDataAndRequestOverlay(
        appName: String,
        usedMinutes: Int,
        limitMinutes: Int,
        packageName: String? = null
    ) {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        editor.putString("${PFX}overlay_app_name", appName)
        editor.putInt("${PFX}overlay_used_minutes", usedMinutes)
        editor.putInt("${PFX}overlay_limit_minutes", limitMinutes)
        
        // Also save package name if available for blocking
        if (packageName != null) {
            editor.putString("${PFX}overlay_package_name", packageName)
        }
        // Mark as device locked for Flutter UI consistency
        editor.putBoolean("${PFX}is_device_locked", true)
        editor.commit()
        
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
     * Shows a toast message for debugging.
     */
    private fun showDebugToast(message: String) {
        handler.post {
            try {
                Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show()
                Log.d(TAG, "Debug Toast: $message")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to show debug toast", e)
            }
        }
    }

    private fun checkPrayerLocksAndMaybeBlock() {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("${PFX}$_PREF_ACTIVE_PRAYER_ENABLED", true)) {
            return
        }
        
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
            // Don't show overlay if this app is in foreground
            val currentForegroundApp = getCurrentForegroundApp()
            if (currentForegroundApp == this.packageName) {
                Log.d(TAG, "This app is in foreground, skipping prayer lock overlay")
                return
            }
            
            // Check if overlay was recently shown for this prayer lock
            val prayerLockKey = "prayer_lock_$prayerName"
            if (wasRecentlyShown(prayerLockKey)) {
                Log.d(TAG, "Prayer lock overlay already shown for $prayerName")
                return
            }
            
            val remainingMs = lockEnd - now
            val remainingMinutes = ((remainingMs / 1000L) + 59L) / 60L
            
            Log.i(TAG, "In prayer lock period: $prayerName (${remainingMinutes} minutes remaining)")
            
            // Show toast warning (with cooldown to avoid spamming)
            if (now - lastPrayerLockToastTime > toastCooldownMs) {
                showDebugToast("Prayer Lock: $prayerName\nLocked for ${remainingMinutes}m")
                lastPrayerLockToastTime = now
            }
            
            // Mark overlay as shown for this prayer lock
            markOverlayShown(prayerLockKey)
            
            // Check if Strict Mode (Hard Lock) is enabled
            val isStrictMode = prefs.getBoolean("${PFX}is_strict_mode", false)
            if (isStrictMode) {
                Log.i(TAG, "Strict Mode active, triggering Hard Lock for Prayer: $prayerName")
                triggerHardLock("Prayer Time Lock - $prayerName", 0, remainingMinutes.toInt())
            } else {
                // Show overlay for prayer lock
                saveOverlayDataAndRequestOverlay(
                    appName = "Prayer Time Lock - $prayerName",
                    usedMinutes = 0,
                    limitMinutes = remainingMinutes.toInt()
                )
            }
        } else if (now >= lockEnd) {
            // Lock period has ended, clear it
            Log.d(TAG, "Prayer lock period ended, clearing")
            
            // Clear prayer lock overlay session
            val prayerLockKey = "prayer_lock_$prayerName"
            clearOverlayShown(prayerLockKey)
            
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
                    showDebugToast("Prayer Time Warning: $prayerName\nLocked in ${minutesUntilStart.toInt()}m")
                    lastPrayerLockToastTime = now
                }
            }
            Log.d(TAG, "Not yet in prayer lock period (${minutesUntilStart} minutes until start)")
        }
    }

    /** Applies the active child's parent-configured overnight device lock. */
    private fun checkSleepLockAndMaybeBlock() {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("${PFX}$_PREF_ACTIVE_SLEEP_ENABLED", true)) return
        val start = readIntPreference(prefs, _PREF_ACTIVE_SLEEP_START, 0)
        val end = readIntPreference(prefs, _PREF_ACTIVE_SLEEP_END, 0)
        if (start == end) return

        val calendar = Calendar.getInstance()
        val nowMinutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        val inSleepWindow = if (start < end) nowMinutes >= start && nowMinutes < end else nowMinutes >= start || nowMinutes < end
        if (!inSleepWindow) return

        val currentPackage = getCurrentForegroundApp() ?: return
        if (currentPackage == packageName || isSystemApp(currentPackage) || isSnoozed(currentPackage)) return
        val activeChild = prefs.getString("${PFX}$_PREF_ACTIVE_CHILD", "child") ?: "child"
        val overlayKey = "sleep_lock_$activeChild"
        val isStrictMode = prefs.getBoolean("${PFX}is_strict_mode", false)
        if (!isStrictMode && wasRecentlyShown(overlayKey)) return
        markOverlayShown(overlayKey)

        val minutesUntilWake = when {
            start < end -> (end - nowMinutes).coerceAtLeast(1)
            nowMinutes >= start -> 24 * 60 - nowMinutes + end
            else -> end - nowMinutes
        }
        if (isStrictMode) {
            showDebugToast("Sleep time: device locked")
            triggerHardLock("Sleep time", 0, minutesUntilWake, currentPackage)
        } else {
            showDebugToast("Sleep time")
            saveOverlayDataAndRequestOverlay("Sleep time", 0, minutesUntilWake, currentPackage)
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
            val scheduleEnabled = try {
                JSONObject(scheduleJson).optBoolean("enabled", false)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to parse schedule enabled state", e)
                true
            }
            if (scheduleEnabled) {
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
        try {
            val scheduleObj = JSONObject(scheduleJson)
            if (!scheduleObj.optBoolean("enabled", false)) return false

            val calendar = Calendar.getInstance()
            val currentDay = calendar.get(Calendar.DAY_OF_WEEK) % 7
            val isWeekend = currentDay == 0 || currentDay == 6

            val activeDaysArray = scheduleObj.optJSONArray("activeDays")
            if (activeDaysArray != null && activeDaysArray.length() > 0) {
                var dayEnabled = false
                for (i in 0 until activeDaysArray.length()) {
                    if (activeDaysArray.optInt(i, -1) == currentDay) {
                        dayEnabled = true
                        break
                    }
                }
                if (!dayEnabled) {
                    return false
                }
            }

            val nowHour = calendar.get(Calendar.HOUR_OF_DAY)
            val nowMinute = calendar.get(Calendar.MINUTE)
            val nowTotalMinutes = nowHour * 60 + nowMinute

            val differentWeekendRules = scheduleObj.optBoolean("differentWeekendRules", false)
            val startTimeRaw = if (differentWeekendRules && isWeekend) {
                scheduleObj.optString("weekendStartTime", scheduleObj.optString("startTime", "09:00"))
            } else {
                scheduleObj.optString("startTime", "09:00")
            }
            val endTimeRaw = if (differentWeekendRules && isWeekend) {
                scheduleObj.optString("weekendEndTime", scheduleObj.optString("endTime", "21:00"))
            } else {
                scheduleObj.optString("endTime", "21:00")
            }

            val startTotal = parseTimeToMinutes(startTimeRaw)
            val endTotal = parseTimeToMinutes(endTimeRaw)

            if (startTotal == null || endTotal == null) {
                Log.w(TAG, "Invalid schedule time format start=$startTimeRaw end=$endTimeRaw")
                return true
            }

            return if (startTotal <= endTotal) {
                nowTotalMinutes >= startTotal && nowTotalMinutes < endTotal
            } else {
                nowTotalMinutes >= startTotal || nowTotalMinutes < endTotal
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing schedule JSON", e)
        }
        return true // Default to active if parsing fails for safety
    }

    private fun parseTimeToMinutes(time: String): Int? {
        val parts = time.split(":")
        if (parts.size != 2) return null

        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null
        if (hour !in 0..23 || minute !in 0..59) return null

        return hour * 60 + minute
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
                now - 60_000, 
                now
            )
            // Get the app with the most recent lastTimeUsed
            val currentApp = stats?.maxByOrNull { it.lastTimeUsed }
            // Be more lenient - if any app was used in last 20 seconds
            if (currentApp != null && (now - currentApp.lastTimeUsed) < 20_000) {
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
            val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val tempBlockedJson = prefs.getString("${PFX}blocked_apps_with_timestamps", null)
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
                
                // Check for snooze
                if (isSnoozed(packageName)) {
                    Log.d(TAG, "App $packageName is currently snoozed, skipping")
                    continue
                }

                // Check for Strict Mode (Hard Lock)
                val isStrictMode = prefs.getBoolean("${PFX}is_strict_mode", false)
                
                // If recently shown and not in strict mode, just close app
                if (!isStrictMode && wasRecentlyShown(packageName)) {
                    Log.d(TAG, "Overlay recently shown for $packageName, closing app directly")
                    closeAppAndGoHome(packageName)
                    continue
                }

                val appName = getAppName(packageName)
                Log.i(TAG, "App $appName exceeded limit: $usedMinutes / $limitMinutes - StrictMode: $isStrictMode")
                
                // Mark as recently shown
                markOverlayShown(packageName)
                
                if (isStrictMode) {
                    // Trigger Hard Lock for custom app limit
                    triggerHardLock(appName, usedMinutes, limitMinutes, packageName)
                } else {
                    // Soft Lock: Show overlay briefly, then automatically close the app
                    saveOverlayDataAndRequestOverlay(appName, usedMinutes, limitMinutes, packageName)
                    handler.postDelayed({
                        closeAppAndGoHome(packageName)
                    }, 2500) // Slightly more time to see the overlay
                }
            }
        }
    }

    /**
     * Checks if an app is a system app that should NEVER be blocked.
     */
    private fun isSystemApp(packageName: String): Boolean {
        // Essential system packages that must always be accessible
        val essentialPackages = setOf(
            "com.android.settings",
            "com.android.dialer",
            "com.android.mms",
            "com.android.launcher",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.google.android.packageinstaller",
            "com.android.packageinstaller",
            "com.google.android.permissioncontroller",
            "com.android.permissioncontroller",
            "com.android.systemui",
            "com.google.android.gsf",
            "com.google.android.gms"
        )
        
        if (essentialPackages.contains(packageName)) return true
        
        // Also allow the default launcher
        try {
            val intent = Intent(Intent.ACTION_MAIN)
            intent.addCategory(Intent.CATEGORY_HOME)
            val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            if (resolveInfo?.activityInfo?.packageName == packageName) return true
        } catch (e: Exception) {}

        return false
    }

    /**
     * Checks if an app is currently snoozed by a parent.
     */
    private fun isSnoozed(packageName: String): Boolean {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val snoozeUntil = prefs.getLong("${PFX}snooze_until_$packageName", 0L)
        return System.currentTimeMillis() < snoozeUntil
    }

    /**
     * Checks if overlay was recently shown for an app (within last 5 minutes).
     */
    private fun wasRecentlyShown(packageName: String): Boolean {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val lastShown = prefs.getLong("${PFX}last_shown_$packageName", 0L)
        return (System.currentTimeMillis() - lastShown) < 5 * 60 * 1000L // 5 minutes
    }

    /**
     * Marks overlay as shown for an app with current timestamp.
     */
    private fun markOverlayShown(packageName: String) {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putLong("${PFX}last_shown_$packageName", System.currentTimeMillis())
            .apply()

        // Also update the set for backward compatibility if needed
        val shownSet = prefs.getStringSet("${PFX}$_PREF_OVERLAY_SHOWN", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        shownSet.add(packageName)
        prefs.edit()
            .putStringSet("${PFX}$_PREF_OVERLAY_SHOWN", shownSet)
            .apply()
    }

    /**
     * Clears overlay shown status for a specific app/key.
     */
    private fun clearOverlayShown(key: String) {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val shownSet = prefs.getStringSet("${PFX}$_PREF_OVERLAY_SHOWN", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        shownSet.remove(key)
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
        private const val _PREF_ACTIVE_SOCIAL_LIMIT = "active_social_media_limit_minutes"
        private const val _PREF_ACTIVE_GAMES_LIMIT = "active_games_limit_minutes"
        private const val _PREF_ACTIVE_CHILD = "active_child_id"
        private const val _PREF_ACTIVE_PRAYER_ENABLED = "active_prayer_lock_enabled"
        private const val _PREF_ACTIVE_SLEEP_ENABLED = "active_sleep_lock_enabled"
        private const val _PREF_ACTIVE_SLEEP_START = "active_sleep_lock_start_minutes"
        private const val _PREF_ACTIVE_SLEEP_END = "active_sleep_lock_end_minutes"
        private const val _PREF_APP_CATEGORIES = "parental_control_app_categories"
        private const val _PREF_CHILD_USAGE_DAY = "child_category_usage_day"
        private const val _PREF_CHILD_CATEGORY_USAGE = "child_category_usage"
        private const val _PREF_CHILD_LAST_TOTALS = "child_category_last_device_totals"
        private const val _PREF_SCHEDULE = "parental_control_schedule"
        private const val _PREF_OVERLAY_SHOWN = "overlay_shown_sessions"

        // Same package map as in core/constants/social_media_apps.dart
        private val SOCIAL_APPS = mapOf(
            "com.facebook.katana" to "Facebook",
            "com.instagram.android" to "Instagram",
            "com.instagram.barcelona" to "Threads",
            "com.twitter.android" to "Twitter",
            "com.snapchat.android" to "Snapchat",
            "com.zhiliaoapp.musically" to "TikTok",
            "com.ss.android.ugc.trill" to "TikTok",
            "com.reddit.frontpage" to "Reddit",
            "com.discord" to "Discord",
            "com.pinterest" to "Pinterest",
            "com.tumblr" to "Tumblr",
            "com.google.android.youtube" to "YouTube"
        )
        private val GAMES_APPS = mapOf(
            "com.roblox.client" to "Roblox",
            "com.mojang.minecraftpe" to "Minecraft",
            "com.epicgames.fortnite" to "Fortnite",
            "com.tencent.ig" to "PUBG Mobile",
            "com.dts.freefireth" to "Free Fire",
            "com.mobile.legends" to "Mobile Legends",
            "com.supercell.clashofclans" to "Clash of Clans",
            "com.supercell.clashroyale" to "Clash Royale",
            "com.supercell.brawlstars" to "Brawl Stars",
            "com.king.candycrushsaga" to "Candy Crush Saga",
            "com.kiloo.subwaysurf" to "Subway Surfers"
        )
    }
}
