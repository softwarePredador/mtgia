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
  _RealtimeMessagesApiClient({this.sendStatus = 201});

  final int sendStatus;
  final getEndpoints = <String>[];
  final postEndpoints = <String>[];
  final postBodies = <Map<String, dynamic>>[];
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
      return ApiResponse(200, {
        'conversation_id': 'conversation-1',
        'marked_read': 1,
        'unread': unread,
      });
    }
    return ApiResponse(200, {'ok': true});
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postEndpoints.add(endpoint);
    postBodies.add(Map<String, dynamic>.from(body));
    if (endpoint == '/conversations/conversation-1/messages') {
      return ApiResponse(sendStatus, {
        'id': 'message-sent',
        'sender_id': 'user-1',
        'message': body['message'],
        'created_at': '2026-05-11T10:01:00Z',
      });
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

class _SwitchingMessagesApiClient extends ApiClient {
  final completers = <String, Completer<ApiResponse>>{};

  @override
  Future<ApiResponse> get(String endpoint) {
    final completer = Completer<ApiResponse>();
    completers[endpoint] = completer;
    return completer.future;
  }
}

class _FailingConversationsApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/conversations?')) {
      return ApiResponse(500, {'error': 'server_error'});
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
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

  test('fetchConversations exposes error on backend failure', () async {
    final provider = MessageProvider(
      apiClient: _FailingConversationsApiClient(),
    );

    await provider.fetchConversations();

    expect(provider.conversations, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNotNull);
  });

  test(
    'sendMessage refreshes conversation list preview after success',
    () async {
      final api = _RealtimeMessagesApiClient();
      final provider = MessageProvider(apiClient: api);

      final sent = await provider.sendMessage('conversation-1', 'resposta');

      expect(sent, isTrue);
      expect(provider.messages.first.id, 'message-sent');
      expect(provider.conversations, hasLength(1));
      expect(
        api.postEndpoints,
        contains('/conversations/conversation-1/messages'),
      );
      expect(api.getEndpoints, contains('/conversations?page=1&limit=20'));
    },
  );

  test(
    'sendMessage preserves client id and accepts idempotent replay',
    () async {
      final api = _RealtimeMessagesApiClient(sendStatus: 200);
      final provider = MessageProvider(apiClient: api);

      final first = await provider.sendMessage(
        'conversation-1',
        'resposta',
        clientRequestId: 'stable-request-1',
      );
      final replay = await provider.sendMessage(
        'conversation-1',
        'resposta',
        clientRequestId: 'stable-request-1',
      );

      expect(first, isTrue);
      expect(replay, isTrue);
      expect(
        api.postBodies.map((body) => body['client_request_id']),
        everyElement('stable-request-1'),
      );
      expect(provider.messages, hasLength(1));
    },
  );

  test('late message response cannot overwrite active conversation', () async {
    final api = _SwitchingMessagesApiClient();
    final provider = MessageProvider(apiClient: api);

    provider.setActiveConversation('conversation-a');
    final first = provider.fetchMessages('conversation-a');
    await Future<void>.delayed(Duration.zero);

    provider.setActiveConversation('conversation-b');
    final second = provider.fetchMessages('conversation-b');
    await Future<void>.delayed(Duration.zero);

    api.completers['/conversations/conversation-b/messages?page=1&limit=50']!
        .complete(
          ApiResponse(200, {
            'data': [
              {
                'id': 'message-b',
                'sender_id': 'user-b',
                'message': 'B ativa',
                'created_at': '2026-05-15T14:00:00Z',
              },
            ],
            'total': 1,
          }),
        );
    await second;

    api.completers['/conversations/conversation-a/messages?page=1&limit=50']!
        .complete(
          ApiResponse(200, {
            'data': [
              {
                'id': 'message-a',
                'sender_id': 'user-a',
                'message': 'A atrasada',
                'created_at': '2026-05-15T13:59:00Z',
              },
            ],
            'total': 1,
          }),
        );
    await first;

    expect(provider.activeConversationId, 'conversation-b');
    expect(provider.messages, hasLength(1));
    expect(provider.messages.single.id, 'message-b');
  });

  test(
    'late conversation response cannot repopulate state after clear',
    () async {
      final api = _SwitchingMessagesApiClient();
      final provider = MessageProvider(apiClient: api);

      final request = provider.fetchConversations();
      await Future<void>.delayed(Duration.zero);

      provider.clearAllState();
      api.completers['/conversations?page=1&limit=20']!.complete(
        ApiResponse(200, {
          'data': [
            {
              'id': 'conversation-stale',
              'other_user': {'id': 'user-stale', 'username': 'stale'},
              'last_message': 'stale',
              'unread_count': 4,
              'created_at': '2026-05-15T14:00:00Z',
            },
          ],
          'total': 1,
        }),
      );
      await request;

      expect(provider.conversations, isEmpty);
      expect(provider.unreadCount, 0);
      expect(provider.isLoading, isFalse);
    },
  );

  test(
    'late chat response is ignored after active conversation closes',
    () async {
      final api = _SwitchingMessagesApiClient();
      final provider = MessageProvider(apiClient: api);

      provider.setActiveConversation('conversation-a');
      final request = provider.fetchMessages('conversation-a');
      await Future<void>.delayed(Duration.zero);

      provider.clearActiveConversation('conversation-a');
      api.completers['/conversations/conversation-a/messages?page=1&limit=50']!
          .complete(
            ApiResponse(200, {
              'data': [
                {
                  'id': 'message-stale',
                  'sender_id': 'user-a',
                  'message': 'stale',
                  'created_at': '2026-05-15T14:00:00Z',
                },
              ],
              'total': 1,
            }),
          );
      await request;

      expect(provider.activeConversationId, isNull);
      expect(provider.messages, isEmpty);
      expect(provider.isLoadingMessages, isFalse);
    },
  );
}
