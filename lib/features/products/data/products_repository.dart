import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/providers.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/product.dart';
import '../../reviews/data/review.dart';
import 'product_query.dart';

class ProductDetails {
  const ProductDetails({required this.product, required this.related, required this.reviews});

  /// `GET /products/{id}` wraps the product: `{product, related, reviews_summary}`.
  factory ProductDetails.fromJson(Json json) => ProductDetails(
    product: Product.fromJson(asJson(json['product'])),
    related: asJsonList(json['related']).map(Product.fromJson).toList(),
    reviews: ReviewsSummary.fromJson(asJson(json['reviews_summary'])),
  );

  final Product product;
  final List<Product> related;
  final ReviewsSummary reviews;
}

class ProductsRepository {
  ProductsRepository(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  Future<Paginated<Product>> fetchProducts(
    ProductQuery query, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      '${_config.storePath}/products',
      query: query.toQuery(page: page),
      cancelToken: cancelToken,
    );
    final items = response.list.map(Product.fromJson).toList();
    final meta = response.pageMeta ??
        PageMeta(page: page, perPage: ProductQuery.perPage, total: items.length, lastPage: page);
    return Paginated(items: items, meta: meta);
  }

  Future<ProductDetails> fetchDetails(int id) async {
    final response = await _api.get('${_config.storePath}/products/$id');
    return ProductDetails.fromJson(response.json);
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider)),
);
