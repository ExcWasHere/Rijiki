import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/home/owner/presentation/management/domain/management_module.dart';

// Modul tanpa `route` tampil "segera hadir" saat diketuk. Halaman CMS,
// Karyawan, Pelanggan Setia, dan Poin berada di luar shell owner (tanpa
// bottom navbar) agar bisa dibuka worker berizin; backend tetap memeriksa
// izin di setiap endpoint.
const List<ManagementModule> _workerModules = [
  ManagementModule(
    id: 'orders_all',
    title: 'Semua pesanan',
    subtitle: 'Lihat dan atur seluruh pesanan',
    icon: Icons.receipt_long_rounded,
    color: AppColors.primary,
    permissions: {AppPermission.manageOrdersAll},
  ),
  ManagementModule(
    id: 'finance',
    title: 'Keuangan',
    subtitle: 'Pemasukan, pengeluaran, dan laba',
    icon: Icons.account_balance_wallet_rounded,
    color: AppColors.rijikiBlue,
    permissions: {AppPermission.manageFinance},
  ),
  ManagementModule(
    id: 'repeat_customers',
    title: 'Pelanggan Setia',
    subtitle: 'Pelanggan yang kembali order',
    icon: Icons.favorite_rounded,
    color: AppColors.rijikiOrange,
    permissions: {AppPermission.viewAnalytics},
    route: RoutePaths.managementRepeatCustomers,
  ),
  ManagementModule(
    id: 'workers',
    title: 'Karyawan',
    subtitle: 'Data karyawan dan KPI',
    icon: Icons.groups_rounded,
    color: AppColors.primaryDark,
    permissions: {AppPermission.manageWorkers},
    route: RoutePaths.ownerWorkers,
  ),
  ManagementModule(
    id: 'cms',
    title: 'CMS',
    subtitle: 'Layanan, acara, promo, souvenir',
    icon: Icons.dashboard_customize_rounded,
    color: AppColors.accent,
    permissions: {
      AppPermission.manageCmsServices,
      AppPermission.manageCmsEvents,
      AppPermission.manageCmsPromos,
      AppPermission.manageCmsMerchandise,
      AppPermission.manageTestimonials,
      AppPermission.managePoints,
    },
    route: RoutePaths.ownerCms,
  ),
  ManagementModule(
    id: 'points',
    title: 'Poin',
    subtitle: 'Penukaran, penyesuaian, dan aturan poin',
    icon: Icons.stars_rounded,
    color: AppColors.rijikiOrange,
    permissions: {AppPermission.managePoints},
    route: RoutePaths.managementPoints,
  ),
];
const bool _showAllModulesForWorker = false;

final workerManagementModulesProvider = Provider<List<ManagementModule>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const [];
  if (_showAllModulesForWorker) return _workerModules;
  return [
    for (final module in _workerModules)
      if (module.isVisibleFor(user)) module,
  ];
});
