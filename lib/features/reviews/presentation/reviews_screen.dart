import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/reviews_providers.dart';
import 'review_tile.dart';
import 'write_review_sheet.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = reviewsProvider(productId);
    return Scaffold(
      appBar: AppBar(title: Text(s.reviews)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWriteReviewSheet(context, productId),
        icon: const Icon(Icons.rate_review_outlined),
        label: Text(s.writeReview),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: AsyncValueView(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          data: (paged) => paged.items.isEmpty
              ? ListView(children: [EmptyView(message: s.noReviews, icon: Icons.reviews_outlined)])
              : NotificationListener<ScrollEndNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < AppSizes.loadMoreThreshold) ref.read(provider.notifier).loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.fabClearance),
                    itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => i < paged.items.length
                        ? ReviewTile(review: paged.items[i])
                        : paged.loadMoreError != null
                        ? TextButton(onPressed: () => ref.read(provider.notifier).loadMore(), child: Text(s.retry))
                        : const LoadingView(),
                  ),
                ),
        ),
      ),
    );
  }
}
