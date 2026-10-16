import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    final color = clamped >= 0.7 ? AppColors.primaryDark : AppColors.warning;

    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => LinearProgressIndicator(
              value: animated,
              minHeight: 6,
              color: color,
              backgroundColor: AppColors.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            '${(clamped * 100).round()}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
