import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/product.dart';

class FavoritesRepository {
  FavoritesRepository(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  String get _base => '${_config.storePath}/favorites';

  /// Items may be products directly or wrappers with a nested `product`.
  Future<List<Product>> fetchFavorites() async {
    final list = (await _api.get(_base)).list;
    return list
        .map((json) => json['product'] is Map ? asJson(json['product']) : json)
        .map(Product.fromJson)
        .map((p) => p.copyWith(isFavorite: true))
        .toList();
  }

  /// Toggles and returns the server's resulting `is_favorite`.
  Future<bool> toggle(int productId) async {
    final data = (await _api.post('$_base/$productId')).json;
    final value = readBool(data['is_favorite']);
    if (value == null) throw StateError('Toggle response missing is_favorite');
    return value;
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider)),
);
