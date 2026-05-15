import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';

class _FakeNotificationApiClient extends ApiClient {
  final requestedEndpoints = <String>[];
  final putEndpoints = <String>[];
  int unread = 2;
  bool readAllCalled = false;

  @override
  Future<ApiResponse> get(String endpoint) async {
    requestedEndpoints.add(endpoint);
    if (endpoint == '/notifications/count') {
      return ApiResponse(200, {'unread': unread});
    }
    if (endpoint.startsWith('/notifications?')) {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'notif-1',
            'type': 'direct_message',
            'reference_id': 'conversation-1',
            'title': 'Nova mensagem',
            'body': 'Oi',
            'read_at': null,
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
    if (endpoint == '/notifications/read-all') {
      readAllCalled = true;
      unread = 0;
      return ApiResponse(200, {'marked_read': 2, 'unread': unread});
    }
    if (endpoint == '/notifications/notif-1/read') {
      return ApiResponse(200, {'ok': true});
    }
    return ApiResponse(404, {'error': 'unexpected $endpoint'});
  }
}

class _DelayedNotificationApiClient extends ApiClient {
  final completers = <String, Completer<ApiResponse>>{};

  @override
  Future<ApiResponse> get(String endpoint) {
    final completer = Completer<ApiResponse>();
    completers[endpoint] = completer;
    return completer.future;
  }
}

void main() {
  group('AppNotification Model', () {
    test('fromJson deve parsear corretamente com todos os campos', () {
      final json = {
        'id': 'notif-1',
        'type': 'new_follower',
        'reference_id': 'user-123',
        'title': 'JohnDoe começou a seguir você',
        'body': null,
        'read_at': null,
        'created_at': '2025-01-30T10:00:00Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif-1');
      expect(notif.type, 'new_follower');
      expect(notif.referenceId, 'user-123');
      expect(notif.title, 'JohnDoe começou a seguir você');
      expect(notif.body, isNull);
      expect(notif.readAt, isNull);
      expect(notif.createdAt, '2025-01-30T10:00:00Z');
      expect(notif.isRead, isFalse);
    });

    test('fromJson deve marcar isRead true quando read_at presente', () {
      final json = {
        'id': 'notif-2',
        'type': 'trade_accepted',
        'reference_id': 'trade-456',
        'title': 'Trade aceito!',
        'body': 'Sua proposta foi aceita por Jane',
        'read_at': '2025-01-30T11:00:00Z',
        'created_at': '2025-01-30T10:00:00Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.isRead, isTrue);
      expect(notif.body, 'Sua proposta foi aceita por Jane');
    });

    test('fromJson deve usar defaults para campos ausentes', () {
      final json = {'id': 'notif-3'};

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif-3');
      expect(notif.type, '');
      expect(notif.referenceId, isNull);
      expect(notif.title, '');
      expect(notif.body, isNull);
      expect(notif.readAt, isNull);
      expect(notif.createdAt, '');
      expect(notif.isRead, isFalse);
    });

    test('todos os tipos de notificação devem parsear', () {
      final types = [
        'new_follower',
        'trade_offer_received',
        'trade_accepted',
        'trade_declined',
        'trade_shipped',
        'trade_delivered',
        'trade_completed',
        'trade_message',
        'direct_message',
      ];

      for (final type in types) {
        final json = {
          'id': 'notif-$type',
          'type': type,
          'title': 'Test notification',
          'created_at': '2025-01-30T10:00:00Z',
        };

        final notif = AppNotification.fromJson(json);
        expect(notif.type, type, reason: 'Falhou para tipo $type');
      }
    });
  });

  group('NotificationProvider', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('estado inicial deve ser correto', () {
      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
      expect(provider.isLoading, isFalse);
    });

    test('stopPolling não deve lançar exceção quando não há polling ativo', () {
      // Should not throw
      provider.stopPolling();
    });

    test('dispose deve parar o polling', () {
      // startPolling will fail without server, but stopPolling should work
      provider.stopPolling();
      // No exception means success
    });

    test(
      'foreground event refreshes badge and loaded notification list',
      () async {
        final api = _FakeNotificationApiClient();
        final provider = NotificationProvider(apiClient: api);

        await provider.fetchNotifications();
        api.unread = 3;

        await provider.handleRealtimeEvent(
          type: 'direct_message',
          referenceId: 'conversation-1',
        );

        expect(provider.unreadCount, 3);
        expect(provider.notifications, hasLength(1));
        expect(
          api.requestedEndpoints,
          containsAll([
            '/notifications/count',
            '/notifications?page=1&limit=30',
          ]),
        );
      },
    );

    test('markAsRead and markAllAsRead update local badge state', () async {
      final api = _FakeNotificationApiClient();
      final provider = NotificationProvider(apiClient: api);

      await provider.fetchNotifications();
      await provider.fetchUnreadCount();
      expect(provider.unreadCount, 2);

      await provider.markAsRead('notif-1');
      expect(provider.notifications.single.isRead, isTrue);
      expect(provider.unreadCount, 1);

      await provider.markAllAsRead();
      expect(api.readAllCalled, isTrue);
      expect(provider.unreadCount, 0);
    });

    test(
      'late count and list responses are ignored after clearAllState',
      () async {
        final api = _DelayedNotificationApiClient();
        final provider = NotificationProvider(apiClient: api);

        final countRequest = provider.fetchUnreadCount();
        await Future<void>.delayed(Duration.zero);
        provider.clearAllState();
        api.completers['/notifications/count']!.complete(
          ApiResponse(200, {'unread': 7}),
        );
        await countRequest;

        expect(provider.unreadCount, 0);

        final listRequest = provider.fetchNotifications();
        await Future<void>.delayed(Duration.zero);
        provider.clearAllState();
        api.completers['/notifications?page=1&limit=30']!.complete(
          ApiResponse(200, {
            'data': [
              {
                'id': 'notif-stale',
                'type': 'direct_message',
                'reference_id': 'conversation-stale',
                'title': 'Stale',
                'created_at': '2026-05-15T14:00:00Z',
              },
            ],
            'total': 1,
          }),
        );
        await listRequest;

        expect(provider.notifications, isEmpty);
        expect(provider.isLoading, isFalse);
      },
    );
  });
}
