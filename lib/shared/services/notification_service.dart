/// 로컬 알림 초기화, 권한 확인, 캘린더 리마인더 재등록을 담당한다.
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/shared/constants/reminder_constants.dart';
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
  static const _afterMeetingSecondPayloadPrefix = 'calendar_after_second:';

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

  int secondAfterMeetingNotificationId(String eventId) {
    return _notificationId('after_second:$eventId');
  }

  String _beforeMeetingPayload(String eventId) =>
      '$_beforeMeetingPayloadPrefix$eventId';

  String _afterMeetingPayload(String eventId) =>
      '$_afterMeetingPayloadPrefix$eventId';

  String _secondAfterMeetingPayload(String eventId) =>
      '$_afterMeetingSecondPayloadPrefix$eventId';

  Future<void> initialize() async {
    /// 알림 플러그인을 1회만 초기화한다.
    if (Platform.isMacOS) return;
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

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
          payload.startsWith(_afterMeetingPayloadPrefix) ||
          payload.startsWith(_afterMeetingSecondPayloadPrefix);
    }).length;
  }

  Future<void> scheduleBeforeMeetingReminder(CalendarEvent event) async {
    /// 단일 일정에 대한 사전 알림을 예약한다.
    if (Platform.isMacOS) return;
    await initialize();

    final eventId = event.id;
    final start = event.start?.dateTime;

    if (eventId == null || start == null) return;
    if (event.start?.isAllDay ?? false) return;

    final scheduledAt = start.subtract(
      const Duration(minutes: ReminderConstants.beforeMeetingMinutes),
    );
    final now = tz.TZDateTime.now(tz.local);
    final zonedTime = tz.TZDateTime.from(scheduledAt, tz.local);
    final id = beforeMeetingNotificationId(eventId);

    await _plugin.cancel(id);

    if (!zonedTime.isAfter(now)) return;

    await _plugin.zonedSchedule(
      id,
      event.summary ?? '予定',
      '間もなく予定があります',
      zonedTime,
      _details,
      payload: _beforeMeetingPayload(eventId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleAfterMeetingReminder(CalendarEvent event) async {
    /// 미팅 종료 후 기록 작성을 유도하는 알림들을 예약한다.
    if (Platform.isMacOS) return;
    await initialize();

    final eventId = event.id;
    final end = event.end?.dateTime;

    if (eventId == null || end == null) return;
    if (event.end?.isAllDay ?? false) return;

    final now = tz.TZDateTime.now(tz.local);
    final reminderMinutes = ReminderConstants.afterMeetingReminderMinutes;
    final reminderIds = [
      afterMeetingNotificationId(eventId),
      secondAfterMeetingNotificationId(eventId),
    ];

    for (final id in reminderIds) {
      await _plugin.cancel(id);
    }

    for (var index = 0; index < reminderMinutes.length; index++) {
      final minute = reminderMinutes[index];
      final scheduledAt = end.add(Duration(minutes: minute));
      final zonedTime = tz.TZDateTime.from(scheduledAt, tz.local);
      if (!zonedTime.isAfter(now)) {
        continue;
      }

      final id =
          index == 0
              ? afterMeetingNotificationId(eventId)
              : secondAfterMeetingNotificationId(eventId);
      final payload =
          index == 0
              ? _afterMeetingPayload(eventId)
              : _secondAfterMeetingPayload(eventId);

      await _plugin.zonedSchedule(
        id,
        event.summary ?? '予定',
        'ミーティング内容を記録してください',
        zonedTime,
        _details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelForEvent(String eventId) async {
    await initialize();
    await _plugin.cancel(beforeMeetingNotificationId(eventId));
    await _plugin.cancel(afterMeetingNotificationId(eventId));
    await _plugin.cancel(secondAfterMeetingNotificationId(eventId));
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
          !payload.startsWith(_afterMeetingPayloadPrefix) &&
          !payload.startsWith(_afterMeetingSecondPayloadPrefix)) {
        continue;
      }

      final eventId = payload
          .replaceFirst(_beforeMeetingPayloadPrefix, '')
          .replaceFirst(_afterMeetingPayloadPrefix, '')
          .replaceFirst(_afterMeetingSecondPayloadPrefix, '');
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
          await _plugin.cancel(secondAfterMeetingNotificationId(eventId));
        }
        continue;
      }

      await scheduleAfterMeetingReminder(event);
    }
  }
}
