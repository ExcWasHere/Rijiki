import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/location/default_location.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/utils/idempotency_key.dart';
import 'package:rijiki/features/order/domain/applied_promo.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/order/domain/price_quote.dart';
import 'package:rijiki/features/order/presentation/controllers/order_list_controller.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/presentation/controllers/service_list_controller.dart';

Duration? _noRetry(int retryCount, Object error) => null;

// Alamat order mengikuti alamat default di profil (customer_profiles.default_address
// lewat session/defaultLocationProvider). Customer boleh mengubahnya di form;
// ongkir sementara tetap dihitung backend dari koordinat profil.
// Bila profil belum punya alamat, form mulai kosong dan checkout meminta
// customer mengisi alamat lebih dulu.
final defaultAddressProvider = Provider<String>((ref) {
  return ref.watch(defaultLocationProvider)?.address.trim() ?? '';
});

/// Promo di form order: daftar promo yang sudah lolos cek server (maks 1
/// promo layanan + 1 promo ongkir) dan status input kode berikutnya.
@immutable
class PromoUiState {
  const PromoUiState({
    this.applied = const [],
    this.checkingCode,
    this.error,
  });

  final List<AppliedPromo> applied;

  /// Kode yang sedang diperiksa server; null = tidak sedang memeriksa.
  final String? checkingCode;

  /// Galat kode terakhir yang dicoba.
  final String? error;

  bool get isChecking => checkingCode != null;
  bool get canAddMore => applied.length < AppliedPromo.maxPerOrder;
  List<String> get appliedCodes => [for (final p in applied) p.code];

