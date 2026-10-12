import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/data/mock_order_store.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/order/domain/order_item.dart';
import 'package:rijiki/features/order/domain/price_quote.dart';
import 'package:rijiki/features/order/domain/order_repository.dart';
import 'package:rijiki/features/order/domain/order_status_history.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';

class MockOrderRepository implements OrderRepository {
  const MockOrderRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  @override
  Future<List<CustomerOrder>> fetchOrders() {
    return scenario.resolve<List<CustomerOrder>>(
      empty: const [],
      data: MockOrderStore.apply(_buildOrders()),
    );
  }

  @override
  Future<List<CustomerOrder>> fetchActiveOrders() {
    return scenario.resolve<List<CustomerOrder>>(
      empty: const [],
      data: MockOrderStore.apply(_buildOrders())
          .where((order) => order.status.isActive)
          .take(2)
          .toList(),
    );
  }

  @override
  Future<CustomerOrder> fetchOrderById(String id) async {
    final orders = await scenario.resolve<List<CustomerOrder>>(
      empty: const [],
      data: MockOrderStore.apply(_buildOrders()),
    );
    return orders.firstWhere(
      (order) => order.id == id,
      orElse: () => throw const MockException('Order tidak ditemukan'),
    );
  }

  static const int _shippingFee = 8000;

  @override
  Future<PriceQuote> quotePrice({
    required int subtotal,
    String? promoCode,
  }) async {
    await scenario.resolve<bool>(empty: true, data: true);

    final code = promoCode?.trim().toUpperCase() ?? '';
    if (code.isEmpty) {
      return PriceQuote(
        price: PriceBreakdown(subtotal: subtotal, shipping: _shippingFee),
      );
    }

    final int discount;
    final String description;
    switch (code) {
      case 'RIJIKI10':
        discount = (subtotal * 0.10).round().clamp(0, 15000).toInt();
        description = 'Diskon 10% (maks Rp 15.000)';
      case 'HEMAT5K':
        discount = subtotal < 5000 ? subtotal : 5000;
        description = 'Potongan Rp 5.000';
      default:
        throw const PromoException(
          'Kode promo tidak ditemukan atau sudah tidak berlaku.',
        );
    }

    return PriceQuote(
      price: PriceBreakdown(
        subtotal: subtotal,
        discount: discount,
        shipping: _shippingFee,
      ),
      promoCode: code,
      promoDescription: description,
    );
  }

  @override
  Future<CustomerOrder> createOrder(NewOrder order, PriceQuote quote) async {
    await scenario.resolve<bool>(empty: true, data: true);

    final now = DateTime.now();
    final sequence = MockOrderStore.nextSequence();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    final created = CustomerOrder(
      id: 'ord-new-$sequence',
      orderNumber: 'RJK-$month$day-${sequence.toString().padLeft(3, '0')}',
      status: OrderStatus.order,
      paymentStatus: OrderPaymentStatus.unpaid,
      items: [
        for (var i = 0; i < order.items.length; i++)
          OrderItem(
            id: 'it-new-$sequence-$i',
            shoeName: order.items[i].shoeBrand.trim(),
            serviceName: order.items[i].service!.name,
            price: order.items[i].service!.basePrice,
            quantity: order.items[i].quantity,
            notes: order.items[i].notes.trim().isEmpty
                ? null
                : order.items[i].notes.trim(),
          ),
      ],
      price: quote.price,
      promoCode: quote.promoCode,
      customerName: order.customerName.trim(),
      customerPhone: order.phone.trim(),
      pickupAddress: order.pickupAddress,
      deliveryAddress: order.deliveryAddress,
      createdAt: now,
      statusHistory: [OrderStatusHistory(status: OrderStatus.order, changedAt: now)],
    );
    MockOrderStore.created.insert(0, created);
    return created;
  }

