package com.example.mu_super_app

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.mu_super_app.usage.MonitorForegroundService

class MainActivity : FlutterActivity() {

    private val serviceChannel = "social_limiter/service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
    }

    private fun startMonitoringService() {
        val intent = Intent(this, MonitorForegroundService::class.java)
        ContextCompat.startForegroundService(this, intent)
    }

    private fun stopMonitoringService() {
        val intent = Intent(this, MonitorForegroundService::class.java)
        stopService(intent)
    }
}
