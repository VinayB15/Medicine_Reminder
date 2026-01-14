import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification plugin + timezone
  static Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
  }

  /// Schedule notification at exact time
  static Future<void> scheduleNotification(
  int id,
  String medicineName,
  DateTime time,
) async {
  await _plugin.zonedSchedule(
    id,
    'Medicine Reminder',
    'Time to take $medicineName',
    tz.TZDateTime.from(time, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_channel',
        'Medicine Reminder',
        channelDescription: 'Notification for medicine reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
}