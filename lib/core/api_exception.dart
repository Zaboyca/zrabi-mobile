class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  String get displayMessage {
    if (errors.isEmpty) {
      return _humanize(message);
    }

    final parts = errors.values.expand((list) => list).where((e) => e.isNotEmpty);
    if (parts.isEmpty) {
      return _humanize(message);
    }

    return parts.map(_humanize).join('\n');
  }

  String _humanize(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    if (lower == 'unauthenticated' ||
        lower == 'unauthenticated.' ||
        lower == 'неавторизован' ||
        lower == 'неавторизован.') {
      return 'Нужно войти в аккаунт';
    }
    if (statusCode == 401 &&
        (lower.contains('unauthenticated') || lower.contains('неавториз'))) {
      return 'Нужно войти в аккаунт';
    }
    return trimmed.isEmpty ? raw : trimmed;
  }

  String? fieldError(String key) {
    final list = errors[key];
    if (list == null || list.isEmpty) {
      return null;
    }
    return list.first;
  }

  @override
  String toString() => 'ApiException($statusCode): $displayMessage';
}
