import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS 네이티브 geofence 코드와 통신하는 Flutter 래퍼다.
/// 아직 실제 화면에 연결하지 않고, 서비스 레이어에서 직접 호출할 수 있게만 둔다.
class IosGeofenceChannelService {
  static const MethodChannel _channel = MethodChannel('jg_business/geofence');

  /// 현재 실행 환경이 iOS 네이티브 geofence 채널을 지원하는지 확인한다.
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// 사용 중 권한만 먼저 요청한다.
  Future<void> requestWhenInUsePermission() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('requestWhenInUsePermission');
  }

  /// 백그라운드 geofence 용 항상 허용 권한을 요청한다.
  Future<void> requestAlwaysPermission() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('requestAlwaysPermission');
  }

  /// iOS 네이티브 CLLocation 권한 상태를 문자열로 읽는다.
  Future<String?> currentAuthorizationStatus() async {
    if (!isSupported) return null;
    return _channel.invokeMethod<String>('currentAuthorizationStatus');
  }

  /// 하나의 원형 geofence 를 등록한다.
  Future<void> registerRegion({
    required String identifier,
    required double latitude,
    required double longitude,
    required double radius,
    required bool notifyOnEntry,
    required bool notifyOnExit,
  }) async {
    if (!isSupported) return;

    await _channel.invokeMethod<void>('registerRegion', {
      'identifier': identifier,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'notifyOnEntry': notifyOnEntry,
      'notifyOnExit': notifyOnExit,
    });
  }

  /// 특정 geofence 를 제거한다.
  Future<void> unregisterRegion(String identifier) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('unregisterRegion', {
      'identifier': identifier,
    });
  }

  /// 등록된 모든 geofence 를 제거한다.
  Future<void> unregisterAllRegions() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('unregisterAllRegions');
  }

  /// 현재 iOS 네이티브에 등록된 geofence identifier 목록을 읽는다.
  Future<List<String>> monitoredRegionIdentifiers() async {
    if (!isSupported) return const [];

    final result = await _channel.invokeListMethod<String>(
      'monitoredRegionIdentifiers',
    );
    return result ?? const [];
  }
}
