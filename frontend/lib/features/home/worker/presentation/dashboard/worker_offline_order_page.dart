import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/order/presentation/widgets/service_picker_sheet.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/section_header.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum WorkerPaymentMethod {
  cash,
  qris,
}

class WorkerOfflineOrderPage extends ConsumerStatefulWidget {
  const WorkerOfflineOrderPage({super.key});

  @override
  ConsumerState<WorkerOfflineOrderPage> createState() =>
      _WorkerOfflineOrderPageState();
}

class _WorkerOfflineOrderPageState
    extends ConsumerState<WorkerOfflineOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  final _promoController = TextEditingController();
  final _workerController = TextEditingController();

  WorkerPaymentMethod _paymentMethod = WorkerPaymentMethod.cash;
  CareService? _selectedService;
  int _quantity = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    _promoController.dispose();
    _workerController.dispose();
    super.dispose();
  }

  Future<void> _pickService() async {
    final picked = await showServicePickerSheet(
      context,
      selectedId: _selectedService?.id,
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedService = picked;
    });
  }

 Future<void> _saveOrder() async {
  if (!_formKey.currentState!.validate()) return;

  if (_selectedService == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Silakan pilih layanan perawatan sepatu'),
      ),
    );
    return;
  }

  final total = _selectedService!.basePrice * _quantity;

  if (_paymentMethod == WorkerPaymentMethod.qris) {
    await _showQrisDialog(total);
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Data valid. Proses penyimpanan backend belum dihubungkan.',
      ),
    ),
  );
}

Future<void> _showQrisDialog(int total) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Pembayaran QRIS',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Silakan pindai kode QR berikut '
              'untuk melakukan pembayaran.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Placeholder QRIS
            Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: 'RIJIKI_QRIS',
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    color: Colors.white,
                    child: const Text(
                      'QRIS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'QRIS RIJIKI',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            const Text('Total pembayaran'),

            const SizedBox(height: 4),

            Text(
              CurrencyFormatter.rupiah(total),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Buat Pesanan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SectionHeader(title: 'Data pelanggan'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama pelanggan',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama pelanggan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9+]'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nomor HP wajib diisi';
                      }
                      if (value.trim().length < 8) {
                        return 'Nomor HP tidak valid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: 'Detail sepatu'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _brandController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Merek sepatu',
                      hintText: 'Contoh: Nike, Adidas',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Merek sepatu wajib diisi';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Jumlah sepatu',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_quantity',
                            style: textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: _quantity < 10
                                ? () => setState(() => _quantity++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan kondisi sepatu',
                      hintText:
                          'Contoh: sepatu menguning atau kotor berat',
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _pickService,
                      child: Text(
                        _selectedService == null
                            ? 'Pilih layanan'
                            : 'Ganti layanan',
                      ),
                    ),
                  ),

                  if (_selectedService != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.outline.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedService!.name,
                            style: textTheme.titleSmall,
                          ),
                          if (_selectedService!.description != null &&
                              _selectedService!.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedService!.description!,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.rupiah(
                              _selectedService!.basePrice,
                            ),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Promo'),
            const SizedBox(height: AppSpacing.sm),

            AppCard(
              child: TextFormField(
                controller: _promoController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kode promo (opsional)',
                  hintText: 'Masukkan kode promo',
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: 'Worker'),
            const SizedBox(height: AppSpacing.sm),

            AppCard(
              child: TextFormField(
                controller: _workerController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama worker',
                  hintText: 'Pilih worker yang menangani pesanan',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama worker wajib diisi';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: 'Pembayaran'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metode pembayaran',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  RadioGroup<WorkerPaymentMethod>(
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paymentMethod = value);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<WorkerPaymentMethod>(
                          value: WorkerPaymentMethod.cash,
                          title: Text('Tunai'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<WorkerPaymentMethod>(
                          value: WorkerPaymentMethod.qris,
                          title: Text('QRIS'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            if (_selectedService != null)
              Text(
                'Subtotal layanan',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),

            if (_selectedService != null) ...[
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.rupiah(
                  _selectedService!.basePrice * _quantity,
                ),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.25),
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveOrder,
              child: const Text('Simpan Pesanan'),
            ),
          ),
        ),
      ),
    );
  }
}