import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/scan/presentation/controllers/scan_controller.dart';
import 'package:rijiki/features/scan/presentation/scan_navigation.dart';
import 'package:rijiki/features/scan/presentation/widgets/recommended_service_card.dart';
import 'package:rijiki/features/scan/presentation/widgets/scan_result_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';

class ScanResultPage extends ConsumerWidget {
  const ScanResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);
    final result = state.result;
    final textTheme = Theme.of(context).textTheme;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: context.closeScan,
          ),
          title: const Text('Hasil scan'),
        ),
        body: Center(
          child: EmptyState(
            icon: Icons.document_scanner_outlined,
            title: 'Belum ada hasil scan',
            message: 'Foto sepatumu dulu untuk mendapat rekomendasi.',
            actionLabel: 'Scan sekarang',
            onAction: () => context.pushReplacement(RoutePaths.customerScan),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: context.closeScan,
        ),
        title: const Text('Hasil scan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.imagePath != null)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Image.file(
                  File(state.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: AppColors.outline.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('Hasil analisis', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm + 4),
          ScanResultCard(
            icon: Icons.checkroom_rounded,
            title: 'Tipe sepatu',
            predictions: [result.shoeType],
          ),
          const SizedBox(height: 12),
          ScanResultCard(
            icon: Icons.layers_outlined,
            title: 'Material',
            predictions: [result.material],
          ),
          const SizedBox(height: 12),
          ScanResultCard(
            icon: Icons.water_drop_outlined,
            title: 'Kondisi',
            predictions: result.conditions,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Layanan yang cocok', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm + 4),
          RecommendedServiceCard(
            service: result.recommendedService,
            reason: result.recommendationReason,
          ),
          const SizedBox(height: AppSpacing.md),
          const _Disclaimer(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  // TODO(segmen-3): bawa layanan rekomendasi ke alur buat order.
                  onPressed: () => context.go(RoutePaths.customerOrders),
                  child: const Text('Pesan layanan ini'),
                ),
                TextButton(
                  onPressed: () =>
                      context.pushReplacement(RoutePaths.customerScan),
                  child: const Text('Scan ulang'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Ini rekomendasi awal dari sistem. Tim Rijiki tetap mengecek kondisi sepatumu langsung sebelum dikerjakan.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
