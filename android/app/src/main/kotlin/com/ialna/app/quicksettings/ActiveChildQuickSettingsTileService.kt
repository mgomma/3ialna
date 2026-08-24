package com.ialna.app.quicksettings

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.ialna.app.MainActivity

/**
 * A parent-controlled Android Quick Settings entry point. Android requires the
 * device owner to add the tile; this service never exposes a child name in the
 * notification shade. Tapping it opens 3ialna's active-child selector.
 */
class ActiveChildQuickSettingsTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    override fun onClick() {
        super.onClick()
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_OPEN_CHILD_SELECTOR, true)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                771,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun updateTile() {
        qsTile?.apply {
            label = "3ialna"
            contentDescription = "3ialna active child settings"
            state = Tile.STATE_ACTIVE
            updateTile()
        }
    }

    companion object {
        fun refresh(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
            TileService.requestListeningState(
                context,
                ComponentName(context, ActiveChildQuickSettingsTileService::class.java),
            )
        }
    }
}
