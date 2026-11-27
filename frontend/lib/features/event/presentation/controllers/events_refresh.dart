import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/features/event/presentation/controllers/customer_events_controller.dart';
import 'package:rijiki/features/points/presentation/controllers/point_history_controller.dart';
import 'package:rijiki/features/points/presentation/controllers/point_redeem_controller.dart';

/// Memuat ulang semua data halaman Acara & Promo (event, saldo, hadiah,
/// pengajuan pending, dan penolakan baru). Dipanggil saat tab dipilih dan saat
/// tarik-untuk-refresh.
void refreshEventsTab(WidgetRef ref) {
  ref.invalidate(customerEventsProvider);
  ref.invalidate(pointBalanceProvider);
  ref.invalidate(rewardsProvider);
  ref.invalidate(pendingRedemptionsProvider);
  ref.invalidate(rejectionNoticesProvider);
}
