package com.example.mu_super_app.apps

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.drawable.Drawable
import android.util.Log
import java.io.File

/**
 * Helper class for querying installed applications on the device.
 * 
 * This provides methods to get a list of all installed apps with their
 * package names, labels, icons, and other metadata.
 */
object AppListHelper {

    private const val TAG = "AppListHelper"

    /**
     * Data class representing an installed app.
     */
    data class AppInfo(
        val packageName: String,
        val appName: String,
        val icon: Drawable?,
        val isSystemApp: Boolean,
        val isEnabled: Boolean,
        val installTime: Long,
        val updateTime: Long
    )

    /**
     * Gets a list of all installed applications.
     * 
     * @param includeSystemApps Whether to include system apps in the result
     * @return List of AppInfo objects
     */
    fun getAllInstalledApps(
        context: Context,
        includeSystemApps: Boolean = true
    ): List<AppInfo> {
        val packageManager = context.packageManager
        val apps = mutableListOf<AppInfo>()

        try {
            val installedPackages = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                packageManager.getInstalledPackages(
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstalledPackages(0)
            }

            for (packageInfo in installedPackages) {
                try {
                    val appInfo = packageInfo.applicationInfo ?: continue
                    
                    // Filter system apps if requested
                    if (!includeSystemApps && (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                        continue
                    }

                    // Skip this app itself
                    if (appInfo.packageName == context.packageName) {
                        continue
                    }

                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val icon = try {
                        packageManager.getApplicationIcon(appInfo.packageName)
                    } catch (e: Exception) {
                        null
                    }

                    val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                    val isEnabled = appInfo.enabled

                    val installTime = try {
                        appInfo.sourceDir?.let { File(it).lastModified() } ?: 0L
                    } catch (e: Exception) {
                        0L
                    }

                    val updateTime = packageInfo.lastUpdateTime

                    apps.add(
                        AppInfo(
                            packageName = appInfo.packageName,
                            appName = appName,
                            icon = icon,
                            isSystemApp = isSystemApp,
                            isEnabled = isEnabled,
                            installTime = installTime,
                            updateTime = updateTime
                        )
                    )
                } catch (e: Exception) {
                    Log.w(TAG, "Error getting info for package: ${packageInfo.packageName}", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting installed packages", e)
        }

        // Sort by app name
        return apps.sortedBy { it.appName }
    }

    /**
     * Gets app info for a specific package name.
     */
    fun getAppInfo(context: Context, packageName: String): AppInfo? {
        return try {
            val packageManager = context.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            
            val appName = packageManager.getApplicationLabel(appInfo).toString()
            val icon = try {
                packageManager.getApplicationIcon(packageName)
            } catch (e: Exception) {
                null
            }

            val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val isEnabled = appInfo.enabled

            val installTime = try {
                appInfo.sourceDir?.let { File(it).lastModified() } ?: 0L
            } catch (e: Exception) {
                0L
            }

            AppInfo(
                packageName = packageName,
                appName = appName,
                icon = icon,
                isSystemApp = isSystemApp,
                isEnabled = isEnabled,
                installTime = installTime,
                updateTime = 0L
            )
        } catch (e: Exception) {
            Log.w(TAG, "Error getting app info for package: $packageName", e)
            null
        }
    }

    /**
     * Checks if an app is installed.
     */
    fun isAppInstalled(context: Context, packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        } catch (e: Exception) {
            Log.w(TAG, "Error checking if app is installed: $packageName", e)
            false
        }
    }
}

