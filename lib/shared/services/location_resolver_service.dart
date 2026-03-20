/// 플랫폼별 주소 -> 좌표 해석 구현을 분기한다.
export 'location_resolver_service_stub.dart'
    if (dart.library.io) 'location_resolver_service_app.dart';
