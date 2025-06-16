package com.example.stride

import android.content.Intent
import android.content.SharedPreferences
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
  private val CHANNEL = "stride/tracking"
  private lateinit var prefs: SharedPreferences

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    
    prefs = getSharedPreferences(BackgroundTrackingService.PREFS_NAME, MODE_PRIVATE)
    
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "startTracking" -> {
          val intent = Intent(this, BackgroundTrackingService::class.java).apply {
            action = BackgroundTrackingService.ACTION_START
          }
          ContextCompat.startForegroundService(this, intent)
          result.success(null)
        }
        "stopTracking" -> {
          val intent = Intent(this, BackgroundTrackingService::class.java).apply {
            action = BackgroundTrackingService.ACTION_STOP
          }
          ContextCompat.startForegroundService(this, intent)
          result.success(null)
        }
        "pauseTracking" -> {
          val intent = Intent(this, BackgroundTrackingService::class.java).apply {
            action = BackgroundTrackingService.ACTION_PAUSE
          }
          ContextCompat.startForegroundService(this, intent)
          result.success(null)
        }
        "resumeTracking" -> {
          val intent = Intent(this, BackgroundTrackingService::class.java).apply {
            action = BackgroundTrackingService.ACTION_RESUME
          }
          ContextCompat.startForegroundService(this, intent)
          result.success(null)
        }
        "getTrackingStatus" -> {
          val response = JSONObject()
          response.put("isTracking", isServiceRunning())
          response.put("isPaused", prefs.getBoolean(BackgroundTrackingService.KEY_IS_PAUSED, false))
          response.put("routePoints", prefs.getString(BackgroundTrackingService.KEY_ROUTE_POINTS, "[]"))
          response.put("startTime", prefs.getString(BackgroundTrackingService.KEY_START_TIME, null))
          response.put("lastTime", prefs.getString(BackgroundTrackingService.KEY_LAST_TIME, null))
          result.success(response.toString())
        }
        else -> result.notImplemented()
      }
    }
  }
  
  private fun isServiceRunning(): Boolean {
    return prefs.contains(BackgroundTrackingService.KEY_START_TIME)
  }
}
