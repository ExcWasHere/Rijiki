import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/cms/domain/cms_section.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_hub_controller.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_section_tile.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';

class CmsHubPage extends ConsumerWidget {
  const CmsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(cmsSectionsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CMS')),
      body: sections.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Belum ada bagian CMS yang bisa diakses',
              ),
            )
          : RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: () => refreshCmsHub(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    'Kelola konten yang dilihat customer.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final section in sections) ...[
                    _SectionRow(section: section),
                    const SizedBox(height: AppSpacing.sm + 4),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SectionRow extends ConsumerWidget {
  const _SectionRow({required this.section});

  final CmsSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cmsSectionSummaryProvider(section.id));

    return CmsSectionTile(
      section: section,
      summary: summary.value,
      summaryLoading: summary.isLoading,
      onTap: () {
        final route = section.route;
        if (route == null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('${section.title} segera hadir.')),
            );
          return;
        }
        context.push(route);
      },
    );
  }
}
