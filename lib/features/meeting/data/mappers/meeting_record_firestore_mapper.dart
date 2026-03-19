/// `meeting_records` 문서와 엔티티 간 변환을 담당한다.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';

abstract final class MeetingRecordFirestoreMapper {
  static Map<String, dynamic> toUpsertMap(
    MeetingRecordEntity record, {
    required Timestamp now,
  }) {
    return {
      'userId': record.userId,
      'clientId': record.clientId,
      'googleEventId': record.googleEventId,
      'calendarId': record.calendarId,
      'title': record.title,
      'companyName': record.companyName,
      'contactName': record.contactName,
      'scheduledStartAt': _toTimestamp(record.scheduledStartAt),
      'scheduledEndAt': _toTimestamp(record.scheduledEndAt),
      'locationName': record.locationName,
      'summary': record.summary,
      'notes': record.notes,
      'nextAction': record.nextAction,
      'nextActionDueAt': _toTimestamp(record.nextActionDueAt),
      'status': record.status,
      'sync': {
        'sheets': {
          'status': record.sheetsSyncStatus,
          'lastAttemptAt': _toTimestamp(record.sheetsLastAttemptAt),
          'lastSyncedAt': _toTimestamp(record.sheetsLastSyncedAt),
          'errorCode': record.sheetsErrorCode,
        },
      },
      'createdAt': record.createdAt != null ? _toTimestamp(record.createdAt) : now,
      'updatedAt': now,
    };
  }

  static Map<String, dynamic> toSheetsSyncUpdateMap({
    required String status,
    required DateTime attemptedAt,
    required DateTime? syncedAt,
    required String? errorCode,
  }) {
    return {
      'sync': {
        'sheets': {
          'status': status,
          'lastAttemptAt': _toTimestamp(attemptedAt),
          'lastSyncedAt': _toTimestamp(syncedAt),
          'errorCode': errorCode,
        },
      },
      'updatedAt': Timestamp.now(),
    };
  }

  static MeetingRecordEntity fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final sync = Map<String, dynamic>.from(data['sync'] as Map? ?? const {});
    final sheets = Map<String, dynamic>.from(
      sync['sheets'] as Map? ?? const {},
    );

    return MeetingRecordEntity(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      clientId: data['clientId'] as String?,
      googleEventId: data['googleEventId'] as String? ?? '',
      calendarId: data['calendarId'] as String? ?? 'primary',
      title: data['title'] as String? ?? '',
      companyName: data['companyName'] as String?,
      contactName: data['contactName'] as String?,
      scheduledStartAt: _fromTimestamp(data['scheduledStartAt']),
      scheduledEndAt: _fromTimestamp(data['scheduledEndAt']),
      locationName: data['locationName'] as String?,
      summary: data['summary'] as String? ?? '',
      notes: data['notes'] as String?,
      nextAction: data['nextAction'] as String?,
      nextActionDueAt: _fromTimestamp(data['nextActionDueAt']),
      status: data['status'] as String? ?? 'draft',
      createdAt: _fromTimestamp(data['createdAt']),
      updatedAt: _fromTimestamp(data['updatedAt']),
      sheetsSyncStatus: sheets['status'] as String? ?? 'pending',
      sheetsLastAttemptAt: _fromTimestamp(sheets['lastAttemptAt']),
      sheetsLastSyncedAt: _fromTimestamp(sheets['lastSyncedAt']),
      sheetsErrorCode: sheets['errorCode'] as String?,
    );
  }

  static Timestamp? _toTimestamp(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }

  static DateTime? _fromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
