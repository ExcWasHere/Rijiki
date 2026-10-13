import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/home/owner/presentation/management/domain/management_module.dart';

const List<ManagementModule> _allModules = [
  ManagementModule(
    id: 'finance',
    title: 'Keuangan',
    subtitle: 'Pemasukan, pengeluaran, dan laba',
    icon: Icons.account_balance_wallet_rounded,
    color: AppColors.rijikiBlue,
    route: RoutePaths.ownerFinance,
    permissions: {AppPermission.manageFinance},
  ),
  ManagementModule(
    id: 'repeat_customers',
    title: 'Repeat customer',
    subtitle: 'Pelanggan yang kembali order',
    icon: Icons.favorite_rounded,
    color: AppColors.rijikiOrange,
    route: RoutePaths.ownerManagementRepeatCustomers,
    permissions: {AppPermission.viewAnalytics},
  ),
  ManagementModule(
    id: 'workers',
    title: 'Worker',
    subtitle: 'Data worker dan KPI',
    icon: Icons.groups_rounded,
    color: AppColors.primaryDark,
    permissions: {AppPermission.manageWorkers},
  ),
  ManagementModule(
    id: 'cms',
    title: 'CMS',
    subtitle: 'Layanan, event, promo, merchandise',
    icon: Icons.dashboard_customize_rounded,
    color: AppColors.accent,
    permissions: {
      AppPermission.manageCmsServices,
      AppPermission.manageCmsEvents,
      AppPermission.manageCmsPromos,
      AppPermission.manageCmsMerchandise,
    },
  ),
];

final managementModulesProvider = Provider<List<ManagementModule>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const [];
  return [
    for (final module in _allModules)
      if (module.isVisibleFor(user)) module,
  ];
});
