package com.zdelivery.zdelivery

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.zdelivery.zdelivery/config"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getGoogleMapsApiKey" -> result.success(readGoogleMapsApiKey())
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun readGoogleMapsApiKey(): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(
                packageName,
                PackageManager.GET_META_DATA
            )
            appInfo.metaData?.getString("com.google.android.geo.API_KEY") ?: ""
        } catch (_: Exception) {
            ""
        }
    }
}
