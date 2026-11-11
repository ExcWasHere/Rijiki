import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/core/utils/idempotency_key.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/delivery_method.dart';
import 'package:rijiki/features/order/domain/new_offline_order.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/order/presentation/controllers/staff_order_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/service_picker_sheet.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/section_header.dart';

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

  OfflinePaymentMethod _paymentMethod = OfflinePaymentMethod.cash;

  /// Pengantaran untuk order offline masih maintenance (PRD Open Question #54).
  static const DeliveryMethod _deliveryMethod = DeliveryMethod.selfPickup;

  CareService? _selectedService;
  int _quantity = 1;

  /// worker_profiles.id pilihan; null = worker yang login.
  String? _workerId;

  bool _submitting = false;

  /// Kunci dipakai ulang bila upaya simpan diulang dengan isi yang sama
  /// (mis. gagal jaringan), supaya order tidak terbuat dua kali.
  String? _attemptKey;
  String? _attemptSignature;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final service = _selectedService;
    if (service == null) {
      _snack('Silakan pilih layanan perawatan sepatu');
      return;
    }

    final promo = _promoController.text.trim().toUpperCase();
    final item = OrderDraftItem(
      id: 'offline-1',
      shoeBrand: _brandController.text.trim(),
      quantity: _quantity,
      service: service,
      notes: _notesController.text.trim(),
    );

    final signature = [
      _nameController.text.trim(),
      _phoneController.text.trim(),
      item.shoeBrand,
      item.quantity,
      service.id,
      item.notes,
      promo,
      _workerId ?? '',
      _paymentMethod.json,
    ].join('|');
    if (_attemptKey == null || _attemptSignature != signature) {
      _attemptKey = generateIdempotencyKey();
      _attemptSignature = signature;
    }

    setState(() => _submitting = true);
    try {
      final order = await ref
          .read(staffOrderCommandsProvider)
          .createOffline(
            NewOfflineOrder(
              customerName: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              items: [item],
              paymentMethod: _paymentMethod,
              deliveryMethod: _deliveryMethod,
              promoCode: promo.isEmpty ? null : promo,
              assignedWorkerId: _workerId,
              idempotencyKey: _attemptKey,
            ),
          );
      _attemptKey = null;
      _attemptSignature = null;
      if (!mounted) return;
      await _onCreated(order);
    } catch (e) {
      if (mounted) _snack(Failure.messageOf(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onCreated(CustomerOrder order) async {
    final isOwner = ref.read(sessionProvider)?.role == UserRole.owner;

    if (_paymentMethod == OfflinePaymentMethod.qris) {
      context.pushReplacement(
        isOwner
            ? RoutePaths.ownerOrderPaymentFor(order.id)
            : RoutePaths.workerOrderPaymentFor(order.id),
      );
      return;
    }

    await _showCashSuccess(order);
    if (!mounted) return;

    if (order.assignedToMe || isOwner) {
      context.pushReplacement(
        isOwner
            ? RoutePaths.ownerOrderDetailFor(order.id)
            : RoutePaths.workerOrderDetailFor(order.id),
      );
    } else {
      // Ditangani worker lain: pembuat tidak punya akses ke detailnya.
      context.pop();
    }
  }

  Future<void> _showCashSuccess(CustomerOrder order) {
    final textTheme = Theme.of(context).textTheme;
    final discount = order.price.discount;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.check_circle_rounded,
          size: 48,
          color: AppColors.primary,
        ),
        title: const Text('Pesanan tersimpan', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(order.orderNumber, style: textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('Pembayaran tunai diterima'),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.rupiah(order.totalPrice),
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (discount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Sudah termasuk diskon ${CurrencyFormatter.rupiah(discount)}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOwner = ref.watch(sessionProvider)?.role == UserRole.owner;
    final workers = ref.watch(assignableWorkersProvider);
    final workerList = workers.value ?? const [];
    final selectedWorker = workerList.any((w) => w.id == _workerId)
        ? _workerId
        : null;

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
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Nama pelanggan wajib diisi';
                      if (text.length < 2) return 'Nama pelanggan terlalu pendek';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      hintText: 'Contoh: 081234567890',
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
                      Text('$_quantity', style: textTheme.titleMedium),
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
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Catatan kondisi sepatu',
                      hintText: 'Contoh: sepatu menguning atau kotor berat',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String?>(
                    key: ValueKey('worker-$selectedWorker-${workerList.length}'),
                    initialValue: selectedWorker,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Worker yang menangani',
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(isOwner ? 'Belum ditentukan' : 'Saya sendiri'),
                      ),
                      for (final w in workerList)
                        DropdownMenuItem<String?>(
                          value: w.id,
                          child: Text(
                            '${w.fullName} · ${w.division}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) => setState(() => _workerId = value),
                  ),
                  if (workers.isLoading || workers.hasError) ...[
                    const SizedBox(height: 6),
                    Text(
                      workers.isLoading
                          ? 'Memuat daftar worker...'
                          : 'Daftar worker belum bisa dimuat.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: 'Serah-terima'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: RadioGroup<DeliveryMethod>(
                groupValue: _deliveryMethod,
                onChanged: (_) {},
                child: const Column(
                  children: [
                    RadioListTile<DeliveryMethod>(
                      value: DeliveryMethod.selfPickup,
                      title: Text('Ambil sendiri di outlet'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<DeliveryMethod>(
                      value: DeliveryMethod.delivery,
                      enabled: false,
                      title: Text('Diantar ke alamat'),
                      subtitle: Text('Masih dalam maintenance'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
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

                  RadioGroup<OfflinePaymentMethod>(
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      if (value != null && !_submitting) {
                        setState(() => _paymentMethod = value);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<OfflinePaymentMethod>(
                          value: OfflinePaymentMethod.cash,
                          title: Text('Tunai'),
                          subtitle: Text('Uang diterima, pesanan langsung lunas'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<OfflinePaymentMethod>(
                          value: OfflinePaymentMethod.qris,
                          title: Text('QRIS'),
                          subtitle: Text('QR ditampilkan setelah pesanan disimpan'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            if (_selectedService != null) ...[
              Text(
                'Subtotal layanan',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.rupiah(
                  _selectedService!.basePrice * _quantity,
                ),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_promoController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Diskon promo dihitung saat pesanan disimpan.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
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
              top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _saveOrder,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(
                      _paymentMethod == OfflinePaymentMethod.qris
                          ? 'Simpan & Tampilkan QRIS'
                          : 'Simpan Pesanan',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}