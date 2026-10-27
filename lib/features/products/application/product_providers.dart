import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/providers.dart';
import '../../../shared/models/paged_controller.dart';
import '../../../shared/models/paged_state.dart';
import '../../../shared/models/product.dart';
import '../../authentication/application/auth_controller.dart';
import '../data/product_query.dart';
import '../data/products_repository.dart';

class ProductListController extends PagedController<Product> {
  ProductListController(this.query);

  final ProductQuery query;

  @override
  Future<PagedState<Product>> build() {
    ref.watch(localeProvider);
    return super.build();
  }

  @override
  Future<Paginated<Product>> fetchPage(int page, CancelToken cancelToken) => ref
      .read(productsRepositoryProvider)
      .fetchProducts(query, page: page, cancelToken: cancelToken);
}

/// Paginated product listing keyed by filters. Auto-disposed so leaving a
/// screen (or changing a search query) cancels its request.
final productListProvider = AsyncNotifierProvider.autoDispose
    .family<ProductListController, PagedState<Product>, ProductQuery>(ProductListController.new);

/// Product details; re-fetched when the session changes so `is_favorite` is
/// accurate for the signed-in customer.
final productDetailsProvider = FutureProvider.autoDispose.family<ProductDetails, int>((ref, id) {
  ref.watch(localeProvider);
  ref.watch(isAuthenticatedProvider);
  return ref.watch(productsRepositoryProvider).fetchDetails(id);
});
