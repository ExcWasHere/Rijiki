import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/shared/widgets/animated_nav_bar.dart';

class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<NavBarItem> _items = [
    NavBarItem(
      label: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard_rounded,
    ),
    NavBarItem(
      label: 'Order',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
    ),
    NavBarItem(
      label: 'Manajemen',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
    ),
    NavBarItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: AnimatedNavBar(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onSelected: (branch) => navigationShell.goBranch(
          branch,
          initialLocation: branch == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
