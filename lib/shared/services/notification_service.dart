import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'calendar_reminder';
  static const _channelName = 'Calendar Reminder';
  static const _channelDescription = 'Calendar event reminders';

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  int notificationIdForEvent(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleOneHourBefore(CalendarEvent event) async {
    final eventId = event.id;
    final start = event.start?.dateTime;

    if (eventId == null || start == null) return;
    //TODO
    if (event.start?.isAllDay ?? false) return;

    // final scheduledAt = start.subtract(const Duration(hours: 1));
    final scheduledAt = start.subtract(const Duration(minutes: 1));
    final now = tz.TZDateTime.now(tz.local);
    final zonedTime = tz.TZDateTime.from(scheduledAt, tz.local);
    final id = notificationIdForEvent(eventId);

    await _plugin.cancel(id);

    if (!zonedTime.isAfter(now)) return;

    await _plugin.zonedSchedule(
      id,
      event.summary ?? '予定',
      '1時間後予定があります',
      zonedTime,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelForEvent(String eventId) async {
    await _plugin.cancel(notificationIdForEvent(eventId));
  }

  Future<void> resyncCalendarNotifications(List<CalendarEvent> events) async {
    await _plugin.cancelAll();

    for (final event in events) {
      await scheduleOneHourBefore(event);
    }
  }
}
