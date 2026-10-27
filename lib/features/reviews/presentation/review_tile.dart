import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/common.dart';
import '../data/review.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: AvatarSizes.sm,
            child: Text(review.initials ?? (review.customerName?.substring(0, 1) ?? '?')),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(review.customerName ?? '',
                          style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
                    Text(formatDate(review.createdAt, locale), style: theme.textTheme.bodySmall),
                  ],
                ),
                RatingStars(rating: review.rating.toDouble(), size: IconSizes.sm),
                if (review.comment != null) ...[
                  const SizedBox(height: Gap.xs),
                  Text(review.comment!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
