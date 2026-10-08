import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/home/presentation/controllers/home_controller.dart';
import 'package:rijiki/features/home/presentation/widgets/active_order_card.dart';
import 'package:rijiki/features/home/presentation/widgets/greeting_header.dart';
import 'package:rijiki/features/home/presentation/widgets/promo_event_banner.dart';
import 'package:rijiki/features/home/presentation/widgets/scan_cta_card.dart';
import 'package:rijiki/features/home/presentation/widgets/service_carousel.dart';
import 'package:rijiki/features/home/presentation/widgets/testimonial_carousel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final name = _firstName(user?.fullName, user?.email);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: () => refreshHome(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GreetingHeader(
                  name: name,
                  avatarUrl: user?.avatarUrl,
                  onAvatarTap: () => context.go(RoutePaths.customerProfile),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ScanCtaCard(
                  onScan: () => context.push(RoutePaths.customerScan),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const ActiveOrderSection(),
              const SizedBox(height: AppSpacing.xl),
              const ServiceCarousel(),
              const SizedBox(height: AppSpacing.xl),
              const PromoEventBanner(),
              const SizedBox(height: AppSpacing.xl),
              const TestimonialCarousel(),
            ],
          ),
        ),
      ),
    );
  }

  static String _firstName(String? fullName, String? email) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed.split(RegExp(r'\s+')).first;
    final local = email?.split('@').first ?? '';
    return local.isEmpty ? 'Sobat Rijiki' : local;
  }
}
