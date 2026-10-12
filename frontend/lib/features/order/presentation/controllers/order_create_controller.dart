import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/order/domain/price_quote.dart';
import 'package:rijiki/features/order/presentation/controllers/order_list_controller.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/presentation/controllers/service_list_controller.dart';

Duration? _noRetry(int retryCount, Object error) => null;

// TODO(backend): ambil dari customer_profiles.default_address.
const String _mockDefaultAddress =
    'Jl. Soekarno Hatta No. 9, Lowokwaru, Kota Malang';

final defaultAddressProvider = Provider<String>((ref) => _mockDefaultAddress);

enum PromoStatus { idle, checking, applied, invalid }

@immutable
class PromoUiState {
  const PromoUiState({
    this.status = PromoStatus.idle,
    this.code,
    this.description,
    this.error,
  });

  final PromoStatus status;
  final String? code;
  final String? description;
  final String? error;

  String? get appliedCode => status == PromoStatus.applied ? code : null;
}

@immutable
class OrderCreateState {
  const OrderCreateState({
    required this.customerName,
    required this.phone,
    required this.items,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.sameDeliveryAddress = true,
    this.promo = const PromoUiState(),
    this.isSubmitting = false,
  });

  final String customerName;
  final String phone;
  final List<OrderDraftItem> items;
  final String pickupAddress;
  final String deliveryAddress;
  final bool sameDeliveryAddress;
  final PromoUiState promo;
  final bool isSubmitting;

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  String get effectiveDeliveryAddress =>
      sameDeliveryAddress ? pickupAddress : deliveryAddress;

  bool get isValid =>
      customerName.trim().isNotEmpty &&
      phone.trim().length >= 9 &&
      items.isNotEmpty &&
      items.every((item) => item.isComplete) &&
      pickupAddress.trim().isNotEmpty &&
      effectiveDeliveryAddress.trim().isNotEmpty;

  OrderCreateState copyWith({
    String? customerName,
    String? phone,
    List<OrderDraftItem>? items,
    String? pickupAddress,
    String? deliveryAddress,
    bool? sameDeliveryAddress,
    PromoUiState? promo,
    bool? isSubmitting,
  }) {
    return OrderCreateState(
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      items: items ?? this.items,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      sameDeliveryAddress: sameDeliveryAddress ?? this.sameDeliveryAddress,
      promo: promo ?? this.promo,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class OrderCreateController extends Notifier<OrderCreateState> {
  static const int maxItems = 5;
  static const int maxQuantity = 10;

  int _nextItemId = 1;

  String _newItemId() => 'draft-${_nextItemId++}';

  @override
  OrderCreateState build() {
    final user = ref.read(sessionProvider);
    final address = ref.read(defaultAddressProvider);
    return OrderCreateState(
      customerName: user?.fullName ?? '',
      phone: user?.phoneNumber ?? '',
      items: [OrderDraftItem(id: _newItemId())],
      pickupAddress: address,
      deliveryAddress: address,
    );
  }

  /// Pilih layanan awal (mis. dari hasil scan atau kartu layanan di Beranda).
  Future<void> preselectService(String serviceId) async {
    try {
      final services = await ref.read(allServicesProvider.future);
      final service = services.where((s) => s.id == serviceId).firstOrNull;
      if (service == null || state.items.isEmpty) return;
      final first = state.items.first;
      if (first.service != null) return;
      state = state.copyWith(
        items: [first.copyWith(service: service), ...state.items.skip(1)],
      );
    } catch (_) {
      // Daftar layanan gagal dimuat: customer tetap bisa memilih manual.
    }
  }

  void setName(String value) => state = state.copyWith(customerName: value);
  void setPhone(String value) => state = state.copyWith(phone: value);
  void setPickupAddress(String value) =>
      state = state.copyWith(pickupAddress: value);
  void setDeliveryAddress(String value) =>
      state = state.copyWith(deliveryAddress: value);
  void setSameDeliveryAddress(bool value) =>
      state = state.copyWith(sameDeliveryAddress: value);

  void addItem() {
    if (state.items.length >= maxItems) return;
    state = state.copyWith(
      items: [...state.items, OrderDraftItem(id: _newItemId())],
    );
  }

  void removeItem(String id) {
    if (state.items.length <= 1) return;
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  void updateItem(
    String id, {
    String? shoeBrand,
    int? quantity,
    CareService? service,
    String? notes,
  }) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id)
            item.copyWith(
              shoeBrand: shoeBrand,
              quantity: quantity?.clamp(1, maxQuantity).toInt(),
              service: service,
              notes: notes,
            )
          else
            item,
      ],
    );
  }

  Future<void> applyPromo(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return;

    state = state.copyWith(
      promo: PromoUiState(status: PromoStatus.checking, code: code),
    );
    try {
      final quote = await ref
          .read(orderRepositoryProvider)
          .quotePrice(subtotal: state.subtotal, promoCode: code);
      state = state.copyWith(
        promo: PromoUiState(
          status: PromoStatus.applied,
          code: quote.promoCode ?? code,
          description: quote.promoDescription,
        ),
      );
    } on PromoException catch (e) {
      state = state.copyWith(
        promo: PromoUiState(
          status: PromoStatus.invalid,
          code: code,
          error: e.message,
        ),
      );
    } catch (_) {
      state = state.copyWith(
        promo: PromoUiState(
          status: PromoStatus.invalid,
          code: code,
          error: 'Kode promo gagal diperiksa. Coba lagi.',
        ),
      );
    }
  }

  void clearPromo() => state = state.copyWith(promo: const PromoUiState());

  /// Kirim order. Mengembalikan order baru, atau null bila gagal.
  Future<CustomerOrder?> submit(PriceQuote quote) async {
    if (state.isSubmitting || !state.isValid) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            NewOrder(
              customerName: state.customerName.trim(),
              phone: state.phone.trim(),
              items: state.items,
              pickupAddress: state.pickupAddress.trim(),
              deliveryAddress: state.effectiveDeliveryAddress.trim(),
              promoCode: quote.promoCode,
            ),
            quote,
          );
      // Daftar order dan Beranda ikut diperbarui.
      ref.invalidate(ordersProvider);
      return order;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return null;
    }
  }
}

final orderCreateControllerProvider =
    NotifierProvider.autoDispose<OrderCreateController, OrderCreateState>(
      OrderCreateController.new,
    );

/// Harga untuk draft saat ini (subtotal, promo, ongkir).
/// Dihitung ulang hanya bila subtotal atau promo yang terpasang berubah.
final orderQuoteProvider = FutureProvider.autoDispose<PriceQuote>((ref) {
  final key = ref.watch(
    orderCreateControllerProvider.select(
      (state) => (state.subtotal, state.promo.appliedCode),
    ),
  );
  return ref
      .watch(orderRepositoryProvider)
      .quotePrice(subtotal: key.$1, promoCode: key.$2);
}, retry: _noRetry);
