import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/cms/domain/cms_status_filter.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_hub_controller.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_list_filter.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';

final serviceManageFilterProvider =
    NotifierProvider.autoDispose<CmsListFilterNotifier, CmsListFilter>(
      CmsListFilterNotifier.new,
    );

final cmsServicesProvider = FutureProvider.autoDispose<List<CareService>>((
  ref,
) {
  return ref.watch(serviceRepositoryProvider).fetchAllServices();
});

final cmsServiceCountsProvider = Provider.autoDispose<CmsCounts>((ref) {
  final services = ref.watch(cmsServicesProvider).value ?? const [];
  return CmsCounts.of(services.map((s) => s.isActive));
});

final filteredCmsServicesProvider = Provider.autoDispose<List<CareService>>((
  ref,
) {
  final services = ref.watch(cmsServicesProvider).value ?? const [];
  final filter = ref.watch(serviceManageFilterProvider);

  return [
    for (final service in services)
      if (filter.matches(
        isActive: service.isActive,
        texts: [service.name, service.description],
      ))
        service,
  ];
});

@immutable
class ServiceManageState {
  const ServiceManageState({
    this.busyId,
    this.busyValue,
    this.saving = false,
    this.errorMessage,
  });

  final String? busyId;
  final bool? busyValue;
  final bool saving;
  final String? errorMessage;
}

class ServiceManageNotifier extends Notifier<ServiceManageState> {
  @override
  ServiceManageState build() => const ServiceManageState();
  Future<bool> setActive(CareService service, bool active) async {
    if (state.busyId != null) return false;
    state = ServiceManageState(busyId: service.id, busyValue: active);
    try {
      await ref
          .read(serviceRepositoryProvider)
          .setServiceActive(service.id, active);
      if (!ref.mounted) return true;
      _refresh();
      await ref.read(cmsServicesProvider.future);
      if (!ref.mounted) return true;
      state = const ServiceManageState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const ServiceManageState(
        errorMessage: 'Gagal mengubah status layanan. Coba lagi ya.',
      );
      return false;
    }
  }

  Future<bool> save({String? id, required CareServiceInput input}) async {
    if (state.saving) return false;
    state = const ServiceManageState(saving: true);
    try {
      final repository = ref.read(serviceRepositoryProvider);
      if (id == null) {
        await repository.createService(input);
      } else {
        await repository.updateService(id, input);
      }
      if (!ref.mounted) return true;
      _refresh();
      state = const ServiceManageState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const ServiceManageState(
        errorMessage: 'Gagal menyimpan layanan. Coba lagi ya.',
      );
      return false;
    }
  }

  void _refresh() {
    ref.invalidate(cmsServicesProvider);
    ref.invalidate(cmsServiceSummaryProvider);
  }
}

final serviceManageProvider =
    NotifierProvider.autoDispose<ServiceManageNotifier, ServiceManageState>(
      ServiceManageNotifier.new,
    );
