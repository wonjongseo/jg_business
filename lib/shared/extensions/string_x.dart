/// 문자열 공백 처리에 사용하는 확장 메서드 모음이다.
extension StringX on String {
  String? get nullIfBlank {
    final trimmed = trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
