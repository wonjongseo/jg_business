/// 일정별 영업 상태를 Firestore `meeting_status` 컬렉션에 저장한다.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jg_business/features/meeting/data/models/meeting_status_entity.dart';

class MeetingStatusFirestoreDataSource {
  MeetingStatusFirestoreDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('meeting_status');

  Future<void> upsertMeetingStatus(MeetingStatusEntity status) async {
    final now = Timestamp.now();

    await _collection.doc(status.id).set({
      'userId': status.userId,
      'googleEventId': status.googleEventId,
      'calendarId': status.calendarId,
      'scheduledStartAt': _toTimestamp(status.scheduledStartAt),
      'scheduledEndAt': _toTimestamp(status.scheduledEndAt),
      'locationName': status.locationName,
      'locationGeo': {
        'latitude': status.locationLatitude,
        'longitude': status.locationLongitude,
      },
      'recordStatus': status.recordStatus,
      'reminderStatus': {
        'beforeMeeting': status.beforeMeetingReminderStatus,
        'afterMeeting': status.afterMeetingReminderStatus,
        'leaveLocation': status.leaveLocationReminderStatus,
      },
      'followUpStatus': status.followUpStatus,
      'lastNotificationAt': _toTimestamp(status.lastNotificationAt),
      'lastSyncedAt': _toTimestamp(status.lastSyncedAt),
      'createdAt': status.createdAt != null ? _toTimestamp(status.createdAt) : now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<List<MeetingStatusEntity>> fetchByGoogleEventIds({
    required String userId,
    required List<String> googleEventIds,
  }) async {
    if (googleEventIds.isEmpty) return const [];

    final results = <MeetingStatusEntity>[];
    for (var i = 0; i < googleEventIds.length; i += 10) {
      final chunk = googleEventIds.sublist(
        i,
        i + 10 > googleEventIds.length ? googleEventIds.length : i + 10,
      );

      final query = await _collection
          .where('userId', isEqualTo: userId)
          .where('googleEventId', whereIn: chunk)
          .get();

      results.addAll(query.docs.map(_fromDoc));
    }

    return results;
  }

  Timestamp? _toTimestamp(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }

  DateTime? _fromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  MeetingStatusEntity _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final reminderStatus = Map<String, dynamic>.from(
      data['reminderStatus'] as Map? ?? const {},
    );
    final locationGeo = Map<String, dynamic>.from(
      data['locationGeo'] as Map? ?? const {},
    );

    return MeetingStatusEntity(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      googleEventId: data['googleEventId'] as String? ?? '',
      calendarId: data['calendarId'] as String? ?? 'primary',
      scheduledStartAt: _fromTimestamp(data['scheduledStartAt']),
      scheduledEndAt: _fromTimestamp(data['scheduledEndAt']),
      locationName: data['locationName'] as String?,
      locationLatitude: (locationGeo['latitude'] as num?)?.toDouble(),
      locationLongitude: (locationGeo['longitude'] as num?)?.toDouble(),
      recordStatus: data['recordStatus'] as String? ?? 'idle',
      beforeMeetingReminderStatus:
          reminderStatus['beforeMeeting'] as String? ?? 'idle',
      afterMeetingReminderStatus:
          reminderStatus['afterMeeting'] as String? ?? 'idle',
      leaveLocationReminderStatus:
          reminderStatus['leaveLocation'] as String? ?? 'idle',
      followUpStatus: data['followUpStatus'] as String? ?? 'idle',
      lastNotificationAt: _fromTimestamp(data['lastNotificationAt']),
      lastSyncedAt: _fromTimestamp(data['lastSyncedAt']),
      createdAt: _fromTimestamp(data['createdAt']),
      updatedAt: _fromTimestamp(data['updatedAt']),
    );
  }
}
