import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/cms/domain/cms_status_filter.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_hub_controller.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_list_filter.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/domain/promo_event_input.dart';

final eventManageFilterProvider =
    NotifierProvider.autoDispose<CmsListFilterNotifier, CmsListFilter>(
      CmsListFilterNotifier.new,
    );

final cmsEventsProvider = FutureProvider.autoDispose<List<PromoEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).fetchAllEvents();
});

final cmsEventCountsProvider = Provider.autoDispose<CmsCounts>((ref) {
  final events = ref.watch(cmsEventsProvider).value ?? const [];
  return CmsCounts.of(events.map((e) => e.isPublished));
});

final filteredCmsEventsProvider = Provider.autoDispose<List<PromoEvent>>((ref) {
  final events = ref.watch(cmsEventsProvider).value ?? const [];
  final filter = ref.watch(eventManageFilterProvider);

  return [
    for (final event in events)
      if (filter.matches(
        isActive: event.isPublished,
        texts: [event.title, event.description],
      ))
        event,
  ];
});

class EventManageNotifier extends Notifier<CmsActionState> {
  @override
  CmsActionState build() => const CmsActionState();
  Future<bool> setPublished(PromoEvent event, bool published) async {
    if (state.busyId != null) return false;
    state = CmsActionState(busyId: event.id, busyValue: published);
    try {
      await ref
          .read(eventRepositoryProvider)
          .setEventPublished(event.id, published);
      if (!ref.mounted) return true;
      _refresh();
      await ref.read(cmsEventsProvider.future);
      if (!ref.mounted) return true;
      state = const CmsActionState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const CmsActionState(
        errorMessage: 'Gagal mengubah status event. Coba lagi ya.',
      );
      return false;
    }
  }

  Future<bool> save({String? id, required PromoEventInput input}) async {
    if (state.saving) return false;
    state = const CmsActionState(saving: true);
    try {
      final repository = ref.read(eventRepositoryProvider);
      if (id == null) {
        await repository.createEvent(input);
      } else {
        await repository.updateEvent(id, input);
      }
      if (!ref.mounted) return true;
      _refresh();
      state = const CmsActionState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const CmsActionState(
        errorMessage: 'Gagal menyimpan event. Coba lagi ya.',
      );
      return false;
    }
  }

  void _refresh() {
    ref.invalidate(cmsEventsProvider);
    ref.invalidate(cmsEventSummaryProvider);
  }
}

final eventManageProvider =
    NotifierProvider.autoDispose<EventManageNotifier, CmsActionState>(
      EventManageNotifier.new,
    );
