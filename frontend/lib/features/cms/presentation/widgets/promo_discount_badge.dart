import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/discount_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/cms/presentation/utils/promo_format.dart';
import 'package:rijiki/features/event/domain/promo.dart';

class PromoDiscountBadge extends StatelessWidget {
  const PromoDiscountBadge({super.key, required this.promo, this.size = 56});

  final Promo promo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isFixed = promo.discountType == DiscountType.fixed;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.rijikiOrange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFixed)
            Text(
              'Rp',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          Text(
            compactPromoValue(promo),
            maxLines: 1,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
