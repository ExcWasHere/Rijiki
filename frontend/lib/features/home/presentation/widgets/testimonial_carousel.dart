import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/home/presentation/controllers/home_controller.dart';
import 'package:rijiki/features/home/presentation/widgets/testimonial_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/section_header.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class TestimonialCarousel extends ConsumerWidget {
  const TestimonialCarousel({super.key});

  static const double _height = 196;
  static const double _cardWidth = 272;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonials = ref.watch(homeTestimonialsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(title: 'Kata pelanggan'),
        ),
        const SizedBox(height: AppSpacing.sm),
        testimonials.when(
          loading: () => SizedBox(
            height: _height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: 2,
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
                onRetry: () => ref.invalidate(homeTestimonialsProvider),
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: StateCard(
                  child: EmptyState(
                    icon: Icons.star_outline_rounded,
                    title: 'Belum ada testimoni',
                    message: 'Ulasan dari pelanggan Rijiki akan muncul di sini.',
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
                itemBuilder: (_, index) => SizedBox(
                  width: _cardWidth,
                  child: TestimonialCard(testimonial: list[index]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
