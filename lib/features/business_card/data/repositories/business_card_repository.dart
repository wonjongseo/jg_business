/// 명함 OCR 결과를 저장하는 리포지토리다.
import 'package:jg_business/features/business_card/data/datasources/business_card_firestore_data_source.dart';
import 'package:jg_business/features/business_card/data/models/business_card_entity.dart';

class BusinessCardRepository {
  BusinessCardRepository({
    required BusinessCardFirestoreDataSource firestoreDataSource,
  }) : _firestoreDataSource = firestoreDataSource;

  final BusinessCardFirestoreDataSource _firestoreDataSource;

  Future<void> save(BusinessCardEntity card) {
    return _firestoreDataSource.saveBusinessCard(card);
  }
}
