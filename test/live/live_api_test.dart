// Read-only contract checks against the real backend. Skipped by default;
// run with: flutter test test/live --dart-define=LIVE_API=true
import 'package:digital_shelf/core/config/app_config.dart';
import 'package:digital_shelf/core/network/api_client.dart';
import 'package:digital_shelf/core/network/interceptors.dart';
import 'package:digital_shelf/features/home/data/home_repository.dart';
import 'package:digital_shelf/features/products/data/product_query.dart';
import 'package:digital_shelf/features/products/data/products_repository.dart';
import 'package:digital_shelf/features/reviews/data/reviews_repository.dart';
import 'package:digital_shelf/features/store/data/store_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _live = bool.fromEnvironment('LIVE_API');

void main() {
  final config = AppConfig.fromEnvironment();
  final dio = Dio(BaseOptions(baseUrl: config.baseUrl))
    ..interceptors.add(HeadersInterceptor(languageCode: () => 'ar', token: () => null));
  final api = ApiClient(dio);

  group('live read-only API', skip: _live ? false : 'set --dart-define=LIVE_API=true', () {
    test('ping + store', () async {
      final repo = StoreRepository(api, config);
      expect(await repo.ping(), isTrue);
      final store = await repo.fetchStore();
      expect(store.slug, config.storeSlug);
      expect(store.primaryColor, isNotNull);
    });

    test('home + categories', () async {
      final repo = HomeRepository(api, config);
      final (home, categories) = await (repo.fetchHome(), repo.fetchCategories()).wait;
      expect(home.categories.length, categories.length);
    });

    test('products: filters, sort, pagination, details, reviews', () async {
      final repo = ProductsRepository(api, config);
      final page = await repo.fetchProducts(
        const ProductQuery(inStock: true, sort: ProductSort.price),
        page: 1,
      );
      final prices = page.items.map((p) => p.finalPrice).toList();
      expect(prices, orderedEquals([...prices]..sort()));
      expect(page.meta.page, 1);

      if (page.items.isNotEmpty) {
        final details = await repo.fetchDetails(page.items.first.id);
        expect(details.product.id, page.items.first.id);
        final reviews = await ReviewsRepository(api, config).fetchReviews(details.product.id);
        expect(reviews.meta.page, 1);
      }
    });
  });
}
