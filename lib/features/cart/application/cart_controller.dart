import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../data/cart.dart';
import '../data/cart_repository.dart';

/// The customer's server-side cart. Guests have no cart (`Cart.empty`).
/// Mutations run one at a time and replace state with the API's response.
class CartController extends AsyncNotifier<Cart> {
  Future<void> _queue = Future.value();

  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() async {
    ref.watch(localeProvider);
    if (!ref.watch(isAuthenticatedProvider)) return Cart.empty;
    return _repo.fetchCart();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addItem(int productId, {int quantity = 1, Map<String, String> options = const {}}) =>
      _mutate(() => _repo.addItem(productId: productId, quantity: quantity, options: options));

  Future<void> updateQuantity(int itemId, int quantity) => _mutate(() => _repo.updateQuantity(itemId, quantity));

  Future<void> removeItem(int itemId) => _mutate(() => _repo.removeItem(itemId));

  Future<void> clear() => _mutate(_repo.clear);

  Future<void> applyCoupon(String code) => _mutate(() => _repo.applyCoupon(code));

  Future<void> removeCoupon() => _mutate(_repo.removeCoupon);

  /// Serializes mutations so rapid taps can't interleave; errors propagate to
  /// the caller for display while the last good cart stays on screen.
  Future<void> _mutate(Future<Cart?> Function() action) {
    final run = _queue.then((_) async {
      final updated = await action() ?? await _repo.fetchCart();
      if (ref.mounted) state = AsyncData(updated);
    });
    _queue = run.catchError((Object _) {});
    return run;
  }
}

final cartControllerProvider = AsyncNotifierProvider<CartController, Cart>(CartController.new);

/// Badge count; 0 while loading or for guests.
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartControllerProvider.select((c) => c.value?.itemsCount ?? 0)),
);
