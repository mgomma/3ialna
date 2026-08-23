package com.example.mu_super_app.voice

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.example.mu_super_app.R

class VoicePlaybackService : Service() {
    private var player: MediaPlayer? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val path = intent?.getStringExtra(EXTRA_PATH)
        if (path.isNullOrBlank()) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        startForeground(NOTIFICATION_ID, buildNotification())
        player?.release()
        player = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()
            )
            setDataSource(path)
            setOnCompletionListener {
                it.release()
                player = null
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelfResult(startId)
            }
            setOnErrorListener { _, _, _ ->
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelfResult(startId)
                true
            }
            prepare()
            start()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        player?.release()
        player = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Parent voice notifications",
                NotificationManager.IMPORTANCE_LOW,
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("3ialna")
            .setContentText("Playing a parent voice notification")
            .setOngoing(true)
            .build()
    }

    companion object {
        const val EXTRA_PATH = "voice_path"
        const val CHANNEL_ID = "parent_voice_playback"
        const val NOTIFICATION_ID = 3201
    }
}
