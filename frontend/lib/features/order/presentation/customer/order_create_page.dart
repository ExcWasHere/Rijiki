import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/order/presentation/controllers/order_create_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/address_edit_sheet.dart';
import 'package:rijiki/features/order/presentation/widgets/draft_item_card.dart';
import 'package:rijiki/features/order/presentation/widgets/promo_code_field.dart';
import 'package:rijiki/features/order/presentation/widgets/service_picker_sheet.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/section_header.dart';

class OrderCreatePage extends ConsumerStatefulWidget {
  const OrderCreatePage({super.key, this.initialServiceId});
  final String? initialServiceId;

  @override
  ConsumerState<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends ConsumerState<OrderCreatePage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final state = ref.read(orderCreateControllerProvider);
    _name = TextEditingController(text: state.customerName);
    _phone = TextEditingController(text: state.phone);

    final serviceId = widget.initialServiceId;
    if (serviceId != null) {
      ref
          .read(orderCreateControllerProvider.notifier)
          .preselectService(serviceId);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _editAddress({required bool pickup}) async {
    final controller = ref.read(orderCreateControllerProvider.notifier);
    final state = ref.read(orderCreateControllerProvider);
    final result = await showAddressEditSheet(
      context,
      title: pickup ? 'Alamat penjemputan' : 'Alamat pengantaran',
      initial: pickup ? state.pickupAddress : state.deliveryAddress,
    );
    if (result == null) return;
    if (pickup) {
      controller.setPickupAddress(result);
    } else {
      controller.setDeliveryAddress(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderCreateControllerProvider);
    final controller = ref.read(orderCreateControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat order')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader(title: 'Data pemesan'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  onChanged: controller.setName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _phone,
                  onChanged: controller.setPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No HP'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Sepatu & layanan'),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < state.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            DraftItemCard(
              key: ValueKey(state.items[i].id),
              item: state.items[i],
              index: i,
              canRemove: state.items.length > 1,
              onBrandChanged: (value) => controller.updateItem(
                state.items[i].id,
                shoeBrand: value,
              ),
              onQuantityChanged: (value) => controller.updateItem(
                state.items[i].id,
                quantity: value,
              ),
              onNotesChanged: (value) =>
                  controller.updateItem(state.items[i].id, notes: value),
              onPickService: () async {
                final picked = await showServicePickerSheet(
                  context,
                  selectedId: state.items[i].service?.id,
                );
                if (picked != null) {
                  controller.updateItem(state.items[i].id, service: picked);
                }
              },
              onRemove: () => controller.removeItem(state.items[i].id),
            ),
          ],
          if (state.items.length < OrderCreateController.maxItems) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.addItem,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tambah sepatu lain'),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Alamat'),
          const SizedBox(height: AppSpacing.sm),
          _AddressCard(
            label: 'Alamat penjemputan',
            address: state.pickupAddress,
            onEdit: () => _editAddress(pickup: true),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            value: state.sameDeliveryAddress,
            onChanged: controller.setSameDeliveryAddress,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Antar ke alamat yang sama',
              style: textTheme.bodyMedium,
            ),
          ),
          if (!state.sameDeliveryAddress)
            _AddressCard(
              label: 'Alamat pengantaran',
              address: state.deliveryAddress,
              onEdit: () => _editAddress(pickup: false),
            ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Kode promo'),
          const SizedBox(height: AppSpacing.sm),
          PromoCodeField(
            promo: state.promo,
            onApply: controller.applyPromo,
            onClear: controller.clearPromo,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subtotal layanan',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.rupiah(state.subtotal),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: state.isValid
                      ? () => context.push(RoutePaths.orderSummary)
                      : null,
                  child: const Text('Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.label,
    required this.address,
    required this.onEdit,
  });

  final String label;
  final String address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
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
                Text(address, style: textTheme.bodyMedium),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }
}
