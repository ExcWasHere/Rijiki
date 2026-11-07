import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/points/domain/point_rule.dart';

final pointRulesProvider = FutureProvider.autoDispose<List<PointRule>>((ref) {
  return ref.watch(pointRuleRepositoryProvider).fetchRules();
});

class PointRulesNotifier extends Notifier<CmsActionState> {
  @override
  CmsActionState build() => const CmsActionState();

  Future<bool> save({
    required PointRule rule,
    required PointRuleInput input,
  }) async {
    if (state.busyId != null) return false;
    state = CmsActionState(busyId: rule.id);
    try {
      await ref.read(pointRuleRepositoryProvider).updateRule(rule.id, input);
      if (!ref.mounted) return true;
      ref.invalidate(pointRulesProvider);
      await ref.read(pointRulesProvider.future);
      if (!ref.mounted) return true;
      state = const CmsActionState();
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = CmsActionState(
        errorMessage: e is Failure && e.message.trim().isNotEmpty
            ? e.message
            : 'Gagal menyimpan aturan poin. Coba lagi ya.',
      );
      return false;
    }
  }
}

final pointRulesManageProvider =
    NotifierProvider.autoDispose<PointRulesNotifier, CmsActionState>(
      PointRulesNotifier.new,
    );
