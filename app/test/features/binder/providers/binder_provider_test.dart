import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';

class _FakeBinderApiClient extends ApiClient {
  var deletedItemId = '';
  Map<String, dynamic>? lastPostBody;
  Map<String, dynamic>? lastPutBody;

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/binder?')) {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'binder-1',
            'card_id': 'card-1',
            'card_name': 'Sol Ring',
            'quantity': 1,
            'condition': 'NM',
            'is_foil': false,
            'for_trade': true,
            'for_sale': false,
            'currency': 'BRL',
            'language': 'pt',
            'list_type': 'have',
          },
        ],
        'page': 1,
        'limit': 20,
        'total': 1,
      });
    }

    if (endpoint == '/binder/stats') {
      return ApiResponse(200, {
        'total_items': 0,
        'unique_cards': 0,
        'for_trade_count': 0,
        'for_sale_count': 0,
        'estimated_value': 0.0,
      });
    }

    return ApiResponse(404, {'error': 'unexpected endpoint $endpoint'});
  }

  @override
  Future<ApiResponse> delete(String endpoint) async {
    deletedItemId = endpoint.split('/').last;
    return ApiResponse(204, null);
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    lastPostBody = body;
    return ApiResponse(201, {'id': 'binder-created'});
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    lastPutBody = body;
    return ApiResponse(200, {'message': 'ok'});
  }
}

void main() {
  test(
    'removeItem treats backend 204 No Content as successful delete',
    () async {
      final api = _FakeBinderApiClient();
      final provider = BinderProvider(apiClient: api);

      await provider.fetchMyBinder(reset: true);
      expect(provider.items, hasLength(1));
      expect(provider.items.single.language, 'pt');

      final removed = await provider.removeItem('binder-1');

      expect(removed, isTrue);
      expect(api.deletedItemId, 'binder-1');
      expect(provider.items, isEmpty);
      expect(provider.error, isNull);
    },
  );

  test('addItem sends language to backend contract', () async {
    final api = _FakeBinderApiClient();
    final provider = BinderProvider(apiClient: api);

    final created = await provider.addItem(
      cardId: 'card-1',
      language: 'es',
      condition: 'LP',
    );

    expect(created, isTrue);
    expect(api.lastPostBody?['language'], 'es');
    expect(api.lastPostBody?['condition'], 'LP');
  });

  test(
    'updateItem applies language locally when backend accepts update',
    () async {
      final api = _FakeBinderApiClient();
      final provider = BinderProvider(apiClient: api);
      await provider.fetchMyBinder(reset: true);

      final updated = await provider.updateItem('binder-1', {'language': 'ja'});

      expect(updated, isTrue);
      expect(api.lastPutBody?['language'], 'ja');
      expect(provider.items.single.language, 'ja');
    },
  );
}
