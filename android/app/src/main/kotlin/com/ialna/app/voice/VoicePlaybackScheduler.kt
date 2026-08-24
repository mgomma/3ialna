package com.ialna.app.voice

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

    private const val PRAYER_PREFS = "3ialna_prayer_voice_playback"
    private const val PRAYER_KEY_PATH = "path"
    private const val PRAYER_KEY_TIMES = "times"
    private const val PRAYER_REQUEST_CODE_BASE = 3300
    private const val MAX_PRAYER_ALARMS = 35

    fun schedule(context: Context, path: String, atMillis: Long): Boolean {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        if (!canScheduleExactAlarms(alarmManager)) return false
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_PATH, path)
            .putLong(KEY_AT, atMillis)
            .apply()
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            atMillis,
            scheduledPendingIntent(context, REQUEST_CODE, path),
        )
        return true
    }

    fun schedulePrayer(context: Context, path: String, atMillisList: List<Long>): Boolean {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val times = atMillisList
            .filter { it > System.currentTimeMillis() }
            .distinct()
            .sorted()
            .take(MAX_PRAYER_ALARMS)
        if (times.isEmpty()) return false

        cancelPrayer(context)
        context.getSharedPreferences(PRAYER_PREFS, Context.MODE_PRIVATE).edit()
            .putString(PRAYER_KEY_PATH, path)
            .putStringSet(PRAYER_KEY_TIMES, times.map { it.toString() }.toSet())
            .apply()
        if (!canScheduleExactAlarms(alarmManager)) return false
        times.forEachIndexed { index, atMillis ->
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                atMillis,
                scheduledPendingIntent(context, PRAYER_REQUEST_CODE_BASE + index, path),
            )
        }
        return true
    }

    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        existingPendingIntent(context, REQUEST_CODE)?.let(alarmManager::cancel)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }

    fun cancelPrayer(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        repeat(MAX_PRAYER_ALARMS) { index ->
            existingPendingIntent(context, PRAYER_REQUEST_CODE_BASE + index)
                ?.let(alarmManager::cancel)
        }
        context.getSharedPreferences(PRAYER_PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }

    fun isScheduled(context: Context): Boolean {
        val at = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong(KEY_AT, 0L)
        return at > System.currentTimeMillis()
    }

    fun reschedule(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val path = prefs.getString(KEY_PATH, null) ?: return
        val at = prefs.getLong(KEY_AT, 0L)
        if (at > System.currentTimeMillis()) schedule(context, path, at)
    }

    fun reschedulePrayer(context: Context) {
        val prefs = context.getSharedPreferences(PRAYER_PREFS, Context.MODE_PRIVATE)
        val path = prefs.getString(PRAYER_KEY_PATH, null) ?: return
        val times = prefs.getStringSet(PRAYER_KEY_TIMES, emptySet())
            .orEmpty()
            .mapNotNull { it.toLongOrNull() }
            .filter { it > System.currentTimeMillis() }
        if (times.isNotEmpty()) schedulePrayer(context, path, times)
    }

    fun canScheduleExactAlarms(context: Context): Boolean =
        canScheduleExactAlarms(context.getSystemService(AlarmManager::class.java))

    private fun canScheduleExactAlarms(alarmManager: AlarmManager): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()

    private fun scheduledPendingIntent(
        context: Context,
        requestCode: Int,
        path: String,
    ): PendingIntent {
        val intent = Intent(context, VoicePlaybackReceiver::class.java)
            .setAction(VoicePlaybackReceiver.ACTION_PLAY)
            .putExtra(VoicePlaybackService.EXTRA_PATH, path)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun existingPendingIntent(context: Context, requestCode: Int): PendingIntent? {
        val intent = Intent(context, VoicePlaybackReceiver::class.java)
            .setAction(VoicePlaybackReceiver.ACTION_PLAY)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
