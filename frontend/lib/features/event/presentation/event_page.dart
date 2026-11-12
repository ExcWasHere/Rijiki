import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/event_type.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/event/domain/event_promo.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/presentation/controllers/customer_events_controller.dart';
import 'package:rijiki/features/event/presentation/controllers/events_refresh.dart';
import 'package:rijiki/features/event/presentation/utils/event_promo_format.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';
import 'package:rijiki/features/points/domain/reward.dart';
import 'package:rijiki/features/points/presentation/controllers/point_history_controller.dart';
import 'package:rijiki/features/points/presentation/controllers/point_redeem_controller.dart';
import 'package:rijiki/features/points/presentation/utils/point_history_format.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/network_image_box.dart';

class EventPage extends ConsumerStatefulWidget {
  const EventPage({super.key});

  @override
  ConsumerState<EventPage> createState() => _EventPageState();
}

class _EventPageState extends ConsumerState<EventPage>
    with WidgetsBindingObserver {
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Acara', 'Promo', 'Merch'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(customerEventsProvider);
      ref.invalidate(pointBalanceProvider);
      ref.invalidate(rewardsProvider);
      ref.invalidate(pendingRedemptionsProvider);
    }
  }

  Future<void> _refresh() async {
    refreshEventsTab(ref);
    try {
      await Future.wait([
        ref.read(customerEventsProvider.future),
        ref.read(pointBalanceProvider.future),
        ref.read(rewardsProvider.future),
        ref.read(pendingRedemptionsProvider.future),
      ]);
    } catch (_) {}
  }

  Future<void> _redeem(Reward reward) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tukar ${reward.name}?'),
        content: Text(
          '${formatPoints(reward.pointsCost)} poin akan dipakai. Pengajuan '
          'dikirim ke Rijiki dulu, dan poin baru dipotong setelah disetujui.\n\n'
          'Setelah disetujui, hadiah bisa diambil sendiri di outlet atau '
          'dibawa bersama order berikutnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ajukan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(redeemProvider.notifier).redeem(reward);
    if (!mounted) return;

    final message = ok
        ? 'Pengajuan tukar ${reward.name} terkirim. Tunggu persetujuan Rijiki ya.'
        : (ref.read(redeemProvider).errorMessage ??
              'Gagal mengajukan penukaran. Coba lagi ya.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRejectionNotice(List<PointRedemption> items) {
    const maxShown = 3;
    final lines = [
      for (final r in items.take(maxShown))
        '• ${r.rewardName}: '
            '${(r.notes ?? '').trim().isEmpty ? 'tidak ada alasan dicantumkan.' : r.notes!.trim()}',
    ];
    final more = items.length - maxShown;
    final text = [
      items.length == 1
          ? 'Pengajuan tukar poin ditolak.'
          : '${items.length} pengajuan tukar poin ditolak.',
      ...lines,
      if (more > 0) '+$more lainnya',
    ].join('\n');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 8),
          showCloseIcon: true,
        ),
      );
  }

  List<PromoEvent> _applyFilter(List<PromoEvent> all) {
    return switch (_selectedFilter) {
      'Promo' => [
        for (final e in all)
          if (e.type == EventType.promo) e,
      ],
      'Acara' => [
        for (final e in all)
          if (e.type != EventType.promo) e,
      ],
      _ => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final showEvents = _selectedFilter != 'Merch';
    final showMerch = _selectedFilter == 'Semua' || _selectedFilter == 'Merch';
    final async = ref.watch(customerEventsProvider);
    final events = async.value;
    final balance = ref.watch(pointBalanceProvider);
    final rewards = ref.watch(rewardsProvider);
    final pending =
        ref.watch(pendingRedemptionsProvider).value ?? const <PointRedemption>[];
    final available = ref.watch(availablePointsProvider);
    final redeem = ref.watch(redeemProvider);
    final reserved = pending.fold<int>(0, (sum, r) => sum + r.pointsUsed);

    ref.listen<AsyncValue<List<PointRedemption>>>(rejectionNoticesProvider, (
      previous,
      next,
    ) {
      final items = next.value;
      if (items == null || items.isEmpty || !mounted) return;
      _showRejectionNotice(items);
    });

    Widget eventsBody;
    if (events != null) {
      final filtered = _applyFilter(events);
      eventsBody = filtered.isEmpty
          ? const _EmptyState(message: 'Belum ada promo atau acara.')
          : Column(
              children: [
                for (final item in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PromoEventCard(
                      event: item,
                      onTap: () => _showDetail(context, item),
                    ),
                  ),
              ],
            );
    } else if (async.hasError) {
      eventsBody = ErrorState(
        message: 'Gagal memuat promo dan acara.',
        onRetry: () => ref.invalidate(customerEventsProvider),
      );
    } else {
      eventsBody = const Column(
        children: [
          LoadingSkeleton(height: 140, radius: 18),
          SizedBox(height: AppSpacing.sm),
          LoadingSkeleton(height: 140, radius: 18),
        ],
      );
    }

    Widget rewardsBody;
    final rewardList = rewards.value;
    if (rewardList != null) {
      rewardsBody = rewardList.isEmpty
          ? const _EmptyState(message: 'Belum ada hadiah yang bisa ditukar.')
          : SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rewardList.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final reward = rewardList[index];
                  return _RewardCard(
                    reward: reward,
                    available: available,
                    busy: redeem.busyId == reward.id,
                    locked: redeem.busyId != null,
                    onRedeem: () => _redeem(reward),
                  );
                },
              ),
            );
    } else if (rewards.hasError) {
      rewardsBody = ErrorState(
        message: 'Gagal memuat hadiah.',
        onRetry: () => ref.invalidate(rewardsProvider),
      );
    } else {
      rewardsBody = const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            LoadingSkeleton(width: 175, height: 270, radius: 18),
            SizedBox(width: AppSpacing.sm),
            LoadingSkeleton(width: 175, height: 270, radius: 18),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 32,
            ),
            children: [
              const _EventHeader(),
              const SizedBox(height: AppSpacing.md),
              _PointCard(
                balance: balance,
                onTap: () => balance.hasError
                    ? ref.invalidate(pointBalanceProvider)
                    : context.push(RoutePaths.customerPointHistory),
              ),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _PendingStrip(
                  count: pending.length,
                  reserved: reserved,
                  available: available,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _FilterList(
                filters: _filters,
                selectedFilter: _selectedFilter,
                onSelected: (value) => setState(() => _selectedFilter = value),
              ),
              if (showEvents) ...[
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle(title: 'Promo & acara'),
                const SizedBox(height: AppSpacing.sm),
                eventsBody,
              ],
              if (showMerch) ...[
                const SizedBox(height: AppSpacing.md),
                const _SectionTitle(title: 'Merch'),
                const SizedBox(height: AppSpacing.sm),
                rewardsBody,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String? _period(PromoEvent event) {
  final start = event.startDate;
  final end = event.endDate;
  if (start != null && end != null) {
    return '${DateFormatter.shortDate(start)} - ${DateFormatter.shortDate(end)}';
  }
  return DateFormatter.validity(start, end);
}

void _showDetail(BuildContext context, PromoEvent event) {
  final messenger = ScaffoldMessenger.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) =>
        _EventDetailSheet(event: event, messenger: messenger),
  );
}

class _EventHeader extends StatelessWidget {
  const _EventHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Acara & Promo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({required this.balance, required this.onTap});

  final AsyncValue<PointBalance> balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = balance.value;

    Widget title;
    if (value != null) {
      title = Text(
        '${formatPoints(value.balance)} Point',
        style: textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      );
    } else if (balance.hasError) {
      title = Text(
        'Poin belum bisa dimuat',
        style: textTheme.titleSmall?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      title = const LoadingSkeleton(width: 110, height: 22, radius: 8);
    }

    final hint = balance.hasError
        ? 'Ketuk untuk coba lagi.'
        : 'Kumpulkan point dari tiap transaksi untuk mendapatkan hadiah yang menarik.';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.40),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC83D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 27,
                  color: Color(0xFFFFB800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Lihat riwayat poin',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterList extends StatelessWidget {
  const _FilterList({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => onSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  filter,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PromoEventCard extends StatelessWidget {
  const _PromoEventCard({required this.event, required this.onTap});

  final PromoEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = event.type.accent;
    final cardColor = Color.lerp(AppColors.surface, accent, 0.06)!;
    final promo = event.promo;
    final period = _period(event);
    final banner = event.bannerImageUrl;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.40),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (banner != null && banner.isNotEmpty) ...[
                NetworkImageBox(
                  url: banner,
                  width: double.infinity,
                  height: 120,
                  radius: 14,
                ),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Pill(label: event.type.label, color: accent),
                  if (promo != null)
                    _Pill(
                      label: promo.discountLabel,
                      color: AppColors.rijikiOrange,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              if (event.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  event.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              if (promo != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kode ${promo.code}',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              if (period != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        period,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(color: accent),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailSheet extends StatelessWidget {
  const _EventDetailSheet({required this.event, required this.messenger});

  final PromoEvent event;
  final ScaffoldMessengerState messenger;

  Future<void> _copy(BuildContext context, EventPromo promo) async {
    await Clipboard.setData(ClipboardData(text: promo.code));
    if (context.mounted) Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Kode ${promo.code} disalin. Pakai saat membuat order.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = event.type.accent;
    final promo = event.promo;
    final period = _period(event);
    final banner = event.bannerImageUrl;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (banner != null && banner.isNotEmpty) ...[
              NetworkImageBox(
                url: banner,
                width: double.infinity,
                height: 160,
                radius: 16,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _Pill(label: event.type.label, color: accent),
            const SizedBox(height: AppSpacing.sm),
            Text(
              event.title,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (period != null) ...[
              const SizedBox(height: 4),
              Text(
                period,
                style: textTheme.labelMedium?.copyWith(color: accent),
              ),
            ],
            if (event.description != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                event.description!,
                style: textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
            if (promo != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.rijikiOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.rijikiOrange.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.discountLabel,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.rijikiOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Berlaku sampai ${DateFormatter.shortDate(promo.endDate)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    for (final line in promo.conditions)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(
                              child: Text(line, style: textTheme.bodySmall),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            promo.code,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _copy(context, promo),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Salin kode'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.20),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PendingStrip extends StatelessWidget {
  const _PendingStrip({
    required this.count,
    required this.reserved,
    required this.available,
  });

  final int count;
  final int reserved;
  final int? available;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = available == null
        ? '${formatPoints(reserved)} poin ditahan'
        : '${formatPoints(reserved)} poin ditahan · tersedia ${formatPoints(available!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.rijikiOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.rijikiOrange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 18,
              color: AppColors.rijikiOrange,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count pengajuan tukar poin menunggu persetujuan',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.available,
    required this.busy,
    required this.locked,
    required this.onRedeem,
  });

  final Reward reward;

  /// Poin yang masih bisa dipakai; null bila saldo belum termuat.
  final int? available;
  final bool busy;
  final bool locked;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final image = reward.imageUrl;
    final shortOfPoints = available != null && available! < reward.pointsCost;
    final canRedeem = reward.inStock && !shortOfPoints;
    final label = !reward.inStock
        ? 'Stok habis'
        : (shortOfPoints ? 'Poin kurang' : 'Tukar');

    return Container(
      width: 175,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null && image.isNotEmpty)
            NetworkImageBox(
              url: image,
              width: double.infinity,
              height: 110,
              radius: 14,
            )
          else
            Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            reward.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            reward.description ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 17, color: Color(0xFFFFB800)),
              const SizedBox(width: 4),
              Text(
                '${formatPoints(reward.pointsCost)} poin',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: FilledButton(
              onPressed: canRedeem && !locked ? onRedeem : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rijikiOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                textStyle: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
