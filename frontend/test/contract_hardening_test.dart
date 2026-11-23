import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/storage/token_storage.dart';
import 'package:rijiki/features/finance/data/finance_repository_impl.dart';
import 'package:rijiki/features/order/data/order_repository_impl.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';
import 'package:rijiki/features/worker_management/data/worker_repository_impl.dart';

class _FakeTokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'token-tes';

  @override
  Future<String?> readRefreshToken() async => 'refresh-tes';
}

ApiClient _api(Future<http.Response> Function(http.Request) handler) {
  return ApiClient(
    baseUrl: 'https://contoh.test',
    tokenStorage: _FakeTokens(),
    client: MockClient(handler),
  );
}

Map<String, dynamic> _quoteJson() => {
  'subtotal': 80000,
  'discount_amount': 8000,
  'shipping_fee': 10000,
  'total_price': 82000,
  'promos': [
    {
      'code': 'HEMAT',
      'applies_to': 'subtotal',
      'discount_amount': 8000,
      'description': 'Hemat · Diskon 10%',
    },
  ],
  'distance_km': 2.5,
};

void main() {
  group('quote harga', () {
    test('tidak mengirim subtotal dari client, hanya item dan promo', () async {
      late Map<String, dynamic> body;
      final repo = OrderRepositoryImpl(
        api: _api((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(_quoteJson()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final quote = await repo.quotePrice(
        subtotal: 999999,
        promoCodes: const ['HEMAT'],
        items: const [
          OrderDraftItem(
            id: 'draft-1',
            service: CareService(
              id: 'svc-1',
              name: 'Deep Clean',
              category: ServiceCategory.cuciSepatu,
              basePrice: 40000,
            ),
            quantity: 2,
          ),
        ],
      );

      // Subtotal dari client tidak boleh ikut: backend menghitungnya sendiri.
      expect(body.containsKey('subtotal'), isFalse);
      expect(body['items'], [
        {'service_id': 'svc-1', 'quantity': 2},
      ]);
      expect(body['promo_codes'], ['HEMAT']);
      expect(quote.price.subtotal, 80000);
    });
  });

  group('paginasi transaksi keuangan', () {
    test('mengirim page dan limit lalu membaca total dari server', () async {
      late Uri captured;
      final repo = FinanceRepositoryImpl(
        api: _api((request) async {
          captured = request.url;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'trx-1',
                  'type': 'expense',
                  'category': null,
                  'amount': 45000,
                  'description': null,
                  'related_order_id': null,
                  'transaction_date': '2026-11-18',
                  'item_name': 'Sabun',
                  'quantity': 2,
                  'unit': 'botol',
                  'vendor_name': 'Toko Maju',
                  'input_source': 'manual',
                  'receipt_image_url': null,
                  'payment_method': null,
                },
              ],
              'total': 137,
              'page': 3,
              'limit': 20,
              'income': 0,
              'expense': 45000,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final page = await repo.fetchTransactionPage(
        const TransactionFilter(),
        page: 3,
        limit: 20,
      );

      expect(captured.queryParameters['page'], '3');
      expect(captured.queryParameters['limit'], '20');
      // Total dari server menentukan apakah masih ada halaman berikutnya.
      expect(page.total, 137);
      expect(page.items, hasLength(1));
      expect(page.hasMore, isTrue);
    });
  });

  group('ulasan worker', () {
    test('meminta halaman pertama dan membaca daftar dari items', () async {
      late Uri captured;
      final repo = WorkerRepositoryImpl(
        api: _api((request) async {
          captured = request.url;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'rev-1',
                  'customer_name': 'A***',
                  'rating_value': 5,
                  'created_at': '2026-11-18T10:00:00Z',
                  'order_number': 'RJK-1',
                  'comment': 'Mantap',
                  'service_name': 'Deep Clean',
                },
              ],
              'total': 1,
              'page': 1,
              'limit': 50,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final reviews = await repo.fetchReviews('worker-1');

      expect(captured.queryParameters['page'], '1');
      expect(captured.queryParameters['limit'], '50');
      expect(reviews.single.orderNumber, 'RJK-1');
    });
  });
}
