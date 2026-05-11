import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/services/realtime_notification_coordinator.dart';

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
  });
}
