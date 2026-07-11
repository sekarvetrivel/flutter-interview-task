package com.example.flutter_application_4

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Channel name and method name must exactly match the Dart side
    // (see battery_screen.dart: BatteryChannel._channel).
    private val CHANNEL = "com.example/battery"
    private val METHOD_GET_BATTERY_LEVEL = "getBatteryLevel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == METHOD_GET_BATTERY_LEVEL) {
                    val batteryLevel = getBatteryLevel()
                    if (batteryLevel != -1) {
                        result.success(batteryLevel)
                    } else {
                        // Mirrors on the Dart side as a PlatformException with
                        // this exact code, which battery_screen.dart handles
                        // explicitly instead of crashing.
                        result.error(
                            "UNAVAILABLE",
                            "Battery level not available on this device.",
                            null
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    // Returns the ACTUAL current battery percentage (0-100), not a
    // hardcoded value, using BatteryManager where available (API 21+),
    // falling back to the sticky battery-changed broadcast on older
    // devices.
    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val levelFromManager = batteryManager?.getIntProperty(
            BatteryManager.BATTERY_PROPERTY_CAPACITY
        ) ?: -1

        if (levelFromManager in 0..100) return levelFromManager

        // Fallback path for devices/emulators where the above property
        // isn't populated.
        val intent: Intent? = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

        return if (level != -1 && scale != -1 && scale != 0) {
            (level * 100 / scale)
        } else {
            -1
        }
    }
}

// NOTE ON CROSS-PLATFORM SUPPORT:
// To also support iOS with this same Dart code, no Dart-side changes are
// needed at all -- BatteryChannel already just calls a MethodChannel named
// "com.example/battery" with method "getBatteryLevel" regardless of
// platform. What's needed is purely native:
//   1. Implement the identical channel name + method name in
//      AppDelegate.swift (see ios/AppDelegate.swift in this folder).
//   2. Set `UIDevice.current.isBatteryMonitoringEnabled = true` before
//      reading `UIDevice.current.batteryLevel`, and convert the 0.0-1.0
//      float iOS returns into a 0-100 int to match what the Dart side
//      expects.
//   3. Return a FlutterError (iOS's equivalent of `result.error(...)`)
//      when `batteryLevel < 0` (the value iOS returns when monitoring
//      isn't enabled or the device is a simulator without a battery), so
//      it surfaces as a PlatformException in Dart just like on Android.
