import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';

extension ExpenseTypeUi on ExpenseType {
  String get label => switch (this) {
    ExpenseType.material => 'Belanja Bahan',
    ExpenseType.equipment => 'Alat',
    ExpenseType.externalService => 'Jasa',
    ExpenseType.other => 'Lain-lain',
  };
  String get example => switch (this) {
    ExpenseType.material => 'Sabun sepatu, pembersih, pewangi, kain lap',
    ExpenseType.equipment => 'Sikat, mesin, rak pengering',
    ExpenseType.externalService => 'Servis alat, tukang, jasa perbaikan',
    ExpenseType.other => 'Listrik, sewa, gaji, perlengkapan kantor',
  };

  Color get color => switch (this) {
    ExpenseType.material => AppColors.rijikiBlue,
    ExpenseType.equipment => AppColors.primaryDark,
    ExpenseType.externalService => AppColors.rijikiOrange,
    ExpenseType.other => AppColors.onSurfaceVariant,
  };

  IconData get icon => switch (this) {
    ExpenseType.material => Icons.inventory_2_rounded,
    ExpenseType.equipment => Icons.handyman_rounded,
    ExpenseType.externalService => Icons.engineering_rounded,
    ExpenseType.other => Icons.more_horiz_rounded,
  };
}
