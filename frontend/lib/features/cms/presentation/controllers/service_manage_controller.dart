import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_hub_controller.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';

enum ServiceStatusFilter {
  all('Semua'),
  active('Aktif'),
  inactive('Nonaktif');

  const ServiceStatusFilter(this.label);

  final String label;
}

@immutable
class ServiceManageFilter {
  const ServiceManageFilter({
    this.query = '',
    this.status = ServiceStatusFilter.all,
  });

  final String query;
  final ServiceStatusFilter status;

  ServiceManageFilter copyWith({String? query, ServiceStatusFilter? status}) {
    return ServiceManageFilter(
      query: query ?? this.query,
      status: status ?? this.status,
    );
  }
}

class ServiceManageFilterNotifier extends Notifier<ServiceManageFilter> {
  @override
  ServiceManageFilter build() => const ServiceManageFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setStatus(ServiceStatusFilter status) =>
      state = state.copyWith(status: status);

  void reset() => state = const ServiceManageFilter();
}

final serviceManageFilterProvider =
    NotifierProvider.autoDispose<ServiceManageFilterNotifier, ServiceManageFilter>(
      ServiceManageFilterNotifier.new,
    );

final cmsServicesProvider = FutureProvider.autoDispose<List<CareService>>((
  ref,
) {
  return ref.watch(serviceRepositoryProvider).fetchAllServices();
});

@immutable
class ServiceCounts {
  const ServiceCounts({
    required this.all,
    required this.active,
    required this.inactive,
  });

  final int all;
  final int active;
  final int inactive;

  int forStatus(ServiceStatusFilter status) => switch (status) {
    ServiceStatusFilter.all => all,
    ServiceStatusFilter.active => active,
    ServiceStatusFilter.inactive => inactive,
  };
}

final cmsServiceCountsProvider = Provider.autoDispose<ServiceCounts>((ref) {
  final services = ref.watch(cmsServicesProvider).value ?? const [];
  final active = services.where((s) => s.isActive).length;
  return ServiceCounts(
    all: services.length,
    active: active,
    inactive: services.length - active,
  );
});

final filteredCmsServicesProvider = Provider.autoDispose<List<CareService>>((
  ref,
) {
  final services = ref.watch(cmsServicesProvider).value ?? const [];
  final filter = ref.watch(serviceManageFilterProvider);
  final query = filter.query.trim().toLowerCase();

  bool matchesStatus(CareService service) => switch (filter.status) {
    ServiceStatusFilter.all => true,
    ServiceStatusFilter.active => service.isActive,
    ServiceStatusFilter.inactive => !service.isActive,
  };

  bool matchesQuery(CareService service) =>
      query.isEmpty ||
      service.name.toLowerCase().contains(query) ||
      (service.description ?? '').toLowerCase().contains(query);

  return [
    for (final service in services)
      if (matchesStatus(service) && matchesQuery(service)) service,
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
