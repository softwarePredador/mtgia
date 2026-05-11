package com.mtgia.mtg_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val LIFE_COUNTER_LIFECYCLE_CHANNEL = "manaloom/life_counter_lifecycle"
        private const val PUSH_NOTIFICATION_CHANNEL = "manaloom_notifications"
    }

    private var lifeCounterLifecycleChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createPushNotificationChannel()
        lifeCounterLifecycleChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LIFE_COUNTER_LIFECYCLE_CHANNEL,
        )
    }

    private fun createPushNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val channel = NotificationChannel(
            PUSH_NOTIFICATION_CHANNEL,
            "ManaLoom",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Notificações de mensagens, trocas e comunidade"
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        lifeCounterLifecycleChannel?.invokeMethod(
            "userLeaveHint",
            mapOf("timestampMs" to System.currentTimeMillis()),
        )
    }

    override fun onPause() {
        super.onPause()
        lifeCounterLifecycleChannel?.invokeMethod(
            "activityPaused",
            mapOf("timestampMs" to System.currentTimeMillis()),
        )
    }

    override fun onResume() {
        super.onResume()
        lifeCounterLifecycleChannel?.invokeMethod(
            "activityResumed",
            mapOf("timestampMs" to System.currentTimeMillis()),
        )
    }
}
