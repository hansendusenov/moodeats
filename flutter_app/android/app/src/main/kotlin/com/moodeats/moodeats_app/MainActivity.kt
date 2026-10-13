package com.moodeats.moodeats_app

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.moodeats.moodeats_app/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceInfo") {
                val info = mapOf(
                    "manufacturer" to Build.MANUFACTURER,
                    "model" to Build.MODEL,
                    "brand" to Build.BRAND,
                    "device" to Build.DEVICE,
                    "sdkInt" to Build.VERSION.SDK_INT,
                    "release" to Build.VERSION.RELEASE
                )
                result.success(info)
            } else {
                result.notImplemented()
            }
        }
    }
}
