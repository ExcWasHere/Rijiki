import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/home/owner/presentation/management/domain/management_module.dart';

/// Modul Manajemen yang dapat dibuka worker bila Owner memberi izin terkait
/// (PRD Bagian 5.1). Modul "Hak Akses" sengaja tidak ada karena khusus Owner.
///
/// `route` masih null (tampil "Segera") sampai halaman versi worker dibuat:
/// halaman owner saat ini berpindah layar lewat path `/owner/...`.
const List<ManagementModule> _workerModules = [
  ManagementModule(
    id: 'orders_all',
    title: 'Semua order',
    subtitle: 'Lihat dan atur seluruh order',
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
  ),
  ManagementModule(
    id: 'workers',
    title: 'Karyawan',
    subtitle: 'Data karyawan dan KPI',
    icon: Icons.groups_rounded,
    color: AppColors.primaryDark,
    permissions: {AppPermission.manageWorkers},
  ),
  ManagementModule(
    id: 'cms',
    title: 'CMS',
    subtitle: 'Layanan, acara, promo, merchandise',
    icon: Icons.dashboard_customize_rounded,
    color: AppColors.accent,
    permissions: {
      AppPermission.manageCmsServices,
      AppPermission.manageCmsEvents,
      AppPermission.manageCmsPromos,
      AppPermission.manageCmsMerchandise,
      AppPermission.manageTestimonials,
    },
  ),
  ManagementModule(
    id: 'points',
    title: 'Poin',
    subtitle: 'Penukaran dan aturan poin',
    icon: Icons.stars_rounded,
    color: AppColors.rijikiOrange,
    permissions: {AppPermission.managePoints},
  ),
];

/// Fase UI: true = semua modul tampil untuk worker yang sudah login.
/// Ubah ke false saat integrasi backend agar modul disaring oleh izin
/// delegasi Owner (PRD Bagian 5.1).
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
