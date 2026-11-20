import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/storage/token_storage.dart';
import 'package:rijiki/features/chat/data/order_chat_repository_impl.dart';
import 'package:rijiki/features/chat/domain/order_message.dart';

class _FakeTokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'token-tes';

  @override
  Future<String?> readRefreshToken() async => 'refresh-tes';
}

OrderChatRepositoryImpl _repo(
  Future<http.Response> Function(http.Request) handler,
) {
  return OrderChatRepositoryImpl(
    api: ApiClient(
      baseUrl: 'https://contoh.test',
      tokenStorage: _FakeTokens(),
      client: MockClient(handler),
    ),
  );
}

Map<String, dynamic> _messageJson({
  String id = 'msg-1',
  String senderRole = 'worker',
  String body = 'Sepatu sudah selesai dicuci ya',
  bool mine = false,
  String createdAt = '2026-11-18T08:00:00Z',
}) {
  return {
    'id': id,
    'order_id': 'order-1',
    'sender_id': mine ? 'user-saya' : 'user-lain',
    'sender_role': senderRole,
    'body': body,
    'created_at': createdAt,
    'mine': mine,
  };
}

void main() {
  group('OrderChatRepositoryImpl', () {
    test('fetchThread memetakan pesan, peran pengirim, dan unread', () async {
      late http.Request captured;
      final repo = _repo((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'items': [
              _messageJson(id: 'msg-1'),
              _messageJson(
                id: 'msg-2',
                senderRole: 'customer',
                body: 'Siap, terima kasih',
                mine: true,
              ),
            ],
            'unread': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final thread = await repo.fetchThread('order-1');

      expect(captured.url.path, '/api/orders/order-1/messages');
      expect(captured.headers['Authorization'], 'Bearer token-tes');
      expect(thread.unread, 1);
      expect(thread.messages, hasLength(2));
      expect(thread.messages.first.senderRole, MessageSenderRole.worker);
      expect(thread.messages.first.mine, isFalse);
      expect(thread.messages.last.senderRole, MessageSenderRole.customer);
      expect(thread.messages.last.mine, isTrue);
      expect(
        thread.messages.first.createdAt.toUtc(),
        DateTime.utc(2026, 11, 18, 8),
      );
    });

    test('send mengirim body dan mengembalikan pesan tersimpan', () async {
      late http.Request captured;
      final repo = _repo((request) async {
        captured = request;
        return http.Response(
          jsonEncode(
            _messageJson(body: 'Kapan kurir sampai?', mine: true, senderRole: 'customer'),
          ),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final sent = await repo.send('order-1', 'Kapan kurir sampai?');

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/orders/order-1/messages');
      expect(jsonDecode(captured.body), {'body': 'Kapan kurir sampai?'});
      expect(sent.body, 'Kapan kurir sampai?');
      expect(sent.mine, isTrue);
    });

    test('markRead memanggil endpoint baca', () async {
      late http.Request captured;
      final repo = _repo((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'unread': 0}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await repo.markRead('order-1');

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/orders/order-1/messages/read');
    });

    test('peran pengirim tidak dikenal jatuh ke worker tanpa melempar', () async {
      final repo = _repo((request) async {
        return http.Response(
          jsonEncode({
            'items': [_messageJson(senderRole: 'sistem')],
            'unread': 0,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final thread = await repo.fetchThread('order-1');

      expect(thread.messages.single.senderRole, MessageSenderRole.worker);
    });
  });
}
