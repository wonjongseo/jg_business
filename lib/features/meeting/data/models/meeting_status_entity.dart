/// 일정별 기록 상태와 리마인더 상태를 표현하는 Firestore 모델이다.
class MeetingStatusEntity {
  const MeetingStatusEntity({
    required this.id,
    required this.userId,
    required this.googleEventId,
    required this.calendarId,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.locationName,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.recordStatus,
    required this.beforeMeetingReminderStatus,
    required this.afterMeetingReminderStatus,
    required this.leaveLocationReminderStatus,
    required this.followUpStatus,
    required this.lastNotificationAt,
    required this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String googleEventId;
  final String calendarId;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final String? locationName;
  final double? locationLatitude;
  final double? locationLongitude;
  final String recordStatus;
  final String beforeMeetingReminderStatus;
  final String afterMeetingReminderStatus;
  final String leaveLocationReminderStatus;
  final String followUpStatus;
  final DateTime? lastNotificationAt;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
