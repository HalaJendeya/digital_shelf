import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/product.dart';

enum BannerLinkType { product, category, none }

class HomeBanner {
  const HomeBanner({
    required this.id,
    this.title,
    this.image,
    this.linkType = BannerLinkType.none,
    this.linkId,
    this.linkName,
  });

  factory HomeBanner.fromJson(Json json) => HomeBanner(
    id: readInt(json['id']) ?? 0,
    title: readString(json['title']),
    image: readString(json['image']),
    linkType: switch (readString(json['link_type'])) {
      'product' => BannerLinkType.product,
      'category' => BannerLinkType.category,
      _ => BannerLinkType.none,
    },
    linkId: readInt(json['link_id']),
    linkName: readString(json['link_name']),
  );

  final int id;
  final String? title;
  final String? image;
  final BannerLinkType linkType;
  final int? linkId;
  final String? linkName;
}

class HomeData {
  const HomeData({
    required this.banners,
    required this.categories,
    required this.featured,
    required this.newest,
    required this.bestSellers,
  });

  factory HomeData.fromJson(Json json) => HomeData(
    banners: asJsonList(json['banners']).map(HomeBanner.fromJson).toList(),
    categories: asJsonList(json['categories']).map(Category.fromJson).toList(),
    featured: asJsonList(json['featured']).map(Product.fromJson).toList(),
    newest: asJsonList(json['newest']).map(Product.fromJson).toList(),
    bestSellers: asJsonList(json['best_sellers']).map(Product.fromJson).toList(),
  );

  final List<HomeBanner> banners;
  final List<Category> categories;
  final List<Product> featured;
  final List<Product> newest;
  final List<Product> bestSellers;

  bool get isEmpty => featured.isEmpty && newest.isEmpty && bestSellers.isEmpty;
}

class HomeRepository {
  HomeRepository(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  /// One request for the whole home screen.
  Future<HomeData> fetchHome() async =>
      HomeData.fromJson((await _api.get('${_config.storePath}/home')).json);

  Future<List<Category>> fetchCategories() async =>
      (await _api.get('${_config.storePath}/categories')).list.map(Category.fromJson).toList();
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider)),
);

final homeProvider = FutureProvider<HomeData>((ref) {
  ref.watch(localeProvider);
  return ref.watch(homeRepositoryProvider).fetchHome();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  ref.watch(localeProvider);
  return ref.watch(homeRepositoryProvider).fetchCategories();
});
