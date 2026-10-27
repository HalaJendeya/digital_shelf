import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../shared/models/paged_controller.dart';
import '../../../shared/models/paged_state.dart';
import '../../products/application/product_providers.dart';
import '../data/review.dart';
import '../data/reviews_repository.dart';

class ReviewsController extends PagedController<Review> {
  ReviewsController(this.productId);

  final int productId;

  @override
  Future<Paginated<Review>> fetchPage(int page, CancelToken cancelToken) => ref
      .read(reviewsRepositoryProvider)
      .fetchReviews(productId, page: page, cancelToken: cancelToken);

  /// Submits a review, then refreshes the list and the product's summary.
  /// Throws `AppException(code: REVIEW_REQUIRES_PURCHASE)` when not eligible.
  Future<void> submit({required int rating, String? comment}) async {
    await ref.read(reviewsRepositoryProvider).submitReview(productId, rating: rating, comment: comment);
    ref.invalidate(productDetailsProvider(productId));
    ref.invalidateSelf();
  }
}

final reviewsProvider = AsyncNotifierProvider.autoDispose
    .family<ReviewsController, PagedState<Review>, int>(ReviewsController.new);
