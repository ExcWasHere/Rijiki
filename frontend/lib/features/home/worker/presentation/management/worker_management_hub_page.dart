import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/home/owner/presentation/management/presentation/widgets/module_menu_tile.dart';
import 'package:rijiki/features/home/worker/presentation/management/controllers/worker_management_modules_controller.dart';

class WorkerManagementHubPage extends ConsumerWidget {
  const WorkerManagementHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(workerManagementModulesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manajemen', style: textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Kelola data dan pengaturan untuk karyawan.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (modules.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 40,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Belum ada menu yang bisa diakses.',
                          textAlign: TextAlign.center,
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Minta Owner memberi izin bila kamu butuh akses.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm + 4,
                    crossAxisSpacing: AppSpacing.sm + 4,
                    mainAxisExtent: 156,
                  ),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final module = modules[index];
                    return ModuleMenuTile(
                      module: module,
                      onTap: () {
                        final route = module.route;
                        if (route == null) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('${module.title} segera hadir.'),
                              ),
                            );
                          return;
                        }
                        context.push(route);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
