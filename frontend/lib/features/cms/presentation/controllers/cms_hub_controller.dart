import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/cms/domain/cms_section.dart';
import 'package:rijiki/features/cms/presentation/utils/point_format.dart';
import 'package:rijiki/features/cms/presentation/utils/promo_format.dart';
import 'package:rijiki/features/rating/domain/managed_rating.dart';

const List<CmsSection> _allSections = [
  CmsSection(
    id: CmsSectionId.services,
    title: 'Layanan',
    description: 'Daftar layanan dan harganya',
    icon: Icons.cleaning_services_rounded,
    color: AppColors.rijikiBlue,
    permission: AppPermission.manageCmsServices,
  ),
  CmsSection(
    id: CmsSectionId.events,
    title: 'Event',
    description: 'Event, kolaborasi, dan pengumuman',
    icon: Icons.event_rounded,
    color: AppColors.rijikiOrange,
    permission: AppPermission.manageCmsEvents,
  ),
  CmsSection(
    id: CmsSectionId.promos,
    title: 'Promo',
    description: 'Kode promo dan masa berlakunya',
    icon: Icons.local_offer_rounded,
    color: AppColors.accent,
    permission: AppPermission.manageCmsPromos,
  ),
  CmsSection(
    id: CmsSectionId.merchandise,
    title: 'Merchandise',
    description: 'Hadiah yang bisa ditukar dengan poin',
    icon: Icons.card_giftcard_rounded,
    color: AppColors.primaryDark,
    permission: AppPermission.manageCmsMerchandise,
  ),
  CmsSection(
    id: CmsSectionId.points,
    title: 'Poin',
    description: 'Atur poin yang didapat customer',
    icon: Icons.stars_rounded,
    color: AppColors.rijikiOrange,
    permission: AppPermission.managePoints,
  ),
  CmsSection(
    id: CmsSectionId.testimonials,
    title: 'Testimoni',
    description: 'Testimoni pilihan dan rekap foto',
    icon: Icons.reviews_rounded,
    color: AppColors.success,
    permission: AppPermission.manageTestimonials,
  ),
];

final cmsSectionsProvider = Provider<List<CmsSection>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const [];
  return [
    for (final section in _allSections)
      if (section.isVisibleFor(user)) section,
  ];
});

final cmsServiceSummaryProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final services = await ref.watch(serviceRepositoryProvider).fetchAllServices();
  final active = services.where((s) => s.isActive).length;
  final inactive = services.length - active;
  return inactive == 0
      ? '$active layanan aktif'
      : '$active layanan aktif · $inactive nonaktif';
});

final cmsEventSummaryProvider = FutureProvider.autoDispose<String>((ref) async {
  final events = await ref.watch(eventRepositoryProvider).fetchAllEvents();
  final published = events.where((e) => e.isPublished).length;
  final hidden = events.length - published;
  return hidden == 0
      ? '$published event tayang'
      : '$published event tayang · $hidden disembunyikan';
});

final cmsPromoSummaryProvider = FutureProvider.autoDispose<String>((ref) async {
  final promos = await ref.watch(promoRepositoryProvider).fetchAllPromos();
  final live = promos.where((p) => p.isActive).toList();
  final running = live.where((p) => promoPhaseOf(p) == PromoPhase.running).length;
  final upcoming = live.where((p) => promoPhaseOf(p) == PromoPhase.upcoming).length;
  if (running == 0 && upcoming == 0) return 'Tidak ada promo berlangsung';
  return upcoming == 0
      ? '$running promo berlangsung'
      : '$running promo berlangsung · $upcoming akan datang';
});

final cmsMerchandiseSummaryProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final items = await ref
      .watch(merchandiseRepositoryProvider)
      .fetchAllMerchandise();
  final active = items.where((m) => m.isActive).toList();
  final soldOut = active.where((m) => m.isOutOfStock).length;
  return soldOut == 0
      ? '${active.length} merchandise aktif'
      : '${active.length} merchandise aktif · $soldOut stok habis';
});

final cmsPointSummaryProvider = FutureProvider.autoDispose<String>((ref) async {
  final rules = await ref.watch(pointRuleRepositoryProvider).fetchRules();
  final parts = [
    for (final rule in rules)
      if (rule.isActive) '${rule.source.shortTitle} ${formatPointRuleValue(rule)}',
  ];
  return parts.isEmpty ? 'Aturan poin belum aktif' : parts.join(' · ');
});

final cmsTestimonialSummaryProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final page = await ref
      .watch(testimonialManageRepositoryProvider)
      .fetchRatings(RatingListFilter.all, limit: 1);
  final summary = page.summary;
  if (summary.total == 0) return 'Belum ada rating';
  final average = summary.average;
  final stars = average == null ? '' : '${average.toStringAsFixed(1)} ★ · ';
  return '$stars${summary.total} rating · ${summary.featured} pilihan';
});

final cmsSectionSummaryProvider = Provider.autoDispose
    .family<AsyncValue<String?>, CmsSectionId>((ref, id) {
      return switch (id) {
        CmsSectionId.services => ref
            .watch(cmsServiceSummaryProvider)
            .whenData<String?>((text) => text),
        CmsSectionId.events => ref
            .watch(cmsEventSummaryProvider)
            .whenData<String?>((text) => text),
        CmsSectionId.promos => ref
            .watch(cmsPromoSummaryProvider)
            .whenData<String?>((text) => text),
        CmsSectionId.merchandise => ref
            .watch(cmsMerchandiseSummaryProvider)
            .whenData<String?>((text) => text),
        CmsSectionId.points => ref
            .watch(cmsPointSummaryProvider)
            .whenData<String?>((text) => text),
        CmsSectionId.testimonials => ref
            .watch(cmsTestimonialSummaryProvider)
            .whenData<String?>((text) => text),
      };
    });

Future<void> refreshCmsHub(WidgetRef ref) async {
  ref.invalidate(cmsServiceSummaryProvider);
  ref.invalidate(cmsEventSummaryProvider);
  ref.invalidate(cmsPromoSummaryProvider);
  ref.invalidate(cmsMerchandiseSummaryProvider);
  ref.invalidate(cmsPointSummaryProvider);
  ref.invalidate(cmsTestimonialSummaryProvider);
  try {
    await Future.wait<Object?>([
      ref.read(cmsServiceSummaryProvider.future),
      ref.read(cmsEventSummaryProvider.future),
      ref.read(cmsPromoSummaryProvider.future),
      ref.read(cmsMerchandiseSummaryProvider.future),
      ref.read(cmsPointSummaryProvider.future),
      ref.read(cmsTestimonialSummaryProvider.future),
    ]);
  } catch (_) {
  }
}
