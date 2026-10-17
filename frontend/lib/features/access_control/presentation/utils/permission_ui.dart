import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/app_permission.dart';

extension AppPermissionUi on AppPermission {
  String get label => switch (this) {
    AppPermission.manageOrdersAll => 'Kelola semua order',
    AppPermission.manageCmsServices => 'Kelola layanan',
    AppPermission.manageCmsEvents => 'Kelola event',
    AppPermission.manageCmsPromos => 'Kelola promo',
    AppPermission.manageCmsMerchandise => 'Kelola merchandise',
    AppPermission.manageTestimonials => 'Kelola testimoni',
    AppPermission.manageFinance => 'Kelola keuangan',
    AppPermission.manageWorkers => 'Kelola worker',
    AppPermission.managePoints => 'Kelola poin',
    AppPermission.viewAnalytics => 'Lihat analitik',
  };

  String get description => switch (this) {
    AppPermission.manageOrdersAll =>
      'Melihat dan mengelola seluruh order, bukan hanya yang ditugaskan, '
          'serta menugaskan worker.',
    AppPermission.manageCmsServices => 'Mengubah daftar layanan dan harganya.',
    AppPermission.manageCmsEvents =>
      'Menambah dan mengubah event, kolaborasi, dan pengumuman.',
    AppPermission.manageCmsPromos => 'Mengelola kode promo.',
    AppPermission.manageCmsMerchandise =>
      'Mengelola merchandise yang bisa ditukar dengan poin.',
    AppPermission.manageTestimonials =>
      'Menandai testimoni pilihan dan mengunduh rekap foto.',
    AppPermission.manageFinance =>
      'Melihat dan mencatat pemasukan serta pengeluaran, juga ekspor Excel.',
    AppPermission.manageWorkers =>
      'Melihat data, KPI, dan rating worker. Hak akses tetap khusus Owner.',
    AppPermission.managePoints => 'Mengatur aturan poin dan penukaran.',
    AppPermission.viewAnalytics => 'Melihat analitik seperti repeat customer.',
  };
}

class PermissionGroup {
  const PermissionGroup(this.title, this.icon, this.permissions);

  final String title;
  final IconData icon;
  final List<AppPermission> permissions;
}

const List<PermissionGroup> permissionGroups = [
  PermissionGroup('Order', Icons.receipt_long_rounded, [
    AppPermission.manageOrdersAll,
  ]),
  PermissionGroup('Konten (CMS)', Icons.dashboard_customize_rounded, [
    AppPermission.manageCmsServices,
    AppPermission.manageCmsEvents,
    AppPermission.manageCmsPromos,
    AppPermission.manageCmsMerchandise,
    AppPermission.manageTestimonials,
  ]),
  PermissionGroup('Keuangan', Icons.account_balance_wallet_rounded, [
    AppPermission.manageFinance,
  ]),
  PermissionGroup('Worker', Icons.groups_rounded, [
    AppPermission.manageWorkers,
  ]),
  PermissionGroup('Poin', Icons.stars_rounded, [AppPermission.managePoints]),
  PermissionGroup('Analitik', Icons.insights_rounded, [
    AppPermission.viewAnalytics,
  ]),
];
