import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../shared/models/store.dart';

class StoreRepository {
  StoreRepository(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  /// `GET /ping` — returns true when the backend answers `pong`.
  Future<bool> ping() async {
    final response = await _api.get('/ping');
    return response.json['pong'] == true;
  }

  /// `GET /stores/{slug}` — branding, contact, delivery and currency.
  Future<Store> fetchStore() async {
    final response = await _api.get(_config.storePath);
    return Store.fromJson(response.json);
  }
}

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider)),
);

/// Store configuration; kept alive for the app's lifetime and refreshed on
/// language change because names/descriptions are localized server-side.
final storeProvider = FutureProvider<Store>((ref) {
  ref.watch(localeProvider);
  return ref.watch(storeRepositoryProvider).fetchStore();
});
