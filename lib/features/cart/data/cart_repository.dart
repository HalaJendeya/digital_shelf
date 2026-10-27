import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/providers.dart';
import 'cart.dart';

/// Every mutation returns the updated cart when the response carries one, or
/// `null` so the caller can re-fetch.
class CartRepository {
  CartRepository(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  String get _base => '${_config.storePath}/cart';

  Future<Cart> fetchCart() async => Cart.fromJson((await _api.get(_base)).json);

  Future<Cart?> addItem({required int productId, int quantity = 1, Map<String, String> options = const {}}) =>
      _cartOrNull(
        _api.post(
          '$_base/items',
          body: {'product_id': productId, 'quantity': quantity, if (options.isNotEmpty) 'options': options},
        ),
      );

  Future<Cart?> updateQuantity(int itemId, int quantity) =>
      _cartOrNull(_api.patch('$_base/items/$itemId', body: {'quantity': quantity}));

  Future<Cart?> removeItem(int itemId) => _cartOrNull(_api.delete('$_base/items/$itemId'));

  Future<Cart?> clear() => _cartOrNull(_api.delete(_base));

  Future<Cart?> applyCoupon(String code) => _cartOrNull(_api.post('$_base/coupon', body: {'code': code}));

  Future<Cart?> removeCoupon() => _cartOrNull(_api.delete('$_base/coupon'));

  Future<Cart?> _cartOrNull(Future<ApiResponse> request) async {
    final json = (await request).json;
    return Cart.looksLikeCart(json) ? Cart.fromJson(json) : null;
  }
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider)),
);
