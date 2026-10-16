import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/cms/domain/cms_section.dart';

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

final cmsSectionSummaryProvider = Provider.autoDispose
    .family<AsyncValue<String?>, CmsSectionId>((ref, id) {
      return switch (id) {
        CmsSectionId.services => ref
            .watch(cmsServiceSummaryProvider)
            .whenData<String?>((text) => text),
        CmsSectionId.events => ref
            .watch(cmsEventSummaryProvider)
            .whenData<String?>((text) => text),
        CmsSectionId.merchandise => ref
            .watch(cmsMerchandiseSummaryProvider)
            .whenData<String?>((text) => text),
        _ => const AsyncData<String?>(null),
      };
    });

Future<void> refreshCmsHub(WidgetRef ref) async {
  ref.invalidate(cmsServiceSummaryProvider);
  ref.invalidate(cmsEventSummaryProvider);
  ref.invalidate(cmsMerchandiseSummaryProvider);
  try {
    await Future.wait<Object?>([
      ref.read(cmsServiceSummaryProvider.future),
      ref.read(cmsEventSummaryProvider.future),
      ref.read(cmsMerchandiseSummaryProvider.future),
    ]);
  } catch (_) {
  }
}
