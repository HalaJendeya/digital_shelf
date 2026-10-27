import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/models/product.dart';
import '../../authentication/application/auth_controller.dart';
import '../data/favorites_repository.dart';

/// Single source of truth for favorites, shared by cards, details and the
/// favorites page so a toggle anywhere is reflected everywhere.
class FavoritesController extends AsyncNotifier<List<Product>> {
  final _inFlight = <int>{};

  @override
  Future<List<Product>> build() async {
    ref.watch(localeProvider);
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref.read(favoritesRepositoryProvider).fetchFavorites();
  }

  /// Optimistic toggle, reconciled with the server's `is_favorite`.
  Future<void> toggle(Product product) async {
    if (!_inFlight.add(product.id)) return;
    final before = state.value ?? const <Product>[];
    final wasFavorite = before.any((p) => p.id == product.id);
    state = AsyncData(_apply(before, product, !wasFavorite));
    try {
      final isFavorite = await ref.read(favoritesRepositoryProvider).toggle(product.id);
      if (!ref.mounted) return;
      state = AsyncData(_apply(state.value ?? before, product, isFavorite));
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    } finally {
      _inFlight.remove(product.id);
    }
  }

  static List<Product> _apply(List<Product> list, Product product, bool favorite) {
    final without = list.where((p) => p.id != product.id).toList();
    return favorite ? [product.copyWith(isFavorite: true), ...without] : without;
  }
}

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, List<Product>>(FavoritesController.new);

/// Whether [productId] is a favorite. Falls back to the product payload's
/// `is_favorite` until the favorites list has loaded.
final isFavoriteProvider = Provider.family<bool, ({int id, bool fallback})>((ref, arg) {
  final list = ref.watch(favoritesControllerProvider);
  if (!list.hasValue) return arg.fallback;
  return list.requireValue.any((p) => p.id == arg.id);
});
