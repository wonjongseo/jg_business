/// 명함 OCR 원본과 추출 결과를 저장하는 Firestore 문서 모델이다.
class BusinessCardEntity {
  const BusinessCardEntity({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.imagePath,
    required this.rawText,
    required this.companyName,
    required this.contactName,
    required this.phoneNumber,
    required this.email,
    required this.notes,
    required this.ocrStatus,
    required this.linkedClientId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String sourceType;
  final String? imagePath;
  final String rawText;
  final String? companyName;
  final String? contactName;
  final String? phoneNumber;
  final String? email;
  final String? notes;
  final String ocrStatus;
  final String? linkedClientId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
