import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/storage/token_storage.dart';
import 'package:rijiki/features/service/data/service_repository_impl.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';

class _FakeTokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'token-tes';

  @override
  Future<String?> readRefreshToken() async => 'refresh-tes';
}

ServiceRepositoryImpl _repo(Future<http.Response> Function(http.Request) handler) {
  return ServiceRepositoryImpl(
    api: ApiClient(
      baseUrl: 'https://contoh.test',
      tokenStorage: _FakeTokens(),
      client: MockClient(handler),
    ),
  );
}

Map<String, dynamic> _serviceJson({
  String id = 'svc-1',
  String name = 'Deep Clean',
  String category = 'cuci_sepatu',
  num price = 40000,
  bool active = true,
}) {
  return {
    'id': id,
    'name': name,
    'description': 'Pembersihan total',
    'category': category,
    'base_price': price,
    'estimated_duration_minutes': 120,
    'is_active': active,
  };
}

void main() {
  group('ServiceRepositoryImpl', () {
    test('fetchAllServices memakai endpoint CMS dan mengirim token', () async {
      late http.Request captured;
      final repo = _repo((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'items': [_serviceJson(), _serviceJson(id: 'svc-2', name: 'Reglue', category: 'reparasi', active: false)],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final services = await repo.fetchAllServices();

      expect(captured.url.path, '/api/services/manage');
      expect(captured.headers['Authorization'], 'Bearer token-tes');
      expect(services, hasLength(2));
      expect(services.first.category, ServiceCategory.cuciSepatu);
      expect(services.last.category, ServiceCategory.reparasi);
      expect(services.last.isActive, isFalse);
    });

    test('fetchServices (katalog customer) tidak mengirim token', () async {
      late http.Request captured;
      final repo = _repo((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'items': [_serviceJson()]}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await repo.fetchServices();

      expect(captured.url.path, '/api/services');
      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('createService mengirim payload yang dipakai backend', () async {
      late http.Request captured;
      final repo = _repo((request) async {
        captured = request;
        return http.Response(
          jsonEncode(_serviceJson(id: 'svc-baru', name: 'Unyellowing Baru')),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final created = await repo.createService(
        const CareServiceInput(
          name: '  Unyellowing Baru  ',
          category: ServiceCategory.reparasi,
          basePrice: 32000,
          description: '   ',
          estimatedDurationMinutes: null,
        ),
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/services');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['name'], 'Unyellowing Baru');
      expect(body['category'], 'reparasi');
      expect(body['base_price'], 32000);
      expect(body['description'], isNull);
      expect(body['estimated_duration_minutes'], isNull);
      expect(body['is_active'], isTrue);
      expect(created.id, 'svc-baru');
    });

    test('setServiceActive hanya mengirim is_active', () async {
      late http.Request captured;
      final repo = _repo((request) async {
        captured = request;
        return http.Response(
          jsonEncode(_serviceJson(active: false)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final updated = await repo.setServiceActive('svc-1', false);

      expect(captured.method, 'PATCH');
      expect(captured.url.path, '/api/services/svc-1');
      expect(jsonDecode(captured.body), {'is_active': false});
      expect(updated.isActive, isFalse);
    });

    test('nama duplikat dari backend muncul sebagai pesan Failure', () async {
      final repo = _repo((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'service_name_taken',
              'message': 'Nama layanan ini sudah dipakai.',
            },
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      await expectLater(
        repo.createService(
          const CareServiceInput(
            name: 'Deep Clean',
            category: ServiceCategory.cuciSepatu,
            basePrice: 40000,
          ),
        ),
        throwsA(
          isA<Failure>().having(
            (f) => f.message,
            'message',
            'Nama layanan ini sudah dipakai.',
          ),
        ),
      );
    });
  });
}
