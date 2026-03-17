/// 캘린더 이벤트와 Firestore meeting_status 상태를 맞추는 리포지토리다.
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/meeting/data/datasources/meeting_status_firestore_data_source.dart';
import 'package:jg_business/features/meeting/data/models/meeting_status_entity.dart';

class MeetingStatusRepository {
  MeetingStatusRepository({
    required MeetingStatusFirestoreDataSource firestoreDataSource,
  }) : _firestoreDataSource = firestoreDataSource;

  final MeetingStatusFirestoreDataSource _firestoreDataSource;

  Future<List<MeetingStatusEntity>> syncStatusesForEvents({
    required String userId,
    required List<CalendarEvent> events,
  }) async {
    /// 현재 일정 목록을 기준으로 상태 문서를 생성하거나 필요한 값만 보정한다.
    final now = DateTime.now();
    final eventIds = events.map((event) => event.id).whereType<String>().toList();
    if (eventIds.isEmpty) return const [];

    final existing = await _firestoreDataSource.fetchByGoogleEventIds(
      userId: userId,
      googleEventIds: eventIds,
    );
    final byEventId = {
      for (final status in existing) status.googleEventId: status,
    };

    final merged = <MeetingStatusEntity>[];
    for (final event in events) {
      final eventId = event.id;
      if (eventId == null || eventId.isEmpty) {
        continue;
      }

      final existingStatus = byEventId[eventId];
      final defaultRecordStatus = _defaultRecordStatus(event);
      final normalizedRecordStatus =
          existingStatus?.recordStatus == 'completed'
              ? 'completed'
              : existingStatus?.recordStatus == 'idle' &&
                      defaultRecordStatus == 'pending'
                  ? 'pending'
                  : existingStatus?.recordStatus ?? defaultRecordStatus;
      final normalizedBeforeMeetingStatus = _beforeMeetingStatus(
        event: event,
        now: now,
      );
      final normalizedAfterMeetingStatus = _afterMeetingStatus(
        event: event,
        recordStatus: normalizedRecordStatus,
        now: now,
      );
      final status = existingStatus == null
          ? MeetingStatusEntity(
              id: '${userId}_$eventId',
              userId: userId,
              googleEventId: eventId,
              calendarId: 'primary',
              scheduledStartAt: event.start?.dateTime ?? event.start?.date,
              scheduledEndAt: event.end?.dateTime ?? event.end?.date,
              locationName: event.location,
              recordStatus: normalizedRecordStatus,
              beforeMeetingReminderStatus: normalizedBeforeMeetingStatus,
              afterMeetingReminderStatus: normalizedAfterMeetingStatus,
              leaveLocationReminderStatus: 'idle',
              followUpStatus: 'idle',
              lastNotificationAt: null,
              lastSyncedAt: DateTime.now(),
              createdAt: null,
              updatedAt: null,
            )
          : MeetingStatusEntity(
              id: existingStatus.id,
              userId: existingStatus.userId,
              googleEventId: existingStatus.googleEventId,
              calendarId: existingStatus.calendarId,
              scheduledStartAt: event.start?.dateTime ?? event.start?.date,
              scheduledEndAt: event.end?.dateTime ?? event.end?.date,
              locationName: event.location,
              recordStatus: normalizedRecordStatus,
              beforeMeetingReminderStatus: normalizedBeforeMeetingStatus,
              afterMeetingReminderStatus: normalizedAfterMeetingStatus,
              leaveLocationReminderStatus:
                  existingStatus.leaveLocationReminderStatus,
              followUpStatus: existingStatus.followUpStatus,
              lastNotificationAt: existingStatus.lastNotificationAt,
              lastSyncedAt: DateTime.now(),
              createdAt: existingStatus.createdAt,
              updatedAt: existingStatus.updatedAt,
            );

      merged.add(status);

      if (existingStatus == null ||
          status.recordStatus != existingStatus.recordStatus ||
          status.beforeMeetingReminderStatus !=
              existingStatus.beforeMeetingReminderStatus ||
          status.afterMeetingReminderStatus !=
              existingStatus.afterMeetingReminderStatus ||
          status.scheduledStartAt != existingStatus.scheduledStartAt ||
          status.scheduledEndAt != existingStatus.scheduledEndAt ||
          status.locationName != existingStatus.locationName) {
        await _firestoreDataSource.upsertMeetingStatus(status);
      }
    }

    return merged;
  }

  Future<void> markRecordCompleted({
    required String userId,
    required CalendarEvent event,
  }) async {
    /// 미팅 기록 저장 후 recordStatus를 completed로 올린다.
    final eventId = event.id;
    if (eventId == null || eventId.isEmpty) return;

    await _firestoreDataSource.upsertMeetingStatus(
      MeetingStatusEntity(
        id: '${userId}_$eventId',
        userId: userId,
        googleEventId: eventId,
        calendarId: 'primary',
        scheduledStartAt: event.start?.dateTime ?? event.start?.date,
        scheduledEndAt: event.end?.dateTime ?? event.end?.date,
        locationName: event.location,
        recordStatus: 'completed',
        beforeMeetingReminderStatus: 'done',
        afterMeetingReminderStatus: 'done',
        leaveLocationReminderStatus: 'idle',
        followUpStatus: 'idle',
        lastNotificationAt: null,
        lastSyncedAt: DateTime.now(),
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  Future<void> markRecordDeleted({
    required String userId,
    required CalendarEvent event,
  }) async {
    final eventId = event.id;
    if (eventId == null || eventId.isEmpty) return;

    final recordStatus = _defaultRecordStatus(event);
    await _firestoreDataSource.upsertMeetingStatus(
      MeetingStatusEntity(
        id: '${userId}_$eventId',
        userId: userId,
        googleEventId: eventId,
        calendarId: 'primary',
        scheduledStartAt: event.start?.dateTime ?? event.start?.date,
        scheduledEndAt: event.end?.dateTime ?? event.end?.date,
        locationName: event.location,
        recordStatus: recordStatus,
        beforeMeetingReminderStatus: _beforeMeetingStatus(
          event: event,
          now: DateTime.now(),
        ),
        afterMeetingReminderStatus: _afterMeetingStatus(
          event: event,
          recordStatus: recordStatus,
          now: DateTime.now(),
        ),
        leaveLocationReminderStatus: 'idle',
        followUpStatus: 'idle',
        lastNotificationAt: null,
        lastSyncedAt: DateTime.now(),
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  String _defaultRecordStatus(CalendarEvent event) {
    final end = event.end?.dateTime ?? event.end?.date;
    if (end != null && end.isBefore(DateTime.now())) {
      return 'pending';
    }
    return 'idle';
  }

  String _beforeMeetingStatus({
    required CalendarEvent event,
    required DateTime now,
  }) {
    final start = event.start?.dateTime;
    if (start == null || (event.start?.isAllDay ?? false)) {
      return 'idle';
    }

    final reminderAt = start.subtract(const Duration(minutes: 1));
    return reminderAt.isAfter(now) ? 'scheduled' : 'done';
  }

  String _afterMeetingStatus({
    required CalendarEvent event,
    required String recordStatus,
    required DateTime now,
  }) {
    final end = event.end?.dateTime;
    if (end == null || (event.end?.isAllDay ?? false)) {
      return 'idle';
    }
    if (recordStatus == 'completed') {
      return 'done';
    }

    final reminderAt = end.add(const Duration(minutes: 5));
    return reminderAt.isAfter(now) ? 'scheduled' : 'due';
  }
}
