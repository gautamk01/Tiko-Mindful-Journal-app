package com.example.tracking_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.tracking_app/mood"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPendingMood" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val hasPending = prefs.getBoolean("has_pending_mood", false)
                    
                    if (hasPending) {
                        val moodValue = prefs.getInt("pending_mood_value", 0)
                        val timestamp = prefs.getLong("pending_mood_timestamp", 0)
                        
                        Log.d(TAG, "Found pending mood: $moodValue at $timestamp")
                        
                        // Clear the pending mood
                        with(prefs.edit()) {
                            remove("has_pending_mood")
                            remove("pending_mood_value")
                            remove("pending_mood_timestamp")
                            apply()
                        }
                        
                        val moodData = HashMap<String, Any>()
                        moodData["moodValue"] = moodValue
                        moodData["timestamp"] = timestamp
                        
                        result.success(moodData)
                    } else {
                        result.success(null)
                    }
                }
                "sendCustomMoodNotification" -> {
                   sendCustomMoodNotification()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun sendCustomMoodNotification() {
        val notificationHelper = CustomMoodNotification(this)
        notificationHelper.sendNotification()
    }
}
