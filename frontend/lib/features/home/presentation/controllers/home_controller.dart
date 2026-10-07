import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/rating/domain/testimonial.dart';
import 'package:rijiki/features/service/domain/care_service.dart';

Duration? _noRetry(int retryCount, Object error) => null;
const int homeServiceLimit = 6;

final homeServicesProvider = FutureProvider<List<CareService>>((ref) async {
  final services = await ref.watch(serviceRepositoryProvider).fetchServices();
  return services.take(homeServiceLimit).toList();
}, retry: _noRetry);

final homeEventsProvider = FutureProvider<List<PromoEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).fetchActiveEvents();
}, retry: _noRetry);

final homeActiveOrdersProvider = FutureProvider<List<CustomerOrder>>((ref) {
  return ref.watch(orderRepositoryProvider).fetchActiveOrders();
}, retry: _noRetry);

final homeTestimonialsProvider = FutureProvider<List<Testimonial>>((ref) {
  return ref.watch(ratingRepositoryProvider).fetchFeaturedTestimonials();
}, retry: _noRetry);

Future<void> refreshHome(WidgetRef ref) async {
  Future<void> safe(Future<Object?> future) async {
    try {
      await future;
    } catch (_) {
    }
  }

  await Future.wait([
    safe(ref.refresh(homeServicesProvider.future)),
    safe(ref.refresh(homeEventsProvider.future)),
    safe(ref.refresh(homeActiveOrdersProvider.future)),
    safe(ref.refresh(homeTestimonialsProvider.future)),
  ]);
}
