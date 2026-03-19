/// 미팅 기록을 Firestore `meeting_records` 컬렉션에 저장한다.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jg_business/features/meeting/data/mappers/meeting_record_firestore_mapper.dart';
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

    await _collection.doc(record.id).set(
      MeetingRecordFirestoreMapper.toUpsertMap(record, now: now),
      SetOptions(merge: true),
    );
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
    await _collection.doc(recordId).set(
      MeetingRecordFirestoreMapper.toSheetsSyncUpdateMap(
        status: status,
        attemptedAt: attemptedAt,
        syncedAt: syncedAt,
        errorCode: errorCode,
      ),
      SetOptions(merge: true),
    );
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
    return MeetingRecordFirestoreMapper.fromDoc(doc);
  }

  Future<List<MeetingRecordEntity>> fetchRecentByUser(String userId) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .limit(50)
        .get();

    final records = query.docs.map(MeetingRecordFirestoreMapper.fromDoc).toList();
    records.sort((a, b) {
      final left = a.updatedAt ?? a.scheduledStartAt ?? DateTime(1970);
      final right = b.updatedAt ?? b.scheduledStartAt ?? DateTime(1970);
      return right.compareTo(left);
    });
    return records.take(20).toList();
  }

  Future<List<MeetingRecordEntity>> fetchByClientId({
    required String userId,
    required String clientId,
  }) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .where('clientId', isEqualTo: clientId)
        .limit(50)
        .get();

    final records = query.docs.map(MeetingRecordFirestoreMapper.fromDoc).toList();
    records.sort((a, b) {
      final left = a.updatedAt ?? a.scheduledStartAt ?? DateTime(1970);
      final right = b.updatedAt ?? b.scheduledStartAt ?? DateTime(1970);
      return right.compareTo(left);
    });
    return records.take(20).toList();
  }
}
