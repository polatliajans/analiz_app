package com.polatliajans.kriptoanaliz

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kriptoanaliz/system")
            .setMethodCallHandler { call, result ->
                if (call.method == "openNotificationSettings") {
                    result.success(openNotificationSettings())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun openNotificationSettings(): Boolean {
        val intents = ArrayList<Intent>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intents.add(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            )
        }
        intents.add(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
        )
        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            } catch (e: Exception) {
                // Try the next, more generic intent.
            }
        }
        return false
    }
}
