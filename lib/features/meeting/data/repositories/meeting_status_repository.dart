/// 캘린더 이벤트와 Firestore meeting_status 상태를 맞추는 리포지토리다.
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/meeting/data/datasources/meeting_status_firestore_data_source.dart';
import 'package:jg_business/features/meeting/data/models/meeting_status_entity.dart';
import 'package:jg_business/shared/constants/reminder_constants.dart';
import 'package:jg_business/shared/models/location_coordinate.dart';
import 'package:jg_business/shared/services/location_resolver_service.dart';

class MeetingStatusRepository {
  MeetingStatusRepository({
    required MeetingStatusFirestoreDataSource firestoreDataSource,
    required LocationResolverService locationResolverService,
  }) : _firestoreDataSource = firestoreDataSource,
       _locationResolverService = locationResolverService;

  final MeetingStatusFirestoreDataSource _firestoreDataSource;
  final LocationResolverService _locationResolverService;

  /// 현재 캘린더 이벤트 목록을 기준으로 `meeting_status` 문서를 동기화한다.
  ///
  /// 처리 순서:
  /// 1. 기존 Firestore 상태 문서를 eventId 기준으로 찾는다.
  /// 2. 장소 문자열이 있으면 좌표를 해석하거나 기존 좌표를 재사용한다.
  /// 3. 기록 상태와 시간 기반 리마인더 상태를 현재 시각 기준으로 계산한다.
  /// 4. 달라진 값이 있으면 Firestore에 upsert 한다.
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

      // 이미 저장된 상태 문서가 있으면 좌표/상태 보정의 기준으로 사용한다.
      final existingStatus = byEventId[eventId];
      final coordinate = await _resolveCoordinate(
        locationName: event.location,
        existingStatus: existingStatus,
      );
      // 일정이 이미 끝났다면 기본 상태는 기록 대기(pending)다.
      final defaultRecordStatus = _defaultRecordStatus(event);
      final normalizedRecordStatus =
          existingStatus?.recordStatus == 'completed'
              ? 'completed'
              : existingStatus?.recordStatus == 'idle' &&
                      defaultRecordStatus == 'pending'
                  ? 'pending'
                  : existingStatus?.recordStatus ?? defaultRecordStatus;
      // 리마인더 상태는 현재 시각을 기준으로 다시 계산한다.
      final normalizedBeforeMeetingStatus = _beforeMeetingStatus(
        event: event,
        now: now,
      );
      final normalizedAfterMeetingStatus = _afterMeetingStatus(
        event: event,
        recordStatus: normalizedRecordStatus,
        now: now,
      );
      // Firestore에 저장할 최종 상태 문서를 만든다.
      final status = existingStatus == null
          ? MeetingStatusEntity(
              id: '${userId}_$eventId',
              userId: userId,
              googleEventId: eventId,
              calendarId: 'primary',
              scheduledStartAt: event.start?.dateTime ?? event.start?.date,
              scheduledEndAt: event.end?.dateTime ?? event.end?.date,
              locationName: event.location,
              locationLatitude: coordinate?.latitude,
              locationLongitude: coordinate?.longitude,
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
              locationLatitude: coordinate?.latitude,
              locationLongitude: coordinate?.longitude,
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

      // 의미 있는 값이 바뀌었을 때만 Firestore에 다시 저장한다.
      if (existingStatus == null ||
          status.recordStatus != existingStatus.recordStatus ||
          status.beforeMeetingReminderStatus !=
              existingStatus.beforeMeetingReminderStatus ||
          status.afterMeetingReminderStatus !=
              existingStatus.afterMeetingReminderStatus ||
          status.scheduledStartAt != existingStatus.scheduledStartAt ||
          status.scheduledEndAt != existingStatus.scheduledEndAt ||
          status.locationName != existingStatus.locationName ||
          status.locationLatitude != existingStatus.locationLatitude ||
          status.locationLongitude != existingStatus.locationLongitude) {
        await _firestoreDataSource.upsertMeetingStatus(status);
      }
    }

