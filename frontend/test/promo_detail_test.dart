import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/event_type.dart';
import 'package:rijiki/features/event/domain/event_promo.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/presentation/utils/event_promo_format.dart';
import 'package:rijiki/features/event/presentation/widgets/event_detail_sheet.dart';
import 'package:rijiki/features/order/domain/applied_promo.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/order/domain/order_repository.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';
import 'package:rijiki/features/order/domain/price_quote.dart';
import 'package:rijiki/features/order/presentation/controllers/order_create_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/promo_code_field.dart';
import 'package:rijiki/features/service/domain/care_service.dart';

Map<String, dynamic> _promoJson({
  Object? quotaLeft,
  Object? usageLimitPerCustomer,
  List<String> serviceNames = const [],
  Object? minSubtotal = 50000,
  Object? maxDiscountAmount = 20000,
  bool firstOrderOnly = true,
  bool available = true,
}) => {
  'id': 'promo-1',
  'code': 'HEMAT',
  'title': 'Hemat 20%',
  'description': null,
  'discount_type': 'percentage',
  'discount_value': 20,
  'applies_to': 'subtotal',
  'min_subtotal': minSubtotal,
  'max_discount_amount': maxDiscountAmount,
  'first_order_only': firstOrderOnly,
  'usage_limit_per_customer': usageLimitPerCustomer,
  'service_names': serviceNames,
  'start_date': '2026-01-01',
  'end_date': '2026-12-31',
  'is_active': true,
  'quota_left': quotaLeft,
  'available': available,
};

PromoEvent _event({EventPromo? promo}) => PromoEvent(
  id: 'ev-1',
  title: 'Promo Hemat',
  type: EventType.promo,
  description: null,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 12, 31),
  promo: promo,
);

const _deepClean = CareService(
  id: 'svc-1',
  name: 'Deep Clean',
  category: ServiceCategory.cuciSepatu,
  basePrice: 40000,
);

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({this.onQuote});

  /// Dipanggil setiap quote; boleh melempar [PromoException].
  final Future<PriceQuote> Function(List<String> codes, List<OrderDraftItem> items)? onQuote;

  final List<List<String>> quoteCalls = [];

  @override
  Future<PriceQuote> quotePrice({
    required int subtotal,
    List<String> promoCodes = const [],
    List<OrderDraftItem> items = const [],
  }) async {
    quoteCalls.add(promoCodes);
    if (onQuote != null) return onQuote!(promoCodes, items);
    return const PriceQuote(price: PriceBreakdown(subtotal: 40000));
  }

  @override
  Future<List<CustomerOrder>> fetchOrders() async => const [];

  @override
  Future<List<CustomerOrder>> fetchActiveOrders() async => const [];

  @override
  Future<CustomerOrder> fetchOrderById(String id) async =>
      throw UnimplementedError();

  @override
  Future<CustomerOrder> createOrder(NewOrder order, PriceQuote quote) async =>
      throw UnimplementedError();
}

