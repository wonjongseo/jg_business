/// 주소 문자열을 좌표로 변환한 결과다.
/// 위치 기반 알림은 이 위도/경도 값을 기준으로 반경 계산을 하게 된다.
class LocationCoordinate {
  const LocationCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  String toString() =>
      'LocationCoordinate(latitude: $latitude, longitude: $longitude)';
}
