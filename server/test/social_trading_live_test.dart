@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final skipIntegration = Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
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
      'password': 'TestPassword123!',
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
    final body = await jsonRequest(
      'GET',
      '/notifications/count',
      token: token,
    );
    return body['unread'] as int? ?? 0;
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
        expect(trade.keys, containsAll(['id', 'status', 'type', 'created_at']));
        expect(trade['status'], 'pending');
        final tradeId = trade['id'] as String;

        await Future<void>.delayed(const Duration(milliseconds: 1600));
        expect(await unreadCount(sellerToken), greaterThanOrEqualTo(1));

        final accepted = await jsonRequest(
          'PUT',
          '/trades/$tradeId/respond',
          token: sellerToken,
          body: {'action': 'accept'},
        );
        expect(accepted['status'], 'accepted');

        final invalidStatus = await http.put(
          Uri.parse('$baseUrl/trades/$tradeId/status'),
          headers: jsonHeaders(sellerToken),
          body: jsonEncode({
            'status': 'shipped',
            'delivery_method': 'mail',
          }),
        );
        expect(invalidStatus.statusCode, 400);

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
        expect(shipped['old_status'], 'accepted');
        expect(shipped['status'], 'shipped');

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
        final types = (notifications['data'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((item) => item['type'])
            .toSet();
        expect(types, containsAll(['trade_offer_received', 'direct_message']));
      },
      timeout: const Timeout(Duration(minutes: 2)),
      skip: skipIntegration,
    );
  });
}
