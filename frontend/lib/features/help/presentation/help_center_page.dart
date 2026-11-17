import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/profile/presentation/shared/contact_sheet.dart';

/// "Pusat bantuan": pertanyaan yang paling sering ditanyakan customer.
class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const List<({String question, String answer})> _faqs = [
    (
      question: 'Bagaimana cara memesan cuci sepatu?',
      answer:
          'Pilih layanan di beranda atau pindai sepatumu lewat tombol Pindai, '
          'lalu lanjutkan ke ringkasan order. Kurir Rijiki akan menjemput sepatu '
          'sesuai jadwal yang kamu pilih.',
    ),
    (
      question: 'Metode pembayaran apa yang tersedia?',
      answer:
          'Pembayaran order dari aplikasi memakai QRIS. Setelah QR dibuat, '
          'pindai dengan aplikasi e-wallet atau mobile banking apa pun, lalu '
          'status order otomatis berubah setelah pembayaran masuk.',
    ),
    (
      question: 'Berapa lama proses pencucian?',
      answer:
          'Layanan Fast Cleaning selesai di hari yang sama, sedangkan Deep '
          'Cleaning membutuhkan 2–3 hari kerja tergantung kondisi sepatu. '
          'Perkiraan waktu tampil di detail setiap layanan.',
    ),
    (
      question: 'Bagaimana cara melacak posisi sepatu saya?',
      answer:
          'Buka tab Pesan, pilih order yang sedang berjalan, lalu ketuk Lacak. '
          'Peta menampilkan posisi kurir saat sepatu sedang diantar.',
    ),
    (
      question: 'Bagaimana poin Rijiki didapat dan dipakai?',
      answer:
          'Poin otomatis masuk setelah order selesai dan saat kamu memberi '
          'rating. Poin bisa ditukar dengan merchandise di tab Promo, lalu '
          'diambil di outlet atau dibawa bersama order berikutnya.',
    ),
    (
      question: 'Bisakah order dibatalkan?',
      answer:
          'Order yang belum dibayar bisa dibatalkan lewat detail order. Setelah '
          'pembayaran masuk, pembatalan dan refund dilayani CS Rijiki di luar '
          'aplikasi.',
    ),
    (
      question: 'Bagaimana kalau hasil cucian belum sesuai?',
      answer:
          'Hubungi kami maksimal 1x24 jam setelah sepatu diterima. Sertakan '
          'nomor order dan foto sepatu agar tim bisa memeriksa dan menindaklanjuti.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pusat bantuan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Text(
              'Pertanyaan umum',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < _faqs.length; index++) ...[
                    _FaqTile(
                      question: _faqs[index].question,
                      answer: _faqs[index].answer,
                    ),
                    if (index < _faqs.length - 1)
                      const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masih butuh bantuan?',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tim Rijiki siap membantu setiap hari '
                    '${RijikiContact.operatingHours} WIB.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => showContactSheet(context),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Hubungi Rijiki'),
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
