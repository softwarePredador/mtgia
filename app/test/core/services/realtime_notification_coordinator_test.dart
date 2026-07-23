import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/services/realtime_notification_coordinator.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';

class _RecordingNotificationProvider extends NotificationProvider {
  final List<(String, String?)> events = [];

  @override
  Future<void> handleRealtimeEvent({
    required String type,
    String? referenceId,
  }) async {
    events.add((type, referenceId));
  }
}

class _RecordingMessageProvider extends MessageProvider {
  final List<String> handledConversationIds = [];

  @override
  Future<void> handleRealtimeDirectMessage(String conversationId) async {
    handledConversationIds.add(conversationId);
  }
}

class _RecordingTradeProvider extends TradeProvider {
  final List<(String, String)> events = [];

  @override
  Future<void> handleRealtimeTradeEvent(String type, String tradeId) async {
    events.add((type, tradeId));
  }
}

GoRouter _testRouter() {
  return GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink())],
  );
}

void main() {
  group('RealtimeNotificationCoordinator payload routing', () {
    test('parses minimal FCM data payload', () {
      final payload = PushNotificationPayload.fromData({
        'type': 'trade_message',
        'reference_id': 'trade-1',
      });

      expect(payload, isNotNull);
      expect(payload!.type, 'trade_message');
      expect(payload.referenceId, 'trade-1');
      expect(payload.isTradeEvent, isTrue);
    });

    test('maps notification tap payloads to stable app routes', () {
      expect(
        RealtimeNotificationCoordinator.routeForPayload(
          const PushNotificationPayload(
            type: 'new_follower',
            referenceId: 'user-1',
          ),
        ),
        '/community/user/user-1',
      );
      expect(
        RealtimeNotificationCoordinator.routeForPayload(
          const PushNotificationPayload(
            type: 'trade_shipped',
            referenceId: 'trade-1',
          ),
        ),
        '/trades/trade-1',
      );
      expect(
        RealtimeNotificationCoordinator.routeForPayload(
          const PushNotificationPayload(
            type: 'direct_message',
            referenceId: 'conversation-1',
          ),
        ),
        '/messages/conversation-1',
      );
    });

    test(
      'dispatches a foreground direct message to the correct providers',
      () async {
        final router = _testRouter();
        final notifications = _RecordingNotificationProvider();
        final messages = _RecordingMessageProvider();
        final trades = _RecordingTradeProvider();
        addTearDown(router.dispose);

        final coordinator = RealtimeNotificationCoordinator(
          router: router,
          notificationProvider: notifications,
          messageProvider: messages,
          tradeProvider: trades,
        );

        await coordinator.handleForegroundData({
          'type': 'direct_message',
          'reference_id': 'conversation-1',
        });

        expect(notifications.events, [('direct_message', 'conversation-1')]);
        expect(messages.handledConversationIds, ['conversation-1']);
        expect(trades.events, isEmpty);
      },
    );

    test(
      'dispatches a foreground trade event to the correct providers',
      () async {
        final router = _testRouter();
        final notifications = _RecordingNotificationProvider();
        final messages = _RecordingMessageProvider();
        final trades = _RecordingTradeProvider();
        addTearDown(router.dispose);

        final coordinator = RealtimeNotificationCoordinator(
          router: router,
          notificationProvider: notifications,
          messageProvider: messages,
          tradeProvider: trades,
        );

        await coordinator.handleForegroundData({
          'type': 'trade_message',
          'reference_id': 'trade-1',
        });

        expect(notifications.events, [('trade_message', 'trade-1')]);
        expect(messages.handledConversationIds, isEmpty);
        expect(trades.events, [('trade_message', 'trade-1')]);
      },
    );

    test('ignores payloads without a notification type', () async {
      final router = _testRouter();
      final notifications = _RecordingNotificationProvider();
      final messages = _RecordingMessageProvider();
      final trades = _RecordingTradeProvider();
      addTearDown(router.dispose);

      final coordinator = RealtimeNotificationCoordinator(
        router: router,
        notificationProvider: notifications,
        messageProvider: messages,
        tradeProvider: trades,
      );

      await coordinator.handleForegroundData({
        'reference_id': 'conversation-1',
      });

      expect(notifications.events, isEmpty);
      expect(messages.handledConversationIds, isEmpty);
      expect(trades.events, isEmpty);
    });
  });
}
