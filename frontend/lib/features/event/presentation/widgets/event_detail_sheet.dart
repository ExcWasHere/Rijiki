import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/event/domain/event_promo.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/presentation/utils/event_promo_format.dart';
import 'package:rijiki/shared/widgets/network_image_box.dart';

/// Detail acara/promo yang dibuka dari daftar Acara & Promo maupun banner di
/// Beranda. Selalu menampilkan isi: kode promo, masa berlaku, syarat, dan
/// keterangan acara, dengan teks cadangan bila datanya kosong.
Future<void> showEventDetailSheet(BuildContext context, PromoEvent event) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) =>
        _EventDetailSheet(event: event, messenger: messenger),
  );
}

/// Rentang tanggal acara/promo; null bila keduanya kosong.
String? eventPeriod(PromoEvent event) {
  final start = event.startDate;
  final end = event.endDate;
  if (start != null && end != null) return DateFormatter.range(start, end);
  return DateFormatter.validity(start, end);
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
    final period = eventPeriod(event);
    final banner = event.bannerImageUrl;
    final description = event.description?.trim();

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
            EventPill(label: event.type.label, color: accent),
            const SizedBox(height: AppSpacing.sm),
            Text(
              event.title,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (period != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.event_rounded, size: 15, color: accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      period,
                      style: textTheme.labelMedium?.copyWith(color: accent),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              description?.isNotEmpty == true
                  ? description!
                  : (promo == null
                        ? 'Detail acara ini belum diisi. Cek lagi nanti ya.'
                        : 'Klaim potongan harga dengan kode promo di bawah saat '
                              'membuat pesanan.'),
              style: textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            if (promo != null) ...[
              const SizedBox(height: AppSpacing.md),
              _PromoDetailCard(promo: promo, onCopy: () => _copy(context, promo)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PromoDetailCard extends StatelessWidget {
  const _PromoDetailCard({required this.promo, required this.onCopy});

  final EventPromo promo;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reason = promo.unavailableReason;

    return Container(
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
            'Berlaku ${DateFormatter.shortDate(promo.startDate)} - '
            '${DateFormatter.shortDate(promo.endDate)}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (reason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          for (final line in promo.conditions)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(line, style: textTheme.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kode promo',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      promo.code,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Salin'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip kecil untuk jenis acara atau nilai potongan.
class EventPill extends StatelessWidget {
  const EventPill({super.key, required this.label, required this.color});

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
