import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/widgets/binder_item_editor.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/collection/screens/collection_screen.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/messages/screens/message_inbox_screen.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/notifications/screens/notification_screen.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:manaloom/features/trades/screens/trade_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> delete(String endpoint, {required String token}) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl$endpoint'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 204) {
      fail('DELETE $endpoint -> ${response.statusCode}: ${response.body}');
    }
  }

  Future<_RuntimeUser> registerUser(String prefix) async {
    final unique = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final username = '${prefix}_$unique';
    final email = '$username@example.com';
    const password = 'Qa123456!';
    final data = await postJson(
      '/auth/register',
      {'username': username, 'email': email, 'password': password},
      expected: {201},
    );
    final user = data['user'] as Map<String, dynamic>;
    return _RuntimeUser(
      id: user['id'] as String,
      username: username,
      email: email,
      password: password,
      token: data['token'] as String,
    );
  }

  Future<Map<String, dynamic>> findCard(String name) async {
    final data = await getJson(
      '/cards?name=${Uri.encodeQueryComponent(name)}&limit=1',
    );
    final cards = data['data'] as List<dynamic>? ?? [];
    if (cards.isEmpty) fail('Card not found for runtime setup: $name');
    return cards.first as Map<String, dynamic>;
  }

  Future<String> addBinderItem({
    required String token,
    required String cardId,
    required int quantity,
    required String condition,
    required bool forTrade,
    required bool forSale,
    required String notes,
    double? price,
  }) async {
    final data = await postJson(
      '/binder',
      {
        'card_id': cardId,
        'quantity': quantity,
        'condition': condition,
        'is_foil': false,
        'for_trade': forTrade,
        'for_sale': forSale,
        'price': price,
        'notes': notes,
        'list_type': 'have',
      },
      token: token,
      expected: {201},
    );
    return data['id'] as String;
  }

  Future<String> waitForTradeByMessage({
    required String token,
    required String message,
  }) async {
    for (var i = 0; i < 20; i += 1) {
      final data = await getJson('/trades?role=sender&limit=20', token: token);
      final trades = data['data'] as List<dynamic>? ?? [];
      for (final trade in trades.cast<Map<String, dynamic>>()) {
        if (trade['message'] == message) {
          return trade['id'] as String;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    fail('Trade with message not found: $message');
  }

  Future<bool> hasNotificationType(String token, String type) async {
    final data = await getJson('/notifications?limit=50', token: token);
    final notifications = data['data'] as List<dynamic>? ?? [];
    return notifications.cast<Map<String, dynamic>>().any(
      (notification) => notification['type'] == type,
    );
  }

  Future<String> tradeStatus(String token, String tradeId) async {
    final data = await getJson('/trades/$tradeId', token: token);
    return data['status'] as String;
  }

  Future<int> tradeMessageCount(String token, String tradeId) async {
    final data = await getJson('/trades/$tradeId/messages', token: token);
    return data['total'] as int? ?? 0;
  }

  Future<Map<String, dynamic>> findBinderItemByCardName({
    required String token,
    required String cardName,
  }) async {
    final data = await getJson(
      '/binder?search=${Uri.encodeQueryComponent(cardName)}&limit=20',
      token: token,
    );
    final items = data['data'] as List<dynamic>? ?? [];
    for (final item in items.cast<Map<String, dynamic>>()) {
      final card = item['card'] as Map<String, dynamic>? ?? {};
      if (card['name'] == cardName) return item;
    }
    fail('Binder item not found for $cardName');
  }

  Future<Map<String, dynamic>> firstNotificationByType(
    String token,
    String type,
  ) async {
    final data = await getJson('/notifications?limit=50', token: token);
    final notifications = data['data'] as List<dynamic>? ?? [];
    for (final notification in notifications.cast<Map<String, dynamic>>()) {
      if (notification['type'] == type) return notification;
    }
    fail('Notification type not found: $type');
  }

  Future<bool> notificationIsRead(String token, String notificationId) async {
    final data = await getJson('/notifications?limit=50', token: token);
    final notifications = data['data'] as List<dynamic>? ?? [];
    final notification = notifications.cast<Map<String, dynamic>>().firstWhere(
      (item) => item['id'] == notificationId,
      orElse: () => fail('Notification not found: $notificationId'),
    );
    return notification['read_at'] != null;
  }

  Future<int> notificationUnreadCount(String token) async {
    final data = await getJson('/notifications/count', token: token);
    return data['unread'] as int? ?? 0;
  }

  Future<int> directMessageCount(String token, String conversationId) async {
    final data = await getJson(
      '/conversations/$conversationId/messages?limit=20',
      token: token,
    );
    return data['total'] as int? ?? 0;
  }

  Future<int> directUnreadCount(String token) async {
    final data = await getJson('/conversations/unread-count', token: token);
    return data['unread'] as int? ?? 0;
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'x-request-id': 'qa-bmt-${DateTime.now().microsecondsSinceEpoch}',
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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'iPhone 15 runtime: binder marketplace sale trade lifecycle with notifications',
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
          'qa_bmt_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      // ignore: avoid_print
      print('BINDER_MARKETPLACE_TRADE_BASE_URL ${ApiClient.baseUrl}');
      // ignore: avoid_print
      print('BINDER_MARKETPLACE_TRADE_MARKER $marker');

      final seller = await api.registerUser('${marker}_seller');
      final buyer = await api.registerUser('${marker}_buyer');
      final saleCard = await api.findCard('Sol Ring');
      final buyerCard = await api.findCard('Arcane Signet');
      final editorCard = await api.findCard('Command Tower');

      final sellerBinderItemId = await api.addBinderItem(
        token: seller.token,
        cardId: saleCard['id'] as String,
        quantity: 1,
        condition: 'NM',
        forTrade: false,
        forSale: true,
        price: 12.34,
        notes: '$marker seller marketplace sale item',
      );
      await api.addBinderItem(
        token: buyer.token,
        cardId: buyerCard['id'] as String,
        quantity: 1,
        condition: 'NM',
        forTrade: true,
        forSale: false,
        notes: '$marker buyer visible binder item',
      );

      final transientBuyerItemId = await api.addBinderItem(
        token: buyer.token,
        cardId: buyerCard['id'] as String,
        quantity: 1,
        condition: 'LP',
        forTrade: true,
        forSale: false,
        notes: '$marker buyer delete contract item',
      );
      await api.putJson('/binder/$transientBuyerItemId', {
        'quantity': 2,
        'notes': '$marker buyer updated then deleted',
      }, token: buyer.token);
      await api.delete('/binder/$transientBuyerItemId', token: buyer.token);

      final marketplaceProbe = await api.getJson(
        '/community/marketplace?search=Sol%20Ring&for_sale=true&limit=50',
      );
      final marketplaceItems = marketplaceProbe['data'] as List<dynamic>? ?? [];
      expect(
        marketplaceItems.cast<Map<String, dynamic>>().any(
          (item) =>
              item['id'] == sellerBinderItemId &&
              (item['owner'] as Map<String, dynamic>)['id'] == seller.id,
        ),
        isTrue,
        reason: 'seller binder item must be visible in marketplace API',
      );

      final auth = AuthProvider();
      final loggedIn = await auth.login(buyer.email, buyer.password);
      expect(loggedIn, isTrue);

      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          binder: BinderProvider(),
          trade: TradeProvider(),
          messages: MessageProvider(),
          notifications: NotificationProvider(),
          home: _BinderEditorRuntimeHarness(
            cardId: editorCard['id'] as String,
            cardName: editorCard['name'] as String,
            cardImageUrl: editorCard['image_url'] as String?,
          ),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Binder editor runtime harness'));

      await tester.tap(find.text('Abrir editor add'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Adicionar — Command Tower'));
      await _tapVisible(tester, find.text('PT'));
      await _tapVisible(tester, find.text('Disponível para venda'));
      await tester.pump();
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, '1.23');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await _tapVisible(tester, find.widgetWithText(ElevatedButton, 'Adicionar'));
      await tester.pump();
      await _pumpUntil(tester, () async {
        final data = await api.getJson(
          '/binder?search=Command%20Tower&limit=20',
          token: buyer.token,
        );
        final items = data['data'] as List<dynamic>? ?? [];
        return items.cast<Map<String, dynamic>>().any((item) {
          final card = item['card'] as Map<String, dynamic>? ?? {};
          return card['name'] == 'Command Tower' && item['language'] == 'pt';
        });
      }, description: 'Command Tower created through BinderItemEditor');
      await _pumpUntil(
        tester,
        () async => find.text('Adicionar — Command Tower').evaluate().isEmpty,
        description: 'BinderItemEditor add sheet dismissed',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir editor edit'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Editar — Command Tower'));
      await _tapVisible(tester, find.byIcon(Icons.add).last);
      await _tapVisible(tester, find.text('LP'));
      await _tapVisible(tester, find.text('ES'));
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, '4.56');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await _tapVisible(tester, find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pump();
      await _pumpUntil(tester, () async {
        final item = await api.findBinderItemByCardName(
          token: buyer.token,
          cardName: 'Command Tower',
        );
        return item['quantity'] == 2 &&
            item['condition'] == 'LP' &&
            item['language'] == 'es' &&
            (item['price'] as num).toDouble() == 4.56;
      }, description: 'Command Tower edited through BinderItemEditor');
      await _pumpUntil(
        tester,
        () async => find.text('Editar — Command Tower').evaluate().isEmpty,
        description: 'BinderItemEditor edit sheet dismissed',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir editor edit'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Editar — Command Tower'));
      await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Remover'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Remover do Fichário?'));
      await tester.tap(find.widgetWithText(TextButton, 'Remover'));
      await tester.pump();
      await _pumpUntil(tester, () async {
        final data = await api.getJson(
          '/binder?search=Command%20Tower&limit=20',
          token: buyer.token,
        );
        final items = data['data'] as List<dynamic>? ?? [];
        return items.cast<Map<String, dynamic>>().every((item) {
          final card = item['card'] as Map<String, dynamic>? ?? {};
          return card['name'] != 'Command Tower';
        });
      }, description: 'Command Tower deleted through BinderItemEditor');

      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          binder: BinderProvider(),
          trade: TradeProvider(),
          messages: MessageProvider(),
          notifications: NotificationProvider(),
          home: const CollectionScreen(),
        ),
      );
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Coleção'));
      await _pumpUntilFound(tester, find.widgetWithText(Tab, 'Fichário'));
      await _pumpUntilFound(tester, find.widgetWithText(Tab, 'Tenho'));
      await _pumpUntilFound(tester, find.text('Arcane Signet'));

      await tester.tap(
        find.widgetWithText(Tab, 'Marketplace'),
        warnIfMissed: false,
      );
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.text('Buscar carta no marketplace...'),
      );
      await tester.enterText(find.byType(TextField).first, 'Sol Ring');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await _pumpUntilFound(tester, find.text(seller.username));

      final sellerCard = find.ancestor(
        of: find.text(seller.username),
        matching: find.byType(Card),
      );
      expect(sellerCard, findsOneWidget);
      final buyButton = find.descendant(
        of: sellerCard,
        matching: find.widgetWithText(OutlinedButton, 'Quero comprar'),
      );
      await tester.tap(buyButton);
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Nova Proposta'));
      await _pumpUntilFound(tester, find.text('Sol Ring'));
      await _pumpUntilFound(tester, find.text('Pagamento'));

      final tradeMessage = '$marker marketplace sale proposal';
      await tester.ensureVisible(find.text('Mensagem (opcional)'));
      await tester.enterText(find.byType(TextField).last, tradeMessage);
      await tester.ensureVisible(find.text('Enviar Proposta'));
      await tester.tap(find.text('Enviar Proposta'));
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.text('Proposta enviada com sucesso! 🎉'),
        attempts: 60,
        step: const Duration(milliseconds: 500),
      );

      final tradeId = await api.waitForTradeByMessage(
        token: buyer.token,
        message: tradeMessage,
      );
      // ignore: avoid_print
      print('BINDER_MARKETPLACE_TRADE_ID $tradeId');
      expect(
        await api.hasNotificationType(seller.token, 'trade_offer_received'),
        isTrue,
      );

      await tester.tap(find.widgetWithText(Tab, 'Trades'), warnIfMissed: false);
      await tester.pump();
      await _pumpUntilFound(tester, find.widgetWithText(Tab, 'Enviadas'));
      await tester.tap(find.widgetWithText(Tab, 'Enviadas'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text(seller.username));
      await _pumpUntilFound(tester, find.text('Pendente'));

      await _loginAs(auth, seller);
      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          binder: BinderProvider(),
          trade: TradeProvider(),
          messages: MessageProvider(),
          notifications: NotificationProvider(),
          home: TradeDetailScreen(
            key: ValueKey('seller-detail-$tradeId'),
            tradeId: tradeId,
          ),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Pendente'));
      await tester.tap(find.text('Aceitar'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Aceito'));
      expect(
        await api.hasNotificationType(buyer.token, 'trade_accepted'),
        isTrue,
      );

      final tradeChatMessage = '$marker seller chat ui';
      await tester.ensureVisible(find.text('Chat (0)'));
      await tester.enterText(find.byType(TextField).last, tradeChatMessage);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await _pumpUntilFound(tester, find.text(tradeChatMessage));
      expect(
        await api.tradeMessageCount(seller.token, tradeId),
        greaterThan(0),
      );
      expect(
        await api.hasNotificationType(buyer.token, 'trade_message'),
        isTrue,
      );

      await tester.ensureVisible(find.text('Marcar como Enviado'));
      await tester.tap(find.text('Marcar como Enviado'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Informar envio'));
      await tester.enterText(find.byType(TextField).last, 'QA$marker');
      await tester.tap(find.text('Confirmar Envio'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Enviado'));
      expect(
        await api.hasNotificationType(buyer.token, 'trade_shipped'),
        isTrue,
      );

      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          binder: BinderProvider(),
          trade: TradeProvider(),
          messages: MessageProvider(),
          notifications: NotificationProvider(),
          home: const SizedBox.shrink(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      await _loginAs(auth, buyer);
      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          binder: BinderProvider(),
          trade: TradeProvider(),
          messages: MessageProvider(),
          notifications: NotificationProvider(),
          home: TradeDetailScreen(
            key: ValueKey('buyer-detail-$tradeId'),
            tradeId: tradeId,
          ),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Enviado'));
      await tester.scrollUntilVisible(
        find.textContaining('Chat ('),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await _pumpUntilFound(tester, find.text(tradeChatMessage));
      await tester.ensureVisible(find.text('Confirmar Entrega'));
      await tester.tap(find.text('Confirmar Entrega'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Entregue'));
      await tester.ensureVisible(find.text('Finalizar'));
      await tester.tap(find.text('Finalizar'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Concluído'));
      expect(await api.tradeStatus(buyer.token, tradeId), 'completed');
      expect(
        await api.hasNotificationType(seller.token, 'trade_completed'),
        isTrue,
      );

      final tradeMessageNotification = await api.firstNotificationByType(
        buyer.token,
        'trade_message',
      );
      await tester.pumpWidget(
        _runtimeRouterApp(
          auth: auth,
          binder: BinderProvider(),
          trade: TradeProvider(),
          messages: MessageProvider(),
          notifications: NotificationProvider(),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Notificações'));
      await _pumpUntilFound(tester, find.textContaining('aceitou'));
      await _pumpUntilFound(tester, find.text(tradeChatMessage));
      await tester.tap(find.text(tradeChatMessage));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Detalhes do Trade'));
      expect(
        await api.notificationIsRead(
          buyer.token,
          tradeMessageNotification['id'] as String,
        ),
        isTrue,
      );

      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          binder: BinderProvider(),
          trade: TradeProvider(),
          messages: MessageProvider(),
          notifications: NotificationProvider(),
          home: const NotificationScreen(),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Notificações'));
      await _pumpUntilFound(tester, find.text('Ler todas'));
      await tester.tap(find.text('Ler todas'));
      await tester.pump();
      await _pumpUntil(
        tester,
        () async => await api.notificationUnreadCount(buyer.token) == 0,
        description: 'notifications read-all reflected in backend',
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'iPhone 15 runtime: direct messages conversation chat and read receipt',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ApiClient.setToken(null);

      final api = _RuntimeApi(ApiClient.baseUrl);
      addTearDown(api.close);

      final marker =
          'qa_dm_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      // ignore: avoid_print
      print('DIRECT_MESSAGES_BASE_URL ${ApiClient.baseUrl}');
      // ignore: avoid_print
      print('DIRECT_MESSAGES_MARKER $marker');

      final sender = await api.registerUser('${marker}_sender');
      final receiver = await api.registerUser('${marker}_receiver');
      final conversation = await api.postJson('/conversations', {
        'user_id': receiver.id,
      }, token: sender.token);
      final conversationId = conversation['id'] as String;
      final inboundMessage = '$marker inbound direct message';
      await api.postJson(
        '/conversations/$conversationId/messages',
        {'message': inboundMessage},
        token: sender.token,
        expected: {201},
      );

      final auth = AuthProvider();
      final loggedIn = await auth.login(receiver.email, receiver.password);
      expect(loggedIn, isTrue);

      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          binder: BinderProvider(),
          trade: TradeProvider(),
          messages: MessageProvider(),
          notifications: NotificationProvider(),
          home: const MessageInboxScreen(),
        ),
      );
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Mensagens'));
      await _pumpUntilFound(tester, find.text(sender.username));
      await _pumpUntilFound(tester, find.text(inboundMessage));
      await tester.tap(find.text(sender.username));
      await tester.pump();
      await _pumpUntilFound(tester, find.text(inboundMessage));
      await _pumpUntil(
        tester,
        () async => await api.directUnreadCount(receiver.token) == 0,
        description: 'direct message read receipt reflected in backend',
      );

      final reply = '$marker receiver reply ui';
      await tester.enterText(find.byType(TextField).last, reply);
      await tester.tap(find.byIcon(Icons.send_rounded).last);
      await tester.pump();
      await _pumpUntilFound(tester, find.text(reply));
      await _pumpUntil(
        tester,
        () async =>
            await api.directMessageCount(receiver.token, conversationId) >= 2,
        description: 'direct message reply persisted',
      );

      expect(tester.takeException(), isNull);
    },
  );
}

Widget _runtimeApp({
  required AuthProvider auth,
  required BinderProvider binder,
  required TradeProvider trade,
  required MessageProvider messages,
  required NotificationProvider notifications,
  required Widget home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<BinderProvider>.value(value: binder),
      ChangeNotifierProvider<CardProvider>(create: (_) => CardProvider()),
      ChangeNotifierProvider<TradeProvider>.value(value: trade),
      ChangeNotifierProvider<MessageProvider>.value(value: messages),
      ChangeNotifierProvider<NotificationProvider>.value(value: notifications),
    ],
    child: MaterialApp(
      title: 'ManaLoom Binder Marketplace Trade Runtime',
      theme: AppTheme.darkTheme,
      home: home,
    ),
  );
}

Widget _runtimeRouterApp({
  required AuthProvider auth,
  required BinderProvider binder,
  required TradeProvider trade,
  required MessageProvider messages,
  required NotificationProvider notifications,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const NotificationScreen()),
      GoRoute(
        path: '/trades/:id',
        builder:
            (_, state) =>
                TradeDetailScreen(tradeId: state.pathParameters['id']!),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<BinderProvider>.value(value: binder),
      ChangeNotifierProvider<CardProvider>(create: (_) => CardProvider()),
      ChangeNotifierProvider<TradeProvider>.value(value: trade),
      ChangeNotifierProvider<MessageProvider>.value(value: messages),
      ChangeNotifierProvider<NotificationProvider>.value(value: notifications),
    ],
    child: MaterialApp.router(
      title: 'ManaLoom Notifications Runtime',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    ),
  );
}

class _BinderEditorRuntimeHarness extends StatelessWidget {
  const _BinderEditorRuntimeHarness({
    required this.cardId,
    required this.cardName,
    required this.cardImageUrl,
  });

  final String cardId;
  final String cardName;
  final String? cardImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Binder editor runtime harness',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openAdd(context),
              child: const Text('Abrir editor add'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _openEdit(context),
              child: const Text('Abrir editor edit'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    final provider = context.read<BinderProvider>();
    BinderItemEditor.show(
      context,
      cardId: cardId,
      cardName: cardName,
      cardImageUrl: cardImageUrl,
      onSave:
          (data) => provider.addItem(
            cardId: data['card_id'] as String,
            quantity: data['quantity'] as int? ?? 1,
            condition: data['condition'] as String? ?? 'NM',
            isFoil: data['is_foil'] as bool? ?? false,
            forTrade: data['for_trade'] as bool? ?? false,
            forSale: data['for_sale'] as bool? ?? false,
            price:
                data['price'] != null
                    ? (data['price'] as num).toDouble()
                    : null,
            notes: data['notes'] as String?,
            language: data['language'] as String? ?? 'en',
            listType: data['list_type'] as String? ?? 'have',
          ),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final provider = context.read<BinderProvider>();
    final items = await provider.fetchBinderDirect(
      listType: 'have',
      search: cardName,
      limit: 20,
    );
    if (!context.mounted) return;
    BinderItem? item;
    for (final entry in items ?? <BinderItem>[]) {
      if (entry.cardName == cardName) {
        item = entry;
        break;
      }
    }
    if (item == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$cardName não encontrado')));
      return;
    }
    final selectedItem = item;
    BinderItemEditor.show(
      context,
      item: selectedItem,
      onSave: (data) => provider.updateItem(selectedItem.id, data),
      onDelete: () => provider.removeItem(selectedItem.id),
    );
  }
}

Future<void> _loginAs(AuthProvider auth, _RuntimeUser user) async {
  await auth.logout();
  final ok = await auth.login(user.email, user.password);
  expect(ok, isTrue, reason: 'login failed for ${user.username}');
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 80,
  Duration step = const Duration(milliseconds: 500),
}) async {
  await _pumpUntil(
    tester,
    () async => finder.evaluate().isNotEmpty,
    description: finder.toString(),
    attempts: attempts,
    step: step,
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await tester.tap(finder);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Future<bool> Function() condition, {
  required String description,
  int attempts = 80,
  Duration step = const Duration(milliseconds: 500),
}) async {
  for (var i = 0; i < attempts; i += 1) {
    await tester.pump(step);
    if (await condition()) return;
  }
  fail('Timeout waiting for $description');
}
