import 'package:geolocator/geolocator.dart';
import 'package:jg_business/shared/models/location_permission_info.dart';

/// 위치 서비스 활성화 상태와 권한 상태를 앱에서 관리한다.
class LocationPermissionService {
  /// 현재 위치 서비스 ON/OFF 와 권한 수준을 한 번에 읽는다.
  Future<LocationPermissionInfo> getStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    return LocationPermissionInfo(
      serviceEnabled: serviceEnabled,
      permission: _mapPermission(permission),
    );
  }

  /// 우선 foreground 권한을 요청한다.
  Future<LocationPermissionInfo> requestWhenInUsePermission() async {
    await Geolocator.requestPermission();
    return getStatus();
  }

  /// 이탈 알림까지 쓰려면 항상 허용 상태가 필요하므로 별도 요청 경로를 둔다.
  Future<LocationPermissionInfo> requestAlwaysPermission() async {
    final current = await Geolocator.checkPermission();
    if (current == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    await Geolocator.requestPermission();
    return getStatus();
  }

  /// 위치 서비스 설정 화면을 연다.
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  /// 앱 권한 설정 화면을 연다.
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  /// Geolocator enum 을 UI 친화적인 문자열로 바꾼다.
  String _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
        return 'always';
      case LocationPermission.whileInUse:
        return 'whileInUse';
      case LocationPermission.denied:
        return 'denied';
      case LocationPermission.deniedForever:
        return 'deniedForever';
      case LocationPermission.unableToDetermine:
        return 'unknown';
    }
  }
}
