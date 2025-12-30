import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return; // Notifications not supported on web
    }

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to home screen
    if (kDebugMode) {
      debugPrint('Notification tapped: ${response.payload}');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    // For Android 13+
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notifications are enabled
  Future<bool> isPermissionGranted() async {
    if (kIsWeb) return false;
    return await Permission.notification.isGranted;
  }

  /// Schedule daily reminder notification
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    await cancelAllNotifications();

    // Check if today's entry already exists
    final db = DatabaseService();
    final today = _formatDate(DateTime.now());
    if (db.hasEntryForDate(today)) {
      // Entry exists for today, schedule for tomorrow
      await _scheduleNotification(
        hour: hour,
        minute: minute,
        skipToday: true,
      );
    } else {
      await _scheduleNotification(
        hour: hour,
        minute: minute,
        skipToday: false,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int hour,
    required int minute,
    required bool skipToday,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If time has passed today or we need to skip today, schedule for tomorrow
    if (scheduledDate.isBefore(now) || skipToday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      '毎日のリマインダー',
      channelDescription: '日記を書く時間をお知らせします',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      0,
      '1分日記',
      '今日はどんな1日でしたか？質問に答えて日記を残しましょう',
      tzDateTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'daily_reminder',
    );

    if (kDebugMode) {
      debugPrint('Notification scheduled for: $tzDateTime');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  /// Update notification schedule when entry is saved
  Future<void> onEntrySaved() async {
    if (kIsWeb) return;
    
    final db = DatabaseService();
    final settings = db.getSettings();
    
    if (settings.notificationEnabled) {
      await scheduleDailyReminder(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      );
    }
  }

  /// Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'テスト通知',
      channelDescription: 'テスト用の通知チャンネル',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '1分日記',
      'テスト通知です',
      details,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
