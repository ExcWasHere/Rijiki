import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/order/domain/courier_tracking.dart';

const Duration courierPollInterval = Duration(seconds: 10);
final courierTrackingProvider = StreamProvider.autoDispose
    .family<CourierTracking, String>((ref, orderId) {
      return _poll(ref, orderId);
    });

Stream<CourierTracking> _poll(Ref ref, String orderId) async* {
  final repo = ref.read(courierTrackingRepositoryProvider);
  var hasData = false;

  while (true) {
    try {
      final tracking = await repo.fetch(orderId);
      if (tracking == null) {
        throw const Failure(
          FailureType.conflict,
          'Pengantaran sudah selesai atau belum dimulai.',
        );
      }
      hasData = true;
      yield tracking;
    } on Failure catch (e) {
      final transient =
          e.type == FailureType.network || e.type == FailureType.server;
      if (!hasData || !transient) rethrow;
    }
    await Future<void>.delayed(courierPollInterval);
  }
}
