import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';

/// Filter status daftar penukaran. null = semua. Awalnya menampilkan yang menunggu.
class RedemptionFilterNotifier extends Notifier<RedemptionStatus?> {
  @override
  RedemptionStatus? build() => RedemptionStatus.pending;

  void select(RedemptionStatus? status) => state = status;
}

final redemptionFilterProvider =
    NotifierProvider.autoDispose<RedemptionFilterNotifier, RedemptionStatus?>(
      RedemptionFilterNotifier.new,
    );

final redemptionsProvider = FutureProvider.autoDispose<RedemptionList>((ref) {
  final status = ref.watch(redemptionFilterProvider);
  return ref
      .watch(pointManagementRepositoryProvider)
      .fetchRedemptions(status: status);
});

final pendingRedemptionCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(pointManagementRepositoryProvider).fetchPendingCount();
});

@immutable
class PointActionState {
  const PointActionState({this.busyId, this.errorMessage});

  final String? busyId;
  final String? errorMessage;
}

class RedemptionActionNotifier extends Notifier<PointActionState> {
  @override
  PointActionState build() => const PointActionState();

  Future<bool> process({
    required PointRedemption redemption,
    required RedemptionStatus status,
    String? notes,
  }) async {
    if (state.busyId != null) return false;
    state = PointActionState(busyId: redemption.id);
    try {
      await ref
          .read(pointManagementRepositoryProvider)
          .processRedemption(redemption.id, status: status, notes: notes);
      if (!ref.mounted) return true;
      ref.invalidate(redemptionsProvider);
      ref.invalidate(pendingRedemptionCountProvider);
      state = const PointActionState();
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = PointActionState(
        errorMessage: e is Failure && e.message.trim().isNotEmpty
            ? e.message
            : 'Gagal memproses pengajuan. Coba lagi ya.',
      );
      return false;
    }
  }
}

final redemptionActionProvider =
    NotifierProvider.autoDispose<RedemptionActionNotifier, PointActionState>(
      RedemptionActionNotifier.new,
    );
