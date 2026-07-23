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

  Map<String, String> headers([String? token]) => {
    'Content-Type': 'application/json',
    'X-Request-Id': 'privacy-live-${DateTime.now().microsecondsSinceEpoch}',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> objectBody(http.Response response) {
    final decoded = jsonDecode(response.body);
    expect(decoded, isA<Map<String, dynamic>>(), reason: response.body);
    return decoded as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    expect(response.statusCode, 201, reason: response.body);
    return objectBody(response);
  }

  Future<http.Response> login(String email, String password) => http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: headers(),
    body: jsonEncode({'email': email, 'password': password}),
  );

  Set<String> allKeys(Object? value) {
    final keys = <String>{};
    void visit(Object? current) {
      if (current is Map) {
        for (final entry in current.entries) {
          keys.add(entry.key.toString().toLowerCase());
          visit(entry.value);
        }
      } else if (current is Iterable) {
        for (final entry in current) {
          visit(entry);
        }
      }
    }

    visit(value);
    return keys;
  }

  test(
    'portable export and account deletion preserve failure then revoke success',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final username = 'privacy_live_$suffix';
      final email = '$username@example.invalid';
      const password = 'BetaQa!2026-Deck';
      final account = await register(
        username: username,
        email: email,
        password: password,
      );
      final token = account['token'] as String;

      final cardSearch = await http.get(
        Uri.parse('$baseUrl/cards?name=Sol%20Ring&limit=1'),
        headers: headers(token),
      );
      expect(cardSearch.statusCode, 200, reason: cardSearch.body);
      final cards = objectBody(cardSearch)['data'] as List<dynamic>;
      expect(cards, isNotEmpty);
      final cardId = (cards.first as Map<String, dynamic>)['id'] as String;

      final createDeck = await http.post(
        Uri.parse('$baseUrl/decks'),
        headers: headers(token),
        body: jsonEncode({
          'name': 'Privacy export deck $suffix',
          'format': 'commander',
          'is_public': true,
          'cards': [
            {'card_id': cardId, 'quantity': 1, 'is_commander': false},
          ],
        }),
      );
      expect(createDeck.statusCode, anyOf(200, 201), reason: createDeck.body);
      final deckId = objectBody(createDeck)['id'] as String;

      final binder = await http.post(
        Uri.parse('$baseUrl/binder'),
        headers: headers(token),
        body: jsonEncode({
          'card_id': cardId,
          'quantity': 2,
          'condition': 'NM',
          'for_trade': true,
          'list_type': 'have',
        }),
      );
      expect(binder.statusCode, 201, reason: binder.body);

      final postGame = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(token),
        body: jsonEncode({
          'id': 'privacy-export-note',
          'deck_id': deckId,
          'result': 'vitória',
          'table_level': 'casual',
          'notes': 'Nota portátil.',
          'play_session_id': 'privacy-export-session',
          'base_revision': 0,
        }),
      );
      expect(postGame.statusCode, 201, reason: postGame.body);

      final unauthenticatedExport = await http.get(
        Uri.parse('$baseUrl/users/me/export'),
        headers: headers(),
      );
      expect(unauthenticatedExport.statusCode, 401);

      final export = await http.get(
        Uri.parse('$baseUrl/users/me/export'),
        headers: headers(token),
      );
      expect(export.statusCode, 200, reason: export.body);
      expect(
        export.headers['cache-control']?.toLowerCase(),
        contains('no-store'),
      );
      expect(export.headers['pragma']?.toLowerCase(), contains('no-cache'));
      expect(
        export.headers['content-disposition'],
        contains('manaloom-user-data-'),
      );
      final exported = objectBody(export);
      expect(exported['schema_version'], 1);
      expect((exported['account'] as Map)['username'], username);
      expect((exported['account'] as Map)['email'], email);
      final data = exported['data'] as Map<String, dynamic>;
      expect(data['decks'], hasLength(1));
      expect(data['deck_cards'], hasLength(1));
      expect(data['binder_items'], hasLength(1));
      expect(data['post_game_notes'], hasLength(1));
      final exportedDataKeys = allKeys({
        'account': exported['account'],
        'data': exported['data'],
      });
      expect(exportedDataKeys, isNot(contains('password_hash')));
      expect(exportedDataKeys, isNot(contains('fcm_token')));
      expect(jsonEncode(exported).toLowerCase(), isNot(contains('bearer ')));
      expect(
        (exported['portability'] as Map)['omitted_secrets'],
        containsAll(['password_hash', 'jwt', 'fcm_token']),
      );

      final invalidConfirmation = await http.delete(
        Uri.parse('$baseUrl/users/me'),
        headers: headers(token),
        body: jsonEncode({'confirmation': 'excluir', 'password': password}),
      );
      expect(invalidConfirmation.statusCode, 400);
      expect(
        objectBody(invalidConfirmation)['error'],
        'invalid_deletion_confirmation',
      );

      final wrongPassword = await http.delete(
        Uri.parse('$baseUrl/users/me'),
        headers: headers(token),
        body: jsonEncode({
          'confirmation': 'EXCLUIR MINHA CONTA',
          'password': 'WrongPassword!2026',
        }),
      );
      expect(wrongPassword.statusCode, 401, reason: wrongPassword.body);
      expect(objectBody(wrongPassword)['error'], 'invalid_password');

      final sessionAfterFailure = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers(token),
      );
      expect(
        sessionAfterFailure.statusCode,
        200,
        reason: sessionAfterFailure.body,
      );
      final loginAfterFailure = await login(email, password);
      expect(loginAfterFailure.statusCode, 200, reason: loginAfterFailure.body);

      final deletion = await http.delete(
        Uri.parse('$baseUrl/users/me'),
        headers: headers(token),
        body: jsonEncode({
          'confirmation': 'EXCLUIR MINHA CONTA',
          'password': password,
        }),
      );
      expect(deletion.statusCode, 200, reason: deletion.body);
      expect(
        deletion.headers['cache-control']?.toLowerCase(),
        contains('no-store'),
      );
      final deletionBody = objectBody(deletion);
      expect(deletionBody['account_deleted'], isTrue);
      expect(deletionBody['deletion_mode'], 'anonymized');
      expect(deletionBody['deleted_at'], isA<String>());
      expect(deletionBody['retention'], isA<Map>());

      final oldSession = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers(token),
      );
      expect(oldSession.statusCode, 401, reason: oldSession.body);

      final oldLogin = await login(email, password);
      expect(oldLogin.statusCode, 401, reason: oldLogin.body);

      final exportAfterDelete = await http.get(
        Uri.parse('$baseUrl/users/me/export'),
        headers: headers(token),
      );
      expect(exportAfterDelete.statusCode, 401, reason: exportAfterDelete.body);

      final publicDeckAfterDelete = await http.get(
        Uri.parse('$baseUrl/community/decks/$deckId'),
        headers: headers(),
      );
      expect(
        publicDeckAfterDelete.statusCode,
        404,
        reason: publicDeckAfterDelete.body,
      );
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
