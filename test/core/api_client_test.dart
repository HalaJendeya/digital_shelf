import 'package:digital_shelf/core/error/app_exception.dart';
import 'package:digital_shelf/core/network/api_client.dart';
import 'package:digital_shelf/core/network/interceptors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';

void main() {
  late FakeAdapter adapter;
  late ApiClient client;
  String? token;
  var unauthorizedCalls = 0;

  setUp(() {
    token = null;
    unauthorizedCalls = 0;
    adapter = FakeAdapter((_) => FakeResponse(200, ok({})));
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      HeadersInterceptor(languageCode: () => 'en', token: () => token),
      UnauthorizedInterceptor(() => unauthorizedCalls++),
      RetryInterceptor(dio, baseDelay: Duration.zero),
    ]);
    client = ApiClient(dio);
  });

  test('unwraps data and pagination meta', () async {
    adapter.handler = (_) => FakeResponse(200, ok([{'id': 1}], meta: {'page': 1, 'per_page': 15, 'total': 20, 'last_page': 2}));
    final response = await client.get('/x');
    expect(response.list.single['id'], 1);
    expect(response.pageMeta!.hasMore, isTrue);
  });

  test('sends Accept, Accept-Language and bearer token only when present', () async {
    await client.get('/public');
    expect(adapter.requests.last.headers['Accept'], 'application/json');
    expect(adapter.requests.last.headers['Accept-Language'], 'en');
    expect(adapter.requests.last.headers.containsKey('Authorization'), isFalse);

    token = 'abc';
    await client.get('/private');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer abc');
  });

  test('maps 422 validation errors with field details', () async {
    adapter.handler = (_) => FakeResponse(
      422,
      errorBody(422, 'VALIDATION_ERROR', 'Invalid', {'email': ['Email is required.']}),
    );
    await expectLater(
      client.post('/login', body: {}),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.validation)
          .having((e) => e.code, 'code', 'VALIDATION_ERROR')
          .having((e) => e.fieldError('email'), 'email', 'Email is required.')),
    );
  });

  test('maps 401/403/404 and signals unauthorized only for token requests', () async {
    adapter.handler = (_) => FakeResponse(401, errorBody(401, 'UNAUTHENTICATED', 'Please log in first'));
    await expectLater(client.get('/cart'), throwsA(isA<AppException>().having((e) => e.isUnauthorized, 'u', isTrue)));
    expect(unauthorizedCalls, 0);

    token = 'expired';
    await expectLater(client.get('/cart'), throwsA(isA<AppException>()));
    expect(unauthorizedCalls, 1);

    adapter.handler = (_) => FakeResponse(403, errorBody(403, 'REVIEW_REQUIRES_PURCHASE', 'Buy first'));
    await expectLater(
      client.post('/reviews'),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.forbidden)
          .having((e) => e.code, 'code', 'REVIEW_REQUIRES_PURCHASE')),
    );

    adapter.handler = (_) => FakeResponse(404, errorBody(404, 'NOT_FOUND', 'Not found'));
    await expectLater(client.get('/products/1'),
        throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.notFound)));
  });

  test('treats success:false inside a 200 as an error', () async {
    adapter.handler = (_) => FakeResponse(200, errorBody(400, 'COUPON_INVALID', 'Bad coupon'));
    await expectLater(client.post('/coupon'), throwsA(isA<AppException>().having((e) => e.code, 'code', 'COUPON_INVALID')));
  });

  test('retries idempotent GET on transient failure', () async {
    var calls = 0;
    adapter.handler = (_) => ++calls < 3 ? const FakeResponse(503, {}) : FakeResponse(200, ok({'pong': true}));
    final response = await client.get('/ping');
    expect(response.json['pong'], isTrue);
    expect(calls, 3);
  });

  test('never retries POST (checkout must not be duplicated)', () async {
    var calls = 0;
    adapter.handler = (_) {
      calls++;
      return const FakeResponse(503, {});
    };
    await expectLater(client.post('/checkout', body: {}),
        throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.server)));
    expect(calls, 1);
  });

  test('connection failures become network errors after retries', () async {
    adapter.handler = (_) => const FakeResponse.connectionError();
    await expectLater(client.get('/home'),
        throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.network)));
    expect(adapter.requests.length, 3);
  });
}
