import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/messages/providers/message_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../features/trades/providers/trade_provider.dart';
import '../observability/app_observability.dart';

class PushNotificationPayload {
  const PushNotificationPayload({required this.type, this.referenceId});

  final String type;
  final String? referenceId;

  static PushNotificationPayload? fromData(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim();
    if (type == null || type.isEmpty) {
      return null;
    }

    final referenceId = data['reference_id']?.toString().trim();
    return PushNotificationPayload(
      type: type,
      referenceId: referenceId?.isNotEmpty == true ? referenceId : null,
    );
  }

  bool get isTradeEvent =>
      type == 'trade_offer_received' ||
      type == 'trade_accepted' ||
      type == 'trade_declined' ||
      type == 'trade_shipped' ||
      type == 'trade_delivered' ||
      type == 'trade_completed' ||
      type == 'trade_message';

  bool get isDirectMessage => type == 'direct_message';
  bool get isFollower => type == 'new_follower';
}

class RealtimeNotificationCoordinator {
  RealtimeNotificationCoordinator({
    required GoRouter router,
    required NotificationProvider notificationProvider,
    required MessageProvider messageProvider,
    required TradeProvider tradeProvider,
  }) : _router = router,
       _notificationProvider = notificationProvider,
       _messageProvider = messageProvider,
       _tradeProvider = tradeProvider;

  final GoRouter _router;
  final NotificationProvider _notificationProvider;
  final MessageProvider _messageProvider;
  final TradeProvider _tradeProvider;

  Future<void> handleForegroundData(Map<String, dynamic> data) async {
    final payload = PushNotificationPayload.fromData(data);
    if (payload == null) {
      return;
    }

    _debugLog('foreground', payload);
    unawaited(_recordPushEvent('foreground', payload));

    await _notificationProvider.handleRealtimeEvent(
      type: payload.type,
      referenceId: payload.referenceId,
    );

    final referenceId = payload.referenceId;
    if (payload.isDirectMessage && referenceId != null) {
      await _messageProvider.handleRealtimeDirectMessage(referenceId);
      return;
    }

    if (payload.isTradeEvent && referenceId != null) {
      await _tradeProvider.handleRealtimeTradeEvent(payload.type, referenceId);
    }
  }

  void handleMessageTapData(Map<String, dynamic> data) {
    final payload = PushNotificationPayload.fromData(data);
    if (payload == null) {
      return;
    }

    _debugLog('tap', payload);
    unawaited(_recordPushEvent('tap', payload));
    unawaited(handleForegroundData(data));

    final route = RealtimeNotificationCoordinator.routeForPayload(payload);
    if (route == null) {
      return;
    }
    _router.go(route);
  }

  @visibleForTesting
  static String? routeForPayload(PushNotificationPayload payload) {
    final referenceId = payload.referenceId;
    if (referenceId == null) {
      if (payload.isDirectMessage) {
        return '/messages';
      }
      return null;
    }

    if (payload.isFollower) {
      return '/community/user/$referenceId';
    }
    if (payload.isTradeEvent) {
      return '/trades/$referenceId';
    }
    if (payload.isDirectMessage) {
      return '/messages/$referenceId';
    }
    return null;
  }

  void _debugLog(String source, PushNotificationPayload payload) {
    if (!kDebugMode) {
      return;
    }
    final hasReference = payload.referenceId != null;
    debugPrint(
      '[RealtimePush] $source type=${payload.type} has_reference=$hasReference',
    );
  }

  Future<void> _recordPushEvent(
    String source,
    PushNotificationPayload payload,
  ) {
    return AppObservability.instance.recordEvent(
      'push_notification_$source',
      category: 'notifications',
      data: {
        'type': payload.type,
        'has_reference_id': payload.referenceId != null,
      },
    );
  }
}