  /// Kunci quote: urutan tidak memengaruhi harga.
  String get quoteKey => ([...appliedCodes]..sort()).join(',');
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
    this.submitError,
  });

  /// Nama & nomor HP hanya untuk ditampilkan: selalu berasal dari profil akun
  /// dan tidak dikirim ke backend.
  final String customerName;
  final String phone;
  final List<OrderDraftItem> items;
  final String pickupAddress;
  final String deliveryAddress;
  final bool sameDeliveryAddress;
  final PromoUiState promo;
  final bool isSubmitting;
  final String? submitError;

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  /// Ringkasan layanan + jumlah, dipakai sebagai kunci quote: berubah hanya
  /// bila pilihan layanan atau jumlahnya berubah (promo bisa dibatasi per layanan).
  String get quoteItemsKey => [
    for (final item in items)
      if (item.service != null) '${item.service!.id}x${item.quantity}',
  ].join(',');

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
    List<OrderDraftItem>? items,
    String? pickupAddress,
    String? deliveryAddress,
    bool? sameDeliveryAddress,
    PromoUiState? promo,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return OrderCreateState(
      customerName: customerName,
      phone: phone,
      items: items ?? this.items,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      sameDeliveryAddress: sameDeliveryAddress ?? this.sameDeliveryAddress,
      promo: promo ?? this.promo,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

class OrderCreateController extends Notifier<OrderCreateState> {
  static const int maxItems = 5;
  static const int maxQuantity = 10;

  int _nextItemId = 1;

  String _newItemId() => 'draft-${_nextItemId++}';

  // Kunci idempotency untuk upaya checkout yang sedang berjalan. Kirim ulang
  // isi yang sama (mis. sinyal putus) memakai kunci yang sama; isi berubah
  // berarti order baru dengan kunci baru.
  String? _idempotencyKey;
  String? _idempotencyFingerprint;

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
    }
  }

  void setPickupAddress(String value) =>
      state = state.copyWith(pickupAddress: value);
  void setDeliveryAddress(String value) =>
      state = state.copyWith(deliveryAddress: value);
  void setSameDeliveryAddress(bool value) =>
      state = state.copyWith(sameDeliveryAddress: value);

  /// Promo bisa bergantung pada layanan dan subtotal, jadi dilepas saat
  /// keranjang berubah; customer menerapkannya lagi dan dicek ulang server.
  PromoUiState _promoAfterCartChange() => const PromoUiState();

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
      promo: _promoAfterCartChange(),
    );
  }

  void updateItem(
    String id, {
    String? shoeBrand,
    int? quantity,
    CareService? service,
    String? notes,
  }) {
    final cartChanged = quantity != null || service != null;
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
      promo: cartChanged ? _promoAfterCartChange() : null,
    );
  }

  /// Menambah kode promo. Server memeriksa gabungan promo yang sudah dipakai
  /// plus kode baru sekaligus, jadi aturan 1 layanan + 1 ongkir ikut dicek.
  /// Mengembalikan true bila kode diterima.
  Future<bool> applyPromo(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final current = state.promo;
    if (code.isEmpty || current.isChecking) return false;
    if (current.appliedCodes.contains(code)) {
      state = state.copyWith(
        promo: PromoUiState(
          applied: current.applied,
          error: 'Kode $code sudah dipakai.',
        ),
      );
      return false;
    }
    if (!current.canAddMore) return false;

    state = state.copyWith(
      promo: PromoUiState(applied: current.applied, checkingCode: code),
    );
    try {
      final quote = await ref
          .read(orderRepositoryProvider)
          .quotePrice(
            subtotal: state.subtotal,
            promoCodes: [...current.appliedCodes, code],
            items: state.items,
          );
      state = state.copyWith(promo: PromoUiState(applied: quote.promos));
      return true;
    } on PromoException catch (e) {
      state = state.copyWith(
        promo: PromoUiState(applied: current.applied, error: e.message),
      );
    } catch (_) {
      state = state.copyWith(
        promo: PromoUiState(
          applied: current.applied,
          error: 'Kode promo gagal diperiksa. Coba lagi.',
        ),
      );
    }
    return false;
  }

  void removePromo(String code) {
    state = state.copyWith(
      promo: PromoUiState(
        applied: [
          for (final promo in state.promo.applied)
            if (promo.code != code) promo,
        ],
      ),
    );
  }

  void clearPromo() => state = state.copyWith(promo: const PromoUiState());

  String _fingerprint(PriceQuote quote) {
    final lines = [
      for (final item in state.items)
        '${item.service?.id}|${item.shoeBrand.trim()}|${item.quantity}|${item.notes.trim()}',
    ];
    return [
      ...lines,
      state.pickupAddress.trim(),
      state.effectiveDeliveryAddress.trim(),
      ([...quote.promoCodes]..sort()).join(','),
    ].join('\n');
  }

  String _keyFor(String fingerprint) {
    if (_idempotencyKey == null || _idempotencyFingerprint != fingerprint) {
      _idempotencyKey = generateIdempotencyKey();
      _idempotencyFingerprint = fingerprint;
    }
    return _idempotencyKey!;
  }

  Future<CustomerOrder?> submit(PriceQuote quote) async {
    if (state.isSubmitting) return null;
    if (state.pickupAddress.trim().isEmpty ||
        state.effectiveDeliveryAddress.trim().isEmpty) {
      state = state.copyWith(
        submitError: 'Isi alamat penjemputan dan pengantaran dulu ya.',
      );
      return null;
    }
    if (!state.isValid) return null;
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
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
              promoCodes: quote.promoCodes,
              idempotencyKey: _keyFor(_fingerprint(quote)),
            ),
            quote,
          );
      // Order berhasil: upaya berikutnya adalah order baru dengan kunci baru.
      _idempotencyKey = null;
      _idempotencyFingerprint = null;
      ref.invalidate(ordersProvider);
      return order;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e is Failure ? e.message : null,
      );
      return null;
    }
  }
}

final orderCreateControllerProvider =
    NotifierProvider.autoDispose<OrderCreateController, OrderCreateState>(
      OrderCreateController.new,
    );

final orderQuoteProvider = FutureProvider.autoDispose<PriceQuote>((ref) {
  final key = ref.watch(
    orderCreateControllerProvider.select(
      (state) => (state.subtotal, state.promo.quoteKey, state.quoteItemsKey),
    ),
  );
  final current = ref.read(orderCreateControllerProvider);
  return ref
      .watch(orderRepositoryProvider)
      .quotePrice(
        subtotal: key.$1,
        promoCodes: current.promo.appliedCodes,
        items: current.items,
      );
}, retry: _noRetry);