  static const String _homeAddress =
      'Jl. Soekarno Hatta No. 9, Lowokwaru, Kota Malang';
  static List<CustomerOrder> _buildOrders() {
    final now = DateTime.now();

    OrderStatusHistory at(OrderStatus status, Duration ago, {String? note}) =>
        OrderStatusHistory(
          status: status,
          changedAt: now.subtract(ago),
          note: note,
        );

    return [
      CustomerOrder(
        id: 'ord-1',
        orderNumber: 'RJK-0710-005',
        status: OrderStatus.order,
        paymentStatus: OrderPaymentStatus.unpaid,
        items: const [
          OrderItem(
            id: 'it-1',
            shoeName: 'Sandal Eiger',
            serviceName: 'Cuci Sandal',
            price: 18000,
          ),
        ],
        price: const PriceBreakdown(subtotal: 18000, shipping: 8000),
        pickupAddress: _homeAddress,
        deliveryAddress: _homeAddress,
        createdAt: now.subtract(const Duration(hours: 2)),
        scheduledPickupAt: now.add(const Duration(hours: 3)),
        statusHistory: [at(OrderStatus.order, const Duration(hours: 2))],
      ),

      CustomerOrder(
        id: 'ord-2',
        orderNumber: 'RJK-0710-002',
        status: OrderStatus.cleaning,
        paymentStatus: OrderPaymentStatus.paid,
        items: const [
          OrderItem(
            id: 'it-2',
            shoeName: 'Nike Air Force 1',
            serviceName: 'Deep Clean',
            price: 40000,
            notes: 'Ada noda tinta di bagian depan kanan.',
          ),
          OrderItem(
            id: 'it-3',
            shoeName: 'Adidas Samba',
            serviceName: 'Fast Clean',
            price: 30000,
            notes: 'Jahitan di tumit agak longgar.',
          ),
        ],
        price: const PriceBreakdown(subtotal: 70000, shipping: 5000),
        pickupAddress: _homeAddress,
        deliveryAddress: _homeAddress,
        createdAt: now.subtract(const Duration(days: 1)),
        workerName: 'Budi S.',
        statusHistory: [
          at(OrderStatus.order, const Duration(days: 1)),
          at(OrderStatus.pickup, const Duration(hours: 22)),
          at(OrderStatus.waiting, const Duration(hours: 20)),
          at(OrderStatus.cleaning, const Duration(hours: 4)),
        ],
        documentation: const [
          OrderDocumentation(
            id: 'doc-1',
            type: DocumentationType.before,
            orderItemId: 'it-2',
          ),
          OrderDocumentation(
            id: 'doc-2',
            type: DocumentationType.before,
            orderItemId: 'it-3',
          ),
        ],
      ),
      CustomerOrder(
        id: 'ord-3',
        orderNumber: 'RJK-0708-011',
        status: OrderStatus.delivery,
        paymentStatus: OrderPaymentStatus.paid,
        items: const [
          OrderItem(
            id: 'it-4',
            shoeName: 'New Balance 550',
            serviceName: 'Reguler Treatment',
            price: 25000,
          ),
        ],
        price: const PriceBreakdown(
          subtotal: 25000,
          discount: 2500,
          shipping: 10000,
        ),
        promoCode: 'RIJIKI10',
        pickupAddress: _homeAddress,
        deliveryAddress: 'Jl. Veteran No. 12, Klojen, Kota Malang',
        createdAt: now.subtract(const Duration(days: 2)),
        workerName: 'Dewi A.',
        statusHistory: [
          at(OrderStatus.order, const Duration(days: 2)),
          at(OrderStatus.pickup, const Duration(days: 2) - const Duration(hours: 3)),
          at(OrderStatus.waiting, const Duration(days: 1, hours: 20)),
          at(OrderStatus.cleaning, const Duration(days: 1, hours: 6)),
          at(OrderStatus.delivery, const Duration(minutes: 35)),
        ],
        documentation: const [
          OrderDocumentation(
            id: 'doc-3',
            type: DocumentationType.before,
            orderItemId: 'it-4',
          ),
          OrderDocumentation(
            id: 'doc-4',
            type: DocumentationType.after,
            orderItemId: 'it-4',
          ),
        ],
      ),
      CustomerOrder(
        id: 'ord-4',
        orderNumber: 'RJK-0703-004',
        status: OrderStatus.completed,
        paymentStatus: OrderPaymentStatus.paid,
        items: const [
          OrderItem(
            id: 'it-5',
            shoeName: 'Converse Chuck 70',
            serviceName: 'Reglue',
            price: 50000,
            notes: 'Sol depan terbuka sekitar 5 cm.',
          ),
          OrderItem(
            id: 'it-6',
            shoeName: 'Converse Chuck 70',
            serviceName: 'Unyellowing',
            price: 30000,
          ),
        ],
        price: const PriceBreakdown(subtotal: 80000, shipping: 10000),
        pickupAddress: _homeAddress,
        deliveryAddress: _homeAddress,
        createdAt: now.subtract(const Duration(days: 6)),
        completedAt: now.subtract(const Duration(days: 4)),
        workerName: 'Budi S.',
        statusHistory: [
          at(OrderStatus.order, const Duration(days: 6)),
          at(OrderStatus.pickup, const Duration(days: 5, hours: 21)),
          at(OrderStatus.waiting, const Duration(days: 5, hours: 18)),
          at(OrderStatus.cleaning, const Duration(days: 5)),
          at(OrderStatus.delivery, const Duration(days: 4, hours: 3)),
          at(OrderStatus.completed, const Duration(days: 4)),
        ],
        documentation: const [
          OrderDocumentation(
            id: 'doc-5',
            type: DocumentationType.before,
            orderItemId: 'it-5',
          ),
          OrderDocumentation(
            id: 'doc-6',
            type: DocumentationType.after,
            orderItemId: 'it-5',
          ),
          OrderDocumentation(
            id: 'doc-7',
            type: DocumentationType.before,
            orderItemId: 'it-6',
          ),
          OrderDocumentation(
            id: 'doc-8',
            type: DocumentationType.after,
            orderItemId: 'it-6',
          ),
          OrderDocumentation(id: 'doc-9', type: DocumentationType.proofOfDelivery),
        ],
      ),

      CustomerOrder(
        id: 'ord-5',
        orderNumber: 'RJK-0628-020',
        status: OrderStatus.completed,
        paymentStatus: OrderPaymentStatus.paid,
        items: const [
          OrderItem(
            id: 'it-7',
            shoeName: 'Vans Old Skool',
            serviceName: 'Deep Clean',
            price: 40000,
          ),
        ],
        price: const PriceBreakdown(subtotal: 40000, shipping: 10000),
        pickupAddress: _homeAddress,
        deliveryAddress: _homeAddress,
        createdAt: now.subtract(const Duration(days: 12)),
        completedAt: now.subtract(const Duration(days: 10)),
        workerName: 'Dewi A.',
        isRated: true,
        statusHistory: [
          at(OrderStatus.order, const Duration(days: 12)),
          at(OrderStatus.pickup, const Duration(days: 11, hours: 21)),
          at(OrderStatus.waiting, const Duration(days: 11, hours: 18)),
          at(OrderStatus.cleaning, const Duration(days: 11)),
          at(OrderStatus.delivery, const Duration(days: 10, hours: 3)),
          at(OrderStatus.completed, const Duration(days: 10)),
        ],
        documentation: const [
          OrderDocumentation(
            id: 'doc-10',
            type: DocumentationType.before,
            orderItemId: 'it-7',
          ),
          OrderDocumentation(
            id: 'doc-11',
            type: DocumentationType.after,
            orderItemId: 'it-7',
          ),
          OrderDocumentation(id: 'doc-12', type: DocumentationType.proofOfDelivery),
        ],
      ),
      CustomerOrder(
        id: 'ord-6',
        orderNumber: 'RJK-0625-007',
        status: OrderStatus.cancelled,
        paymentStatus: OrderPaymentStatus.unpaid,
        items: const [
          OrderItem(
            id: 'it-8',
            shoeName: 'Eiger Anaconda',
            serviceName: 'Sepatu Gunung',
            price: 45000,
          ),
        ],
        price: const PriceBreakdown(subtotal: 45000, shipping: 10000),
        pickupAddress: _homeAddress,
        deliveryAddress: _homeAddress,
        createdAt: now.subtract(const Duration(days: 15)),
        statusHistory: [
          at(OrderStatus.order, const Duration(days: 15)),
          at(
            OrderStatus.cancelled,
            const Duration(days: 15) - const Duration(hours: 1),
            note: 'Dibatalkan oleh customer',
          ),
        ],
      ),
    ];
  }
}
