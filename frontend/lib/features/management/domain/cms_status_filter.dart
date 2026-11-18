import 'package:flutter/foundation.dart';

enum CmsStatusFilter {
  all('Semua'),
  active('Aktif'),
  inactive('Nonaktif');

  const CmsStatusFilter(this.label);

  final String label;
}

@immutable
class CmsCounts {
  const CmsCounts({
    required this.all,
    required this.active,
    required this.inactive,
  });

  factory CmsCounts.of(Iterable<bool> activeFlags) {
    var active = 0;
    var total = 0;
    for (final flag in activeFlags) {
      total++;
      if (flag) active++;
    }
    return CmsCounts(all: total, active: active, inactive: total - active);
  }

  final int all;
  final int active;
  final int inactive;

  int forStatus(CmsStatusFilter status) => switch (status) {
    CmsStatusFilter.all => all,
    CmsStatusFilter.active => active,
    CmsStatusFilter.inactive => inactive,
  };
}
