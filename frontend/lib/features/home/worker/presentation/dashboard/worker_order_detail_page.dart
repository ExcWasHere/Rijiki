
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class WorkerOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const WorkerOrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  State<WorkerOrderDetailPage> createState() =>
      _WorkerOrderDetailPageState();
}

class _WorkerOrderDetailPageState
    extends State<WorkerOrderDetailPage> {
  final ImagePicker _picker = ImagePicker();

  late String status;

  String? fotoSebelumPath;
  String? fotoSesudahPath;

  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();

    status = widget.order['status']?.toString() ?? 'Menunggu';
    fotoSebelumPath = widget.order['fotoSebelum']?.toString();
    fotoSesudahPath = widget.order['fotoSesudah']?.toString();
  }

  Future<void> _ambilFoto({required bool sebelum}) async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (foto == null || !mounted) return;

      setState(() {
        if (sebelum) {
          fotoSebelumPath = foto.path;
        } else {
          fotoSesudahPath = foto.path;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _mulaiPengerjaan() {
    if (fotoSebelumPath == null) return;

    setState(() => status = 'Diproses');
  }

  void _selesaikanPesanan() {
    if (fotoSebelumPath == null || fotoSesudahPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto sebelum dan sesudah wajib dilengkapi.'),
        ),
      );
      return;
    }

    final updatedOrder = Map<String, dynamic>.from(widget.order);

    updatedOrder['status'] = 'Selesai';
    updatedOrder['fotoSebelum'] = fotoSebelumPath;
    updatedOrder['fotoSesudah'] = fotoSesudahPath;

    Navigator.pop(context, updatedOrder);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String message) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 36,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection({
    required String title,
    required String description,
    required String? photoPath,
    required bool canEdit,
    required VoidCallback onTakePhoto,
  }) {
    final hasPhoto = photoPath != null &&
        File(photoPath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(photoPath),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPhotoPlaceholder(
                    'Foto tidak dapat ditampilkan.',
                  );
                },
              ),
            )
          else
            _buildPhotoPlaceholder('Belum ada foto'),
          if (canEdit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isPickingImage ? null : onTakePhoto,
                child: Text(
                  _isPickingImage
                      ? 'Membuka kamera...'
                      : hasPhoto
                          ? 'Ambil Ulang Foto'
                          : 'Ambil Foto',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (status == 'Menunggu') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              fotoSebelumPath != null ? _mulaiPengerjaan : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Mulai Pengerjaan'),
        ),
      );
    }

    if (status == 'Diproses') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              fotoSebelumPath != null && fotoSesudahPath != null
                  ? _selesaikanPesanan
                  : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Selesaikan Pesanan'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Pesanan telah selesai',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['id']?.toString() ?? '-';
    final shoe = widget.order['shoe']?.toString() ?? '-';
    final customer = widget.order['customer']?.toString() ?? '-';
    final service = widget.order['service']?.toString() ?? '-';
    final date = widget.order['date']?.toString() ?? '-';
    final status = this.status;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.onSurfaceVariant.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shoe,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _infoRow('Customer', customer),
                _infoRow('Layanan', service),
                _infoRow('Tanggal', date),
                _infoRow('Status', status),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Laporan Pengerjaan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status == 'Menunggu'
                ? 'Ambil foto kondisi sepatu sebelum pengerjaan.'
                : status == 'Diproses'
                    ? 'Lengkapi foto sebelum dan sesudah pengerjaan.'
                    : 'Dokumentasi kondisi sepatu sebelum dan sesudah pengerjaan.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          _buildPhotoSection(
            title: 'Foto Sebelum Pengerjaan',
            description: 'Kondisi sepatu sebelum dibersihkan.',
            photoPath: fotoSebelumPath,
            canEdit: status == 'Menunggu',
            onTakePhoto: () => _ambilFoto(sebelum: true),
          ),

          _buildPhotoSection(
            title: 'Foto Sesudah Pengerjaan',
            description: 'Kondisi sepatu setelah dibersihkan.',
            photoPath: fotoSesudahPath,
            canEdit: status == 'Diproses',
            onTakePhoto: () => _ambilFoto(sebelum: false),
          ),

          const SizedBox(height: 8),
          _buildActionButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
