package com.example.mu_super_app.voice

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object VoicePlaybackScheduler {
    private const val PREFS = "3ialna_voice_playback"
    private const val KEY_PATH = "path"
    private const val KEY_AT = "at"
    private const val REQUEST_CODE = 3202

    fun schedule(context: Context, path: String, atMillis: Long): Boolean {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            return false
        }
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val currentAt = prefs.getLong(KEY_AT, 0L)
        if (currentAt > System.currentTimeMillis() && currentAt <= atMillis) return true
        prefs.edit().putString(KEY_PATH, path).putLong(KEY_AT, atMillis).apply()
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            atMillis,
            pendingIntent(context),
        )
        return true
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(pendingIntent(context))
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }

    fun isScheduled(context: Context): Boolean {
        val at = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong(KEY_AT, 0L)
        return at > System.currentTimeMillis()
    }

    fun reschedule(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val path = prefs.getString(KEY_PATH, null) ?: return
        val at = prefs.getLong(KEY_AT, 0L)
        if (at > System.currentTimeMillis()) schedule(context, path, at)
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, VoicePlaybackReceiver::class.java)
            .setAction(VoicePlaybackReceiver.ACTION_PLAY)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
