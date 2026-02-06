import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleRoutine(List<dynamic> steps) async {
    // Cancel all existing notifications to avoid duplicates
    await flutterLocalNotificationsPlugin.cancelAll();

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      String timeString = step['time'] ?? "08:00";
      final String title = step['title'] ?? "Recordatorio Minox Plan";
      final String body = step['body'] ?? "Es hora de tu rutina.";

      // Normalizar separadores: cambiar - o . por :
      timeString = timeString.replaceAll('-', ':').replaceAll('.', ':');

      final parts = timeString.split(":");
      // Asegurarse de quitar espacios
      final int hour = int.parse(parts[0].trim());
      final int minute = int.parse(parts[1].trim());

      await _scheduleDailyNotification(
        id: i,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
      );
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_routine_channel',
          'Rutina Diaria',
          channelDescription: 'Recordatorios para tu rutina de cuidado',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at the same time
    );
  }

  Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    print("🔔 --- PENDING NOTIFICATIONS: ${pending.length} ---");
    for (var n in pending) {
      print(
        "ID: ${n.id} | Title: ${n.title} | Body: ${n.body} | Payload: ${n.payload}",
      );
    }
    print("🔔 ----------------------------------------");
  }
}
