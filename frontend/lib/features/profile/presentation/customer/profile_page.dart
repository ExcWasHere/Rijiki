import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/constants/asset_paths.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/auth/presentation/controllers/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final fullName = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : 'Sobat Rijiki';
    final initials = _initials(fullName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            _ProfileHero(
              name: fullName,
              email: user?.email ?? 'email belum tersedia',
              phone: user?.phoneNumber ?? 'nomor HP belum tersedia',
              initials: initials,
              onEdit: () => _showComingSoon(context, 'Edit profil'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  _MenuSection(
                    title: 'Akun',
                    items: [
                      _ProfileMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Data pribadi',
                        onTap: () => _showComingSoon(context, 'Data pribadi'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Alamat saya',
                        onTap: () => _showComingSoon(context, 'Alamat saya'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.lock_outline_rounded,
                        title: 'Keamanan akun',
                        onTap: () => _showComingSoon(context, 'Keamanan akun'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        onTap: () => _showComingSoon(context, 'Notifikasi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MenuSection(
                    title: 'Aktivitas',
                    items: [
                      _ProfileMenuItem(
                        icon: Icons.inventory_2_outlined,
                        title: 'Riwayat pesanan',
                        onTap: () => context.go(RoutePaths.customerOrders),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Sepatu saya',
                        onTap: () => _showComingSoon(context, 'Sepatu saya'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.star_border_rounded,
                        title: 'Rating & testimoni',
                        onTap: () =>
                            _showComingSoon(context, 'Rating & testimoni'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MenuSection(
                    title: 'Reward',
                    items: [
                      _ProfileMenuItem(
                        icon: Icons.monetization_on_outlined,
                        title: 'Poin saya',
                        trailing: '320 poin',
                        onTap: () => _showComingSoon(context, 'Poin saya'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Tukar poin',
                        onTap: () => _showComingSoon(context, 'Tukar poin'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MenuSection(
                    title: 'Bantuan',
                    items: [
                      _ProfileMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Pusat bantuan',
                        onTap: () => _showComingSoon(context, 'Pusat bantuan'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Hubungi Rijiki',
                        onTap: () => _showComingSoon(context, 'Hubungi Rijiki'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Syarat & ketentuan',
                        onTap: () =>
                            _showComingSoon(context, 'Syarat & ketentuan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: ref.watch(authControllerProvider).isLoading
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .logout(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final values = words.toList();
    if (values.isEmpty) return 'R';
    if (values.length == 1) return values.first.substring(0, 1).toUpperCase();
    return '${values.first[0]}${values.last[0]}'.toUpperCase();
  }

  static void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$title segera hadir')));
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.phone,
    required this.initials,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String phone;
  final String initials;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topInset + 244,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: _ProfileBanner()),
          Positioned(
            top: topInset + AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: const _ProfileHeader(),
          ),
          Positioned(
            top: topInset + 88,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: _ProfileCard(
              name: name,
              email: email,
              phone: phone,
              initials: initials,
              onEdit: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner();

  // Ganti path ini dengan lokasi asset banner profil.

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 226,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(44)),
      ),
      child: Image.asset(AssetPaths.banner1, width: double.infinity, fit: BoxFit.cover),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.canPop() ? context.pop() : null,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('Profil', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.initials,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String phone;
  final String initials;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(18)),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryDark,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  phone,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profil',
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                items[index],
                if (index < items.length - 1)
                  const Divider(indent: 52, endIndent: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurface),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                trailing!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}
