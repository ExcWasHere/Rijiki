import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/delivery_method.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/order_item.dart';
import 'package:rijiki/features/order/domain/order_status_history.dart';
import 'package:rijiki/features/order/presentation/controllers/staff_order_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/assign_worker_sheet.dart';
import 'package:rijiki/features/order/presentation/widgets/before_after_gallery.dart';
import 'package:rijiki/features/order/presentation/widgets/payment_chip.dart';
import 'package:rijiki/features/order/presentation/widgets/price_breakdown_card.dart';
import 'package:rijiki/features/order/presentation/widgets/status_correction_sheet.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/image_source_sheet.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/section_header.dart';
import 'package:rijiki/shared/widgets/status_chip.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class WorkerOrderDetailPage extends ConsumerWidget {
  const WorkerOrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(staffOrderDetailProvider(orderId));
    final loaded = order.value;

    Future<void> refresh() async {
      ref.invalidate(staffOrderDetailProvider(orderId));
      try {
        await ref.read(staffOrderDetailProvider(orderId).future);
      } catch (_) {
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(loaded?.orderNumber ?? 'Detail pesanan')),
      body: order.when(
        skipLoadingOnReload: true,
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            LoadingSkeleton(height: 150),
            SizedBox(height: AppSpacing.md),
            LoadingSkeleton(height: 220),
            SizedBox(height: AppSpacing.md),
            LoadingSkeleton(height: 130),
          ],
        ),
        error: (error, _) => Center(
          child: ErrorState(
            message: error is Failure
                ? error.message
                : 'Order gagal dimuat. Coba lagi ya.',
            onRetry: () => ref.invalidate(staffOrderDetailProvider(orderId)),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: refresh,
          child: _DetailBody(order: data),
        ),
      ),
      bottomNavigationBar: (loaded?.staff?.hasAnyAction ?? false)
          ? _ActionBar(order: loaded!)
          : null,
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.order});

  final CustomerOrder order;

  bool get _showProof {
    if (order.deliveryMethod != DeliveryMethod.delivery) return false;
    final hasProof = order.documentation.any(
      (doc) => doc.type == DocumentationType.proofOfDelivery,
    );
    return hasProof ||
        (order.staff?.canUploadType(DocumentationType.proofOfDelivery) ??
            false) ||
        order.status == OrderStatus.delivery;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _HeaderCard(order: order),
        if (order.status == OrderStatus.delivery && order.assignedToMe) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.push(RoutePaths.workerDeliveryRun),
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('Lihat peta pengantaran'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Sepatu & dokumentasi'),
        const SizedBox(height: AppSpacing.sm),
        for (final item in order.items) ...[
          _ItemCard(order: order, item: item),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_showProof) ...[
          const SizedBox(height: AppSpacing.xs),
          const SectionHeader(title: 'Bukti pengiriman'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: _DocSlot(
              key: ValueKey('${order.id}-proof'),
              order: order,
              type: DocumentationType.proofOfDelivery,
              label: 'Diterima',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!order.isOffline) ...[
          const SizedBox(height: AppSpacing.xs),
          const SectionHeader(title: 'Penjemputan & pengantaran'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.upload_rounded,
                  label: 'Alamat penjemputan',
                  value: order.pickupAddress,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.download_rounded,
                  label: 'Alamat pengantaran',
                  value: order.deliveryAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const SectionHeader(title: 'Pembayaran'),
        const SizedBox(height: AppSpacing.sm),
        PriceBreakdownCard(
          price: order.price,
          paid: order.isPaid,
          promoCode: order.promoCode,
          showPaymentStatus: order.status != OrderStatus.cancelled,
        ),
        if (order.statusHistory.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Riwayat status'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < order.statusHistory.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  _HistoryRow(entry: order.statusHistory[i]),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final CustomerOrder order;

  String get _handler {
    if (order.assignedToMe) return 'Kamu';
    final name = order.workerName;
    if (name != null && name.isNotEmpty) return name;
    return 'Belum diambil';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = order.status;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.orderNumber, style: textTheme.titleMedium),
              ),
              StatusChip(
                label: status.label,
                color: status.color,
                icon: status.icon,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Dibuat ${DateFormatter.dateTime(order.createdAt)}', style: muted),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Customer',
            value: [
              order.customerName ?? '-',
              if ((order.customerPhone ?? '').isNotEmpty) order.customerPhone!,
            ].join('\n'),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Ditangani oleh',
            value: _handler,
          ),
          if (order.isOffline) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.local_shipping_outlined,
              label: 'Serah-terima',
              value: order.deliveryMethod.label,
            ),
          ],
          if (order.scheduledPickupAt != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Jadwal jemput',
              value: DateFormatter.dateTime(order.scheduledPickupAt!),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: PaymentChip(paid: order.isPaid),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.order, required this.item});

  final CustomerOrder order;
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final notes = item.notes;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${item.shoeName} · ${item.serviceName}', style: textTheme.titleSmall),
          if (item.itemCode != null) ...[
            const SizedBox(height: 2),
            Text('Kode ${item.itemCode}', style: muted),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(notes, style: textTheme.bodySmall)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DocSlot(
                  key: ValueKey('${item.id}-before'),
                  order: order,
                  type: DocumentationType.before,
                  item: item,
                  label: 'Sebelum',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DocSlot(
                  key: ValueKey('${item.id}-after'),
                  order: order,
                  type: DocumentationType.after,
                  item: item,
                  label: 'Sesudah',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocSlot extends ConsumerStatefulWidget {
  const _DocSlot({
    super.key,
    required this.order,
    required this.type,
    required this.label,
    this.item,
  });

  final CustomerOrder order;
  final DocumentationType type;
  final String label;
  final OrderItem? item;

  @override
  ConsumerState<_DocSlot> createState() => _DocSlotState();
}

class _DocSlotState extends ConsumerState<_DocSlot> {
  bool _busy = false;

  OrderDocumentation? get _doc {
    final itemId = widget.item?.id;
    for (final doc in widget.order.documentation) {
      if (doc.type == widget.type && doc.orderItemId == itemId) return doc;
    }
    return null;
  }

  Future<void> _pick() async {
    final path = await pickImageFromSheet(context);
    if (path == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(staffOrderCommandsProvider)
          .uploadDocumentation(
            orderId: widget.order.id,
            type: widget.type,
            imagePath: path,
            orderItemId: widget.item?.id,
          );
      if (mounted) _snack(context, 'Foto tersimpan.');
    } catch (e) {
      if (mounted) _snack(context, Failure.messageOf(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(OrderDocumentation doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus foto?'),
        content: const Text('Foto ini akan dihapus dan bisa diunggah ulang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(staffOrderCommandsProvider)
          .deleteDocumentation(
            orderId: widget.order.id,
            documentationId: doc.id,
          );
      if (mounted) _snack(context, 'Foto dihapus.');
    } catch (e) {
      if (mounted) _snack(context, Failure.messageOf(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    final canUpload = widget.order.staff?.canUploadType(widget.type) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            PhotoTile(label: widget.label, doc: doc),
            if (_busy)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (canUpload) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _pick,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(doc == null ? 'Tambah foto' : 'Ganti'),
                ),
              ),
              if (doc != null)
                IconButton(
                  tooltip: 'Hapus foto',
                  onPressed: _busy ? null : () => _delete(doc),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final OrderStatusHistory entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = entry.status;
    final changedAt = entry.changedAt;
    final note = entry.note;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(status.icon, size: 18, color: status.color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status.label, style: textTheme.bodyMedium),
              Text(
                DateFormatter.dateTime(changedAt),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(note, style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MoreAction { assign, correct, cancel }

class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.order});

  final CustomerOrder order;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  CustomerOrder get _order => widget.order;

  static String _advanceLabel(OrderStatus next) => switch (next) {
    OrderStatus.pickup => 'Mulai jemput sepatu',
    OrderStatus.waiting => 'Sepatu tiba di outlet',
    OrderStatus.cleaning => 'Mulai dikerjakan',
    OrderStatus.delivery => 'Mulai antar',
    OrderStatus.completed => 'Selesaikan order',
    _ => next.label,
  };

  Future<bool> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && success != null) _snack(context, success);
      return true;
    } catch (e) {
      if (mounted) _snack(context, Failure.messageOf(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _ensureLocationReady() async {
    final location = ref.read(locationServiceProvider);
    final issue = await location.trackingIssue(request: true);
    if (issue == null) return true;
    if (!mounted) return false;

    final message = switch (issue) {
      LocationIssue.serviceDisabled =>
        'GPS perangkat sedang mati. Nyalakan GPS agar customer bisa melihat posisimu selama pengantaran.',
      LocationIssue.deniedForever =>
        'Izin lokasi ditolak permanen. Aktifkan izin lokasi untuk Rijiki di pengaturan aplikasi.',
      LocationIssue.denied =>
        'Izin lokasi wajib diberikan sebelum mulai mengantar, supaya customer bisa memantau posisimu.',
      LocationIssue.unavailable =>
        'Lokasi belum bisa dibaca. Pastikan GPS aktif lalu coba lagi.',
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Izin lokasi diperlukan'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
          if (issue == LocationIssue.deniedForever)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                location.openAppSettings();
              },
              child: const Text('Buka pengaturan'),
            ),
          if (issue == LocationIssue.serviceDisabled)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                location.openLocationSettings();
              },
              child: const Text('Buka pengaturan GPS'),
            ),
        ],
      ),
    );
    return false;
  }

  Future<void> _claim() => _run(
    () => ref.read(staffOrderCommandsProvider).claim(_order.id),
    success: 'Order diambil. Selamat bekerja!',
  );

  Future<void> _advance() async {
    final next = _order.staff?.nextStatus;
    if (next == null) return;
    if (next == OrderStatus.delivery && !await _ensureLocationReady()) return;

    if (next == OrderStatus.completed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Selesaikan order?'),
          content: const Text(
            'Order yang sudah selesai tidak bisa diubah lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Selesaikan'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final ok = await _run(
      () => ref.read(staffOrderCommandsProvider).updateStatus(_order.id, next),
      success: 'Status diperbarui: ${next.label}.',
    );

    if (ok &&
        next == OrderStatus.delivery &&
        mounted &&
        ref.read(sessionProvider)?.role == UserRole.worker) {
      context.push(RoutePaths.workerDeliveryRun);
    }
  }

  Future<void> _assign() async {
    final choice = await showAssignWorkerSheet(
      context,
      currentWorkerId: _order.assignedWorkerId,
    );
    if (choice == null) return;
    await _run(
      () => ref.read(staffOrderCommandsProvider).assign(_order.id, choice.workerId),
      success: choice.workerId == null
          ? 'Assign dilepas.'
          : 'Worker berhasil di-assign.',
    );
  }

  Future<void> _correct() async {
    final change = await showStatusCorrectionSheet(context, order: _order);
    if (change == null) return;
    await _run(
      () => ref
          .read(staffOrderCommandsProvider)
          .updateStatus(_order.id, change.status, notes: change.notes),
      success: 'Status dikoreksi: ${change.status.label}.',
    );
  }

  Future<void> _cancel() async {
    final notes = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hanya order yang belum dibayar yang bisa dibatalkan.'),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Alasan (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Batalkan order',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    final reason = notes.text.trim();
    notes.dispose();
    if (confirmed != true) return;

    await _run(
      () => ref
          .read(staffOrderCommandsProvider)
          .updateStatus(
            _order.id,
            OrderStatus.cancelled,
            notes: reason.isEmpty ? null : reason,
          ),
      success: 'Order dibatalkan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final caps = _order.staff;
    if (caps == null) return const SizedBox.shrink();

    final hasMore = caps.canAssign || caps.canCorrect || caps.canCancel;
    final next = caps.nextStatus;

    final Widget? primary;
    if (caps.canClaim) {
      primary = FilledButton(
        onPressed: _busy ? null : _claim,
        child: const Text('Ambil order'),
      );
    } else if (caps.canAdvance && next != null) {
      primary = FilledButton(
        onPressed: _busy ? null : _advance,
        child: Text(_advanceLabel(next)),
      );
    } else {
      primary = null;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (hasMore)
                PopupMenuButton<_MoreAction>(
                  enabled: !_busy,
                  tooltip: 'Aksi lain',
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (action) => switch (action) {
                    _MoreAction.assign => _assign(),
                    _MoreAction.correct => _correct(),
                    _MoreAction.cancel => _cancel(),
                  },
                  itemBuilder: (_) => [
                    if (caps.canAssign)
                      PopupMenuItem(
                        value: _MoreAction.assign,
                        child: Text(
                          _order.assignedWorkerId == null
                              ? 'Assign worker'
                              : 'Ganti / lepas worker',
                        ),
                      ),
                    if (caps.canCorrect)
                      const PopupMenuItem(
                        value: _MoreAction.correct,
                        child: Text('Koreksi status'),
                      ),
                    if (caps.canCancel)
                      const PopupMenuItem(
                        value: _MoreAction.cancel,
                        child: Text(
                          'Batalkan order',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              if (primary != null) ...[
                if (hasMore) const SizedBox(width: 8),
                Expanded(
                  child: _busy
                      ? const FilledButton(
                          onPressed: null,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        )
                      : primary,
                ),
              ] else
                const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
