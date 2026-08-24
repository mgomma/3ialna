package com.ialna.app.diagnostics

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Stores a small, sanitized native crash ring buffer in Flutter preferences.
 * It intentionally retains exception types and frame locations only: never a
 * throwable message, user input, child identity, PIN, recording, or usage data.
 */
object CrashReportRecorder {
    private const val preferencesName = "FlutterSharedPreferences"
    private const val reportsKey = "flutter.native_error_reports_v1"
    private const val maxReports = 10
    private var installed = false

    @Synchronized
    fun install(context: Context) {
        if (installed) return
        installed = true
        val previousHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            record(context, "native_uncaught", throwable)
            previousHandler?.uncaughtException(thread, throwable)
        }
    }

    fun record(context: Context, source: String, throwable: Throwable) {
        try {
            val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            val entries = JSONArray(preferences.getString(reportsKey, "[]"))
            val safeFrames = throwable.stackTrace
                .take(12)
                .joinToString("\n") { frame ->
                    "${frame.className.substringAfterLast('.')}.${frame.methodName}:${frame.lineNumber}"
                }
            val entry = JSONObject()
                .put("timestamp", System.currentTimeMillis().toString())
                .put("source", source.take(40))
                .put("errorType", throwable.javaClass.simpleName.take(80))
                .put("stack", safeFrames.take(600))
            entries.put(entry)
            while (entries.length() > maxReports) entries.remove(0)
            preferences.edit().putString(reportsKey, entries.toString()).apply()
        } catch (_: Throwable) {
            // Diagnostics must never create or hide the original crash.
        }
    }
}
