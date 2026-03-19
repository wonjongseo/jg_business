/// 미팅 기록 저장소 인터페이스 역할을 하는 얇은 리포지토리다.
import 'package:jg_business/features/meeting/data/datasources/meeting_record_firestore_data_source.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';

class MeetingRecordRepository {
  MeetingRecordRepository({
    required MeetingRecordFirestoreDataSource firestoreDataSource,
  }) : _firestoreDataSource = firestoreDataSource;

  final MeetingRecordFirestoreDataSource _firestoreDataSource;

  Future<void> save(MeetingRecordEntity record) {
    return _firestoreDataSource.upsertMeetingRecord(record);
  }

  Future<void> delete(String recordId) {
    return _firestoreDataSource.deleteMeetingRecord(recordId);
  }

  Future<void> updateSheetsSyncState({
    required String recordId,
    required String status,
    required DateTime attemptedAt,
    DateTime? syncedAt,
    String? errorCode,
  }) {
    return _firestoreDataSource.updateSheetsSyncState(
      recordId: recordId,
      status: status,
      attemptedAt: attemptedAt,
      syncedAt: syncedAt,
      errorCode: errorCode,
    );
  }

  Future<MeetingRecordEntity?> findByGoogleEventId({
    required String userId,
    required String googleEventId,
  }) {
    return _firestoreDataSource.fetchByGoogleEventId(
      userId: userId,
      googleEventId: googleEventId,
    );
  }

  Future<List<MeetingRecordEntity>> recentByUser(String userId) {
    return _firestoreDataSource.fetchRecentByUser(userId);
  }

  Future<List<MeetingRecordEntity>> byClientId({
    required String userId,
    required String clientId,
  }) {
    return _firestoreDataSource.fetchByClientId(
      userId: userId,
      clientId: clientId,
    );
  }
}
