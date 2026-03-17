/// Firestore에 저장되는 미팅 기록 문서 모델이다.
class MeetingRecordEntity {
  const MeetingRecordEntity({
    required this.id,
    required this.userId,
    required this.clientId,
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
  final String? clientId;
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

  /// Sheets 동기화 상태 변경 시 기존 문서를 기반으로 일부 필드만 교체한다.
  MeetingRecordEntity copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? googleEventId,
    String? calendarId,
    String? title,
    String? companyName,
    String? contactName,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    String? locationName,
    String? summary,
    String? notes,
    String? nextAction,
    DateTime? nextActionDueAt,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sheetsSyncStatus,
    DateTime? sheetsLastAttemptAt,
    DateTime? sheetsLastSyncedAt,
    String? sheetsErrorCode,
    bool clearSheetsLastSyncedAt = false,
    bool clearSheetsErrorCode = false,
  }) {
    return MeetingRecordEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      googleEventId: googleEventId ?? this.googleEventId,
      calendarId: calendarId ?? this.calendarId,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      scheduledStartAt: scheduledStartAt ?? this.scheduledStartAt,
      scheduledEndAt: scheduledEndAt ?? this.scheduledEndAt,
      locationName: locationName ?? this.locationName,
      summary: summary ?? this.summary,
      notes: notes ?? this.notes,
      nextAction: nextAction ?? this.nextAction,
      nextActionDueAt: nextActionDueAt ?? this.nextActionDueAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sheetsSyncStatus: sheetsSyncStatus ?? this.sheetsSyncStatus,
      sheetsLastAttemptAt: sheetsLastAttemptAt ?? this.sheetsLastAttemptAt,
      sheetsLastSyncedAt: clearSheetsLastSyncedAt
          ? null
          : sheetsLastSyncedAt ?? this.sheetsLastSyncedAt,
      sheetsErrorCode: clearSheetsErrorCode
          ? null
          : sheetsErrorCode ?? this.sheetsErrorCode,
    );
  }
}
