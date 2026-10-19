import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class KpiAspectSelector extends StatelessWidget {
  const KpiAspectSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (var score = 1; score <= 5; score++) ...[
          if (score > 1) const SizedBox(width: 8),
          Expanded(
            child: _ScoreButton(
              score: score,
              selected: value == score,
              textStyle: textTheme.titleSmall,
              onTap: onChanged == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onChanged!(score);
                    },
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.score,
    required this.selected,
    required this.textStyle,
    required this.onTap,
  });

  final int score;
  final bool selected;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.35)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? AppColors.primaryDark
              : AppColors.outline.withValues(alpha: 0.4),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              '$score',
              style: textStyle?.copyWith(
                color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
