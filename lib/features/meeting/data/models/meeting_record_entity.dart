class MeetingRecordEntity {
  const MeetingRecordEntity({
    required this.id,
    required this.userId,
    required this.googleEventId,
    required this.calendarId,
    required this.title,
    required this.companyName,
    required this.contactName,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.locationName,
    required this.summary,
    required this.notes,
    required this.nextAction,
    required this.nextActionDueAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.sheetsSyncStatus,
    required this.sheetsLastAttemptAt,
    required this.sheetsLastSyncedAt,
    required this.sheetsErrorCode,
  });

  final String id;
  final String userId;
  final String googleEventId;
  final String calendarId;
  final String title;
  final String? companyName;
  final String? contactName;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final String? locationName;
  final String summary;
  final String? notes;
  final String? nextAction;
  final DateTime? nextActionDueAt;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String sheetsSyncStatus;
  final DateTime? sheetsLastAttemptAt;
  final DateTime? sheetsLastSyncedAt;
  final String? sheetsErrorCode;
}
