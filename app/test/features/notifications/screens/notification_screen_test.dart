import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/notifications/screens/notification_screen.dart';
import 'package:provider/provider.dart';

class _FailingNotificationsApiClient extends ApiClient {
  var fetchCount = 0;

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/notifications?')) {
      fetchCount += 1;
      return ApiResponse(500, {'error': 'server_error'});
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

void main() {
  testWidgets(
    'notifications screen shows error state instead of empty state on fetch failure',
    (tester) async {
      final api = _FailingNotificationsApiClient();
      final provider = NotificationProvider(apiClient: api);

      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationProvider>.value(
          value: provider,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('notifications-error')), findsOneWidget);
      expect(find.byKey(const Key('notifications-empty')), findsNothing);
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(api.fetchCount, greaterThanOrEqualTo(2));
    },
  );
}
