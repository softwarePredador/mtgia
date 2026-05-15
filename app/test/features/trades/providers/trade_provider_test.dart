import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';

class _TradeFailureApiClient extends ApiClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    lastEndpoint = endpoint;
    lastBody = body;
    if (endpoint == '/trades') {
      return ApiResponse(409, {
        'error': 'ownership validation failed: item not available',
      });
    }
    return ApiResponse(500, {'error': 'RequestOptions /trades'});
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    lastEndpoint = endpoint;
    lastBody = body;
    return ApiResponse(400, {'error': 'invalid status transition'});
  }
}

class _RealtimeTradeApiClient extends ApiClient {
  final getEndpoints = <String>[];

  @override
  Future<ApiResponse> get(String endpoint) async {
    getEndpoints.add(endpoint);
    if (endpoint == '/trades/trade-1') {
      return ApiResponse(200, {
        'id': 'trade-1',
        'status': 'shipped',
        'type': 'sale',
        'sender': {'id': 'buyer-1', 'username': 'buyer'},
        'receiver': {'id': 'seller-1', 'username': 'seller'},
        'created_at': '2026-05-11T10:00:00Z',
        'updated_at': '2026-05-11T10:05:00Z',
        'my_items': [],
        'their_items': [],
        'messages': [
          {
            'id': 'message-1',
            'sender_id': 'seller-1',
            'message': 'Enviado',
            'created_at': '2026-05-11T10:05:00Z',
          },
        ],
        'status_history': [
          {
            'id': 'history-1',
            'old_status': 'accepted',
            'new_status': 'shipped',
            'changed_by_username': 'seller',
            'created_at': '2026-05-11T10:05:00Z',
          },
        ],
      });
    }
    if (endpoint == '/trades?page=1&limit=20&role=all') {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'trade-1',
            'status': 'shipped',
            'type': 'sale',
            'sender': {'id': 'buyer-1', 'username': 'buyer'},
            'receiver': {'id': 'seller-1', 'username': 'seller'},
            'created_at': '2026-05-11T10:00:00Z',
            'updated_at': '2026-05-11T10:05:00Z',
          },
        ],
        'total': 1,
        'page': 1,
      });
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

