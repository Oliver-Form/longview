package com.example.stride

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.SharedPreferences
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.Timer
import kotlin.concurrent.timer
import android.speech.tts.TextToSpeech

class BackgroundTrackingService : Service() {
    companion object {
        const val CHANNEL_ID = "stride_tracking_channel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "com.example.stride.ACTION_START"
        const val ACTION_STOP = "com.example.stride.ACTION_STOP"
        const val ACTION_PAUSE = "com.example.stride.ACTION_PAUSE"
        const val ACTION_RESUME = "com.example.stride.ACTION_RESUME"
        
        // SharedPreferences keys
        const val PREFS_NAME = "stride_tracking_prefs"
        const val KEY_ROUTE_POINTS = "routePoints"
        const val KEY_START_TIME = "startTimestamp"
        const val KEY_LAST_TIME = "lastTimestamp"
        const val KEY_IS_PAUSED = "isPaused"
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var lastLocation: Location? = null
    private var distanceMeters = 0.0
    private var startTime = 0L
    private var pausedTime = 0L
    private var isPaused = false
    private var timerTask: Timer? = null
    private lateinit var prefs: SharedPreferences
    
    // Text-to-speech and audio cue variables
    private lateinit var textToSpeech: TextToSpeech
    private var ttsInitialized = false
    private var lastAudioCueDistance = 0.0

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        createNotificationChannel()
        
        // Initialize text-to-speech engine
        textToSpeech = TextToSpeech(applicationContext) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val result = textToSpeech.setLanguage(Locale.getDefault())
                ttsInitialized = result != TextToSpeech.LANG_MISSING_DATA && 
                                result != TextToSpeech.LANG_NOT_SUPPORTED
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startTracking()
            ACTION_STOP -> stopTracking()
            ACTION_PAUSE -> pauseTracking()
            ACTION_RESUME -> resumeTracking()
        }
        return START_STICKY
    }

    private fun startTracking() {
        startTime = System.currentTimeMillis()
        pausedTime = 0L
        isPaused = false
        distanceMeters = 0.0
        lastLocation = null
        lastAudioCueDistance = 0.0
        
        // Clear any existing route data
        with(prefs.edit()) {
            putString(KEY_ROUTE_POINTS, "[]")
            putString(KEY_START_TIME, SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date()))
            putBoolean(KEY_IS_PAUSED, false)
            apply()
        }
        
        val notification = buildNotification(0L, 0.0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        startLocationUpdates()
        
        timerTask = timer(period = 1000) {
            if (!isPaused) {
                val elapsed = System.currentTimeMillis() - startTime - pausedTime
                updateNotification(elapsed, distanceMeters)
            }
        }
    }
    
    private fun startLocationUpdates() {
        val request = LocationRequest.create().apply {
            interval = 5000
            fastestInterval = 2000
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }
        fusedLocationClient.requestLocationUpdates(request, locationCallback, Looper.getMainLooper())
    }

    private fun pauseTracking() {
        isPaused = true
        fusedLocationClient.removeLocationUpdates(locationCallback)
        
        with(prefs.edit()) {
            putBoolean(KEY_IS_PAUSED, true)
            putString(KEY_LAST_TIME, SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date()))
            apply()
        }
        
        val elapsed = System.currentTimeMillis() - startTime - pausedTime
        updateNotification(elapsed, distanceMeters)
    }
    
    private fun resumeTracking() {
        val pauseStartTime = prefs.getString(KEY_LAST_TIME, null)
        if (pauseStartTime != null) {
            val pauseStart = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).parse(pauseStartTime)
            if (pauseStart != null) {
                pausedTime += System.currentTimeMillis() - pauseStart.time
            }
        }
        
        isPaused = false
        with(prefs.edit()) {
            putBoolean(KEY_IS_PAUSED, false)
            apply()
        }
        
        startLocationUpdates()
        val elapsed = System.currentTimeMillis() - startTime - pausedTime
        updateNotification(elapsed, distanceMeters)
    }

    private fun stopTracking() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        timerTask?.cancel()
        
        // Clear tracking data
        with(prefs.edit()) {
            remove(KEY_ROUTE_POINTS)
            remove(KEY_START_TIME)
            remove(KEY_LAST_TIME)
            remove(KEY_IS_PAUSED)
            apply()
        }
        
        stopForeground(true)
        stopSelf()
    }

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.locations.lastOrNull()?.let { location ->
                // Calculate distance if we have a previous location
                lastLocation?.let { prev -> 
                    val newDistance = prev.distanceTo(location)
                    distanceMeters += newDistance
                    
                    // Check if we should trigger an audio cue (every 100 meters)
                    val currentHundredMeter = (distanceMeters / 100).toInt()
                    val lastHundredMeter = (lastAudioCueDistance / 100).toInt()
                    
                    if (currentHundredMeter > lastHundredMeter && !isPaused) {
                        // Calculate elapsed time
                        val elapsed = System.currentTimeMillis() - startTime - pausedTime
                        
                        // Speak the current time
                        speakTime(elapsed)
                        
                        // Update last audio cue distance
                        lastAudioCueDistance = distanceMeters
                    }
                }
                
                // Store the location
                lastLocation = location
                
                // Save to shared preferences for Flutter to access
                val routePointsJson = prefs.getString(KEY_ROUTE_POINTS, "[]") ?: "[]"
                try {
                    val jsonArray = JSONArray(routePointsJson)
                    val point = JSONObject()
                    point.put("latitude", location.latitude)
                    point.put("longitude", location.longitude)
                    point.put("timestamp", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date()))
                    jsonArray.put(point)
                    
                    with(prefs.edit()) {
                        putString(KEY_ROUTE_POINTS, jsonArray.toString())
                        putString(KEY_LAST_TIME, SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date()))
                        apply()
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                
                val elapsed = System.currentTimeMillis() - startTime - pausedTime
                updateNotification(elapsed, distanceMeters)
            }
        }
    }

    private fun buildNotification(elapsedMillis: Long, distanceMeters: Double): Notification {
        val elapsed = formatTime(elapsedMillis)
        val distanceKm = String.format("%.2f km", distanceMeters / 1000)
        val content = "Time: $elapsed  Distance: $distanceKm"
        
        // Create intent to open the app when notification is tapped
        val contentIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingContentIntent = PendingIntent.getActivity(
            this, 0, contentIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create intents for action buttons
        val actionIntent: Intent
        val actionText: String
        val actionIcon: Int
        
        if (isPaused) {
            // Show resume button when paused
            actionIntent = Intent(this, BackgroundTrackingService::class.java).apply { 
                action = ACTION_RESUME 
            }
            actionText = "Resume"
            actionIcon = R.drawable.ic_play
        } else {
            // Show pause button when running
            actionIntent = Intent(this, BackgroundTrackingService::class.java).apply { 
                action = ACTION_PAUSE 
            }
            actionText = "Pause"
            actionIcon = R.drawable.ic_pause
        }
        
        val pendingActionIntent = PendingIntent.getService(
            this, 1, actionIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Stop button
        val stopIntent = Intent(this, BackgroundTrackingService::class.java).apply { 
            action = ACTION_STOP 
        }
        val pendingStopIntent = PendingIntent.getService(
            this, 2, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Stride Running")
            .setContentText(content)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingContentIntent)
            .addAction(actionIcon, actionText, pendingActionIntent)
            .addAction(R.drawable.ic_stop, "Stop", pendingStopIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(elapsedMillis: Long, distanceMeters: Double) {
        val notification = buildNotification(elapsedMillis, distanceMeters)
        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            )
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(chan)
        }
    }

    private fun formatTime(millis: Long): String {
        val seconds = (millis / 1000) % 60
        val minutes = (millis / (1000 * 60)) % 60
        val hours = millis / (1000 * 60 * 60)
        return String.format("%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private fun speakTime(millis: Long) {
        if (!ttsInitialized) return
        
        val hours = millis / (1000 * 60 * 60)
        val minutes = (millis / (1000 * 60)) % 60
        val seconds = (millis / 1000) % 60
        
        val timeText = StringBuilder()
        if (hours > 0) {
            timeText.append("$hours hours ")
        }
        if (minutes > 0 || hours > 0) {
            timeText.append("$minutes minutes ")
        }
        timeText.append("$seconds seconds")
        
        textToSpeech.speak(
            timeText.toString(), 
            TextToSpeech.QUEUE_FLUSH, 
            null, 
            "time_update_${System.currentTimeMillis()}"
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::textToSpeech.isInitialized) {
            textToSpeech.stop()
            textToSpeech.shutdown()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
