/// 로컬 알림 초기화, 권한 확인, 캘린더 리마인더 재등록을 담당한다.
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
  static const _beforeMeetingPayloadPrefix = 'calendar_before:';
  static const _afterMeetingPayloadPrefix = 'calendar_after:';

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

  int _notificationId(String key) => key.hashCode & 0x7fffffff;

  int beforeMeetingNotificationId(String eventId) {
    return _notificationId('before:$eventId');
  }

  int afterMeetingNotificationId(String eventId) {
    return _notificationId('after:$eventId');
  }

  String _beforeMeetingPayload(String eventId) =>
      '$_beforeMeetingPayloadPrefix$eventId';

  String _afterMeetingPayload(String eventId) =>
      '$_afterMeetingPayloadPrefix$eventId';

  Future<void> initialize() async {
    /// 알림 플러그인을 1회만 초기화한다.
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
    /// 플랫폼별 알림 권한 요청을 수행한다.
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
    /// 현재 디바이스에서 알림 권한이 유효한지 확인한다.
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
    /// 캘린더 이벤트용으로 예약된 알림 개수를 센다.
    await initialize();

    final pending = await _plugin.pendingNotificationRequests();
    return pending.where((request) {
      final payload = request.payload ?? '';
      return payload.startsWith(_beforeMeetingPayloadPrefix) ||
          payload.startsWith(_afterMeetingPayloadPrefix);
    }).length;
  }

  Future<void> scheduleBeforeMeetingReminder(CalendarEvent event) async {
    /// 단일 일정에 대한 사전 알림을 예약한다.
    await initialize();

    final eventId = event.id;
    final start = event.start?.dateTime;

    if (eventId == null || start == null) return;
    if (event.start?.isAllDay ?? false) return;

    // final scheduledAt = start.subtract(const Duration(hours: 1));
    final scheduledAt = start.subtract(const Duration(minutes: 1));
    final now = tz.TZDateTime.now(tz.local);
    final zonedTime = tz.TZDateTime.from(scheduledAt, tz.local);
    final id = beforeMeetingNotificationId(eventId);

    await _plugin.cancel(id);

    if (!zonedTime.isAfter(now)) return;

    await _plugin.zonedSchedule(
      id,
      event.summary ?? '予定',
      '1時間後予定があります',
      zonedTime,
      _details,
      payload: _beforeMeetingPayload(eventId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleAfterMeetingReminder(CalendarEvent event) async {
    /// 미팅 종료 5분 후 기록 작성을 유도하는 알림을 예약한다.
    await initialize();

    final eventId = event.id;
    final end = event.end?.dateTime;

    if (eventId == null || end == null) return;
    if (event.end?.isAllDay ?? false) return;

    final scheduledAt = end.add(const Duration(minutes: 5));
    final now = tz.TZDateTime.now(tz.local);
    final zonedTime = tz.TZDateTime.from(scheduledAt, tz.local);
    final id = afterMeetingNotificationId(eventId);

    await _plugin.cancel(id);

    if (!zonedTime.isAfter(now)) return;

    await _plugin.zonedSchedule(
      id,
      event.summary ?? '予定',
      'ミーティング内容を記録してください',
      zonedTime,
      _details,
      payload: _afterMeetingPayload(eventId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelForEvent(String eventId) async {
    await initialize();
    await _plugin.cancel(beforeMeetingNotificationId(eventId));
    await _plugin.cancel(afterMeetingNotificationId(eventId));
  }

  Future<void> resyncCalendarNotifications(
    List<CalendarEvent> events, {
    Set<String> completedRecordEventIds = const {},
  }) async {
    /// 현재 일정 목록 기준으로 캘린더 알림만 선별적으로 재등록한다.
    await initialize();

    final activeEventIds =
        events.map((event) => event.id).whereType<String>().toSet();

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload ?? '';
      if (!payload.startsWith(_beforeMeetingPayloadPrefix) &&
          !payload.startsWith(_afterMeetingPayloadPrefix)) {
        continue;
      }

      final eventId = payload
          .replaceFirst(_beforeMeetingPayloadPrefix, '')
          .replaceFirst(_afterMeetingPayloadPrefix, '');
      if (!activeEventIds.contains(eventId)) {
        await _plugin.cancel(request.id);
      }
    }

    for (final event in events) {
      await scheduleBeforeMeetingReminder(event);

      final eventId = event.id;
      if (eventId == null || completedRecordEventIds.contains(eventId)) {
        if (eventId != null) {
          await _plugin.cancel(afterMeetingNotificationId(eventId));
        }
        continue;
      }

      await scheduleAfterMeetingReminder(event);
    }
  }
}
