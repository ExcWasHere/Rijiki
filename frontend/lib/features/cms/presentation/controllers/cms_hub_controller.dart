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

final cmsServiceCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final services = await ref.watch(serviceRepositoryProvider).fetchServices();
  return services.length;
});

final cmsSectionSummaryProvider = Provider.autoDispose
    .family<AsyncValue<String?>, CmsSectionId>((ref, id) {
      return switch (id) {
        CmsSectionId.services => ref
            .watch(cmsServiceCountProvider)
            .whenData<String?>((count) => '$count layanan'),
        _ => const AsyncData<String?>(null),
      };
    });

Future<void> refreshCmsHub(WidgetRef ref) async {
  ref.invalidate(cmsServiceCountProvider);
  try {
    await ref.read(cmsServiceCountProvider.future);
  } catch (_) {
  }
}
