/// Firestore에 저장되는 고객 문서 모델이다.
class ClientEntity {
  const ClientEntity({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.contactName,
    required this.phoneNumber,
    required this.email,
    required this.notes,
    required this.linkedGoogleEventIds,
    required this.lastMeetingAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String companyName;
  final String? contactName;
  final String? phoneNumber;
  final String? email;
  final String? notes;
  final List<String> linkedGoogleEventIds;
  final DateTime? lastMeetingAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    if (contactName != null && contactName!.trim().isNotEmpty) {
      return '$companyName / ${contactName!.trim()}';
    }
    return companyName;
  }

  ClientEntity copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? notes,
    List<String>? linkedGoogleEventIds,
    DateTime? lastMeetingAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      linkedGoogleEventIds: linkedGoogleEventIds ?? this.linkedGoogleEventIds,
      lastMeetingAt: lastMeetingAt ?? this.lastMeetingAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
