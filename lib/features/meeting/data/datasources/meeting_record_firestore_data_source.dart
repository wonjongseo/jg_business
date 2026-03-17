/// 미팅 기록을 Firestore `meeting_records` 컬렉션에 저장한다.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';

class MeetingRecordFirestoreDataSource {
  MeetingRecordFirestoreDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('meeting_records');

  Future<void> upsertMeetingRecord(MeetingRecordEntity record) async {
    final now = Timestamp.now();

    await _collection.doc(record.id).set({
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
    }, SetOptions(merge: true));
  }

  Future<void> deleteMeetingRecord(String recordId) async {
    await _collection.doc(recordId).delete();
  }

  Future<void> updateSheetsSyncState({
    required String recordId,
    required String status,
    required DateTime attemptedAt,
    DateTime? syncedAt,
    String? errorCode,
  }) async {
    await _collection.doc(recordId).set({
      'sync': {
        'sheets': {
          'status': status,
          'lastAttemptAt': _toTimestamp(attemptedAt),
          'lastSyncedAt': _toTimestamp(syncedAt),
          'errorCode': errorCode,
        },
      },
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<MeetingRecordEntity?> fetchByGoogleEventId({
    required String userId,
    required String googleEventId,
  }) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .where('googleEventId', isEqualTo: googleEventId)
        .limit(1)
        .get();

    final doc = query.docs.isNotEmpty ? query.docs.first : null;
    if (doc == null) return null;
    return _fromDoc(doc);
  }

  Future<List<MeetingRecordEntity>> fetchRecentByUser(String userId) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .limit(50)
        .get();

    final records = query.docs.map(_fromDoc).toList();
    records.sort((a, b) {
      final left = a.updatedAt ?? a.scheduledStartAt ?? DateTime(1970);
      final right = b.updatedAt ?? b.scheduledStartAt ?? DateTime(1970);
      return right.compareTo(left);
    });
    return records.take(20).toList();
  }

  MeetingRecordEntity _fromDoc(
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

  Timestamp? _toTimestamp(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }

  DateTime? _fromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
