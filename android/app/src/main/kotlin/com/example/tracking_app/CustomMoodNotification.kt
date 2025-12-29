package com.example.tracking_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import android.util.Log

class CustomMoodNotification(private val context: Context) {
    
    companion object {
        private const val CHANNEL_ID = "mood_check_channel"
        private const val NOTIFICATION_ID = 999
        private const val TAG = "CustomMoodNotification"
    }
    
    fun sendNotification() {
        Log.d(TAG, "Sending custom mood notification")
        
        createNotificationChannel()
        
        // Create custom notification layout
        val notificationLayout = RemoteViews(
            context.packageName,
            R.layout.notification_mood
        )
        
        // Set up click handlers for each mood button
        for (moodValue in 1..5) {
            val buttonId = context.resources.getIdentifier(
                "mood_button_$moodValue",
                "id",
                context.packageName
            )
            
            val intent = Intent(context, MoodNotificationReceiver::class.java).apply {
                action = MoodNotificationReceiver.ACTION_MOOD_SELECTED
                putExtra(MoodNotificationReceiver.EXTRA_MOOD_VALUE, moodValue)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                moodValue,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            notificationLayout.setOnClickPendingIntent(buttonId, pendingIntent)
            Log.d(TAG, "Set click handler for mood button $moodValue")
        }
        
        // Build notification
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(notificationLayout)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(false)
            .build()
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
        
        Log.d(TAG, "Custom mood notification sent successfully")
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Mood Check Notifications"
            val descriptionText = "Hourly mood check notifications"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
