package com.mtgia.mtg_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val LIFE_COUNTER_LIFECYCLE_CHANNEL = "manaloom/life_counter_lifecycle"
    }

    private var lifeCounterLifecycleChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        lifeCounterLifecycleChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LIFE_COUNTER_LIFECYCLE_CHANNEL,
        )
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
