import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as notif;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final notif.FlutterLocalNotificationsPlugin _notifications =
      notif.FlutterLocalNotificationsPlugin();

  static const _channelId = 'taskflow_reminders';
  static const _channelName = 'Task Reminders';
  static const _channelDesc = 'Reminders for upcoming tasks';

  static Future<void> init() async {
    tz.initializeTimeZones();

    final androidSettings =
        notif.AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = notif.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = notif.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    // Explicitly create the Android notification channel
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            notif.AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        notif.AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: notif.Importance.high,
        ),
      );
    }
  }

  static notif.NotificationDetails _buildDetails() {
    return notif.NotificationDetails(
      android: notif.AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: notif.Importance.high,
        priority: notif.Priority.high,
      ),
      iOS: notif.DarwinNotificationDetails(),
    );
  }

  static Future<void> scheduleTaskReminder(Task task) async {
    if (task.id == null) return;

    final taskId = task.id!;
    final details = _buildDetails();
    final now = tz.TZDateTime.now(tz.local);
    final dueDateTime = tz.TZDateTime.from(task.dueDate, tz.local);

    bool scheduledAny = false;

    // 12-hour reminder
    final reminder12h = dueDateTime.subtract(const Duration(hours: 12));
    if (reminder12h.isAfter(now)) {
      await _notifications.zonedSchedule(
        taskId * 10 + 1,
        'Upcoming Task',
        '${task.title} is due in 12 hours',
        reminder12h,
        details,
        androidScheduleMode:
            notif.AndroidScheduleMode.inexactAllowWhileIdle,
      );
      scheduledAny = true;
    }

    // 3-hour reminder
    final reminder3h = dueDateTime.subtract(const Duration(hours: 3));
    if (reminder3h.isAfter(now)) {
      await _notifications.zonedSchedule(
        taskId * 10 + 2,
        'Task Due Soon',
        '${task.title} is due in 3 hours',
        reminder3h,
        details,
        androidScheduleMode:
            notif.AndroidScheduleMode.inexactAllowWhileIdle,
      );
      scheduledAny = true;
    }

    // If both reminders are in the past (due date < 3h away), fire one now
    if (!scheduledAny && dueDateTime.isAfter(now)) {
      await _notifications.show(
        taskId * 10 + 3,
        'Task Reminder',
        '${task.title} is due soon!',
        details,
      );
    }
  }

  static Future<void> cancelNotifications(int taskId) async {
    await _notifications.cancel(taskId * 10 + 1);
    await _notifications.cancel(taskId * 10 + 2);
    await _notifications.cancel(taskId * 10 + 3);
  }

  static Future<void> requestPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            notif.AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
}
