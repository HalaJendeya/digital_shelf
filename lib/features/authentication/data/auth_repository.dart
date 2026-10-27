import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/json.dart';
import 'customer.dart';

class AuthResult {
  const AuthResult({required this.token, this.customer});

  final String token;
  final Customer? customer;
}

class AuthRepository {
  AuthRepository(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  static const deviceName = 'Digital Shelf Flutter';

  String get _base => '${_config.storePath}/auth';

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await _api.post('$_base/login', body: {
      'email': email,
      'password': password,
      'device_name': deviceName,
    });
    return _parseAuth(response.json);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _api.post('$_base/register', body: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': deviceName,
    });
    return _parseAuth(response.json);
  }

  Future<Customer> me() async => Customer.fromJson((await _api.get('$_base/me')).json);

  /// `email` is optional per the API spec; sent only when the customer changed it.
  Future<Customer?> updateProfile({required String name, required String phone, String? email}) async {
    final response = await _api.put('$_base/profile', body: {'name': name, 'phone': phone, 'email': ?email});
    final data = response.json;
    return data.isEmpty ? null : Customer.fromJson(data);
  }

  Future<void> logout() => _api.post('$_base/logout');

  AuthResult _parseAuth(Json data) {
    final token = readString(pick(data, ['token', 'access_token']));
    if (token == null) {
      throw StateError('Auth response did not include a token');
    }
    final hasCustomer = data['customer'] is Map || data['user'] is Map;
    return AuthResult(token: token, customer: hasCustomer ? Customer.fromJson(data) : null);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider)),
);
