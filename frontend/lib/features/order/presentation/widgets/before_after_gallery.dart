import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/order_item.dart';
import 'package:rijiki/shared/widgets/network_image_box.dart';

/// Galeri foto sebelum/sesudah per item, plus bukti penerimaan.
/// Selama [OrderDocumentation.photoUrl] kosong (data mock), tile tampil
/// sebagai placeholder abu-abu berlabel.
// TODO(backend): foto privat dimuat lewat endpoint ber-auth, teruskan
// header Authorization ke NetworkImageBox.
class BeforeAfterGallery extends StatelessWidget {
  const BeforeAfterGallery({
    super.key,
    required this.items,
    required this.documentation,
  });

  final List<OrderItem> items;
  final List<OrderDocumentation> documentation;

  OrderDocumentation? _find(String itemId, DocumentationType type) {
    return documentation
        .where((doc) => doc.orderItemId == itemId && doc.type == type)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final proof = documentation
        .where((doc) => doc.type == DocumentationType.proofOfDelivery)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          Text('${item.shoeName} · ${item.serviceName}', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PhotoTile(
                  label: 'Sebelum',
                  doc: _find(item.id, DocumentationType.before),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PhotoTile(
                  label: 'Sesudah',
                  doc: _find(item.id, DocumentationType.after),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (proof != null) ...[
          Text('Bukti penerimaan', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _PhotoTile(label: 'Diterima', doc: proof)),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.label, required this.doc});

  final String label;
  final OrderDocumentation? doc;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final url = doc?.photoUrl;

    final Widget content;
    if (url != null) {
      content = NetworkImageBox(url: url, radius: 0);
    } else {
      content = ColoredBox(
        color: AppColors.outline.withValues(alpha: 0.18),
        child: Center(
          child: doc == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Belum diunggah',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : const Icon(
                  Icons.photo_outlined,
                  size: 30,
                  color: AppColors.onSurfaceVariant,
                ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
