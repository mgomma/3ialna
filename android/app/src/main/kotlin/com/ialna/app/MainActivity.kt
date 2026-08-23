package com.ialna.app

import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.content.ActivityNotFoundException
import android.app.ActivityManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import android.provider.Settings
import android.net.Uri
import android.net.VpnService
import com.ialna.app.network.SafeContentVpnService
import com.ialna.app.voice.VoicePlaybackScheduler
import android.widget.Toast
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ialna.app.usage.MonitorForegroundService
import com.ialna.app.kiosk.KioskModeHelper
import com.ialna.app.apps.AppListHelper
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.util.Base64
import android.util.Log
import java.io.ByteArrayOutputStream
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    private val serviceChannel = "social_limiter/service"
    private val kioskChannel = "parental_control/kiosk"
    private val appChannel = "parental_control/apps"
    private val blockingChannel = "app_blocking/block"
    private val accessibilityChannel = "app_blocking/accessibility"
    private val safeContentVpnChannel = "safe_content/vpn"
    private val parentVoiceChannel = "parent_voice_notifications"
    private val childChannel = "parental_control/children"
    private val vpnPermissionRequestCode = 1002
    private val deviceAdminRequestCode = 1001
    private var pendingChildShortcutId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Handle initial intent for hard lock
        intent?.let { handleLockIntent(it) }
        pendingChildShortcutId = intent?.getStringExtra(EXTRA_CHILD_SHORTCUT_ID)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            childChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateLauncherShortcuts" -> {
                    @Suppress("UNCHECKED_CAST")
                    val children = call.argument<List<Map<String, String>>>("children") ?: emptyList()
                    updateChildShortcuts(children)
                    result.success(null)
                }
                "consumeInitialChildShortcut" -> {
                    result.success(pendingChildShortcutId)
                    pendingChildShortcutId = null
                }
                else -> result.notImplemented()
            }
        }

        // Service channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            serviceChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoringService" -> {
                    startMonitoringService()
                    result.success(null)
                }
                "stopMonitoringService" -> {
                    stopMonitoringService()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Kiosk mode channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            kioskChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceOwner" -> {
                    result.success(KioskModeHelper.isDeviceOwner(this))
                }
                "isDeviceAdminEnabled" -> {
                    result.success(KioskModeHelper.isDeviceAdminEnabled(this))
                }
                "requestDeviceAdmin" -> {
                    KioskModeHelper.requestDeviceAdmin(this, deviceAdminRequestCode)
                    result.success(null)
                }
                "startKioskMode" -> {
                    val success = KioskModeHelper.startKioskMode(this)
                    result.success(success)
                }
                "stopKioskMode" -> {
                    val success = KioskModeHelper.stopKioskMode(this)
                    result.success(success)
                }
                "isKioskModeActive" -> {
                    result.success(KioskModeHelper.isKioskModeActive(this))
                }
                "setLockTaskPackages" -> {
                    val success = KioskModeHelper.setLockTaskPackages(this)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }

        // App list channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            appChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAllInstalledApps" -> {
                    try {
                        val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: true
                        val apps = AppListHelper.getAllInstalledApps(this, includeSystemApps)
                        val appList = apps.map { appInfo ->
                            val iconBase64 = appInfo.icon?.let { drawable ->
                                convertDrawableToBase64(drawable)
                            }
                            mapOf(
                                "packageName" to appInfo.packageName,
                                "appName" to appInfo.appName,
                                "icon" to iconBase64,
                                "isSystemApp" to appInfo.isSystemApp,
                                "isEnabled" to appInfo.isEnabled,
                                "installTime" to appInfo.installTime,
                                "updateTime" to appInfo.updateTime
                            )
                        }
                        result.success(appList)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get installed apps: ${e.message}", null)
                    }
                }
                "getAppInfo" -> {
                    try {
                        val packageName = call.argument<String>("packageName")
                        if (packageName == null) {
                            result.error("ERROR", "Package name is required", null)
                            return@setMethodCallHandler
                        }
                        val appInfo = AppListHelper.getAppInfo(this, packageName)
                        if (appInfo != null) {
                            val iconBase64 = appInfo.icon?.let { convertDrawableToBase64(it) }
                            result.success(mapOf(
                                "packageName" to appInfo.packageName,
                                "appName" to appInfo.appName,
                                "icon" to iconBase64,
                                "isSystemApp" to appInfo.isSystemApp,
                                "isEnabled" to appInfo.isEnabled,
                                "installTime" to appInfo.installTime,
                                "updateTime" to appInfo.updateTime
                            ))
                        } else {
                            result.error("ERROR", "App not found", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get app info: ${e.message}", null)
                    }
                }
                "isAppInstalled" -> {
                    try {
                        val packageName = call.argument<String>("packageName")
                        if (packageName == null) {
                            result.error("ERROR", "Package name is required", null)
                            return@setMethodCallHandler
                        }
                        result.success(AppListHelper.isAppInstalled(this, packageName))
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check app: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // App blocking channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            blockingChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "blockApp" -> {
                    try {
                        val packageName = call.argument<String>("packageName")
                        val durationMinutes = call.argument<Int>("durationMinutes")
                        if (packageName == null) {
                            result.error("ERROR", "Package name is required", null)
                            return@setMethodCallHandler
                        }
                        blockApp(packageName, durationMinutes ?: 30)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to block app: ${e.message}", null)
                    }
                }
                "closeAppAndGoHome" -> {
                    try {
                        closeAppAndGoHome()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to close app: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Safe-content VPN channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            safeContentVpnChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isVpnPermissionGranted" -> {
                    result.success(VpnService.prepare(this) == null)
                }
                "requestVpnPermission" -> {
                    val permissionIntent = VpnService.prepare(this)
                    if (permissionIntent == null) {
                        result.success(true)
                    } else {
                        startActivityForResult(permissionIntent, vpnPermissionRequestCode)
                        result.success(false)
                    }
                }
                "startVpn" -> {
                    if (VpnService.prepare(this) != null) {
                        result.error("PERMISSION_REQUIRED", "VPN permission is required", null)
                    } else {
                        val serviceIntent = Intent(this, SafeContentVpnService::class.java)
                        ContextCompat.startForegroundService(this, serviceIntent)
                        result.success(true)
                    }
                }
                "stopVpn" -> {
                    stopService(Intent(this, SafeContentVpnService::class.java))
                    result.success(true)
                }
                "isVpnRunning" -> {
                    val preferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    result.success(preferences.getBoolean(SafeContentVpnService.PREF_RUNNING, false))
                }
                else -> result.notImplemented()
            }
        }

        // Native background parent-voice playback channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            parentVoiceChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleVoicePlayback" -> {
                    val path = call.argument<String>("path")
                    val atMillis = call.argument<Number>("atMillis")?.toLong()
                    if (path.isNullOrBlank() || atMillis == null) {
                        result.error("INVALID_ARGUMENT", "A voice path and playback time are required", null)
                    } else {
                        result.success(VoicePlaybackScheduler.schedule(this, path, atMillis))
                    }
                }
                "cancelVoicePlayback" -> {
                    VoicePlaybackScheduler.cancel(this)
                    result.success(true)
                }
                "isVoicePlaybackScheduled" -> {
                    result.success(VoicePlaybackScheduler.isScheduled(this))
                }
                "requestExactAlarmPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")))
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // AccessibilityService helper channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            accessibilityChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    try {
                        val isEnabled = isAccessibilityServiceEnabled()
                        result.success(isEnabled)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check accessibility: ${e.message}", null)
                    }
                }
                "openAccessibilitySettings" -> {
                    try {
                        openAccessibilitySettings()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open settings: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLockIntent(intent)
        val childId = intent.getStringExtra(EXTRA_CHILD_SHORTCUT_ID)
        if (!childId.isNullOrBlank()) {
            pendingChildShortcutId = childId
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, childChannel).invokeMethod("onChildShortcut", childId)
            }
        }
    }

    private fun updateChildShortcuts(children: List<Map<String, String>>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        val manager = getSystemService(ShortcutManager::class.java) ?: return
        if (children.size < 2) {
            manager.removeAllDynamicShortcuts()
            return
        }
        val shortcuts = children.take(4).mapIndexedNotNull { index, child ->
            val id = child["id"] ?: return@mapIndexedNotNull null
            val name = child["name"]?.takeIf { it.isNotBlank() } ?: "Child ${index + 1}"
            val shortcutIntent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(EXTRA_CHILD_SHORTCUT_ID, id)
            }
            ShortcutInfo.Builder(this, "child_$id")
                .setShortLabel(name.take(25))
                .setLongLabel("Use $name in 3ialna")
                .setIcon(Icon.createWithResource(this, R.mipmap.ic_launcher))
                .setIntent(shortcutIntent)
                .build()
        }
        manager.dynamicShortcuts = shortcuts
    }

    private fun handleLockIntent(intent: Intent) {
        if (intent.getBooleanExtra("EXTRA_HARD_LOCK", false)) {
            Log.i(TAG, "Received EXTRA_HARD_LOCK, starting Kiosk Mode")
            KioskModeHelper.startKioskMode(this)
            
            // Notify Flutter side that device is locked
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, kioskChannel).invokeMethod("onDeviceLocked", null)
            }
        }
    }

    /**
     * Checks if AccessibilityService is enabled.
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        try {
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: ""
            
            val serviceName = ComponentName(
                this,
                com.ialna.app.blocking.AppBlockingAccessibilityService::class.java
            ).flattenToString()
            
            val isEnabled = enabledServices.contains(serviceName)
            Log.d(TAG, "AccessibilityService enabled: $isEnabled (looking for: $serviceName)")
            return isEnabled
        } catch (e: Exception) {
            Log.e(TAG, "Error checking AccessibilityService status", e)
            return false
        }
    }

    /**
     * Opens Accessibility settings to enable the service.
     */
    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
            Log.d(TAG, "Opened Accessibility settings successfully")
        } catch (e: ActivityNotFoundException) {
            Log.e(TAG, "Accessibility settings activity not found", e)
            // Fallback: open general settings
            try {
                val intent = Intent(Settings.ACTION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                startActivity(intent)
                Log.d(TAG, "Opened general Settings as fallback")
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to open Settings", e2)
                // Show toast to user
                Toast.makeText(
                    this,
                    "Please enable Accessibility Service manually in Settings",
                    Toast.LENGTH_LONG
                ).show()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open Accessibility settings", e)
            // Show toast to user
            Toast.makeText(
                this,
                "Please enable Accessibility Service manually in Settings",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    private fun blockApp(packageName: String, durationMinutes: Int) {
        Log.d(TAG, "Blocking app: $packageName for $durationMinutes minutes")
        
        // Save to SharedPreferences for AccessibilityService to read
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val blockedAppsJson = prefs.getString("${PFX}blocked_apps_with_timestamps", "{}") ?: "{}"
        val blockedApps = parseBlockedAppsJson(blockedAppsJson)
        
        // Add new block
        blockedApps[packageName] = System.currentTimeMillis()
        
        prefs.edit()
            .putString("${PFX}blocked_apps_with_timestamps", toBlockedAppsJson(blockedApps))
            .putLong("${PFX}block_duration_minutes", durationMinutes.toLong())
            .apply()
        
        Log.d(TAG, "Block saved. Now closing app: $packageName")
        
        // Force close the app immediately
        forceCloseApp(packageName)
        
        // Then go home
        closeAppAndGoHome()
    }

    private fun parseBlockedAppsJson(json: String): MutableMap<String, Long> {
        val blockedApps = mutableMapOf<String, Long>()
        try {
            val obj = JSONObject(json)
            val keys = obj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val value = obj.opt(key)
                val timestamp = when (value) {
                    is Number -> value.toLong()
                    is String -> value.toLongOrNull()
                    else -> null
                }
                if (timestamp != null) {
                    blockedApps[key] = timestamp
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing blocked apps JSON", e)
        }
        return blockedApps
    }

    private fun toBlockedAppsJson(blockedApps: Map<String, Long>): String {
        val obj = JSONObject()
        blockedApps.forEach { (pkg, timestamp) ->
            obj.put(pkg, timestamp)
        }
        return obj.toString()
    }

    private fun forceCloseApp(packageName: String) {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            
            // Kill background processes for the app
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                activityManager.killBackgroundProcesses(packageName)
                Log.d(TAG, "Killed background processes for: $packageName")
            }
            
            // Also try to get running app processes and kill them
            try {
                val runningApps = activityManager.runningAppProcesses
                runningApps?.forEach { processInfo ->
                    if (processInfo.pkgList.contains(packageName)) {
                        android.os.Process.killProcess(processInfo.pid)
                        Log.d(TAG, "Killed process ${processInfo.pid} for: $packageName")
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not kill processes directly", e)
            }
            
            Log.i(TAG, "Attempted to force close app: $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "Error force closing app: $packageName", e)
        }
    }

    private fun closeAppAndGoHome() {
        try {
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            startActivity(homeIntent)
            Log.d(TAG, "Sent home intent")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending home intent", e)
        }
    }

    private fun startMonitoringService() {
        val intent = Intent(this, MonitorForegroundService::class.java)
        ContextCompat.startForegroundService(this, intent)
    }

    private fun stopMonitoringService() {
        val intent = Intent(this, MonitorForegroundService::class.java)
        stopService(intent)
    }

    private fun convertDrawableToBase64(drawable: android.graphics.drawable.Drawable): String? {
        return try {
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                // Validate dimensions before creating bitmap
                val width = drawable.intrinsicWidth
                val height = drawable.intrinsicHeight
                
                // Skip if invalid dimensions
                if (width <= 0 || height <= 0) {
                    Log.w(TAG, "Invalid drawable dimensions: ${width}x${height}")
                    return null
                }
                
                // Use reasonable max size to avoid memory issues
                val maxSize = 256
                val scaledWidth = if (width > maxSize) maxSize else width
                val scaledHeight = if (height > maxSize) maxSize else height
                
                val bitmap = Bitmap.createBitmap(
                    scaledWidth,
                    scaledHeight,
                    Bitmap.Config.ARGB_8888
                )
                val canvas = android.graphics.Canvas(bitmap)
                drawable.setBounds(0, 0, scaledWidth, scaledHeight)
                drawable.draw(canvas)
                bitmap
            }
            
            // Validate bitmap before encoding
            if (bitmap == null || bitmap.width <= 0 || bitmap.height <= 0) {
                Log.w(TAG, "Invalid bitmap created")
                return null
            }
            
            val outputStream = ByteArrayOutputStream()
            val success = bitmap.compress(Bitmap.CompressFormat.PNG, 90, outputStream)
            if (!success) {
                Log.w(TAG, "Failed to compress bitmap")
                return null
            }
            
            val byteArray = outputStream.toByteArray()
            if (byteArray.isEmpty()) {
                Log.w(TAG, "Empty byte array from bitmap compression")
                return null
            }
            
            Base64.encodeToString(byteArray, Base64.DEFAULT)
        } catch (e: Exception) {
            Log.w(TAG, "Error converting drawable to Base64: ${e.message}", e)
            null
        }
    }


    companion object {
        private const val TAG = "MainActivity"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val PFX = "flutter."
        private const val EXTRA_CHILD_SHORTCUT_ID = "com.ialna.app.EXTRA_CHILD_SHORTCUT_ID"
    }
}
