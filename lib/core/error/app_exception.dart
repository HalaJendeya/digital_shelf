enum AppErrorType {
  network,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}

/// The single error type surfaced to state management and UI.
class AppException implements Exception {
  const AppException({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final AppErrorType type;

  /// Server-provided (already localized) message when available.
  final String message;

  /// Backend error code, e.g. `VALIDATION_ERROR`, `REVIEW_REQUIRES_PURCHASE`.
  final String? code;
  final int? statusCode;

  /// Field → messages, populated for `422 VALIDATION_ERROR`.
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => type == AppErrorType.unauthorized;
  bool get isRetryable =>
      type == AppErrorType.network ||
      type == AppErrorType.timeout ||
      type == AppErrorType.server;

  String? fieldError(String field) {
    final errors = fieldErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }

  @override
  String toString() => 'AppException($type, $code, $statusCode): $message';
}
