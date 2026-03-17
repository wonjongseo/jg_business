/// 명함 OCR 초안과 확정 결과를 Firestore `business_cards`에 저장한다.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jg_business/features/business_card/data/models/business_card_entity.dart';

class BusinessCardFirestoreDataSource {
  BusinessCardFirestoreDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('business_cards');

  Future<void> saveBusinessCard(BusinessCardEntity card) async {
    final now = Timestamp.now();
    await _collection.doc(card.id).set({
      'userId': card.userId,
      'sourceType': card.sourceType,
      'imagePath': card.imagePath,
      'rawText': card.rawText,
      'companyName': card.companyName,
      'contactName': card.contactName,
      'phoneNumber': card.phoneNumber,
      'email': card.email,
      'notes': card.notes,
      'ocrStatus': card.ocrStatus,
      'linkedClientId': card.linkedClientId,
      'createdAt': card.createdAt != null ? Timestamp.fromDate(card.createdAt!) : now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }
}
