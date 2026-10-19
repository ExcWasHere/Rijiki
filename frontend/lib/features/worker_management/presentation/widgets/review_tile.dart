import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_format.dart';
import 'package:rijiki/features/worker_management/domain/worker_review.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/rating_stars.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});

  final WorkerReview review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final comment = review.comment;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(value: review.ratingValue.toDouble(), size: 15),
              const Spacer(),
              Text(
                formatDate(review.createdAt),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (comment != null && comment.isNotEmpty)
            Text(comment, style: textTheme.bodyMedium),
          if (comment != null && comment.isNotEmpty) const SizedBox(height: 6),
          Text(
            [
              review.customerName,
              '#${review.orderNumber}',
              if (review.serviceName != null) review.serviceName!,
            ].join(' · '),
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
