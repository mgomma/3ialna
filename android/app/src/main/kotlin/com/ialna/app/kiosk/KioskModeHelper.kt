package com.ialna.app.kiosk

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.ialna.app.DeviceAdminReceiver

/**
 * Helper class for managing Kiosk Mode (Lock Task Mode) functionality.
 * 
 * Kiosk mode prevents users from accessing the home button, recent apps,
 * and other system UI elements, effectively locking them into the app.
 */
object KioskModeHelper {

    private const val TAG = "KioskModeHelper"

    /**
     * Component name for the device admin receiver.
     */
    private fun getAdminComponentName(context: Context): ComponentName {
        return ComponentName(context, DeviceAdminReceiver::class.java)
    }

    /**
     * Checks if the app is a device owner (required for lock task mode).
     */
    fun isDeviceOwner(context: Context): Boolean {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        return dpm.isDeviceOwnerApp(context.packageName)
    }

    /**
     * Checks if device admin is enabled.
     */
    fun isDeviceAdminEnabled(context: Context): Boolean {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        return dpm.isAdminActive(getAdminComponentName(context))
    }

    /**
     * Requests device admin permission from the user.
     */
    fun requestDeviceAdmin(activity: Activity, requestCode: Int) {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(
            DevicePolicyManager.EXTRA_DEVICE_ADMIN,
            getAdminComponentName(activity)
        )
        intent.putExtra(
            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "This app needs device admin permission to enable kiosk mode for parental controls."
        )
        activity.startActivityForResult(intent, requestCode)
    }

    /**
     * Enables lock task mode (kiosk mode) for the current activity.
     * 
     * Note: This requires the app to be a device owner or have device admin
     * permissions with lock-task policy enabled.
     */
    fun startKioskMode(activity: Activity): Boolean {
        return try {
            val dpm = activity.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            
            if (dpm.isDeviceOwnerApp(activity.packageName)) {
                // Device owner mode - can set lock task packages
                val packages = arrayOf(activity.packageName)
                dpm.setLockTaskPackages(getAdminComponentName(activity), packages)
                activity.startLockTask()
                Log.d(TAG, "Kiosk mode started (device owner)")
                true
            } else if (dpm.isAdminActive(getAdminComponentName(activity))) {
                // Device admin mode - can start lock task
                activity.startLockTask()
                Log.d(TAG, "Kiosk mode started (device admin)")
                true
            } else {
                Log.w(TAG, "Cannot start kiosk mode: device admin not enabled")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start kiosk mode", e)
            false
        }
    }

    /**
     * Disables lock task mode (kiosk mode).
     */
    fun stopKioskMode(activity: Activity): Boolean {
        return try {
            activity.stopLockTask()
            Log.d(TAG, "Kiosk mode stopped")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop kiosk mode", e)
            false
        }
    }

    /**
     * Checks if lock task mode is currently active.
     */
    fun isKioskModeActive(activity: Activity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                // Use reflection to call isInLockTaskMode() method on Activity
                val method = Activity::class.java.getMethod("isInLockTaskMode")
                method.invoke(activity) as? Boolean ?: false
            } catch (e: NoSuchMethodException) {
                Log.w(TAG, "isInLockTaskMode method not found", e)
                false
            } catch (e: Exception) {
                Log.w(TAG, "Error checking lock task mode", e)
                false
            }
        } else {
            false
        }
    }

    /**
     * Sets the app as a lock task package (device owner only).
     */
    fun setLockTaskPackages(context: Context): Boolean {
        return try {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            if (dpm.isDeviceOwnerApp(context.packageName)) {
                val packages = arrayOf(context.packageName)
                dpm.setLockTaskPackages(getAdminComponentName(context), packages)
                Log.d(TAG, "Lock task packages set")
                true
            } else {
                Log.w(TAG, "Cannot set lock task packages: not device owner")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set lock task packages", e)
            false
        }
    }
}
