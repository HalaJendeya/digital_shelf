import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Adds Accept, Accept-Language and (when signed in) the bearer token.
class HeadersInterceptor extends Interceptor {
  HeadersInterceptor({required this.languageCode, required this.token});

  final String Function() languageCode;
  final String? Function() token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';
    options.headers['Accept-Language'] = languageCode();
    final value = token();
    if (value != null && value.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $value';
    }
    handler.next(options);
  }
}

/// Retries idempotent GET requests on transient failures with linear backoff.
/// Never retries POST/PUT/PATCH/DELETE (e.g. checkout must not be duplicated).
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 600),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _attemptKey = 'retry_attempt';
  static const _retryableStatus = {502, 503, 504};

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badResponse:
        return _retryableStatus.contains(err.response?.statusCode);
      default:
        return false;
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    final cancelled = err.requestOptions.cancelToken?.isCancelled ?? false;
    if (cancelled || attempt >= maxRetries || !_shouldRetry(err)) {
      return handler.next(err);
    }
    await Future<void>.delayed(baseDelay * (attempt + 1));
    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// Signals an expired/revoked session for requests that carried a token.
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor(this.onUnauthorized);

  final VoidCallback onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && hadToken) onUnauthorized();
    handler.next(err);
  }
}

/// Debug-only request log. Logs method, path and status — never headers or bodies,
/// so tokens, passwords and customer details stay out of logs.
class SafeLogInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint('[api] ${response.requestOptions.method} '
        '${response.requestOptions.path} → ${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[api] ${err.requestOptions.method} ${err.requestOptions.path} '
        '✗ ${err.response?.statusCode ?? err.type.name}');
    handler.next(err);
  }
}
