class LocationNormalizer {
  static String normalize(String? value) {
    if (value == null) return '';
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String toTitleCase(String? value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return '';

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
