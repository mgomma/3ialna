package com.ialna.app.voice

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class VoicePlaybackReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            ACTION_PLAY -> {
                val path = intent.getStringExtra(VoicePlaybackService.EXTRA_PATH)
                if (!path.isNullOrBlank()) {
                    val serviceIntent = Intent(context, VoicePlaybackService::class.java)
                        .putExtra(VoicePlaybackService.EXTRA_PATH, path)
                    ContextCompat.startForegroundService(context, serviceIntent)
                }
            }
            Intent.ACTION_BOOT_COMPLETED -> {
                VoicePlaybackScheduler.reschedule(context)
            }
        }
    }

    companion object {
        const val ACTION_PLAY = "com.ialna.app.voice.PLAY"
    }
}
