package com.abbas.netanalyzer

import android.net.TrafficStats
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "traffic")
            .setMethodCallHandler { _, result ->
                result.success(listOf(TrafficStats.getTotalRxBytes(), TrafficStats.getTotalTxBytes()))
            }
    }
}
