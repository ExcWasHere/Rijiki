import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/home/presentation/controllers/home_controller.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/section_header.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class ServiceCarousel extends ConsumerWidget {
  const ServiceCarousel({super.key});

  static const double _height = 176;
  static const double _cardWidth = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(homeServicesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO: isi onAction setelah halaman daftar layanan ada.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(title: 'Layanan'),
        ),
        const SizedBox(height: AppSpacing.sm),
        services.when(
          loading: () => SizedBox(
            height: _height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const LoadingSkeleton(
                width: _cardWidth,
                height: _height,
              ),
            ),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: StateCard(
              child: ErrorState(
                onRetry: () => ref.invalidate(homeServicesProvider),
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: StateCard(
                  child: EmptyState(
                    icon: Icons.cleaning_services_outlined,
                    title: 'Layanan belum tersedia',
                    message: 'Daftar layanan akan muncul di sini.',
                  ),
                ),
              );
            }
            return SizedBox(
              height: _height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) => _ServiceCard(service: list[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final CareService service;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWash = service.category == ServiceCategory.cuciSepatu;
    final accent = isWash ? AppColors.rijikiBlue : AppColors.rijikiOrange;
    final icon = isWash
        ? Icons.cleaning_services_rounded
        : Icons.handyman_rounded;

    return SizedBox(
      width: ServiceCarousel._cardWidth,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Color.lerp(accent, Colors.black, 0.25),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              service.name,
              style: textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                service.description ?? service.category.label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              CurrencyFormatter.rupiah(service.basePrice),
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
