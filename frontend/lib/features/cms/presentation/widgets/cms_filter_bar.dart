import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/cms/domain/cms_status_filter.dart';

class CmsFilterBar extends StatelessWidget {
  const CmsFilterBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.status,
    required this.counts,
    required this.onQueryChanged,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final String hint;
  final CmsStatusFilter status;
  final CmsCounts counts;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<CmsStatusFilter> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => TextField(
            controller: controller,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in CmsStatusFilter.values)
              ChoiceChip(
                selected: option == status,
                onSelected: (_) => onStatusChanged(option),
                showCheckmark: false,
                label: Text('${option.label} (${counts.forStatus(option)})'),
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: option == status
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      option == status ? FontWeight.w700 : FontWeight.w500,
                ),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary.withValues(alpha: 0.3),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: option == status
                      ? AppColors.primaryDark
                      : AppColors.outline.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
