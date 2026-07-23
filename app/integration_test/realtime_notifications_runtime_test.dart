import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/services/realtime_notification_coordinator.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/messages/screens/chat_screen.dart';
import 'package:manaloom/features/messages/screens/message_inbox_screen.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/notifications/screens/notification_screen.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:manaloom/features/trades/screens/trade_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';

class _RuntimeUser {
  const _RuntimeUser({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.token,
  });

  final String id;
  final String username;
  final String email;
  final String password;
  final String token;
}

class _RuntimeApi {
  _RuntimeApi(this.baseUrl);

  final String baseUrl;
  final _client = http.Client();

  Future<_RuntimeUser> registerUser(String prefix) async {
    final unique = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final username = '${prefix}_$unique';
    const password = 'BetaQa!2026-Deck';
    final data = await postJson(
      '/auth/register',
      {
        'username': username,
        'email': '$username@example.com',
        'password': password,
      },
      expected: {201},
    );
    final user = data['user'] as Map<String, dynamic>;
    return _RuntimeUser(
      id: user['id'] as String,
      username: username,
      email: '$username@example.com',
      password: password,
      token: data['token'] as String,
    );
  }

  Future<Map<String, dynamic>> getJson(String endpoint, {String? token}) async {
    final response = await _client
        .get(Uri.parse('$baseUrl$endpoint'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    return _decode(response, expected: {200});
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    Set<int> expected = const {200, 201},
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response, expected: expected);
  }

  Future<Map<String, dynamic>> putJson(
    String endpoint,
    Map<String, dynamic> body, {
    required String token,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response, expected: {200});
  }

  Future<void> deleteAccount(_RuntimeUser user) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/users/me'),
          headers: _headers(user.token),
          body: jsonEncode({
            'confirmation': 'EXCLUIR MINHA CONTA',
            'password': user.password,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 404) return;
    _decode(response, expected: {200});
  }

  Future<Map<String, dynamic>> findCard(String name) async {
    final data = await getJson(
      '/cards?name=${Uri.encodeQueryComponent(name)}&limit=1',
    );
    final cards = data['data'] as List<dynamic>? ?? [];
    if (cards.isEmpty) fail('Card not found for runtime setup: $name');
    return cards.first as Map<String, dynamic>;
  }

  Future<String> addSaleBinderItem({
    required String token,
    required String cardId,
    required String marker,
  }) async {
    final data = await postJson(
      '/binder',
      {
        'card_id': cardId,
        'quantity': 1,
        'condition': 'NM',
        'is_foil': false,
        'for_trade': false,
        'for_sale': true,
        'price': 9.99,
        'notes': '$marker realtime sale item',
        'list_type': 'have',
      },
      token: token,
      expected: {201},
    );
    return data['id'] as String;
  }

  Future<void> hideBinderItem(String itemId, {required String token}) async {
    await putJson('/binder/$itemId', {
      'for_trade': false,
      'for_sale': false,
    }, token: token);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'x-request-id': 'qa-realtime-${DateTime.now().microsecondsSinceEpoch}',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(
    http.Response response, {
    required Set<int> expected,
  }) {
    if (!expected.contains(response.statusCode)) {
      fail(
        '${response.request?.method} ${response.request?.url.path} '
        '-> ${response.statusCode}: ${response.body}',
      );
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    fail('Expected JSON object, got ${response.body}');
  }

  void close() => _client.close();
}

class _RuntimeApp {
  _RuntimeApp({
    required this.widget,
    required this.router,
    required this.coordinator,
  });

  final Widget widget;
  final GoRouter router;
  final RealtimeNotificationCoordinator coordinator;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'iPhone 15 runtime: foreground notifications refresh badges, messages and trade detail',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ApiClient.setToken(null);
      expect(ApiClient.baseUrl, isNotEmpty);

      final api = _RuntimeApi(ApiClient.baseUrl);
      addTearDown(api.close);

      final marker =
          'qa_rt_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      // ignore: avoid_print
      print('REALTIME_NOTIFICATIONS_BASE_URL ${ApiClient.baseUrl}');
      // ignore: avoid_print
      print('REALTIME_NOTIFICATIONS_MARKER $marker');

      final seller = await api.registerUser('${marker}_seller');
      addTearDown(() => api.deleteAccount(seller));
      final buyer = await api.registerUser('${marker}_buyer');
      addTearDown(() => api.deleteAccount(buyer));

      final auth = AuthProvider();
      final loggedIn = await auth.login(buyer.email, buyer.password);
      expect(loggedIn, isTrue);

      final notifications = NotificationProvider();
      final messages = MessageProvider();
      final trades = TradeProvider();
      final app = _runtimeApp(
        auth: auth,
        notifications: notifications,
        messages: messages,
        trades: trades,
        initialLocation: '/notifications',
      );
      await tester.pumpWidget(app.widget);
      await tester.pump();
      await pumpUntilFound(tester, find.text('Notificações'));

      final conversation = await api.postJson('/conversations', {
        'user_id': buyer.id,
      }, token: seller.token);
      final conversationId = conversation['id'] as String;
      final directMessage = '$marker direct foreground';
      await api.postJson(
        '/conversations/$conversationId/messages',
        {'message': directMessage},
        token: seller.token,
        expected: {201},
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await app.coordinator.handleForegroundData({
        'type': 'direct_message',
        'reference_id': conversationId,
      });
      await tester.pump();
      await pumpUntilFound(tester, find.text(directMessage));
      expect(notifications.unreadCount, greaterThan(0));

      app.coordinator.handleMessageTapData({
        'type': 'direct_message',
        'reference_id': conversationId,
      });
      await tester.pump();
      await pumpUntilFound(tester, find.byKey(const Key('chat-message-field')));
      await pumpUntilFound(tester, find.text(directMessage));

      final card = await api.findCard('Sol Ring');
      final binderItemId = await api.addSaleBinderItem(
        token: seller.token,
        cardId: card['id'] as String,
        marker: marker,
      );
      addTearDown(() => api.hideBinderItem(binderItemId, token: seller.token));
      final trade = await api.postJson(
        '/trades',
        {
          'receiver_id': seller.id,
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
          'message': '$marker sale proposal',
        },
        token: buyer.token,
        expected: {201},
      );
      final tradeId = trade['id'] as String;

      app.router.go('/trades/$tradeId');
      await tester.pump();
      await pumpUntilFound(tester, find.text('Pendente'));

      await api.putJson('/trades/$tradeId/respond', {
        'action': 'accept',
      }, token: seller.token);
      await tester.pump(const Duration(milliseconds: 1600));
      await app.coordinator.handleForegroundData({
        'type': 'trade_accepted',
        'reference_id': tradeId,
      });
      await tester.pump();
      await pumpUntilFound(tester, find.text('Aceito'));

      await api.putJson('/trades/$tradeId/status', {
        'status': 'shipped',
        'delivery_method': 'correios',
        'tracking_code': 'QA$marker',
      }, token: seller.token);
      await tester.pump(const Duration(milliseconds: 1600));
      await app.coordinator.handleForegroundData({
        'type': 'trade_shipped',
        'reference_id': tradeId,
      });
      await tester.pump();
      await pumpUntilFound(tester, find.text('Enviado'));
      await pumpUntil(
        tester,
        () async =>
            trades.selectedTrade?.statusHistory.any(
              (entry) => entry.newStatus == 'shipped',
            ) ??
            false,
        description: 'trade timeline refreshed after foreground event',
      );

      expect(tester.takeException(), isNull);
    },
  );
}

_RuntimeApp _runtimeApp({
  required AuthProvider auth,
  required NotificationProvider notifications,
  required MessageProvider messages,
  required TradeProvider trades,
  required String initialLocation,
}) {
  late final GoRouter router;
  router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (_, __) => const MessageInboxScreen(),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (_, state) =>
            ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      GoRoute(
        path: '/trades/:tradeId',
        builder: (_, state) =>
            TradeDetailScreen(tradeId: state.pathParameters['tradeId']!),
      ),
    ],
  );
  final coordinator = RealtimeNotificationCoordinator(
    router: router,
    notificationProvider: notifications,
    messageProvider: messages,
    tradeProvider: trades,
  );

  final widget = MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<BinderProvider>(create: (_) => BinderProvider()),
      ChangeNotifierProvider<CardProvider>(create: (_) => CardProvider()),
      ChangeNotifierProvider<NotificationProvider>.value(value: notifications),
      ChangeNotifierProvider<MessageProvider>.value(value: messages),
      ChangeNotifierProvider<TradeProvider>.value(value: trades),
    ],
    child: MaterialApp.router(
      title: 'ManaLoom Realtime Notifications Runtime',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    ),
  );

  return _RuntimeApp(widget: widget, router: router, coordinator: coordinator);
}
