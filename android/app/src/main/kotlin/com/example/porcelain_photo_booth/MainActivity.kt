package com.example.porcelain_photo_booth

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Free space for the launch checks (ADR-0012): Dart has no API for
        // it. Reports only a number of bytes.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "porcelain/device_storage")
            .setMethodCallHandler { call, result ->
                if (call.method == "freeBytes") {
                    try {
                        result.success(StatFs(filesDir.path).availableBytes)
                    } catch (error: IllegalArgumentException) {
                        result.error("unavailable", null, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
