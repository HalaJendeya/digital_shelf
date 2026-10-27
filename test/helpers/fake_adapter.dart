import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeHandler = FakeResponse Function(RequestOptions options);

class FakeResponse {
  const FakeResponse(this.status, [this.body, this.error]);

  /// A connection-level failure instead of an HTTP response.
  const FakeResponse.connectionError() : this(0, null, DioExceptionType.connectionError);

  final int status;
  final Object? body;
  final DioExceptionType? error;
}

/// In-memory Dio adapter: records requests and answers from [handler].
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FakeHandler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = handler(options);
    if (response.error != null) {
      throw DioException(requestOptions: options, type: response.error!, error: const SocketException('x'));
    }
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> ok(Object? data, {Map<String, dynamic>? meta}) => {
  'success': true,
  'message': 'ok',
  'data': data,
  'meta': ?meta,
};

Map<String, dynamic> errorBody(int status, String code, String message, [Map<String, dynamic> details = const {}]) => {
  'success': false,
  'message': message,
  'status': status,
  'error': {'code': code, 'details': details},
};
