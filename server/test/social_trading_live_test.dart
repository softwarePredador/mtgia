@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  Map<String, String> jsonHeaders([String? token]) => {
    'Content-Type': 'application/json',
    'X-Request-Id': 'social-live-${DateTime.now().microsecondsSinceEpoch}',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> registerUser(String suffix) async {
    final body = {
      'username': 'social_live_$suffix',
      'email': 'social_live_$suffix@example.com',
      'password': 'BetaQa!2026-Deck',
    };
    var response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: jsonHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: jsonHeaders(),
        body: jsonEncode({
          'email': body['email'],
          'password': body['password'],
        }),
      );
    }
    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> jsonRequest(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    int expectedStatus = 200,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = switch (method) {
      'GET' => await http.get(uri, headers: jsonHeaders(token)),
      'POST' => await http.post(
        uri,
        headers: jsonHeaders(token),
        body: jsonEncode(body ?? const {}),
      ),
      'PUT' => await http.put(
        uri,
        headers: jsonHeaders(token),
        body: jsonEncode(body ?? const {}),
      ),
      _ => throw ArgumentError('Unsupported method $method'),
    };
    expect(response.statusCode, expectedStatus, reason: response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<int> unreadCount(String token) async {
    final body = await jsonRequest('GET', '/notifications/count', token: token);
    return body['unread'] as int? ?? 0;
  }

  Map<String, dynamic> notificationByType(
    Map<String, dynamic> response,
    String type,
  ) {
    final notifications =
        (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return notifications.firstWhere(
      (item) => item['type'] == type,
      orElse: () => fail('notification type $type not found'),
    );
  }

  Future<Map<String, dynamic>> createTradeFixture(String suffix) async {
    final seller = await registerUser('${suffix}_seller');
    final buyer = await registerUser('${suffix}_buyer');
    final sellerToken = seller['token'] as String;
    final buyerToken = buyer['token'] as String;
    final sellerId = (seller['user'] as Map<String, dynamic>)['id'] as String;
    final buyerId = (buyer['user'] as Map<String, dynamic>)['id'] as String;

    final cardSearch = await jsonRequest(
      'GET',
      '/cards?name=Sol%20Ring&limit=1',
      token: sellerToken,
    );
    final cards = cardSearch['data'] as List<dynamic>;
    expect(cards, isNotEmpty);
    final cardId = (cards.first as Map<String, dynamic>)['id'] as String;

    final binder = await jsonRequest(
      'POST',
      '/binder',
      token: sellerToken,
      expectedStatus: 201,
      body: {
        'card_id': cardId,
        'quantity': 12,
        'condition': 'NM',
        'for_trade': true,
        'for_sale': true,
        'price': 9.99,
        'list_type': 'have',
      },
    );
    final binderItemId = binder['id'] as String;
    addTearDown(
      () => jsonRequest(
        'PUT',
        '/binder/$binderItemId',
        token: sellerToken,
        body: {'for_trade': false, 'for_sale': false},
      ),
    );

    return {
      'sellerToken': sellerToken,
      'buyerToken': buyerToken,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'binderItemId': binderItemId,
    };
  }

  Future<Map<String, dynamic>> createSaleTrade(
    Map<String, dynamic> fixture, {
    String message = 'Mensagem de contrato live',
  }) {
    return jsonRequest(
      'POST',
      '/trades',
      token: fixture['buyerToken'] as String,
      expectedStatus: 201,
      body: {
        'receiver_id': fixture['sellerId'],
        'type': 'sale',
        'payment_method': 'cash',
        'payment_amount': 9.99,
        'requested_items': [
          {
            'binder_item_id': fixture['binderItemId'],
            'quantity': 1,
            'agreed_price': 9.99,
          },
        ],
        'message': message,
      },
    );
  }

  group('social trading live contracts', () {
    test(
      'writes keep response contracts and create deferred notifications',
      () async {
        final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
        final seller = await registerUser('${suffix}_seller');
        final buyer = await registerUser('${suffix}_buyer');
        final sellerToken = seller['token'] as String;
        final buyerToken = buyer['token'] as String;
        final sellerId =
            (seller['user'] as Map<String, dynamic>)['id'] as String;

        final cardSearch = await jsonRequest(
          'GET',
          '/cards?name=Sol%20Ring&limit=1',
          token: sellerToken,
        );
        final cards = cardSearch['data'] as List<dynamic>;
        expect(cards, isNotEmpty);
        final cardId = (cards.first as Map<String, dynamic>)['id'] as String;

        final binder = await jsonRequest(
          'POST',
          '/binder',
          token: sellerToken,
          expectedStatus: 201,
          body: {
            'card_id': cardId,
            'quantity': 4,
            'condition': 'NM',
            'for_trade': true,
            'for_sale': true,
            'price': 9.99,
            'list_type': 'have',
          },
        );
        final binderItemId = binder['id'] as String;
        addTearDown(
          () => jsonRequest(
            'PUT',
            '/binder/$binderItemId',
            token: sellerToken,
            body: {'for_trade': false, 'for_sale': false},
          ),
        );

        final invalidTrade = await http.post(
          Uri.parse('$baseUrl/trades'),
          headers: jsonHeaders(buyerToken),
          body: jsonEncode({
            'receiver_id': sellerId,
            'type': 'sale',
            'payment_method': 'wire',
            'requested_items': [
              {'binder_item_id': binderItemId, 'quantity': 1},
            ],
          }),
        );
        expect(invalidTrade.statusCode, 400);

        final createTradeWatch = Stopwatch()..start();
        final trade = await jsonRequest(
          'POST',
          '/trades',
          token: buyerToken,
          expectedStatus: 201,
          body: {
            'receiver_id': sellerId,
            'type': 'sale',
            'payment_method': 'cash',
            'payment_amount': 9.99,
            'requested_items': [
              {
                'binder_item_id': binderItemId,
                'quantity': 1,
                'agreed_price': 9.99,
              },
            ],
            'message': 'Mensagem de contrato live',
          },
        );
        createTradeWatch.stop();
        expect(
          createTradeWatch.elapsedMilliseconds,
          lessThan(3500),
          reason:
              'POST /trades deve permanecer abaixo do teto live contra DB remoto',
        );
        expect(trade.keys, containsAll(['id', 'status', 'type', 'created_at']));
        expect(trade['status'], 'pending');
        final tradeId = trade['id'] as String;

        await Future<void>.delayed(const Duration(milliseconds: 1600));
        expect(await unreadCount(sellerToken), greaterThanOrEqualTo(1));

        final respondWatch = Stopwatch()..start();
        final accepted = await jsonRequest(
          'PUT',
          '/trades/$tradeId/respond',
          token: sellerToken,
          body: {'action': 'accept'},
        );
        respondWatch.stop();
        expect(
          respondWatch.elapsedMilliseconds,
          lessThan(2000),
          reason:
              'PUT /trades/:id/respond deve permanecer abaixo do teto live contra DB remoto',
        );
        expect(accepted.keys, containsAll(['id', 'status', 'message']));
        expect(accepted['id'], tradeId);
        expect(accepted['status'], 'accepted');
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        final acceptedNotifications = await jsonRequest(
          'GET',
          '/notifications?limit=20',
          token: buyerToken,
        );
        final acceptedTypes =
            (acceptedNotifications['data'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((item) => item['type'])
                .toSet();
        expect(acceptedTypes, contains('trade_accepted'));
        final acceptedNotification = notificationByType(
          acceptedNotifications,
          'trade_accepted',
        );
        expect(acceptedNotification['reference_id'], tradeId);

        final invalidStatus = await http.put(
          Uri.parse('$baseUrl/trades/$tradeId/status'),
          headers: jsonHeaders(sellerToken),
          body: jsonEncode({'status': 'shipped', 'delivery_method': 'mail'}),
        );
        expect(invalidStatus.statusCode, 400);

        final statusWatch = Stopwatch()..start();
        final shipped = await jsonRequest(
          'PUT',
          '/trades/$tradeId/status',
          token: sellerToken,
          body: {
            'status': 'shipped',
            'delivery_method': 'correios',
            'tracking_code': 'QA123',
          },
        );
        statusWatch.stop();
        expect(
          statusWatch.elapsedMilliseconds,
          lessThan(2000),
          reason:
              'PUT /trades/:id/status deve permanecer abaixo do teto live contra DB remoto',
        );
        expect(shipped['old_status'], 'accepted');
        expect(shipped['status'], 'shipped');
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        final buyerNotifications = await jsonRequest(
          'GET',
          '/notifications?limit=20',
          token: buyerToken,
        );
        final buyerTypes =
            (buyerNotifications['data'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((item) => item['type'])
                .toSet();
        expect(buyerTypes, contains('trade_shipped'));
        final shippedNotification = notificationByType(
          buyerNotifications,
          'trade_shipped',
        );
        expect(shippedNotification['reference_id'], tradeId);

        final tradeMessage = await jsonRequest(
          'POST',
          '/trades/$tradeId/messages',
          token: buyerToken,
          expectedStatus: 201,
          body: {'message': 'Mensagem de trade live'},
        );
        expect(
          tradeMessage.keys,
          containsAll(['id', 'trade_offer_id', 'sender_id', 'message']),
        );

        final delivered = await jsonRequest(
          'PUT',
          '/trades/$tradeId/status',
          token: buyerToken,
          body: {'status': 'delivered'},
        );
        expect(delivered['old_status'], 'shipped');
        expect(delivered['status'], 'delivered');

        final completed = await jsonRequest(
          'PUT',
          '/trades/$tradeId/status',
          token: sellerToken,
          body: {'status': 'completed'},
        );
        expect(completed['old_status'], 'delivered');
        expect(completed['status'], 'completed');

        final conversation = await jsonRequest(
          'POST',
          '/conversations',
          token: buyerToken,
          body: {'user_id': sellerId},
        );
        final conversationId = conversation['id'] as String;
        final directMessage = await jsonRequest(
          'POST',
          '/conversations/$conversationId/messages',
          token: buyerToken,
          expectedStatus: 201,
          body: {'message': 'Mensagem direta live'},
        );
        expect(
          directMessage.keys,
          containsAll(['id', 'conversation_id', 'sender_id', 'message']),
        );

        await Future<void>.delayed(const Duration(milliseconds: 1600));
        final notifications = await jsonRequest(
          'GET',
          '/notifications?limit=20',
          token: sellerToken,
        );
        final types =
            (notifications['data'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((item) => item['type'])
                .toSet();
        expect(
          types,
          containsAll([
            'trade_offer_received',
            'trade_message',
            'trade_delivered',
            'direct_message',
          ]),
        );
        expect(
          notificationByType(
            notifications,
            'trade_offer_received',
          )['reference_id'],
          tradeId,
        );
        expect(
          notificationByType(notifications, 'trade_message')['reference_id'],
          tradeId,
        );
        expect(
          notificationByType(notifications, 'direct_message')['reference_id'],
          conversationId,
        );

        await Future<void>.delayed(const Duration(milliseconds: 1600));
        final completedNotifications = await jsonRequest(
          'GET',
          '/notifications?limit=20',
          token: buyerToken,
        );
        expect(
          notificationByType(
            completedNotifications,
            'trade_completed',
          )['reference_id'],
          tradeId,
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
      skip: skipIntegration,
    );

    test(
      'respond covers decline and error contracts',
      () async {
        final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
        final fixture = await createTradeFixture('${suffix}_respond');
        final sellerToken = fixture['sellerToken'] as String;
        final buyerToken = fixture['buyerToken'] as String;

        final noToken = await http.put(
          Uri.parse(
            '$baseUrl/trades/00000000-0000-0000-0000-000000000000/respond',
          ),
          headers: jsonHeaders(),
          body: jsonEncode({'action': 'accept'}),
        );
        expect(noToken.statusCode, 401);

        final missing = await http.put(
          Uri.parse(
            '$baseUrl/trades/00000000-0000-0000-0000-000000000000/respond',
          ),
          headers: jsonHeaders(sellerToken),
          body: jsonEncode({'action': 'accept'}),
        );
        expect(missing.statusCode, 404);

        final invalidActionTrade = await createSaleTrade(
          fixture,
          message: 'Invalid action contract',
        );
        final invalidActionId = invalidActionTrade['id'] as String;
        final invalidAction = await http.put(
          Uri.parse('$baseUrl/trades/$invalidActionId/respond'),
          headers: jsonHeaders(sellerToken),
          body: jsonEncode({'action': 'maybe'}),
        );
        expect(invalidAction.statusCode, 400);

        final receiverOnly = await http.put(
          Uri.parse('$baseUrl/trades/$invalidActionId/respond'),
          headers: jsonHeaders(buyerToken),
          body: jsonEncode({'action': 'accept'}),
        );
        expect(receiverOnly.statusCode, 403);

        final acceptTrade = await createSaleTrade(
          fixture,
          message: 'Double respond contract',
        );
        final acceptTradeId = acceptTrade['id'] as String;
        final accepted = await jsonRequest(
          'PUT',
          '/trades/$acceptTradeId/respond',
          token: sellerToken,
          body: {'action': 'accept'},
        );
        expect(accepted.keys, containsAll(['id', 'status', 'message']));
        expect(accepted['status'], 'accepted');

        final doubleRespond = await http.put(
          Uri.parse('$baseUrl/trades/$acceptTradeId/respond'),
          headers: jsonHeaders(sellerToken),
          body: jsonEncode({'action': 'decline'}),
        );
        expect(doubleRespond.statusCode, 400);
        final afterDoubleRespond = await jsonRequest(
          'GET',
          '/trades/$acceptTradeId',
          token: buyerToken,
        );
        expect(afterDoubleRespond['status'], 'accepted');

        await Future<void>.delayed(const Duration(milliseconds: 1600));
        final acceptedNotifications = await jsonRequest(
          'GET',
          '/notifications?limit=20',
          token: buyerToken,
        );
        final acceptedTypes =
            (acceptedNotifications['data'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((item) => item['type'])
                .toSet();
        expect(acceptedTypes, contains('trade_accepted'));

        final declineTrade = await createSaleTrade(
          fixture,
          message: 'Decline respond contract',
        );
        final declineTradeId = declineTrade['id'] as String;
        final declined = await jsonRequest(
          'PUT',
          '/trades/$declineTradeId/respond',
          token: sellerToken,
          body: {'action': 'decline'},
        );
        expect(declined.keys, containsAll(['id', 'status', 'message']));
        expect(declined['id'], declineTradeId);
        expect(declined['status'], 'declined');

        await Future<void>.delayed(const Duration(milliseconds: 1600));
        final declinedNotifications = await jsonRequest(
          'GET',
          '/notifications?limit=20',
          token: buyerToken,
        );
        final declinedTypes =
            (declinedNotifications['data'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((item) => item['type'])
                .toSet();
        expect(declinedTypes, contains('trade_declined'));
      },
      timeout: const Timeout(Duration(minutes: 2)),
      skip: skipIntegration,
    );
  });
}
