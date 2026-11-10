import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';
import 'package:rijiki/features/points/presentation/controllers/point_management_controller.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final d = value.toLocal();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}.${p(d.minute)}';
}

class RedemptionManagePage extends ConsumerWidget {
  const RedemptionManagePage({super.key});

  static const List<RedemptionStatus?> _filters = [
    RedemptionStatus.pending,
    RedemptionStatus.approved,
    RedemptionStatus.fulfilled,
    RedemptionStatus.rejected,
    null,
  ];

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    PointRedemption redemption,
    RedemptionStatus status, {
    String? notes,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(redemptionActionProvider.notifier)
        .process(redemption: redemption, status: status, notes: notes);

    final message = ok
        ? switch (status) {
            RedemptionStatus.approved =>
              'Disetujui. ${redemption.pointsUsed} poin dipotong dari saldo.',
            RedemptionStatus.rejected => 'Pengajuan ditolak.',
            RedemptionStatus.fulfilled => 'Ditandai sudah diserahkan.',
            RedemptionStatus.pending => 'Tersimpan.',
          }
        : (ref.read(redemptionActionProvider).errorMessage ??
              'Gagal memproses. Coba lagi ya.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    PointRedemption r,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Setujui penukaran?',
      message:
          '${r.displayName} menukar ${r.pointsUsed} poin dengan ${r.rewardName}. '
          'Saldo saat ini ${r.customerBalance} poin. Poin langsung dipotong '
          'dan stok berkurang satu.',
      confirmLabel: 'Setujui',
    );
    if (!ok || !context.mounted) return;
    await _run(context, ref, r, RedemptionStatus.approved);
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    PointRedemption r,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(),
    );
    if (reason == null || !context.mounted) return;
    await _run(context, ref, r, RedemptionStatus.rejected, notes: reason);
  }

  Future<void> _fulfill(
    BuildContext context,
    WidgetRef ref,
    PointRedemption r,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Tandai sudah diserahkan?',
      message: '${r.rewardName} sudah diterima ${r.displayName}.',
      confirmLabel: 'Sudah diserahkan',
    );
    if (!ok || !context.mounted) return;
    await _run(context, ref, r, RedemptionStatus.fulfilled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(redemptionFilterProvider);
    final async = ref.watch(redemptionsProvider);
    final action = ref.watch(redemptionActionProvider);
    final data = async.value;
    final textTheme = Theme.of(context).textTheme;

    Widget body;
    if (data != null) {
      body = data.items.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: EmptyState(
                icon: Icons.redeem_rounded,
                title: filter == RedemptionStatus.pending
                    ? 'Tidak ada pengajuan menunggu'
                    : 'Belum ada pengajuan',
                message:
                    'Pengajuan tukar poin dari customer akan muncul di sini.',
              ),
            )
          : Column(
              children: [
                for (final r in data.items) ...[
                  _RedemptionTile(
                    redemption: r,
                    busy: action.busyId == r.id,
                    locked: action.busyId != null,
                    onApprove: () => _approve(context, ref, r),
                    onReject: () => _reject(context, ref, r),
                    onFulfill: () => _fulfill(context, ref, r),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                ],
              ],
            );
    } else if (async.hasError) {
      body = ErrorState(
        message: 'Gagal memuat pengajuan tukar poin.',
        onRetry: () => ref.invalidate(redemptionsProvider),
      );
    } else {
      body = const LoadingSkeleton(height: 220, radius: AppSpacing.radiusLg);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Penukaran poin')),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(redemptionsProvider);
          try {
            await ref.read(redemptionsProvider.future);
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
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in _filters) ...[
                    ChoiceChip(
                      label: Text(
                        s == RedemptionStatus.pending &&
                                (data?.pendingCount ?? 0) > 0
                            ? '${s!.label} (${data!.pendingCount})'
                            : (s?.label ?? 'Semua'),
                      ),
                      selected: filter == s,
                      onSelected: (_) =>
                          ref.read(redemptionFilterProvider.notifier).select(s),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (data != null && data.total > data.items.length)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Menampilkan ${data.items.length} dari ${data.total} '
                  'pengajuan terbaru.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            body,
          ],
        ),
      ),
    );
  }
}

class _RedemptionTile extends StatelessWidget {
  const _RedemptionTile({
    required this.redemption,
    required this.busy,
    required this.locked,
    required this.onApprove,
    required this.onReject,
    required this.onFulfill,
  });

  final PointRedemption redemption;
  final bool busy;
  final bool locked;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onFulfill;

  Color _statusColor(BuildContext context) {
    return switch (redemption.status) {
      RedemptionStatus.pending => AppColors.rijikiOrange,
      RedemptionStatus.approved => AppColors.rijikiBlue,
      RedemptionStatus.fulfilled => AppColors.success,
      RedemptionStatus.rejected => Theme.of(context).colorScheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final r = redemption;
    final statusColor = _statusColor(context);

    final processedLine = r.processedAt == null
        ? null
        : 'Diproses ${_formatDateTime(r.processedAt)}'
              '${r.processedByName == null ? '' : ' oleh ${r.processedByName}'}';

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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.displayName, style: textTheme.titleSmall),
                    if ((r.customerPhone ?? '').isNotEmpty)
                      Text(r.customerPhone!, style: muted),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.status.label,
                  style: textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(r.rewardName, style: textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            '${r.pointsUsed} poin. Saldo customer sekarang ${r.customerBalance} poin.',
            style: muted,
          ),
          const SizedBox(height: 2),
          Text('Diajukan ${_formatDateTime(r.requestedAt)}', style: muted),
          if (processedLine != null) Text(processedLine, style: muted),
          if ((r.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Catatan: ${r.notes}', style: textTheme.bodySmall),
          ],
          if (r.status == RedemptionStatus.pending ||
              r.status == RedemptionStatus.approved) ...[
            const SizedBox(height: AppSpacing.md),
            if (busy)
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (r.status == RedemptionStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: locked ? null : onReject,
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: locked ? null : onApprove,
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: locked ? null : onFulfill,
                  child: const Text('Tandai sudah diserahkan'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Isi alasan penolakan.');
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak pengajuan?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 300,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Alasan penolakan',
          helperText: 'Alasan ini bisa dilihat customer.',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Tolak')),
      ],
    );
  }
}
