/// 고객 생성/조회와 미팅 연결을 담당한다.
import 'package:jg_business/features/client/data/datasources/client_firestore_data_source.dart';
import 'package:jg_business/features/client/data/models/client_entity.dart';

class ClientRepository {
  ClientRepository({
    required ClientFirestoreDataSource firestoreDataSource,
  }) : _firestoreDataSource = firestoreDataSource;

  final ClientFirestoreDataSource _firestoreDataSource;

  Future<List<ClientEntity>> fetchByUser(String userId) {
    return _firestoreDataSource.fetchByUser(userId);
  }

  Future<ClientEntity?> findById(String clientId) {
    return _firestoreDataSource.findById(clientId);
  }

  Future<ClientEntity?> findExactMatch({
    required String userId,
    required String companyName,
    required String contactName,
  }) async {
    final normalizedCompany = companyName.trim().toLowerCase();
    final normalizedContact = contactName.trim().toLowerCase();
    if (normalizedCompany.isEmpty) return null;

    final clients = await fetchByUser(userId);
    for (final client in clients) {
      final companyMatches = client.companyName.trim().toLowerCase() == normalizedCompany;
      final contactMatches =
          (client.contactName ?? '').trim().toLowerCase() == normalizedContact;
      if (companyMatches && (normalizedContact.isEmpty || contactMatches)) {
        return client;
      }
    }
    return null;
  }

  Future<ClientEntity> upsertFromMeeting({
    required String userId,
    String? selectedClientId,
    required String companyName,
    required String contactName,
    required String googleEventId,
    required DateTime? meetingAt,
  }) async {
    final trimmedCompany = companyName.trim();
    if (trimmedCompany.isEmpty) {
      throw StateError('missing_company_name');
    }

    final existing = selectedClientId != null && selectedClientId.isNotEmpty
        ? await findById(selectedClientId)
        : await findExactMatch(
            userId: userId,
            companyName: trimmedCompany,
            contactName: contactName,
          );

    final linkedEvents = {
      ...?existing?.linkedGoogleEventIds,
      googleEventId,
    }.toList();

    final client = ClientEntity(
      id: existing?.id ?? _buildClientId(userId, trimmedCompany, contactName),
      userId: userId,
      companyName: trimmedCompany,
      contactName: contactName.trim().isEmpty ? null : contactName.trim(),
      phoneNumber: existing?.phoneNumber,
      email: existing?.email,
      notes: existing?.notes,
      linkedGoogleEventIds: linkedEvents,
      lastMeetingAt: meetingAt,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );

    await _firestoreDataSource.upsertClient(client);
    return client;
  }

  Future<ClientEntity> upsertFromBusinessCard({
    required String userId,
    required String companyName,
    required String contactName,
    required String phoneNumber,
    required String email,
    required String notes,
  }) async {
    final existing = await findExactMatch(
      userId: userId,
      companyName: companyName,
      contactName: contactName,
    );

    final client = ClientEntity(
      id: existing?.id ?? _buildClientId(userId, companyName.trim(), contactName),
      userId: userId,
      companyName: companyName.trim(),
      contactName: contactName.trim().isEmpty ? null : contactName.trim(),
      phoneNumber: phoneNumber.trim().isEmpty ? existing?.phoneNumber : phoneNumber.trim(),
      email: email.trim().isEmpty ? existing?.email : email.trim(),
      notes: notes.trim().isEmpty ? existing?.notes : notes.trim(),
      linkedGoogleEventIds: existing?.linkedGoogleEventIds ?? const [],
      lastMeetingAt: existing?.lastMeetingAt,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );

    await _firestoreDataSource.upsertClient(client);
    return client;
  }

  Future<ClientEntity> updateClient({
    required ClientEntity client,
    required String companyName,
    required String contactName,
    required String phoneNumber,
    required String email,
    required String notes,
  }) async {
    final trimmedCompany = companyName.trim();
    if (trimmedCompany.isEmpty) {
      throw StateError('missing_company_name');
    }

    final updatedClient = client.copyWith(
      companyName: trimmedCompany,
      contactName: contactName.trim().isEmpty ? null : contactName.trim(),
      phoneNumber: phoneNumber.trim().isEmpty ? null : phoneNumber.trim(),
      email: email.trim().isEmpty ? null : email.trim(),
      notes: notes.trim().isEmpty ? null : notes.trim(),
    );

    await _firestoreDataSource.upsertClient(updatedClient);
    return updatedClient;
  }

  String _buildClientId(String userId, String companyName, String contactName) {
    final base = '$userId|$companyName|$contactName'
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return base.isEmpty ? '${userId}_client' : base;
  }
}
