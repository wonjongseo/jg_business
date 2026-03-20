import 'package:jg_business/shared/models/location_permission_info.dart';

/// 앱 외 플랫폼에서는 위치 권한 기능을 노출하지 않는다.
class LocationPermissionService {
  /// 지원하지 않는 플랫폼이므로 고정된 기본 상태를 반환한다.
  Future<LocationPermissionInfo> getStatus() async {
    return const LocationPermissionInfo(
      serviceEnabled: false,
      permission: 'unsupported',
    );
  }

  /// 웹/기타 플랫폼에서는 실제 권한 요청을 하지 않는다.
  Future<LocationPermissionInfo> requestWhenInUsePermission() {
    return getStatus();
  }

  /// 웹/기타 플랫폼에서는 실제 권한 요청을 하지 않는다.
  Future<LocationPermissionInfo> requestAlwaysPermission() {
    return getStatus();
  }

  /// 시스템 위치 설정을 열 수 없는 플랫폼이다.
  Future<bool> openLocationSettings() async {
    return false;
  }

  /// 앱 설정을 열 수 없는 플랫폼이다.
  Future<bool> openAppSettings() async {
    return false;
  }
}
