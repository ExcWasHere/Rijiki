import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/presentation/controllers/service_list_controller.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

/// Semua layanan aktif, dikelompokkan per kategori. Dibuka dari tautan
/// "Lihat semua" pada carousel layanan di beranda customer.
class ServiceListPage extends ConsumerWidget {
  const ServiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(allServicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Layanan')),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(allServicesProvider);
          await ref.read(allServicesProvider.future);
        },
        child: services.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: const [
              LoadingSkeleton(height: 72),
              SizedBox(height: 12),
              LoadingSkeleton(height: 72),
              SizedBox(height: 12),
              LoadingSkeleton(height: 72),
            ],
          ),
          error: (_, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              ErrorState(
                message: 'Daftar layanan gagal dimuat. Coba lagi ya.',
                onRetry: () => ref.invalidate(allServicesProvider),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: const [
                  EmptyState(
                    icon: Icons.cleaning_services_outlined,
                    title: 'Belum ada layanan',
                    message: 'Layanan akan muncul di sini setelah ditambahkan.',
                  ),
                ],
              );
            }
            return _ServiceGroups(services: list);
          },
        ),
      ),
    );
  }
}

class _ServiceGroups extends StatelessWidget {
  const _ServiceGroups({required this.services});

  final List<CareService> services;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = <ServiceCategory, List<CareService>>{};
    for (final service in services) {
      groups.putIfAbsent(service.category, () => []).add(service);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(
          'Pilih layanan untuk mulai pesan. Harga akhir mengikuti hasil '
          'pemeriksaan sepatu di outlet.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        for (final category in ServiceCategory.values)
          if (groups[category] case final items?) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              category.label,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final service in items) ...[
              _ServiceTile(service: service),
              const SizedBox(height: 10),
            ],
          ],
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final CareService service;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWash = service.category == ServiceCategory.cuciSepatu;
    final accent = isWash ? AppColors.rijikiBlue : AppColors.rijikiOrange;

    return AppCard(
      onTap: () => context.go(RoutePaths.orderCreateFor(serviceId: service.id)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWash ? Icons.cleaning_services_rounded : Icons.handyman_rounded,
              size: 20,
              color: Color.lerp(accent, Colors.black, 0.25),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: textTheme.titleSmall),
                if (service.description case final description?) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (service.estimatedDurationMinutes case final minutes?) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Estimasi ${_durationLabel(minutes)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            RupiahFormatter.full(service.basePrice),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  static String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes menit';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return '$hours jam';
    if (hours >= 24) {
      final days = hours ~/ 24;
      return '$days hari';
    }
    return '$hours jam $rest menit';
  }
}
