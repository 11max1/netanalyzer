package com.abbas.netanalyzer

import android.content.Context
import android.net.TrafficStats
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var lock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "traffic")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "get" -> result.success(
                        listOf(TrafficStats.getTotalRxBytes(), TrafficStats.getTotalTxBytes())
                    )
                    "lock" -> {
                        val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        if (lock == null) {
                            lock = wm.createMulticastLock("abbas_mdns")
                        }
                        lock?.setReferenceCounted(false)
                        lock?.acquire()
                        result.success(true)
                    }
                    "unlock" -> {
                        lock?.let { if (it.isHeld) it.release() }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
