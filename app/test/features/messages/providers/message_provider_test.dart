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

class _RealtimeMessagesApiClient extends ApiClient {
  final getEndpoints = <String>[];
  final putEndpoints = <String>[];
  int unread = 1;

  @override
  Future<ApiResponse> get(String endpoint) async {
    getEndpoints.add(endpoint);
    if (endpoint == '/conversations/unread-count') {
      return ApiResponse(200, {'unread': unread});
    }
    if (endpoint == '/conversations?page=1&limit=20') {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'conversation-1',
            'other_user': {
              'id': 'user-2',
              'username': 'jogador2',
              'display_name': 'Jogador 2',
            },
            'last_message': 'mensagem nova',
            'last_message_sender_id': 'user-2',
            'unread_count': 1,
            'last_message_at': '2026-05-11T10:00:00Z',
            'created_at': '2026-05-11T09:00:00Z',
          },
        ],
        'total': 1,
      });
    }
    if (endpoint.startsWith('/conversations/conversation-1/messages')) {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'message-1',
            'sender_id': 'user-2',
            'message': 'mensagem nova',
            'created_at': '2026-05-11T10:00:00Z',
          },
        ],
        'total': 1,
      });
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    putEndpoints.add(endpoint);
    if (endpoint == '/conversations/conversation-1/read') {
      unread = 0;
    }
    return ApiResponse(200, {'ok': true});
  }
}

void main() {
  test(
    'fetchMessages ignores overlapping polling calls for same conversation',
    () async {
      final api = _SlowMessagesApiClient();
      final provider = MessageProvider(apiClient: api);

      final first = provider.fetchMessages('conversation-1');
      await Future<void>.delayed(Duration.zero);
      final second = provider.fetchMessages(
        'conversation-1',
        incremental: true,
      );
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
    },
  );

  test(
    'foreground direct_message refreshes inbox, active chat and unread badge',
    () async {
      final api = _RealtimeMessagesApiClient();
      final provider = MessageProvider(apiClient: api);
      provider.setActiveConversation('conversation-1');

      await provider.handleRealtimeDirectMessage('conversation-1');

      expect(provider.conversations, hasLength(1));
      expect(provider.messages, hasLength(1));
      expect(provider.unreadCount, 0);
      expect(
        api.getEndpoints,
        containsAll([
          '/conversations/unread-count',
          '/conversations?page=1&limit=20',
          '/conversations/conversation-1/messages?page=1&limit=50',
        ]),
      );
      expect(api.putEndpoints, contains('/conversations/conversation-1/read'));
    },
  );
}
