import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/providers.dart';
import 'review.dart';

/// Backend code returned (403) when the customer has no delivered order
/// containing the product.
const kReviewRequiresPurchase = 'REVIEW_REQUIRES_PURCHASE';

class ReviewsRepository {
  ReviewsRepository(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  String _path(int productId) => '${_config.storePath}/products/$productId/reviews';

  Future<Paginated<Review>> fetchReviews(int productId, {int page = 1, CancelToken? cancelToken}) async {
    final response = await _api.get(_path(productId), query: {'page': page}, cancelToken: cancelToken);
    final items = response.list.map(Review.fromJson).toList();
    return Paginated(
      items: items,
      meta: response.pageMeta ??
          PageMeta(page: page, perPage: items.length, total: items.length, lastPage: page),
    );
  }

  Future<void> submitReview(int productId, {required int rating, String? comment}) => _api.post(
    _path(productId),
    body: {
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    },
  );
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider)),
);
