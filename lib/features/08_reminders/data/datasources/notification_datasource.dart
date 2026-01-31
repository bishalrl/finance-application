import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/reminder.dart';

/// Data source for managing local notifications
class NotificationDataSource {
  final FlutterLocalNotificationsPlugin _notifications;

  NotificationDataSource(this._notifications);

  /// Initializes notifications
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Schedules a notification for a reminder
  Future<void> scheduleNotification(Reminder reminder) async {
    try {
      final notificationId = reminder.id.hashCode;
      
      // Calculate notification date (30, 15, 7 days before, and on the day)
      final reminderDate = reminder.reminderDate;
      final now = DateTime.now();
      
      // Schedule notification for the reminder date
      if (reminderDate.isAfter(now)) {
        await _scheduleSingleNotification(
          notificationId,
          reminder.title,
          reminder.description ?? 'Reminder: ${reminder.title}',
          reminderDate,
        );
      }

      // Schedule advance notifications if it's a document expiry
      if (reminder.type == ReminderType.documentExpiry && reminderDate.isAfter(now)) {
        final daysUntil = reminderDate.difference(now).inDays;
        
        // 30 days before
        if (daysUntil > 30) {
          final date30 = reminderDate.subtract(const Duration(days: 30));
          if (date30.isAfter(now)) {
            await _scheduleSingleNotification(
              notificationId + 1,
              '${reminder.title} expires in 30 days',
              'Your document will expire soon',
              date30,
            );
          }
        }
        
        // 15 days before
        if (daysUntil > 15) {
          final date15 = reminderDate.subtract(const Duration(days: 15));
          if (date15.isAfter(now)) {
            await _scheduleSingleNotification(
              notificationId + 2,
              '${reminder.title} expires in 15 days',
              'Your document will expire soon',
              date15,
            );
          }
        }
        
        // 7 days before
        if (daysUntil > 7) {
          final date7 = reminderDate.subtract(const Duration(days: 7));
          if (date7.isAfter(now)) {
            await _scheduleSingleNotification(
              notificationId + 3,
              '${reminder.title} expires in 7 days',
              'Your document will expire soon',
              date7,
            );
          }
        }
      }
    } catch (e) {
      throw NotificationException('Failed to schedule notification: $e');
    }
  }

  /// Schedules a single notification
  Future<void> _scheduleSingleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Notifications for reminders and document expiry',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a notification
  Future<void> cancelNotification(String reminderId) async {
    try {
      // Cancel all related notifications (main + advance notifications)
      for (int i = 0; i < 4; i++) {
        await _notifications.cancel(reminderId.hashCode + i);
      }
    } catch (e) {
      throw NotificationException('Failed to cancel notification: $e');
    }
  }

  /// Cancels all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Callback when notification is tapped
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to reminder detail
    // This will be handled by the app's navigation system
  }
}

class NotificationException implements Exception {
  final String message;
  NotificationException(this.message);
  
  @override
  String toString() => 'NotificationException: $message';
}
