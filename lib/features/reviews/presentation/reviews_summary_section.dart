import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/common.dart';
import '../data/review.dart';
import 'review_tile.dart';
import 'write_review_sheet.dart';

/// Rating overview, star distribution and latest reviews from `reviews_summary`.
class ReviewsSummarySection extends StatelessWidget {
  const ReviewsSummarySection({super.key, required this.productId, required this.summary});

  final int productId;
  final ReviewsSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s.reviews, style: context.textStyles.sectionTitle),
            ),
            if (summary.count > 0)
              TextButton(onPressed: () => context.push(Routes.reviews(productId)), child: Text(s.seeAll)),
          ],
        ),
        if (summary.count == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.sm),
            child: Text(s.noReviews, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          )
        else ...[
          Row(
            children: [
              Column(
                children: [
                  Text(summary.average.toStringAsFixed(1),
                      style: context.textStyles.statValue),
                  RatingStars(rating: summary.average),
                  Text(s.reviewsCount(summary.count), style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: Gap.xl),
              Expanded(
                child: Column(
                  children: [
                    for (var star = 5; star >= 1; star--)
                      Row(
                        children: [
                          SizedBox(width: AppSizes.ratingLabelWidth, child: Text('$star', style: theme.textTheme.bodySmall)),
                          const SizedBox(width: Gap.xs),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (summary.distribution[star] ?? 0) / summary.count,
                              minHeight: AppSizes.ratingBarHeight,
                              borderRadius: BorderRadius.circular(Radii.xs),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          for (final review in summary.latest.take(3)) ReviewTile(review: review),
        ],
        const SizedBox(height: Gap.sm),
        OutlinedButton.icon(
          onPressed: () => showWriteReviewSheet(context, productId),
          icon: const Icon(Icons.rate_review_outlined),
          label: Text(s.writeReview),
        ),
      ],
    );
  }
}
