package com.example.tracking_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MoodNotificationReceiver : BroadcastReceiver() {
    
    companion object {
        const val ACTION_MOOD_SELECTED = "com.example.tracking_app.MOOD_SELECTED"
        const val EXTRA_MOOD_VALUE = "mood_value"
        const val NOTIFICATION_ID = 999
        private const val TAG = "MoodNotificationReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received broadcast: ${intent.action}")
        
        if (intent.action == ACTION_MOOD_SELECTED) {
            val moodValue = intent.getIntExtra(EXTRA_MOOD_VALUE, 0)
            Log.d(TAG, "Mood selected: $moodValue")
            
            // Cancel the notification
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(NOTIFICATION_ID)
            
            // Save mood using SharedPreferences as a bridge
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            with(prefs.edit()) {
                putInt("pending_mood_value", moodValue)
                putLong("pending_mood_timestamp", System.currentTimeMillis())
                putBoolean("has_pending_mood", true)
                apply()
            }
            
            Log.d(TAG, "Mood saved to SharedPreferences, will be picked up by Flutter")
        }
    }
}
