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
}
