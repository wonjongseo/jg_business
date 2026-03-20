/// 위치 권한 화면에서 바로 쓸 수 있는 상태 요약 모델이다.
/// UI에서 바로 문구와 버튼 상태를 결정할 수 있도록 최소 정보만 담는다.
class LocationPermissionInfo {
  const LocationPermissionInfo({
    required this.serviceEnabled,
    required this.permission,
  });

  final bool serviceEnabled;
  final String permission;

  /// 사용 중 권한 또는 항상 권한이면 위치 기능을 켤 수 있다.
  bool get isGranted =>
      permission == 'whileInUse' || permission == 'always';

  /// 백그라운드 이탈 알림까지 하려면 항상 허용 상태가 필요하다.
  bool get isAlwaysGranted => permission == 'always';
}
