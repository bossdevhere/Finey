import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification interaction
      },
    );
  }

  static Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String repeatType = 'One Time',
  }) async {
    DateTime targetTime = scheduledTime;
    final now = DateTime.now();

    // Adjust past scheduled times safely without recursive stack overflow
    if (targetTime.isBefore(now)) {
      if (repeatType == 'Daily') {
        targetTime = DateTime(
          now.year,
          now.month,
          now.day,
          scheduledTime.hour,
          scheduledTime.minute,
          scheduledTime.second,
        );
        if (targetTime.isBefore(now)) {
          targetTime = targetTime.add(const Duration(days: 1));
        }
      } else {
        return;
      }
    }

    final tz.TZDateTime tzTime = tz.TZDateTime.from(targetTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'finovo_reminders',
      'Finovo Reminders',
      channelDescription: 'Notifications for Finovo budget reminders and notes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (repeatType == 'One Time') {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      DateTimeComponents? matchComponents;
      if (repeatType == 'Daily') {
        matchComponents = DateTimeComponents.time;
      } else if (repeatType == 'Weekly') {
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
      } else if (repeatType == 'Monthly') {
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
      } else if (repeatType == 'Yearly') {
        matchComponents = DateTimeComponents.dateAndTime;
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
      );
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