class _TradeStatusMutationApiClient extends ApiClient {
  final putEndpoints = <String>[];
  String detailStatus = 'pending';

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/trades?page=1&limit=20&role=all') {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'trade-1',
            'status': 'pending',
            'type': 'trade',
            'sender': {'id': 'sender-1', 'username': 'sender'},
            'receiver': {'id': 'receiver-1', 'username': 'receiver'},
            'created_at': '2026-05-11T10:00:00Z',
            'updated_at': '2026-05-11T10:00:00Z',
          },
        ],
        'total': 1,
        'page': 1,
      });
    }
    if (endpoint == '/trades/trade-1') {
      return ApiResponse(200, {
        'id': 'trade-1',
        'status': detailStatus,
        'type': 'trade',
        'sender': {'id': 'sender-1', 'username': 'sender'},
        'receiver': {'id': 'receiver-1', 'username': 'receiver'},
        'created_at': '2026-05-11T10:00:00Z',
        'updated_at': '2026-05-11T10:05:00Z',
        'my_items': [],
        'their_items': [],
        'messages': [],
        'status_history': [],
      });
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    putEndpoints.add(endpoint);
    if (endpoint == '/trades/trade-1/status') {
      detailStatus = body['status'] as String? ?? 'pending';
      return ApiResponse(200, {'ok': true});
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

class _DelayedTradeApiClient extends ApiClient {
  final completers = <String, Completer<ApiResponse>>{};

  @override
  Future<ApiResponse> get(String endpoint) {
    final completer = Completer<ApiResponse>();
    completers[endpoint] = completer;
    return completer.future;
  }
}

void main() {
  test(
    'createTrade maps item availability failure to friendly message',
    () async {
      final api = _TradeFailureApiClient();
      final provider = TradeProvider(apiClient: api);

      final ok = await provider.createTrade(
        receiverId: 'receiver-1',
        requestedItems: const [
          {'binder_item_id': 'binder-1', 'quantity': 1},
        ],
      );

      expect(ok, isFalse);
      expect(api.lastEndpoint, '/trades');
      expect(
        provider.errorMessage,
        'Algum item desta proposta não está mais disponível. Atualize e tente novamente.',
      );
      expect(provider.errorMessage, isNot(contains('ownership')));
    },
  );

  test(
    'updateTradeStatus maps invalid transition to friendly message',
    () async {
      final api = _TradeFailureApiClient();
      final provider = TradeProvider(apiClient: api);

      final ok = await provider.updateTradeStatus('trade-1', 'completed');

      expect(ok, isFalse);
      expect(api.lastEndpoint, '/trades/trade-1/status');
      expect(
        provider.errorMessage,
        'Esta troca mudou de status. Atualize e tente novamente.',
      );
      expect(provider.errorMessage, isNot(contains('invalid status')));
    },
  );

  test(
    'foreground trade status refreshes active detail and timeline',
    () async {
      final api = _RealtimeTradeApiClient();
      final provider = TradeProvider(apiClient: api);
      provider.setActiveTrade('trade-1');

      await provider.handleRealtimeTradeEvent('trade_shipped', 'trade-1');

      expect(provider.selectedTrade?.status, 'shipped');
      expect(provider.chatMessages, hasLength(1));
      expect(provider.selectedTrade?.statusHistory, hasLength(1));
      expect(api.getEndpoints, contains('/trades/trade-1'));
    },
  );

  test(
    'foreground trade event refreshes inbox list when detail is inactive',
    () async {
      final api = _RealtimeTradeApiClient();
      final provider = TradeProvider(apiClient: api);

      await provider.handleRealtimeTradeEvent('trade_message', 'trade-1');

      expect(provider.trades, hasLength(1));
      expect(api.getEndpoints, contains('/trades?page=1&limit=20&role=all'));
    },
  );

  test(
    'updateTradeStatus patches matching list row after detail refresh',
    () async {
      final api = _TradeStatusMutationApiClient();
      final provider = TradeProvider(apiClient: api);

      await provider.fetchTrades();
      expect(provider.trades.single.status, 'pending');

      final updated = await provider.updateTradeStatus('trade-1', 'shipped');

      expect(updated, isTrue);
      expect(api.putEndpoints, contains('/trades/trade-1/status'));
      expect(provider.selectedTrade?.status, 'shipped');
      expect(provider.trades.single.status, 'shipped');
    },
  );

  test(
    'late list and detail responses are ignored after clearAllState',
    () async {
      final api = _DelayedTradeApiClient();
      final provider = TradeProvider(apiClient: api);

      final listRequest = provider.fetchTrades();
      await Future<void>.delayed(Duration.zero);
      provider.clearAllState();
      api.completers['/trades?page=1&limit=20&role=all']!.complete(
        ApiResponse(200, {
          'data': [
            {
              'id': 'trade-stale',
              'status': 'pending',
              'type': 'trade',
              'sender': {'id': 'sender-stale', 'username': 'sender'},
              'receiver': {'id': 'receiver-stale', 'username': 'receiver'},
              'created_at': '2026-05-15T14:00:00Z',
              'updated_at': '2026-05-15T14:00:00Z',
            },
          ],
          'total': 1,
          'page': 1,
        }),
      );
      await listRequest;

      expect(provider.trades, isEmpty);
      expect(provider.totalTrades, 0);
      expect(provider.isLoading, isFalse);

      provider.setActiveTrade('trade-stale');
      final detailRequest = provider.fetchTradeDetail('trade-stale');
      await Future<void>.delayed(Duration.zero);
      provider.clearAllState();
      api.completers['/trades/trade-stale']!.complete(
        ApiResponse(200, {
          'id': 'trade-stale',
          'status': 'accepted',
          'type': 'trade',
          'sender': {'id': 'sender-stale', 'username': 'sender'},
          'receiver': {'id': 'receiver-stale', 'username': 'receiver'},
          'created_at': '2026-05-15T14:00:00Z',
          'updated_at': '2026-05-15T14:01:00Z',
          'my_items': [],
          'their_items': [],
          'messages': [],
          'status_history': [],
        }),
      );
      await detailRequest;

      expect(provider.selectedTrade, isNull);
      expect(provider.chatMessages, isEmpty);
      expect(provider.activeTradeId, isNull);
      expect(provider.isLoading, isFalse);
    },
  );
}
