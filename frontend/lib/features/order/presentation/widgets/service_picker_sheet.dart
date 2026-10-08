import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/presentation/controllers/service_list_controller.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

Future<CareService?> showServicePickerSheet(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<CareService>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    builder: (context) => _ServicePickerContent(selectedId: selectedId),
  );
}

class _ServicePickerContent extends ConsumerWidget {
  const _ServicePickerContent({required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(allServicesProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text('Pilih layanan', style: textTheme.titleLarge),
          ),
          Flexible(
            child: services.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: LoadingSkeleton(height: 220),
              ),
              error: (_, _) => ErrorState(
                onRetry: () => ref.invalidate(allServicesProvider),
              ),
              data: (list) => ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                children: [
                  for (final category in ServiceCategory.values) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        4,
                      ),
                      child: Text(
                        category.label,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (final service in list.where(
                      (s) => s.category == category,
                    ))
                      _ServiceRow(
                        service: service,
                        selected: service.id == selectedId,
                        onTap: () => Navigator.of(context).pop(service),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final CareService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: textTheme.titleSmall),
                  if (service.description != null)
                    Text(
                      service.description!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              CurrencyFormatter.rupiah(service.basePrice),
              style: textTheme.titleSmall,
            ),
            SizedBox(
              width: 28,
              child: selected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: AppColors.primaryDark,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
