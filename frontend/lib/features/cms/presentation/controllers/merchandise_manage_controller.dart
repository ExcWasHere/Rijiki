import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/cms/domain/cms_status_filter.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_hub_controller.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_list_filter.dart';
import 'package:rijiki/features/merchandise/domain/merchandise.dart';
import 'package:rijiki/features/merchandise/domain/merchandise_input.dart';

final merchandiseManageFilterProvider =
    NotifierProvider.autoDispose<CmsListFilterNotifier, CmsListFilter>(
      CmsListFilterNotifier.new,
    );

final cmsMerchandiseProvider = FutureProvider.autoDispose<List<Merchandise>>((
  ref,
) {
  return ref.watch(merchandiseRepositoryProvider).fetchAllMerchandise();
});

final cmsMerchandiseCountsProvider = Provider.autoDispose<CmsCounts>((ref) {
  final items = ref.watch(cmsMerchandiseProvider).value ?? const [];
  return CmsCounts.of(items.map((m) => m.isActive));
});

final filteredCmsMerchandiseProvider = Provider.autoDispose<List<Merchandise>>((
  ref,
) {
  final items = ref.watch(cmsMerchandiseProvider).value ?? const [];
  final filter = ref.watch(merchandiseManageFilterProvider);

  return [
    for (final item in items)
      if (filter.matches(
        isActive: item.isActive,
        texts: [item.name, item.description],
      ))
        item,
  ];
});

class MerchandiseManageNotifier extends Notifier<CmsActionState> {
  @override
  CmsActionState build() => const CmsActionState();

  Future<bool> setActive(Merchandise item, bool active) async {
    if (state.busyId != null) return false;
    state = CmsActionState(busyId: item.id, busyValue: active);
    try {
      await ref
          .read(merchandiseRepositoryProvider)
          .setMerchandiseActive(item.id, active);
      if (!ref.mounted) return true;
      _refresh();
      await ref.read(cmsMerchandiseProvider.future);
      if (!ref.mounted) return true;
      state = const CmsActionState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const CmsActionState(
        errorMessage: 'Gagal mengubah status merchandise. Coba lagi ya.',
      );
      return false;
    }
  }

  Future<bool> save({String? id, required MerchandiseInput input}) async {
    if (state.saving) return false;
    state = const CmsActionState(saving: true);
    try {
      final repository = ref.read(merchandiseRepositoryProvider);
      if (id == null) {
        await repository.createMerchandise(input);
      } else {
        await repository.updateMerchandise(id, input);
      }
      if (!ref.mounted) return true;
      _refresh();
      state = const CmsActionState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const CmsActionState(
        errorMessage: 'Gagal menyimpan merchandise. Coba lagi ya.',
      );
      return false;
    }
  }

  void _refresh() {
    ref.invalidate(cmsMerchandiseProvider);
    ref.invalidate(cmsMerchandiseSummaryProvider);
  }
}

final merchandiseManageProvider =
    NotifierProvider.autoDispose<MerchandiseManageNotifier, CmsActionState>(
      MerchandiseManageNotifier.new,
    );
