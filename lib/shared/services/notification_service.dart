import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  static const _channelId = 'calendar_reminder';
  static const _channelName = 'Calendar Reminder';
  static const _channelDescription = 'Calendar event reminders';
  static const _calendarPayloadPrefix = 'calendar_event:';

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

  String _payloadForEvent(String eventId) => '$_calendarPayloadPrefix$eventId';

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await initialize();

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
  }

  Future<bool> areNotificationsAllowed() async {
    await initialize();

    final androidEnabled =
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
    if (androidEnabled != null) {
      return androidEnabled;
    }

    final iosSettings =
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
    if (iosSettings != null) {
      return iosSettings.isEnabled;
    }

    return true;
  }

  Future<int> pendingCalendarReminderCount() async {
    await initialize();

    final pending = await _plugin.pendingNotificationRequests();
    return pending.where((request) {
      final payload = request.payload ?? '';
      return payload.startsWith(_calendarPayloadPrefix);
    }).length;
  }

  Future<void> scheduleOneHourBefore(CalendarEvent event) async {
    await initialize();

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
      payload: _payloadForEvent(eventId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelForEvent(String eventId) async {
    await initialize();
    await _plugin.cancel(notificationIdForEvent(eventId));
  }

  Future<void> resyncCalendarNotifications(List<CalendarEvent> events) async {
    await initialize();

    final activeEventIds =
        events.map((event) => event.id).whereType<String>().toSet();

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload ?? '';
      if (!payload.startsWith(_calendarPayloadPrefix)) {
        continue;
      }

      final eventId = payload.replaceFirst(_calendarPayloadPrefix, '');
      if (!activeEventIds.contains(eventId)) {
        await _plugin.cancel(request.id);
      }
    }

    for (final event in events) {
      await scheduleOneHourBefore(event);
    }
  }
}
