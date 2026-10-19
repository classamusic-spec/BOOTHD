package com.example.porcelain_photo_booth

import android.app.ActivityManager
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
                when (call.method) {
                    "freeBytes" -> try {
                        result.success(StatFs(filesDir.path).availableBytes)
                    } catch (error: IllegalArgumentException) {
                        result.error("unavailable", null, null)
                    }
                    // The manifest already keeps app data out of cloud
                    // backup and device transfer (ADR-0009, ADR-0016).
                    "excludeFromBackup" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
        // Whether the tablet is locked to this app (ADR-0016): Dart has no
        // API for it. Read only: the app never starts or stops a lock.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "porcelain/kiosk")
            .setMethodCallHandler { call, result ->
                if (call.method == "lockState") {
                    val activities = getSystemService(ActivityManager::class.java)
                    result.success(
                        when (activities?.lockTaskModeState) {
                            ActivityManager.LOCK_TASK_MODE_LOCKED -> "managed"
                            ActivityManager.LOCK_TASK_MODE_PINNED -> "pinned"
                            ActivityManager.LOCK_TASK_MODE_NONE -> "none"
                            else -> "unknown"
                        },
                    )
                } else {
                    result.notImplemented()
                }
            }
    }
}
