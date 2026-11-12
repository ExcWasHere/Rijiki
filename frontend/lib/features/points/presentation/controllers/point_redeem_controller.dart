import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';
import 'package:rijiki/features/points/domain/reward.dart';
import 'package:rijiki/features/points/presentation/controllers/point_history_controller.dart';

Duration? _noRetry(int retryCount, Object error) => null;

/// Hadiah yang bisa ditukar (merch di halaman Acara & Promo).
final rewardsProvider = FutureProvider.autoDispose<List<Reward>>((ref) {
  return ref.watch(customerPointsRepositoryProvider).fetchRewards();
}, retry: _noRetry);

/// Pengajuan tukar poin yang masih menunggu persetujuan.
final pendingRedemptionsProvider =
    FutureProvider.autoDispose<List<PointRedemption>>((ref) {
      return ref
          .watch(customerPointsRepositoryProvider)
          .fetchRedemptions(status: RedemptionStatus.pending);
    }, retry: _noRetry);

/// Poin yang masih bisa dipakai: saldo dikurangi poin yang sedang "ditahan"
/// pengajuan pending. null selama saldo belum termuat. Hanya untuk tampilan;
/// pengecekan yang mengikat tetap di fungsi SQL.
final availablePointsProvider = Provider.autoDispose<int?>((ref) {
  final balance = ref.watch(pointBalanceProvider).value;
  if (balance == null) return null;
  final pending = ref.watch(pendingRedemptionsProvider).value ?? const [];
  final reserved = pending.fold<int>(0, (sum, r) => sum + r.pointsUsed);
  final available = balance.balance - reserved;
  return available < 0 ? 0 : available;
});

/// Penolakan baru (belum pernah ditampilkan di perangkat ini) untuk snackbar.
///
/// Penanda "sudah dilihat" disimpan per user di penyimpanan lokal:
/// - Pertama kali (belum ada penanda): penolakan lama dianggap sudah dilihat,
///   penanda diisi waktu penolakan terbaru (atau epoch bila belum ada), dan
///   tidak ada yang ditampilkan.
/// - Setelahnya: hanya penolakan yang diproses setelah penanda yang dikembalikan.
final rejectionNoticesProvider =
    FutureProvider.autoDispose<List<PointRedemption>>((ref) async {
      final user = ref.read(sessionProvider);
      if (user == null) return const [];

      final storage = ref.read(tokenStorageProvider);
      final rejected = await ref
          .read(customerPointsRepositoryProvider)
          .fetchRedemptions(status: RedemptionStatus.rejected, limit: 20);

      final dated = [
        for (final r in rejected)
          if (r.processedAt != null) r,
      ];
      DateTime? latest;
      for (final r in dated) {
        final at = r.processedAt!;
        if (latest == null || at.isAfter(latest)) latest = at;
      }

      final seenAt = await storage.readRedemptionSeenAt(user.id);
      if (seenAt == null) {
        await storage.writeRedemptionSeenAt(
          user.id,
          latest ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        return const [];
      }

      final fresh = [
        for (final r in dated)
          if (r.processedAt!.isAfter(seenAt)) r,
      ]..sort((a, b) => b.processedAt!.compareTo(a.processedAt!));

      if (fresh.isNotEmpty && latest != null) {
        await storage.writeRedemptionSeenAt(user.id, latest);
      }
      return fresh;
    }, retry: _noRetry);

@immutable
class RedeemState {
  const RedeemState({this.busyId, this.errorMessage});

  /// id hadiah yang sedang diajukan.
  final String? busyId;
  final String? errorMessage;
}

class RedeemNotifier extends Notifier<RedeemState> {
  @override
  RedeemState build() => const RedeemState();

  Future<bool> redeem(Reward reward) async {
    if (state.busyId != null) return false;
    state = RedeemState(busyId: reward.id);
    try {
      await ref
          .read(customerPointsRepositoryProvider)
          .requestRedemption(reward.id);
      if (!ref.mounted) return true;
      _refresh();
      state = const RedeemState();
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      // Data di layar bisa sudah basi (stok habis, saldo berubah): muat ulang.
      _refresh();
      ref.invalidate(rewardsProvider);
      state = RedeemState(
        errorMessage: e is Failure && e.message.trim().isNotEmpty
            ? e.message
            : 'Gagal mengajukan penukaran. Coba lagi ya.',
      );
      return false;
    }
  }

  void _refresh() {
    ref.invalidate(pendingRedemptionsProvider);
    ref.invalidate(pointBalanceProvider);
  }
}

final redeemProvider = NotifierProvider.autoDispose<RedeemNotifier, RedeemState>(
  RedeemNotifier.new,
);
