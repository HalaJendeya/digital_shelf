import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../utils/json.dart';
import 'api_response.dart';

/// Thin wrapper over Dio that unwraps the `{success, message, data, meta}` envelope
/// and converts every failure into an [AppException].
class ApiClient {
  ApiClient(this.dio);

  final Dio dio;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _send(() => dio.get<dynamic>(
    path,
    queryParameters: query,
    cancelToken: cancelToken,
  ));

  Future<ApiResponse> post(String path, {Object? body}) =>
      _send(() => dio.post<dynamic>(path, data: body));

  Future<ApiResponse> put(String path, {Object? body}) =>
      _send(() => dio.put<dynamic>(path, data: body));

  Future<ApiResponse> patch(String path, {Object? body}) =>
      _send(() => dio.patch<dynamic>(path, data: body));

  Future<ApiResponse> delete(String path, {Object? body}) =>
      _send(() => dio.delete<dynamic>(path, data: body));

  Future<ApiResponse> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final body = asJson(response.data);
      if (body['success'] == false) {
        throw errorFromBody(body, response.statusCode);
      }
      return ApiResponse(
        data: body['data'],
        message: readString(body['message']),
        meta: body['meta'] is Map ? asJson(body['meta']) : null,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.cancel:
      return const AppException(type: AppErrorType.cancelled, message: 'cancelled');
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const AppException(type: AppErrorType.timeout, message: '');
    case DioExceptionType.connectionError:
      return const AppException(type: AppErrorType.network, message: '');
    case DioExceptionType.badResponse:
      return errorFromBody(asJson(e.response?.data), e.response?.statusCode);
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      // SocketException etc. surface as `unknown` on some platforms.
      return const AppException(type: AppErrorType.network, message: '');
  }
}

AppException errorFromBody(Json body, int? statusCode) {
  final status = statusCode ?? readInt(body['status']);
  final error = asJson(body['error']);
  final details = asJson(error['details']);
  final fieldErrors = <String, List<String>>{
    for (final entry in details.entries)
      if (entry.value is List)
        entry.key: (entry.value as List).map((e) => e.toString()).toList()
      else if (entry.value is String)
        entry.key: [entry.value as String],
  };
  return AppException(
    type: _typeForStatus(status),
    message: readString(body['message']) ?? '',
    code: readString(error['code']),
    statusCode: status,
    fieldErrors: fieldErrors,
  );
}

AppErrorType _typeForStatus(int? status) {
  if (status == null) return AppErrorType.unknown;
  if (status == 401) return AppErrorType.unauthorized;
  if (status == 403) return AppErrorType.forbidden;
  if (status == 404) return AppErrorType.notFound;
  if (status == 422) return AppErrorType.validation;
  if (status >= 500) return AppErrorType.server;
  return AppErrorType.unknown;
}
