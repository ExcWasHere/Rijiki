import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/management/domain/cms_status_filter.dart';
import 'package:rijiki/features/management/presentation/controllers/cms_hub_controller.dart';
import 'package:rijiki/features/management/presentation/controllers/cms_list_filter.dart';
import 'package:rijiki/features/home/presentation/controllers/home_controller.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';
import 'package:rijiki/features/service/presentation/controllers/service_list_controller.dart';

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
    } catch (error) {
      if (!ref.mounted) return false;
      state = ServiceManageState(
        errorMessage: _messageOf(
          error,
          'Gagal mengubah status layanan. Coba lagi ya.',
        ),
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
    } catch (error) {
      if (!ref.mounted) return false;
      state = ServiceManageState(
        errorMessage: _messageOf(error, 'Gagal menyimpan layanan. Coba lagi ya.'),
      );
      return false;
    }
  }

  /// Pesan dari backend dipakai apa adanya bila ada (mis. nama sudah dipakai),
  /// supaya pengguna tahu apa yang harus diperbaiki.
  static String _messageOf(Object error, String fallback) {
    final message = error is Failure ? error.message : '';
    return message.isEmpty ? fallback : message;
  }

  /// Layanan aktif dipakai katalog customer dan beranda, jadi ikut disegarkan.
  void _refresh() {
    ref.invalidate(cmsServicesProvider);
    ref.invalidate(cmsServiceSummaryProvider);
    ref.invalidate(allServicesProvider);
    ref.invalidate(homeServicesProvider);
  }
}

final serviceManageProvider =
    NotifierProvider.autoDispose<ServiceManageNotifier, ServiceManageState>(
      ServiceManageNotifier.new,
    );
