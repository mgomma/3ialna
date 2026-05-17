package com.example.mu_super_app.blocking

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast
import android.os.Handler
import android.os.Looper
import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/**
 * AccessibilityService that monitors app launches and blocks apps that are in the blocked list.
 * 
 * This service intercepts app launches and immediately closes blocked apps,
 * returning the user to the home screen.
 */
class AppBlockingAccessibilityService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private val prefs: SharedPreferences by lazy {
        getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        setServiceInfo(info)
        Log.d(TAG, "AppBlockingAccessibilityService connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            if (packageName == null || packageName.isEmpty()) return

            // Don't block this app itself
            if (packageName == this.packageName) return

            // Don't block system apps
            if (isSystemApp(packageName)) return

            // Check if app is blocked
            if (isAppBlocked(packageName)) {
                Log.i(TAG, "Blocking app: $packageName")
                blockApp(packageName)
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "AccessibilityService interrupted")
    }

    /**
     * Checks if an app is currently blocked.
     */
    private fun isAppBlocked(packageName: String): Boolean {
        val blockedAppsJson = prefs.getString("${PFX}blocked_apps_with_timestamps", null)
        if (blockedAppsJson == null || blockedAppsJson == "{}") return false

        try {
            // Parse blocked apps JSON: {"packageName": timestamp, ...}
            val blockedApps = parseBlockedApps(blockedAppsJson)
            val blockTimestamp = blockedApps[packageName] ?: return false

            val now = System.currentTimeMillis()
            val blockDuration = prefs.getInt("${PFX}block_duration_minutes", 30).toLong() * 60 * 1000 // Convert to milliseconds

            // Check if block has expired
            if (now - blockTimestamp > blockDuration) {
                // Block expired, remove it
                removeBlockedApp(packageName)
                return false
            }

            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error checking blocked apps", e)
            return false
        }
    }

    /**
     * Parses blocked apps JSON string.
     */
    private fun parseBlockedApps(json: String): Map<String, Long> {
        val blockedApps = mutableMapOf<String, Long>()
        try {
            val obj = JSONObject(json)
            val keys = obj.keys()
            while (keys.hasNext()) {
                val pkg = keys.next()
                val value = obj.opt(pkg)
                val timestamp = when (value) {
                    is Number -> value.toLong()
                    is String -> value.toLongOrNull()
                    else -> null
                }
                if (timestamp != null) {
                    blockedApps[pkg] = timestamp
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing blocked apps", e)
        }
        return blockedApps
    }

    /**
     * Removes an app from the blocked list.
     */
    private fun removeBlockedApp(packageName: String) {
        try {
            val blockedAppsJson = prefs.getString("${PFX}blocked_apps_with_timestamps", "{}") ?: "{}"
            val blockedApps = parseBlockedApps(blockedAppsJson).toMutableMap()
            blockedApps.remove(packageName)
            
            // Save back to preferences
            val newJson = JSONObject().apply {
                blockedApps.forEach { (pkg, timestamp) ->
                    put(pkg, timestamp)
                }
            }.toString()
            prefs.edit()
                .putString("${PFX}blocked_apps_with_timestamps", newJson)
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error removing blocked app", e)
        }
    }

    /**
     * Gets remaining block time in minutes.
     */
    private fun getRemainingBlockTime(packageName: String): Long {
        val blockedAppsJson = prefs.getString("${PFX}blocked_apps_with_timestamps", null) ?: return 0
        val blockedApps = parseBlockedApps(blockedAppsJson)
        val blockTimestamp = blockedApps[packageName] ?: return 0

        val now = System.currentTimeMillis()
        val blockDuration = prefs.getInt("${PFX}block_duration_minutes", 30).toLong() * 60 * 1000
        val elapsed = now - blockTimestamp
        val remaining = blockDuration - elapsed

        return if (remaining > 0) {
            (remaining / 1000 / 60) + 1 // Convert to minutes, round up
        } else {
            0
        }
    }

    /**
     * Gets app name from package name.
     */
    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
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
     * Blocks an app by closing it and returning to home.
     */
    private fun blockApp(packageName: String) {
        try {
            // Return to home screen
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            startActivity(homeIntent)

            // Show toast notification
            val appName = getAppName(packageName)
            val remainingMinutes = getRemainingBlockTime(packageName)
            
            handler.post {
                Toast.makeText(
                    this,
                    "$appName is blocked. Take a break! Available in $remainingMinutes minute(s)",
                    Toast.LENGTH_LONG
                ).show()
            }

            Log.i(TAG, "Blocked and closed app: $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "Error blocking app: $packageName", e)
        }
    }

    companion object {
        private const val TAG = "AppBlockingService"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val PFX = "flutter."
    }
}

