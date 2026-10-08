import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/rating/domain/testimonial.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/network_image_box.dart';

class TestimonialCard extends StatelessWidget {
  const TestimonialCard({super.key, required this.testimonial});

  final Testimonial testimonial;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photoUrl = testimonial.photoUrl;
    final comment = testimonial.comment;
    final serviceName = testimonial.serviceName;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(
                  i < testimonial.ratingValue
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: comment == null
                ? const SizedBox.shrink()
                : Text(
                    comment,
                    style: textTheme.bodyMedium,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (photoUrl != null) ...[
                NetworkImageBox(url: photoUrl, width: 40, height: 40),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.customerName,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (serviceName != null)
                      Text(
                        serviceName,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
