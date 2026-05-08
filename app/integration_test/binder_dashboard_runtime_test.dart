import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/collection/screens/collection_screen.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

class _RuntimeUser {
  const _RuntimeUser({
    required this.username,
    required this.email,
    required this.password,
    required this.token,
  });

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
    return _RuntimeUser(
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

  Future<void> addWishlistItem({
    required String token,
    required String cardId,
  }) async {
    await postJson(
      '/binder',
      {
        'card_id': cardId,
        'quantity': 1,
        'condition': 'NM',
        'is_foil': false,
        'for_trade': false,
        'for_sale': false,
        'language': 'en',
        'list_type': 'want',
      },
      token: token,
      expected: {201},
    );
  }

  Future<Map<String, dynamic>?> findBinderItemByCardName({
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
    return null;
  }

  Future<Map<String, dynamic>> stats(String token) {
    return getJson('/binder/stats', token: token);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'x-request-id':
          'qa-binder-dashboard-${DateTime.now().microsecondsSinceEpoch}',
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
    'iPhone 15 runtime: binder dashboard value progress filters and item lifecycle',
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
          'qa_binder_dashboard_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      // ignore: avoid_print
      print('BINDER_DASHBOARD_BASE_URL ${ApiClient.baseUrl}');
      // ignore: avoid_print
      print('BINDER_DASHBOARD_MARKER $marker');

      final user = await api.registerUser(marker);
      final solRing = await api.findCard('Sol Ring');
      final commandTower = await api.findCard('Command Tower');
      await api.addWishlistItem(
        token: user.token,
        cardId: commandTower['id'] as String,
      );

      final auth = AuthProvider();
      final loggedIn = await auth.login(user.email, user.password);
      expect(loggedIn, isTrue);

      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          binder: BinderProvider(),
          home: const CollectionScreen(),
        ),
      );
      await tester.pump();

      await pumpUntilFound(tester, find.text('Coleção'));
      await pumpUntilFound(tester, find.widgetWithText(Tab, 'Fichário'));
      await pumpUntilFound(tester, find.text('Resumo da coleção'));
      await pumpUntilFound(tester, find.text('Wishlist'));
      await captureVisualProof(binding, tester, 'binder_01_dashboard');

      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Buscar carta'),
      );
      await tester.pump();
      await pumpUntilFound(tester, find.widgetWithText(Tab, 'Cartas'));
      await tester.enterText(
        find.byKey(const Key('card-search-field')),
        'Sol Ring',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilFound(tester, find.byTooltip('Adicionar'));
      await captureVisualProof(binding, tester, 'binder_02_search_results');
      await _tapVisible(tester, find.byTooltip('Adicionar').first);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Adicionar — Sol Ring'));
      await captureVisualProof(binding, tester, 'binder_03_add_item_sheet');
      await _tapVisible(tester, find.text('PT'));
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Adicionar'),
      );
      await tester.pump();

      await pumpUntil(tester, () async {
        final item = await api.findBinderItemByCardName(
          token: user.token,
          cardName: 'Sol Ring',
        );
        return item != null && item['language'] == 'pt';
      }, description: 'Sol Ring added through collection binder UI');
      await pumpUntil(
        tester,
        () async =>
            find.textContaining('Adicionar — Sol Ring').evaluate().isEmpty,
        description: 'Sol Ring add sheet dismissed',
      );
      await Navigator.of(
        tester.element(find.byType(Navigator).first),
      ).maybePop();
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('Sol Ring'));

      await tester.tap(find.text('Sol Ring').first);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Editar — Sol Ring'));
      await captureVisualProof(binding, tester, 'binder_04_edit_item_sheet');
      await _tapVisible(tester, find.byIcon(Icons.add).last);
      await _tapVisible(tester, find.text('LP'));
      await _tapVisible(tester, find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pump();

      await pumpUntil(tester, () async {
        final item = await api.findBinderItemByCardName(
          token: user.token,
          cardName: 'Sol Ring',
        );
        return item?['quantity'] == 2 && item?['condition'] == 'LP';
      }, description: 'Sol Ring edited through collection binder UI');
      final editedStats = await api.stats(user.token);
      expect(editedStats['total_items'], greaterThanOrEqualTo(2));
      expect(editedStats['duplicate_copies'], greaterThanOrEqualTo(1));
      expect(editedStats['wishlist_count'], greaterThanOrEqualTo(1));
      expect(editedStats['set_progress'], isA<List<dynamic>>());

      final setCode = solRing['set_code']?.toString().toUpperCase() ?? '';
      if (setCode.isNotEmpty) {
        await tester.enterText(
          find.byKey(const Key('binderSetFilterField')),
          setCode,
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump(const Duration(milliseconds: 500));
        await pumpUntilFound(tester, find.text('Sol Ring'));
      }

      await tester.tap(find.text('Sol Ring').first);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Editar — Sol Ring'));
      await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Remover'));
      await tester.pump();
      await pumpUntilFound(tester, find.text('Remover do Fichário?'));
      await tester.tap(find.widgetWithText(TextButton, 'Remover'));
      await tester.pump();

      await pumpUntil(
        tester,
        () async =>
            await api.findBinderItemByCardName(
              token: user.token,
              cardName: 'Sol Ring',
            ) ==
            null,
        description: 'Sol Ring deleted through collection binder UI',
      );
      final finalStats = await api.stats(user.token);
      expect(finalStats['total_items'], 0);
      expect(finalStats['wishlist_count'], greaterThanOrEqualTo(1));
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _runtimeApp({
  required AuthProvider auth,
  required BinderProvider binder,
  required Widget home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<BinderProvider>.value(value: binder),
      ChangeNotifierProvider<CardProvider>(create: (_) => CardProvider()),
      ChangeNotifierProvider<TradeProvider>(create: (_) => TradeProvider()),
      ChangeNotifierProvider<MessageProvider>(create: (_) => MessageProvider()),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(),
      ),
    ],
    child: MaterialApp(
      title: 'ManaLoom Binder Dashboard Runtime',
      theme: AppTheme.darkTheme,
      home: home,
    ),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await tester.tap(finder);
}
