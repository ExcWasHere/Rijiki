import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_format.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/cms/presentation/controllers/testimonial_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/utils/recap_share.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/rating/domain/managed_rating.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/private_image.dart';

class TestimonialManagePage extends ConsumerWidget {
  const TestimonialManagePage({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final request = await showModalBottomSheet<RecapRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => const _ExportSheet(),
    );
    if (request == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Menyiapkan rekap, mohon tunggu...')),
      );
    final file = await ref.read(recapExportProvider.notifier).run(request);
    messenger.hideCurrentSnackBar();

    if (file == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ref.read(recapExportProvider).error ?? 'Rekap gagal dibuat.',
          ),
        ),
      );
      return;
    }

    if (file.truncated) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Rekap memuat ${file.included} dari ${file.total} foto. '
            'Persempit rentang tanggal untuk sisanya.',
          ),
        ),
      );
    }
    try {
      await shareRecapFile(file);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Rekap sudah dibuat, tetapi gagal dibuka. Coba lagi.'),
          ),
        );
    }
  }

  Future<void> _toggleFeatured(
    BuildContext context,
    WidgetRef ref,
    ManagedRating rating,
    bool value,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(testimonialActionProvider.notifier)
        .setFeatured(rating, value);
    final message = ok
        ? (value
              ? 'Testimoni ditampilkan di home customer.'
              : 'Testimoni dicabut dari home customer.')
        : (ref.read(testimonialActionProvider).errorMessage ??
              'Gagal mengubah testimoni.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(testimonialListProvider);
    final data = async.value;
    final filter = ref.watch(testimonialFilterProvider);
    final action = ref.watch(testimonialActionProvider);
    final exporting = ref.watch(recapExportProvider).busy;

    Widget body;
    if (data != null) {
      body = AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: async.isLoading ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(summary: data.summary),
            const SizedBox(height: AppSpacing.md),
            _FilterChips(
              selected: filter,
              onSelected: ref.read(testimonialFilterProvider.notifier).set,
            ),
            const SizedBox(height: AppSpacing.md),
            if (data.items.isEmpty)
              CmsStateCard(
                child: EmptyState(
                  icon: Icons.reviews_rounded,
                  title: filter == RatingListFilter.all
                      ? 'Belum ada rating'
                      : 'Tidak ada rating untuk filter ini',
                  message: filter == RatingListFilter.all
                      ? 'Rating dari customer akan muncul di sini.'
                      : null,
                ),
              )
            else ...[
              for (final rating in data.items) ...[
                _RatingTile(
                  rating: rating,
                  action: action,
                  onToggle: (value) =>
                      _toggleFeatured(context, ref, rating, value),
                ),
                const SizedBox(height: AppSpacing.sm + 4),
              ],
              if (data.hasMore)
                Center(
                  child: data.loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: ref
                              .read(testimonialListProvider.notifier)
                              .loadMore,
                          child: const Text('Muat lebih banyak'),
                        ),
                ),
            ],
          ],
        ),
      );
    } else if (async.hasError) {
      body = CmsStateCard(
        child: ErrorState(
          message: 'Gagal memuat rating.',
          onRetry: () => ref.invalidate(testimonialListProvider),
        ),
      );
    } else {
      body = const LoadingSkeleton(height: 360, radius: AppSpacing.radiusLg);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Testimoni'),
        actions: [
          IconButton(
            tooltip: 'Unduh rekap',
            onPressed: exporting ? null : () => _export(context, ref),
            icon: exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(testimonialListProvider);
          try {
            await ref.read(testimonialListProvider.future);
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [body],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final average = summary.average;

    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          stat(average == null ? '-' : average.toStringAsFixed(1), 'Rata-rata'),
          stat('${summary.total}', 'Rating'),
          stat('${summary.featured}', 'Pilihan'),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final RatingListFilter selected;
  final ValueChanged<RatingListFilter> onSelected;

  static const Map<RatingListFilter, String> _labels = {
    RatingListFilter.all: 'Semua',
    RatingListFilter.featured: 'Pilihan',
    RatingListFilter.withPhoto: 'Ada foto',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final entry in _labels.entries)
          ChoiceChip(
            selected: selected == entry.key,
            onSelected: (_) => onSelected(entry.key),
            showCheckmark: false,
            label: Text(entry.value),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary.withValues(alpha: 0.3),
            shape: const StadiumBorder(),
            side: BorderSide(
              color: selected == entry.key
                  ? AppColors.primaryDark
                  : AppColors.outline.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.rating,
    required this.action,
    required this.onToggle,
  });

  final ManagedRating rating;
  final CmsActionState action;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final busy = action.busyId == rating.id;
    final shown = busy ? (action.busyValue ?? rating.isFeatured) : rating.isFeatured;
    final comment = rating.comment;
    final photoKey = rating.photoKey;
    final meta = [
      if (rating.customerName != null) rating.customerName!,
      if (rating.orderNumber != null) rating.orderNumber!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < rating.ratingValue
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: AppColors.accent,
                          ),
                        const SizedBox(width: 8),
                        Text(formatDate(rating.createdAt), style: muted),
                      ],
                    ),
                    if (comment != null && comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(comment, style: textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 6),
                    if (meta.isNotEmpty) Text(meta, style: muted),
                    if (rating.serviceNames.isNotEmpty)
                      Text(rating.serviceNames.join(' + '), style: muted),
                    if (rating.workerName != null)
                      Text('Worker: ${rating.workerName}', style: muted),
                  ],
                ),
              ),
              if (photoKey != null) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: 420,
                        child: InteractiveViewer(
                          child: PrivateImage(
                            imageKey: photoKey,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: PrivateImage(imageKey: photoKey),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tampilkan di home customer',
                  style: textTheme.bodyMedium,
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: shown,
                  onChanged: action.busyId != null ? null : onToggle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet();

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  RecapSource _source = RecapSource.testimonials;
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      initialDateRange: _range,
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  Widget _sourceChip(RecapSource source, String label) {
    final selected = _source == source;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _source = source),
      showCheckmark: false,
      label: Text(label),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: selected
            ? AppColors.primaryDark
            : AppColors.outline.withValues(alpha: 0.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final range = _range;
    final isBeforeAfter = _source == RecapSource.beforeAfter;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unduh rekap (ZIP)', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _sourceChip(RecapSource.testimonials, 'Testimoni customer'),
              _sourceChip(RecapSource.beforeAfter, 'Foto before/after'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isBeforeAfter
                ? 'Foto sebelum dan sesudah dari worker. Foto ini dihapus '
                      'otomatis 1 bulan setelah diunggah, jadi unduh sebelum itu. '
                      'Tanpa tanggal: 30 hari terakhir.'
                : 'Foto testimoni dari customer beserta rating dan komentar. '
                      'Tanpa tanggal: semua rating.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(
                    range == null
                        ? 'Pilih rentang tanggal'
                        : '${formatDate(range.start)} – ${formatDate(range.end)}',
                  ),
                ),
              ),
              if (range != null)
                IconButton(
                  tooltip: 'Hapus tanggal',
                  onPressed: () => setState(() => _range = null),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                RecapRequest(
                  source: _source,
                  startDate: range?.start,
                  endDate: range?.end,
                ),
              ),
              child: const Text('Unduh'),
            ),
          ),
        ],
      ),
    );
  }
}
