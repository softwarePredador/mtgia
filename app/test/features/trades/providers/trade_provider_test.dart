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
}
