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
import 'package:manaloom/features/community/providers/community_provider.dart';
import 'package:manaloom/features/community/screens/community_screen.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/market/providers/market_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/profile/profile_screen.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';
import 'package:manaloom/features/social/screens/user_profile_screen.dart';
import 'package:manaloom/features/social/screens/user_search_screen.dart';
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

  Future<Map<String, dynamic>> deleteJson(
    String endpoint, {
    required String token,
  }) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl$endpoint'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    return _decode(response, expected: {200});
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

  Future<String> createPublicDeck({
    required String token,
    required String name,
    required String cardId,
    required String marker,
  }) async {
    final data = await postJson('/decks', {
      'name': name,
      'format': 'commander',
      'description': 'Profile community runtime deck $marker',
      'is_public': true,
      'cards': [
        {'card_id': cardId, 'quantity': 1, 'is_commander': false},
      ],
    }, token: token);
    return data['id'] as String;
  }

  Future<bool> isFollowing({
    required String token,
    required String targetUserId,
  }) async {
    final data = await getJson('/community/users/$targetUserId', token: token);
    final user = data['user'] as Map<String, dynamic>;
    return user['is_following'] == true;
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'x-request-id':
          'qa-profile-community-${DateTime.now().microsecondsSinceEpoch}',
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
    'iPhone 15 runtime: profile edit reload and community social navigation',
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
          'qa_pc_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      // ignore: avoid_print
      print('PROFILE_COMMUNITY_BASE_URL ${ApiClient.baseUrl}');
      // ignore: avoid_print
      print('PROFILE_COMMUNITY_MARKER $marker');

      final viewer = await api.registerUser('${marker}_viewer');
      final creator = await api.registerUser('${marker}_creator');
      final card = await api.findCard('Sol Ring');
      final deckName = 'Profile Community Runtime $marker';
      final deckId = await api.createPublicDeck(
        token: creator.token,
        name: deckName,
        cardId: card['id'] as String,
        marker: marker,
      );
      // ignore: avoid_print
      print('PROFILE_COMMUNITY_PUBLIC_DECK_ID $deckId');

      final auth = AuthProvider();
      final loggedIn = await auth.login(viewer.email, viewer.password);
      expect(loggedIn, isTrue);

      await tester.pumpWidget(
        _runtimeApp(auth: auth, home: const ProfileScreen()),
      );
      await tester.pump();
      await pumpUntilFound(tester, find.text('Perfil'));
      await pumpUntilFound(tester, find.text(viewer.username));

      final editedDisplayName = 'Runtime Profile $marker';
      final editedCity = 'Sao Paulo';
      final editedNotes = 'Runtime trade notes $marker';
      await tester.enterText(
        find.byKey(const Key('profile-display-name-field')),
        editedDisplayName,
      );
      await tester.enterText(
        find.byKey(const Key('profile-city-field')),
        editedCity,
      );
      await tester.enterText(
        find.byKey(const Key('profile-trade-notes-field')),
        editedNotes,
      );
      final saveProfileButton = find.byKey(const Key('profile-save-button'));
      await tester.scrollUntilVisible(
        saveProfileButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(saveProfileButton);
      await tester.pump();
      await pumpUntilFound(tester, find.text('Perfil atualizado'));

      final reloadedProfile = await api.getJson(
        '/users/me',
        token: viewer.token,
      );
      final reloadedUser = reloadedProfile['user'] as Map<String, dynamic>;
      expect(reloadedUser['display_name'], editedDisplayName);
      expect(reloadedUser['location_city'], editedCity);
      expect(reloadedUser['trade_notes'], editedNotes);

      await tester.pumpWidget(_runtimeApp(auth: auth, home: const SizedBox()));
      await tester.pump();
      await tester.pumpWidget(
        _runtimeApp(
          auth: auth,
          home: ProfileScreen(key: ValueKey('profile-reload-$marker')),
        ),
      );
      await tester.pump();
      await pumpUntilFound(tester, find.text(editedDisplayName));
      await pumpUntilFound(tester, find.text(editedNotes));

      await tester.pumpWidget(
        _runtimeApp(auth: auth, home: UserProfileScreen(userId: creator.id)),
      );
      await tester.pump();
      await pumpUntilFound(tester, find.text(creator.username));
      await pumpUntilFound(tester, find.textContaining('Decks'));
      await pumpUntilFound(tester, find.text('Seguidores'));
      await pumpUntilFound(tester, find.text('Seguindo'));
      await pumpUntilFound(tester, find.text(deckName));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Seguir'));
      await tester.pump();
      await pumpUntilFound(tester, find.text('Deixar de seguir'));
      await pumpUntil(
        tester,
        () => api.isFollowing(token: viewer.token, targetUserId: creator.id),
        description: 'follow persisted',
      );

      await tester.tap(find.widgetWithText(Tab, 'Seguidores'));
      await tester.pump();
      await pumpUntilFound(tester, find.text(editedDisplayName));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Deixar de seguir'));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.widgetWithText(ElevatedButton, 'Seguir'),
      );
      await pumpUntil(
        tester,
        () async =>
            !(await api.isFollowing(
              token: viewer.token,
              targetUserId: creator.id,
            )),
        description: 'unfollow persisted',
      );

      await tester.pumpWidget(
        _runtimeApp(auth: auth, home: const UserSearchScreen()),
      );
      await tester.pump();
      await pumpUntilFound(tester, find.text('Buscar Usuários'));
      await tester.enterText(find.byType(TextField).first, creator.username);
      await tester.pump(const Duration(milliseconds: 600));
      await pumpUntil(
        tester,
        () async => find.text(creator.username).evaluate().length >= 2,
        description: 'user search result for ${creator.username}',
      );
      await tester.tap(find.text(creator.username).last);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Decks'));
      await tester.pageBack();
      await tester.pump();
      await pumpUntilFound(tester, find.text('Buscar Usuários'));

      await api.postJson(
        '/users/${creator.id}/follow',
        {},
        token: viewer.token,
      );
      await tester.pumpWidget(
        _runtimeApp(auth: auth, home: const CommunityScreen()),
      );
      await tester.pump();
      await pumpUntilFound(tester, find.text('Comunidade'));

      await tester.enterText(find.byType(TextField).first, marker);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await pumpUntilFound(tester, find.text(deckName));
      await tester.tap(find.text(deckName).first);
      await tester.pump();
      await pumpUntil(
        tester,
        () async =>
            find.text('Deck Público').evaluate().isNotEmpty ||
            find.text(deckName).evaluate().isNotEmpty,
        description: 'public deck detail title',
      );
      await pumpUntilFound(tester, find.text(deckName));
      await pumpUntil(
        tester,
        () async => find.byType(Scrollable).evaluate().isNotEmpty,
        description: 'public deck detail scrollable',
      );
      await tester.scrollUntilVisible(
        find.textContaining('Sol Ring'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Sol Ring'), findsWidgets);
      await tester.pageBack();
      await tester.pump();
      await pumpUntilFound(tester, find.text('Comunidade'));

      await tester.tap(find.widgetWithText(Tab, 'Seguindo'));
      await tester.pump();
      await pumpUntilFound(tester, find.text(deckName));

      await tester.tap(find.widgetWithText(Tab, 'Usuários'));
      await tester.pump();
      await pumpUntil(
        tester,
        () async => find.byType(TextField).evaluate().isNotEmpty,
        description: 'community users search field',
      );
      await tester.enterText(find.byType(TextField).last, creator.username);
      await tester.pump(const Duration(milliseconds: 600));
      await pumpUntil(
        tester,
        () async => find.text(creator.username).evaluate().length >= 2,
        description: 'community user tab result for ${creator.username}',
      );
      await tester.tap(find.text(creator.username).last);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Decks'));
      await tester.pageBack();
      await tester.pump();
      await pumpUntilFound(tester, find.text('Comunidade'));

      await api.deleteJson('/users/${creator.id}/follow', token: viewer.token);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Widget _runtimeApp({required AuthProvider auth, required Widget home}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<CommunityProvider>(
        create: (_) => CommunityProvider(),
      ),
      ChangeNotifierProvider<SocialProvider>(create: (_) => SocialProvider()),
      ChangeNotifierProvider<MarketProvider>(create: (_) => MarketProvider()),
      ChangeNotifierProvider<BinderProvider>(create: (_) => BinderProvider()),
      ChangeNotifierProvider<MessageProvider>(create: (_) => MessageProvider()),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(),
      ),
      ChangeNotifierProvider<CardProvider>(create: (_) => CardProvider()),
      ChangeNotifierProvider<DeckProvider>(create: (_) => DeckProvider()),
    ],
    child: MaterialApp(
      title: 'ManaLoom Profile Community Runtime',
      theme: AppTheme.darkTheme,
      home: home,
    ),
  );
}
