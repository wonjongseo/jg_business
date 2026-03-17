/// 고객 정보를 Firestore `clients` 컬렉션에 저장한다.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jg_business/features/client/data/models/client_entity.dart';

class ClientFirestoreDataSource {
  ClientFirestoreDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('clients');

  Future<void> upsertClient(ClientEntity client) async {
    final now = Timestamp.now();
    await _collection.doc(client.id).set({
      'userId': client.userId,
      'companyName': client.companyName,
      'contactName': client.contactName,
      'phoneNumber': client.phoneNumber,
      'email': client.email,
      'notes': client.notes,
      'linkedGoogleEventIds': client.linkedGoogleEventIds,
      'lastMeetingAt': _toTimestamp(client.lastMeetingAt),
      'createdAt': client.createdAt != null ? _toTimestamp(client.createdAt) : now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<List<ClientEntity>> fetchByUser(String userId) async {
    final query = await _collection.where('userId', isEqualTo: userId).get();
    final clients = query.docs.map(_fromDoc).toList();
    clients.sort((a, b) {
      final left = a.updatedAt ?? a.lastMeetingAt ?? DateTime(1970);
      final right = b.updatedAt ?? b.lastMeetingAt ?? DateTime(1970);
      return right.compareTo(left);
    });
    return clients;
  }

  Future<ClientEntity?> findById(String clientId) async {
    final doc = await _collection.doc(clientId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  ClientEntity _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ClientEntity(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      contactName: data['contactName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      email: data['email'] as String?,
      notes: data['notes'] as String?,
      linkedGoogleEventIds: List<String>.from(
        data['linkedGoogleEventIds'] as List? ?? const [],
      ),
      lastMeetingAt: _fromTimestamp(data['lastMeetingAt']),
      createdAt: _fromTimestamp(data['createdAt']),
      updatedAt: _fromTimestamp(data['updatedAt']),
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
