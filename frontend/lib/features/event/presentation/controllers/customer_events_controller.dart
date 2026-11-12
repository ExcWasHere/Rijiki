import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';

Duration? _noRetry(int retryCount, Object error) => null;

/// Event yang sedang tayang untuk halaman Acara & Promo customer.
final customerEventsProvider = FutureProvider.autoDispose<List<PromoEvent>>((
  ref,
) {
  return ref.watch(eventRepositoryProvider).fetchActiveEvents();
}, retry: _noRetry);
