import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/messages/screens/message_inbox_screen.dart';
import 'package:provider/provider.dart';

import '../../../support/list_tile_material_test_support.dart';

class _FailingMessagesApiClient extends ApiClient {
  var fetchCount = 0;

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/conversations?')) {
      fetchCount += 1;
      return ApiResponse(500, {'error': 'server_error'});
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

class _PopulatedMessagesApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/conversations?')) {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'conversation-1',
            'other_user': {
              'id': 'user-2',
              'username': 'teferi',
              'display_name': 'Teferi',
              'avatar_url': null,
            },
            'last_message': 'Sua vez.',
            'unread_count': 2,
            'last_message_at': '2026-07-16T20:00:00Z',
          },
        ],
        'total': 1,
      });
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

void main() {
  testWidgets('conversation tile paints color, border and ink on Material', (
    tester,
  ) async {
    final provider = MessageProvider(apiClient: _PopulatedMessagesApiClient());

    await tester.pumpWidget(
      ChangeNotifierProvider<MessageProvider>.value(
        value: provider,
        child: const MaterialApp(home: MessageInboxScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('message-conversation-tile-conversation-1')),
      findsOneWidget,
    );
    expectListTileInkIsUnobscured(tester);
  });

  testWidgets(
    'inbox shows error state instead of empty state on fetch failure',
    (tester) async {
      final api = _FailingMessagesApiClient();
      final provider = MessageProvider(apiClient: api);

      await tester.pumpWidget(
        ChangeNotifierProvider<MessageProvider>.value(
          value: provider,
          child: const MaterialApp(home: MessageInboxScreen()),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('messages-inbox-error')), findsOneWidget);
      expect(find.byKey(const Key('messages-inbox-empty')), findsNothing);
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(api.fetchCount, greaterThanOrEqualTo(2));
    },
  );
}
