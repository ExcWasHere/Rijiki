import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/service/domain/care_service.dart';

Duration? _noRetry(int retryCount, Object error) => null;

final allServicesProvider = FutureProvider<List<CareService>>((ref) {
  return ref.watch(serviceRepositoryProvider).fetchServices();
}, retry: _noRetry);
