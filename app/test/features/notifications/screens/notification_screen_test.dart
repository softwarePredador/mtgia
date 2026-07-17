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

class _FailingReadAllApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/notifications?')) {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'notif-1',
            'type': 'direct_message',
            'title': 'Nova mensagem',
            'read_at': null,
            'created_at': '2026-07-16T12:00:00Z',
          },
        ],
      });
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    if (endpoint == '/notifications/read-all') {
      return ApiResponse(503, {'error': 'unavailable'});
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

void main() {
  testWidgets(
    'notifications screen shows error state instead of empty state on fetch failure',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
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
      expect(
        tester.getSize(find.byKey(const Key('notifications-content'))).width,
        lessThanOrEqualTo(390),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('notifications-empty')), findsNothing);
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(api.fetchCount, greaterThanOrEqualTo(2));

      tester.view.physicalSize = const Size(1280, 900);
      await tester.pump();
      expect(
        tester.getSize(find.byKey(const Key('notifications-content'))).width,
        lessThanOrEqualTo(840),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('read all failure is visible and keeps unread notification', (
    tester,
  ) async {
    final provider = NotificationProvider(
      apiClient: _FailingReadAllApiClient(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('notifications-read-all-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('notifications-read-all-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível marcar as notificações como lidas. Tente novamente.',
      ),
      findsOneWidget,
    );
    expect(provider.notifications.single.isRead, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
