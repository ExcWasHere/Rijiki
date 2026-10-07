import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/home/presentation/controllers/home_controller.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/network_image_box.dart';
import 'package:rijiki/shared/widgets/section_header.dart';
import 'package:rijiki/shared/widgets/state_card.dart';
import 'package:rijiki/shared/widgets/status_chip.dart';

class PromoEventBanner extends ConsumerWidget {
  const PromoEventBanner({super.key});

  static const double _height = 144;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(homeEventsProvider);
    final cardWidth = (MediaQuery.sizeOf(context).width * 0.78)
        .clamp(240.0, 320.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(
            title: 'Promo & event',
            onAction: () => context.go(RoutePaths.customerEvents),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        events.when(
          loading: () => SizedBox(
            height: _height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) =>
                  LoadingSkeleton(width: cardWidth, height: _height),
            ),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: StateCard(
              child: ErrorState(
                onRetry: () => ref.invalidate(homeEventsProvider),
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: StateCard(
                  child: EmptyState(
                    icon: Icons.local_activity_outlined,
                    title: 'Belum ada promo atau event',
                    message: 'Info terbaru dari Rijiki akan muncul di sini.',
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
                itemBuilder: (_, index) =>
                    _EventCard(event: list[index], width: cardWidth),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.width});

  final PromoEvent event;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final validity = DateFormatter.validity(event.startDate, event.endDate);
    final accentText = Color.lerp(event.type.accent, Colors.black, 0.35);

    return SizedBox(
      width: width,
      child: AppCard(
        color: event.type.tint,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(
                    label: event.type.label,
                    color: event.type.accent,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.description!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  if (validity != null)
                    Text(
                      validity,
                      style: textTheme.labelMedium?.copyWith(color: accentText),
                    ),
                ],
              ),
            ),
            if (event.bannerImageUrl != null) ...[
              const SizedBox(width: 12),
              NetworkImageBox(url: event.bannerImageUrl!, width: 72, height: 72),
            ],
          ],
        ),
      ),
    );
  }
}
