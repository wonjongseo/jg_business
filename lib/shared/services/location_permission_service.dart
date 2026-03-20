/// 플랫폼별 위치 권한/설정 제어 구현을 분기한다.
export 'location_permission_service_stub.dart'
    if (dart.library.io) 'location_permission_service_app.dart';
