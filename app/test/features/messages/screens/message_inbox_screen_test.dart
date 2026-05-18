import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/messages/screens/message_inbox_screen.dart';
import 'package:provider/provider.dart';

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

void main() {
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
