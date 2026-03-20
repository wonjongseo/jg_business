import 'package:jg_business/shared/models/location_coordinate.dart';

/// 좌표 해석을 지원하지 않는 플랫폼용 기본 구현이다.
class LocationResolverService {
  /// 지원하지 않는 플랫폼에서는 항상 null 을 반환한다.
  Future<LocationCoordinate?> resolve(String? address) async {
    return null;
  }
}
