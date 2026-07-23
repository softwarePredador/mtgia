import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/services/message_draft_store.dart';
import 'package:manaloom/features/auth/models/user.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/messages/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopApiClient extends ApiClient {}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider() : super(apiClient: _NoopApiClient());

  @override
  User? get user =>
      User(id: 'user-1', username: 'tester', email: 'tester@example.com');
}

class _ChatApiClient extends ApiClient {
  _ChatApiClient({required this.messagesStatus, required this.sendStatus});

  final int messagesStatus;
  final int sendStatus;
  int messageFetchCount = 0;
  int sendCount = 0;
  final postBodies = <Map<String, dynamic>>[];

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/conversations/conversation-1/messages')) {
      messageFetchCount += 1;
      if (messagesStatus == 200) {
        return ApiResponse(200, {'data': <Map<String, dynamic>>[], 'total': 0});
      }
      return ApiResponse(messagesStatus, {'error': 'server_error'});
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    if (endpoint == '/conversations/conversation-1/read') {
      return ApiResponse(200, {
        'conversation_id': 'conversation-1',
        'marked_read': 0,
        'unread': 0,
      });
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/conversations/conversation-1/messages') {
      sendCount += 1;
      postBodies.add(Map<String, dynamic>.from(body));
      if (sendStatus == 201) {
        return ApiResponse(201, {
          'id': 'message-sent',
          'sender_id': 'user-1',
          'message': body['message'],
          'created_at': '2026-05-28T12:00:00Z',
        });
      }
      return ApiResponse(sendStatus, {'error': 'server_error'});
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

Future<void> _pumpChat(
  WidgetTester tester, {
  required MessageProvider provider,
  MessageDraftStore? draftStore,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => _FakeAuthProvider(),
        ),
        ChangeNotifierProvider<MessageProvider>.value(value: provider),
      ],
      child: MaterialApp(
        home: ChatScreen(
          conversationId: 'conversation-1',
          draftStore: draftStore,
          otherUser: ConversationUser(
            id: 'user-2',
            username: 'opponent',
            displayName: 'Oponente',
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'chat shows error state instead of empty state on fetch failure',
    (tester) async {
      final api = _ChatApiClient(messagesStatus: 500, sendStatus: 201);
      final provider = MessageProvider(apiClient: api);

      await _pumpChat(tester, provider: provider);

      expect(find.byKey(const Key('chat-error-state')), findsOneWidget);
      expect(find.byKey(const Key('chat-empty-state')), findsNothing);
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(api.messageFetchCount, greaterThanOrEqualTo(2));
    },
  );

  testWidgets('chat preserves draft and shows feedback when send fails', (
    tester,
  ) async {
    final api = _ChatApiClient(messagesStatus: 200, sendStatus: 500);
    final provider = MessageProvider(apiClient: api);
    final draftStore = MessageDraftStore();

    await _pumpChat(tester, provider: provider, draftStore: draftStore);

    expect(find.byKey(const Key('chat-empty-state')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'proposta de troca',
    );
    await tester.tap(find.byKey(const Key('chat-message-send-button')));
    await tester.pump();
    await tester.pump();

    expect(api.sendCount, 1);
    expect(find.text('proposta de troca'), findsOneWidget);
    expect(
      find.text('Não foi possível enviar a mensagem. Tente novamente.'),
      findsOneWidget,
    );
    final persisted = await draftStore.load('direct:conversation-1');
    expect(persisted.text, 'proposta de troca');
    expect(persisted.clientRequestId, isNotNull);

    await tester.tap(find.byKey(const Key('chat-message-send-button')));
    await tester.pump();
    await tester.pump();

    expect(api.sendCount, 2);
    expect(
      api.postBodies.map((body) => body['client_request_id']).toSet(),
      hasLength(1),
    );
  });

  testWidgets('chat preserva mobile e limita coluna de leitura no desktop', (
    tester,
  ) async {
    for (final size in const [Size(390, 800), Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final provider = MessageProvider(
        apiClient: _ChatApiClient(messagesStatus: 200, sendStatus: 201),
      );

      await _pumpChat(tester, provider: provider);

      final columnSize = tester.getSize(
        find.byKey(const Key('chat-reading-column')),
      );
      expect(columnSize.width, lessThanOrEqualTo(760));
      expect(columnSize.width, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
