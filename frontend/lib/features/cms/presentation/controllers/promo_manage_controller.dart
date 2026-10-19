import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/cms/domain/cms_status_filter.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_list_filter.dart';
import 'package:rijiki/features/event/domain/promo.dart';
import 'package:rijiki/features/event/domain/promo_input.dart';

final promoManageFilterProvider =
    NotifierProvider.autoDispose<CmsListFilterNotifier, CmsListFilter>(
      CmsListFilterNotifier.new,
    );

final cmsPromosProvider = FutureProvider.autoDispose<List<Promo>>((ref) {
  return ref.watch(promoRepositoryProvider).fetchAllPromos();
});

final cmsPromoCountsProvider = Provider.autoDispose<CmsCounts>((ref) {
  final promos = ref.watch(cmsPromosProvider).value ?? const [];
  return CmsCounts.of(promos.map((p) => p.isActive));
});

final filteredCmsPromosProvider = Provider.autoDispose<List<Promo>>((ref) {
  final promos = ref.watch(cmsPromosProvider).value ?? const [];
  final filter = ref.watch(promoManageFilterProvider);

  return [
    for (final promo in promos)
      if (filter.matches(
        isActive: promo.isActive,
        texts: [promo.code, promo.title, promo.description],
      ))
        promo,
  ];
});

class PromoManageNotifier extends Notifier<CmsActionState> {
  @override
  CmsActionState build() => const CmsActionState();

  Future<bool> setActive(Promo promo, bool active) async {
    if (state.busyId != null) return false;
    state = CmsActionState(busyId: promo.id, busyValue: active);
    try {
      await ref.read(promoRepositoryProvider).setPromoActive(promo.id, active);
      if (!ref.mounted) return true;
      _refresh();
      await ref.read(cmsPromosProvider.future);
      if (!ref.mounted) return true;
      state = const CmsActionState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const CmsActionState(
        errorMessage: 'Gagal mengubah status promo. Coba lagi ya.',
      );
      return false;
    }
  }

  Future<bool> save({String? id, required PromoInput input}) async {
    if (state.saving) return false;
    state = const CmsActionState(saving: true);
    try {
      final repository = ref.read(promoRepositoryProvider);
      if (id == null) {
        await repository.createPromo(input);
      } else {
        await repository.updatePromo(id, input);
      }
      if (!ref.mounted) return true;
      _refresh();
      state = const CmsActionState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const CmsActionState(
        errorMessage: 'Gagal menyimpan promo. Coba lagi ya.',
      );
      return false;
    }
  }

  void _refresh() {
    ref.invalidate(cmsPromosProvider);
  }
}

final promoManageProvider =
    NotifierProvider.autoDispose<PromoManageNotifier, CmsActionState>(
      PromoManageNotifier.new,
    );
