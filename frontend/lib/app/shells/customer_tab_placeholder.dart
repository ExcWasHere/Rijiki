import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';

class CustomerTabPlaceholder extends ConsumerWidget {
  const CustomerTabPlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    this.showAccount = false,
  });

  final String title;
  final IconData icon;
  final String description;
  final bool showAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                icon: icon,
                title: 'Segera hadir',
                message: description,
              ),
              if (showAccount) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  user?.email ?? '-',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () =>
                            ref.read(authControllerProvider.notifier).logout(),
                  child: const Text(AppStrings.logout),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