void main() {
  group('detail promo di halaman Acara & Promo', () {
    test('syarat promo menyebut layanan dan batas per akun', () {
      final promo = EventPromo.fromJson(
        _promoJson(
          serviceNames: const ['Deep Clean', 'Fast Clean'],
          usageLimitPerCustomer: 2,
          quotaLeft: 5,
        ),
      );

      expect(promo.serviceNames, ['Deep Clean', 'Fast Clean']);
      expect(promo.usageLimitPerCustomer, 2);
      expect(promo.conditions, [
        'Berlaku untuk layanan: Deep Clean, Fast Clean',
        'Min. belanja Rp50.000',
        'Maks. potongan Rp20.000',
        'Khusus order pertama',
        'Maks. 2 kali per akun',
        'Sisa kuota 5',
      ]);
    });

    test('promo tanpa syarat tetap punya minimal satu baris keterangan', () {
      final promo = EventPromo.fromJson(
        _promoJson(minSubtotal: null, maxDiscountAmount: null, firstOrderOnly: false),
      );
      expect(promo.conditions, isNotEmpty);
    });

    test('promo yang kuotanya habis punya alasan yang bisa ditampilkan', () {
      final promo = EventPromo.fromJson(_promoJson(quotaLeft: 0, available: false));
      expect(promo.unavailableReason, 'Kuota promo sudah habis.');
    });

    testWidgets('sheet detail menampilkan kode, potongan, dan syarat', (
      tester,
    ) async {
      final promo = EventPromo.fromJson(_promoJson(serviceNames: const ['Deep Clean']));
      final event = _event(promo: promo);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEventDetailSheet(context, event),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      expect(find.text('HEMAT'), findsOneWidget);
      expect(find.text('Diskon 20%'), findsOneWidget);
      expect(
        find.text('Berlaku untuk layanan: Deep Clean'),
        findsOneWidget,
      );
      expect(find.textContaining('membuat pesanan'), findsOneWidget);
    });

    testWidgets('acara tanpa promo tidak menampilkan sheet kosong', (
      tester,
    ) async {
      final event = _event();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEventDetailSheet(context, event),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      expect(find.text('Promo Hemat'), findsOneWidget);
      expect(find.textContaining('Detail acara ini belum diisi'), findsOneWidget);
    });
  });

  group('kolom kode promo', () {
    testWidgets('promo terpakai menampilkan potongannya', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromoCodeField(
              promo: const PromoUiState(
                applied: [
                  AppliedPromo(
                    code: 'HEMAT',
                    appliesToShipping: false,
                    discount: 8000,
                    description: 'Hemat · Diskon 20%',
                  ),
                ],
              ),
              onApply: (_) async => false,
              onRemove: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('HEMAT'), findsOneWidget);
      expect(find.text('Hemat Rp 8.000'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
    });

    testWidgets('kode ditolak menampilkan pesan dari server', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromoCodeField(
              promo: const PromoUiState(
                error: 'Promo ini tidak berlaku untuk layanan yang kamu pilih.',
              ),
              onApply: (_) async => false,
              onRemove: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.text('Promo ini tidak berlaku untuk layanan yang kamu pilih.'),
        findsOneWidget,
      );
    });
  });

  group('promo di form order', () {
    ProviderContainer containerWith(_FakeOrderRepository repository) {
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('kode promo ditolak sebelum layanan dipilih', () async {
      final container = containerWith(_FakeOrderRepository());
      container.listen(orderCreateControllerProvider, (_, _) {});
      final controller = container.read(orderCreateControllerProvider.notifier);

      final accepted = await controller.applyPromo('hemat');

      expect(accepted, isFalse);
      expect(
        container.read(orderCreateControllerProvider).promo.error,
        'Pilih layanan dulu sebelum memakai kode promo.',
      );
    });

    test('promo dilepas dengan alasan saat keranjang berubah', () async {
      var rejectPromo = false;
      final repository = _FakeOrderRepository(
        onQuote: (codes, items) async {
          if (rejectPromo) {
            throw const PromoException(
              'Promo ini tidak berlaku untuk layanan yang kamu pilih.',
            );
          }
          return PriceQuote(
            price: const PriceBreakdown(subtotal: 40000, discount: 8000),
            promos: [
              for (final code in codes)
                AppliedPromo(
                  code: code,
                  appliesToShipping: false,
                  discount: 8000,
                  description: 'Hemat · Diskon 20%',
                ),
            ],
          );
        },
      );
      final container = containerWith(repository);
      // Provider autoDispose: pertahankan hidup selama test.
      container.listen(orderCreateControllerProvider, (_, _) {});
      final controller = container.read(orderCreateControllerProvider.notifier);
      final itemId = container.read(orderCreateControllerProvider).items.first.id;

      controller.updateItem(itemId, service: _deepClean);
      expect(await controller.applyPromo('HEMAT'), isTrue);
      expect(container.read(orderCreateControllerProvider).promo.applied, hasLength(1));

      rejectPromo = true;
      controller.updateItem(itemId, quantity: 2);
      await pumpEventQueue();

      final promo = container.read(orderCreateControllerProvider).promo;
      expect(promo.applied, isEmpty);
      expect(
        promo.error,
        'Promo dilepas: Promo ini tidak berlaku untuk layanan yang kamu pilih.',
      );
    });
  });
}
