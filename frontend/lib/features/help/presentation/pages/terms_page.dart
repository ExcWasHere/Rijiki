import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/profile/presentation/widgets/contact_sheet.dart';

/// "Syarat & ketentuan" layanan Rijiki.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const List<({String title, String body})> _sections = [
    (
      title: '1. Layanan',
      body:
          'Rijiki menyediakan jasa perawatan sepatu dan tas: pembersihan, '
          'perawatan material, dan layanan tambahan lain yang tercantum di '
          'aplikasi. Estimasi waktu dan harga mengikuti daftar layanan yang '
          'berlaku saat order dibuat.',
    ),
    (
      title: '2. Pemesanan dan pembayaran',
      body:
          'Order dari aplikasi dibayar dengan QRIS sebelum sepatu dijemput. '
          'Nominal yang harus dibayar sudah termasuk ongkir sesuai jarak dan '
          'promo yang aktif. Order offline di outlet dapat dibayar tunai atau '
          'QRIS di tempat.',
    ),
    (
      title: '3. Penjemputan dan pengantaran',
      body:
          'Kurir menjemput dan mengantar sepatu pada alamat yang tersimpan di '
          'profilmu. Pastikan alamat dan nomor HP selalu benar. Bila kurir tidak '
          'bisa menghubungimu pada jadwal yang disepakati, order dapat '
          'dijadwalkan ulang.',
    ),
    (
      title: '4. Kondisi sepatu',
      body:
          'Kami memeriksa kondisi sepatu sebelum dibersihkan dan mendokumentasi '
          'kondisinya. Kerusakan yang sudah ada sebelumnya (mis. sol terlepas, '
          'kulit mengelupas, atau warna pudar) dicatat dan tidak menjadi '
          'tanggung jawab Rijiki. Material tertentu dapat berubah warna atau '
          'tekstur setelah dicuci; tim akan menginformasikan risikonya lebih dulu.',
    ),
    (
      title: '5. Pembatalan dan pengembalian',
      body:
          'Order yang belum dibayar bisa dibatalkan dari aplikasi. Setelah '
          'pembayaran diterima, pembatalan dan refund dilayani CS Rijiki. '
          'Keluhan hasil cucian disampaikan maksimal 1x24 jam setelah sepatu '
          'diterima dengan menyertakan nomor order.',
    ),
    (
      title: '6. Poin dan hadiah',
      body:
          'Poin diberikan setelah order selesai dan saat memberi rating, sesuai '
          'aturan poin yang berlaku. Penukaran poin diproses setelah disetujui '
          'Rijiki; poin yang sudah dipakai tidak dapat dikembalikan. Hadiah dapat '
          'diambil di outlet atau dibawa bersama order berikutnya.',
    ),
    (
      title: '7. Data pribadi',
      body:
          'Kami menyimpan nama, email, nomor HP, dan alamat hanya untuk '
          'keperluan layanan: penjemputan, pengantaran, notifikasi status order, '
          'dan program poin. Kata sandi dikelola penyedia autentikasi dan tidak '
          'pernah kami lihat atau simpan.',
    ),
    (
      title: '8. Perubahan ketentuan',
      body:
          'Ketentuan ini dapat diperbarui sewaktu-waktu. Versi terbaru selalu '
          'tersedia di halaman ini dan berlaku sejak ditampilkan di aplikasi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Syarat & ketentuan')),
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
              'Syarat & ketentuan layanan Rijiki Shoe & Care.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final section in _sections) ...[
              Text(
                section.title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                section.body,
                style: textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pertanyaan soal ketentuan ini? Hubungi ${RijikiContact.email} '
              'atau WhatsApp ${RijikiContact.whatsapp}.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
