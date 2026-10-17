import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/worker_management/domain/worker_input.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';

final workersProvider = FutureProvider.autoDispose<List<WorkerSummary>>((ref) {
  return ref.watch(workerRepositoryProvider).fetchWorkers();
});

final workerSummaryProvider = Provider.autoDispose
    .family<WorkerSummary?, String>((ref, id) {
      final workers = ref.watch(workersProvider).value;
      if (workers == null) return null;
      return workers.where((w) => w.profile.id == id).firstOrNull;
    });

final workerDivisionsProvider = Provider.autoDispose<List<String>>((ref) {
  final workers = ref.watch(workersProvider).value ?? const [];
  return {for (final w in workers) w.profile.division}.toList()..sort();
});

@immutable
class WorkerListFilter {
  const WorkerListFilter({this.query = '', this.division});

  final String query;
  final String? division;

  WorkerListFilter copyWith({
    String? query,
    String? division,
    bool clearDivision = false,
  }) {
    return WorkerListFilter(
      query: query ?? this.query,
      division: clearDivision ? null : (division ?? this.division),
    );
  }
}

class WorkerListFilterNotifier extends Notifier<WorkerListFilter> {
  @override
  WorkerListFilter build() => const WorkerListFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setDivision(String? division) => state = division == null
      ? state.copyWith(clearDivision: true)
      : state.copyWith(division: division);

  void reset() => state = const WorkerListFilter();
}

final workerListFilterProvider =
    NotifierProvider.autoDispose<WorkerListFilterNotifier, WorkerListFilter>(
      WorkerListFilterNotifier.new,
    );

final filteredWorkersProvider = Provider.autoDispose<List<WorkerSummary>>((
  ref,
) {
  final workers = ref.watch(workersProvider).value ?? const [];
  final filter = ref.watch(workerListFilterProvider);
  final query = filter.query.trim().toLowerCase();

  return [
    for (final summary in workers)
      if ((filter.division == null ||
              summary.profile.division == filter.division) &&
          (query.isEmpty ||
              summary.profile.fullName.toLowerCase().contains(query) ||
              summary.profile.employeeCode.toLowerCase().contains(query)))
        summary,
  ];
});

@immutable
class WorkerFormState {
  const WorkerFormState({this.saving = false, this.errorMessage});

  final bool saving;
  final String? errorMessage;
}

class WorkerFormNotifier extends Notifier<WorkerFormState> {
  @override
  WorkerFormState build() => const WorkerFormState();
  Future<bool> save({String? id, required WorkerInput input}) async {
    if (state.saving) return false;
    state = const WorkerFormState(saving: true);
    try {
      final repository = ref.read(workerRepositoryProvider);
      if (id == null) {
        await repository.createWorker(input);
      } else {
        await repository.updateWorker(id, input);
      }
      if (!ref.mounted) return true;
      ref.invalidate(workersProvider);
      state = const WorkerFormState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const WorkerFormState(
        errorMessage: 'Gagal menyimpan data worker. Coba lagi ya.',
      );
      return false;
    }
  }
}

final workerFormProvider =
    NotifierProvider.autoDispose<WorkerFormNotifier, WorkerFormState>(
      WorkerFormNotifier.new,
    );
