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

    private const val PRAYER_AZAN_PREFS = "3ialna_prayer_azan_playback"
    private const val PRAYER_AZAN_KEY_PATH = "path"
    private const val PRAYER_AZAN_KEY_TIMES = "times"
    private const val PRAYER_AZAN_REQUEST_CODE_BASE = 3400

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
        return schedulePrayerGroup(
            context,
            path,
            atMillisList,
            PRAYER_PREFS,
            PRAYER_KEY_PATH,
            PRAYER_KEY_TIMES,
            PRAYER_REQUEST_CODE_BASE,
        )
    }

    fun schedulePrayerAzan(context: Context, path: String, atMillisList: List<Long>): Boolean {
        return schedulePrayerGroup(
            context,
            path,
            atMillisList,
            PRAYER_AZAN_PREFS,
            PRAYER_AZAN_KEY_PATH,
            PRAYER_AZAN_KEY_TIMES,
            PRAYER_AZAN_REQUEST_CODE_BASE,
        )
    }

    private fun schedulePrayerGroup(
        context: Context,
        path: String,
        atMillisList: List<Long>,
        preferencesName: String,
        pathKey: String,
        timesKey: String,
        requestCodeBase: Int,
    ): Boolean {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val times = atMillisList
            .filter { it > System.currentTimeMillis() }
            .distinct()
            .sorted()
            .take(MAX_PRAYER_ALARMS)
        if (times.isEmpty()) return false

        cancelPrayerGroup(context, preferencesName, requestCodeBase)
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit()
            .putString(pathKey, path)
            .putStringSet(timesKey, times.map { it.toString() }.toSet())
            .apply()
        if (!canScheduleExactAlarms(alarmManager)) return false
        times.forEachIndexed { index, atMillis ->
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                atMillis,
                scheduledPendingIntent(context, requestCodeBase + index, path),
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
        cancelPrayerGroup(context, PRAYER_PREFS, PRAYER_REQUEST_CODE_BASE)
    }

    fun cancelPrayerAzan(context: Context) {
        cancelPrayerGroup(context, PRAYER_AZAN_PREFS, PRAYER_AZAN_REQUEST_CODE_BASE)
    }

    private fun cancelPrayerGroup(
        context: Context,
        preferencesName: String,
        requestCodeBase: Int,
    ) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        repeat(MAX_PRAYER_ALARMS) { index ->
            existingPendingIntent(context, requestCodeBase + index)
                ?.let(alarmManager::cancel)
        }
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit().clear().apply()
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
        reschedulePrayerGroup(
            context,
            PRAYER_PREFS,
            PRAYER_KEY_PATH,
            PRAYER_KEY_TIMES,
            PRAYER_REQUEST_CODE_BASE,
        )
    }

    fun reschedulePrayerAzan(context: Context) {
        reschedulePrayerGroup(
            context,
            PRAYER_AZAN_PREFS,
            PRAYER_AZAN_KEY_PATH,
            PRAYER_AZAN_KEY_TIMES,
            PRAYER_AZAN_REQUEST_CODE_BASE,
        )
    }

    private fun reschedulePrayerGroup(
        context: Context,
        preferencesName: String,
        pathKey: String,
        timesKey: String,
        requestCodeBase: Int,
    ) {
        val prefs = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val path = prefs.getString(pathKey, null) ?: return
        val times = prefs.getStringSet(timesKey, emptySet())
            .orEmpty()
            .mapNotNull { it.toLongOrNull() }
            .filter { it > System.currentTimeMillis() }
        if (times.isNotEmpty()) {
            schedulePrayerGroup(
                context,
                path,
                times,
                preferencesName,
                pathKey,
                timesKey,
                requestCodeBase,
            )
        }
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