    return merged;
  }

  Future<void> markRecordCompleted({
    required String userId,
    required CalendarEvent event,
  }) async {
    /// 미팅 기록 저장 후 `meeting_status`도 completed 상태로 맞춘다.
    /// 이 시점에도 위치 좌표를 같이 남겨 이후 geofence 등록에 재사용한다.
    final eventId = event.id;
    if (eventId == null || eventId.isEmpty) return;

    final coordinate = await _resolveCoordinate(locationName: event.location);
    await _firestoreDataSource.upsertMeetingStatus(
      MeetingStatusEntity(
        id: '${userId}_$eventId',
        userId: userId,
        googleEventId: eventId,
        calendarId: 'primary',
        scheduledStartAt: event.start?.dateTime ?? event.start?.date,
        scheduledEndAt: event.end?.dateTime ?? event.end?.date,
        locationName: event.location,
        locationLatitude: coordinate?.latitude,
        locationLongitude: coordinate?.longitude,
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
    /// 기록만 삭제했을 때는 일정을 지우는 것이 아니라
    /// 현재 시각 기준으로 pending/idle 상태로 되돌린다.
    final eventId = event.id;
    if (eventId == null || eventId.isEmpty) return;

    final recordStatus = _defaultRecordStatus(event);
    final coordinate = await _resolveCoordinate(locationName: event.location);
    await _firestoreDataSource.upsertMeetingStatus(
      MeetingStatusEntity(
        id: '${userId}_$eventId',
        userId: userId,
        googleEventId: eventId,
        calendarId: 'primary',
        scheduledStartAt: event.start?.dateTime ?? event.start?.date,
        scheduledEndAt: event.end?.dateTime ?? event.end?.date,
        locationName: event.location,
        locationLatitude: coordinate?.latitude,
        locationLongitude: coordinate?.longitude,
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
    /// 종료한 일정이면 기록 대기, 아직 안 끝났으면 idle 상태다.
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
    /// 종일 일정은 시간 기반 미팅 리마인더 대상에서 제외한다.
    final start = event.start?.dateTime;
    if (start == null || (event.start?.isAllDay ?? false)) {
      return 'idle';
    }

    final reminderAt = start.subtract(
      const Duration(minutes: ReminderConstants.beforeMeetingMinutes),
    );
    return reminderAt.isAfter(now) ? 'scheduled' : 'done';
  }

  String _afterMeetingStatus({
    required CalendarEvent event,
    required String recordStatus,
    required DateTime now,
  }) {
    /// 기록이 완료된 일정은 사후 리마인더를 더 이상 보낼 필요가 없다.
    final end = event.end?.dateTime;
    if (end == null || (event.end?.isAllDay ?? false)) {
      return 'idle';
    }
    if (recordStatus == 'completed') {
      return 'done';
    }

    final reminderAt = end.add(
      const Duration(
        minutes: ReminderConstants.primaryAfterMeetingReminderMinute,
      ),
    );
    return reminderAt.isAfter(now) ? 'scheduled' : 'due';
  }

  Future<LocationCoordinate?> _resolveCoordinate({
    required String? locationName,
    MeetingStatusEntity? existingStatus,
  }) async {
    /// 위치 문자열이 없으면 geofence 기준 좌표도 만들 수 없다.
    final normalized = locationName?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    // 같은 주소로 저장된 기존 좌표가 있으면 geocoding을 다시 하지 않는다.
    if (existingStatus != null &&
        existingStatus.locationName?.trim() == normalized &&
        existingStatus.locationLatitude != null &&
        existingStatus.locationLongitude != null) {
      return LocationCoordinate(
        latitude: existingStatus.locationLatitude!,
        longitude: existingStatus.locationLongitude!,
      );
    }

    // 기존 좌표가 없을 때만 실제 주소 -> 좌표 해석을 시도한다.
    return _locationResolverService.resolve(normalized);
  }
}
