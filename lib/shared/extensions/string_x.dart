extension StringX on String {
  String? get nullIfBlank {
    final trimmed = trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
