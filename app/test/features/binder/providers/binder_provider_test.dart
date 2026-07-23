import 'dart:async';

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
            'playable_card_id': 'oracle-1',
            'owned_quantity': 4,
            'allocated_quantity': 2,
            'committed_trade_quantity': 1,
            'free_quantity': 1,
            'missing_quantity': 0,
            'available_quantity': 1,
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
        'estimated_value': null,
        'estimated_value_brl': null,
        'estimated_value_usd': null,
        'owned_quantity': 8,
        'allocated_quantity': 5,
        'committed_trade_quantity': 1,
        'free_quantity': 2,
        'deck_missing_quantity': 0,
      });
    }

    return ApiResponse(404, {'error': 'unexpected endpoint $endpoint'});
  }

  @override
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
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

class _DelayedBinderApiClient extends ApiClient {
  final completers = <String, Completer<ApiResponse>>{};
  final getCalls = <String>[];

  @override
  Future<ApiResponse> get(String endpoint) {
    getCalls.add(endpoint);
    final completer = Completer<ApiResponse>();
    completers[endpoint] = completer;
    return completer.future;
  }
}

Map<String, dynamic> _binderItemJson({
  required String id,
  required String name,
  required String listType,
}) => {
  'id': id,
  'card_id': '$id-card',
  'card_name': name,
  'quantity': 1,
  'condition': 'NM',
  'is_foil': false,
  'for_trade': false,
  'for_sale': false,
  'currency': 'BRL',
  'language': 'pt',
  'list_type': listType,
};

void main() {
  test('binder stats keep missing totals null and currencies separate', () {
    final unavailable = BinderStats.fromJson({
      'estimated_value': null,
      'estimated_value_brl': null,
      'estimated_value_usd': null,
      'price_missing_count': 4,
    });
    final mixed = BinderStats.fromJson({
      'estimated_value': null,
      'estimated_value_brl': 30.0,
      'estimated_value_usd': 12.5,
      'estimated_value_mixed_currency': true,
      'priced_copies_count': 3,
    });

    expect(unavailable.estimatedValue, isNull);
    expect(unavailable.estimatedValueBrl, isNull);
    expect(unavailable.estimatedValueUsd, isNull);
    expect(unavailable.priceMissingCount, 4);
    expect(mixed.estimatedValue, isNull);
    expect(mixed.estimatedValueBrl, 30);
    expect(mixed.estimatedValueUsd, 12.5);
    expect(mixed.estimatedValueMixedCurrency, isTrue);
    expect(mixed.pricedCopiesCount, 3);
  });

  test('parses reserved-list metadata for binder and marketplace cards', () {
    final binderItem = BinderItem.fromJson({
      'id': 'binder-1',
      'card': {'id': 'card-1', 'name': 'Gaea\'s Cradle', 'is_reserved': true},
    });
    final marketplaceItem = MarketplaceItem.fromJson({
      'id': 'market-1',
      'card': {'id': 'card-2', 'name': 'Mox Diamond', 'is_reserved': true},
      'owner': {'id': 'user-1', 'username': 'seller'},
    });

    expect(binderItem.cardIsReserved, isTrue);
    expect(marketplaceItem.cardIsReserved, isTrue);
  });

  test('parses the canonical owned, allocated, free and missing contract', () {
    final item = BinderItem.fromJson({
      'id': 'binder-availability',
      'card_id': 'printing-1',
      'card_name': 'Sol Ring',
      'quantity': 3,
      'playable_card_id': 'oracle-1',
      'owned_quantity': 5,
      'allocated_quantity': 3,
      'committed_trade_quantity': 1,
      'free_quantity': 1,
      'missing_quantity': 0,
      'available_quantity': 1,
    });
    final stats = BinderStats.fromJson({
      'owned_quantity': 5,
      'allocated_quantity': 3,
      'committed_trade_quantity': 1,
      'free_quantity': 1,
      'deck_missing_quantity': 0,
    });

    expect(item.playableCardId, 'oracle-1');
    expect(item.ownedQuantity, 5);
    expect(item.allocatedQuantity, 3);
    expect(item.committedTradeQuantity, 1);
    expect(item.freeQuantity, 1);
    expect(item.availableQuantity, 1);
    expect(stats.ownedQuantity, 5);
    expect(stats.allocatedQuantity, 3);
    expect(stats.committedTradeQuantity, 1);
    expect(stats.freeQuantity, 1);
  });

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

  test(
    'updateItem removes item from active list when list_type changes',
    () async {
      final api = _FakeBinderApiClient();
      final provider = BinderProvider(apiClient: api);

      provider.applyFilters(listType: 'have');
      await Future<void>.delayed(Duration.zero);
      expect(provider.items, hasLength(1));

      final updated = await provider.updateItem('binder-1', {
        'list_type': 'want',
      });

      expect(updated, isTrue);
      expect(api.lastPutBody?['list_type'], 'want');
      expect(provider.items, isEmpty);
    },
  );

  test(
    'reset fetch ignores stale binder response from previous filter',
    () async {
      final api = _DelayedBinderApiClient();
      final provider = BinderProvider(apiClient: api);

      final oldFuture = provider.fetchMyBinder(reset: true);
      await Future<void>.delayed(Duration.zero);
      provider.applyFilters(listType: 'want');
      await Future<void>.delayed(Duration.zero);

      final oldEndpoint = api.getCalls.singleWhere(
        (endpoint) => !endpoint.contains('list_type='),
      );
      final newEndpoint = api.getCalls.singleWhere(
        (endpoint) => endpoint.contains('list_type=want'),
      );

      api.completers[newEndpoint]!.complete(
        ApiResponse(200, {
          'data': [
            _binderItemJson(
              id: 'want-1',
              name: 'Wanted Card',
              listType: 'want',
            ),
          ],
          'page': 1,
          'limit': 20,
          'total': 1,
        }),
      );
      await Future<void>.delayed(Duration.zero);

      api.completers[oldEndpoint]!.complete(
        ApiResponse(200, {
          'data': [
            _binderItemJson(id: 'have-1', name: 'Have Card', listType: 'have'),
          ],
          'page': 1,
          'limit': 20,
          'total': 1,
        }),
      );
      await oldFuture;

      expect(provider.items, hasLength(1));
      expect(provider.items.single.id, 'want-1');
      expect(provider.items.single.listType, 'want');
    },
  );
}
