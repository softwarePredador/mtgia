import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';

class _SlowMessagesApiClient extends ApiClient {
  final completer = Completer<ApiResponse>();
  var messageFetchCount = 0;

  @override
  Future<ApiResponse> get(String endpoint) {
    if (endpoint.startsWith('/conversations/conversation-1/messages')) {
      messageFetchCount += 1;
      return completer.future;
    }
    return Future.value(ApiResponse(404, {'error': 'unexpected $endpoint'}));
  }
}

void main() {
  test('fetchMessages ignores overlapping polling calls for same conversation', () async {
    final api = _SlowMessagesApiClient();
    final provider = MessageProvider(apiClient: api);

    final first = provider.fetchMessages('conversation-1');
    await Future<void>.delayed(Duration.zero);
    final second = provider.fetchMessages('conversation-1', incremental: true);
    await Future<void>.delayed(Duration.zero);

    expect(api.messageFetchCount, 1);

    api.completer.complete(
      ApiResponse(200, {
        'data': [
          {
            'id': 'message-1',
            'sender_id': 'user-1',
            'message': 'hello',
            'created_at': '2026-04-29T19:00:00Z',
          },
        ],
        'total': 1,
      }),
    );

    await first;
    await second;

    expect(provider.messages, hasLength(1));
    expect(provider.isLoadingMessages, isFalse);
  });
}
