import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tracking_app/models/hourly_mood.dart';
import 'package:tracking_app/services/database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _db = DatabaseService();
  bool _initialized = false;

  static const platform = MethodChannel('com.example.tracking_app/mood');

  Future<void> initialize() async {
    if (_initialized) return;

    // Defer heavy initialization to not block debugger connection
    Future.microtask(() async {
      // Initialize timezone in background
      tz.initializeTimeZones();
    });

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request notification permissions
    await _requestPermissions();

    // Start periodic check for pending moods from notification
    _startPendingMoodCheck();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      await android.requestNotificationsPermission();
    }
  }

  void _onNotificationResponse(NotificationResponse response) async {
    print('Notification tapped - payload: ${response.payload}');
    // Dialog will be shown by main.dart navigation handling
  }

  // Check for pending moods every 2 seconds
  void _startPendingMoodCheck() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      await _checkPendingMood();
      return true; // Keep loop running
    });
  }

  Future<void> _checkPendingMood() async {
    try {
      final result = await platform.invokeMethod('checkPendingMood');

      if (result != null) {
        final moodValue = result['moodValue'] as int;
        final timestamp = result['timestamp'] as int;

        print('Received pending mood from notification: $moodValue');

        // Save the mood
        final mood = HourlyMood(
          id: timestamp.toString(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
          mood: moodValue,
        );

        await _db.saveHourlyMood(mood);
        print('Mood saved from notification: $moodValue');
      }
    } catch (e) {
      // Silently handle errors (might happen if app is not fully initialized)
    }
  }

  /// Send a custom notification with inline mood buttons
  Future<void> sendTestNotification() async {
    await initialize();

    // Note: Custom RemoteViews notification with 5 buttons requires native implementation
    // This will be handled by the platform-specific code
    try {
      await platform.invokeMethod('sendCustomMoodNotification');
      print('Custom mood notification sent!');
    } catch (e) {
      print('Error sending custom notification: $e');
      // Fallback to regular notification
      await _sendFallbackNotification();
    }
  }

  Future<void> _sendFallbackNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'mood_check_channel',
      'Mood Check Notifications',
      channelDescription: 'Hourly mood check notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      'How are you feeling right now?',
      'Tap to record your mood',
      notificationDetails,
      payload: 'show_mood_selector',
    );
  }

  /// Schedule hourly mood check notifications
  Future<void> scheduleHourlyMoodChecks() async {
    await initialize();

    // Cancel existing notifications
    await _notifications.cancelAll();

    // Schedule notifications for every hour from 8 AM to 10 PM
    for (int hour = 8; hour <= 22; hour++) {
      await _scheduleNotificationAtHour(hour);
    }
  }

  Future<void> _scheduleNotificationAtHour(int hour) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, 0);

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'mood_check_channel',
      'Mood Check Notifications',
      channelDescription: 'Hourly mood check notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      hour, // Use hour as notification ID
      'How are you feeling?',
      'Tap to record your mood',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'show_mood_selector',
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
