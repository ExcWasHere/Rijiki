import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/auth/presentation/controllers/auth_controller.dart';

/// Halaman "Keamanan akun" yang dipakai semua role.
class AccountSecurityPage extends ConsumerWidget {
  const AccountSecurityPage({super.key});

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _linkGoogle(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(authControllerProvider.notifier).linkGoogle();
    if (!context.mounted) return;

    if (ok) {
      _toast(context, 'Akun Google berhasil dihubungkan.');
      return;
    }
    final state = ref.read(authControllerProvider);
    if (state.hasError) _toast(context, Failure.messageOf(state.error!));
    // Dibatalkan pengguna: tidak menampilkan apa-apa.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final busy = ref.watch(authControllerProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keamanan akun')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                'Akun',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _SecurityTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Ganti kata sandi',
                    subtitle: 'Perbarui kata sandi akunmu',
                    onTap: () => context.push(RoutePaths.changePassword),
                  ),
                  const Divider(indent: 56, endIndent: AppSpacing.md),
                  _SecurityTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Ganti email',
                    subtitle: user?.email ?? 'email belum tersedia',
                    onTap: () => context.push(RoutePaths.changeEmail),
                  ),
                  const Divider(indent: 56, endIndent: AppSpacing.md),
                  _SecurityTile(
                    icon: Icons.link_rounded,
                    title: 'Akun Google',
                    subtitle: 'Hubungkan akun Google untuk masuk lebih cepat',
                    loading: busy,
                    onTap: busy ? null : () => _linkGoogle(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurface),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}