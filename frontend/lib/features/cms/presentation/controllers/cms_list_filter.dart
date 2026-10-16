import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/features/cms/domain/cms_status_filter.dart';

@immutable
class CmsListFilter {
  const CmsListFilter({
    this.query = '',
    this.status = CmsStatusFilter.all,
  });

  final String query;
  final CmsStatusFilter status;

  CmsListFilter copyWith({String? query, CmsStatusFilter? status}) {
    return CmsListFilter(
      query: query ?? this.query,
      status: status ?? this.status,
    );
  }

  bool matches({required bool isActive, required Iterable<String?> texts}) {
    final statusOk = switch (status) {
      CmsStatusFilter.all => true,
      CmsStatusFilter.active => isActive,
      CmsStatusFilter.inactive => !isActive,
    };
    if (!statusOk) return false;

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return texts.any((t) => (t ?? '').toLowerCase().contains(q));
  }
}

class CmsListFilterNotifier extends Notifier<CmsListFilter> {
  @override
  CmsListFilter build() => const CmsListFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setStatus(CmsStatusFilter status) =>
      state = state.copyWith(status: status);

  void reset() => state = const CmsListFilter();
}
