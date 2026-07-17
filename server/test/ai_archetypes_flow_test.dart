@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;

  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  final testUserEmail =
      Platform.environment['TEST_USER_EMAIL'] ??
      'test_archetypes_flow@example.com';
  final testUserPassword =
      Platform.environment['TEST_USER_PASSWORD'] ?? 'BetaQa!2026-Deck';
  final testUserUsername =
      Platform.environment['TEST_USER_USERNAME'] ??
      '${testUserEmail.split('@').first}_archetypes_flow_user';
  final testUser = {
    'email': testUserEmail,
    'password': testUserPassword,
    'username': testUserUsername,
  };

  final createdDeckIds = <String>[];
  String? authToken;

  Map<String, dynamic> decodeJson(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'value': decoded};
  }

  Future<String> getAuthTokenFor(Map<String, String> user) async {
    var response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': user['email'], 'password': user['password']}),
    );

    if (response.statusCode != 200) {
      response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to register test user: ${response.body}');
      }

      response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user['email'],
          'password': user['password'],
        }),
      );
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to login test user: ${response.body}');
    }

    return decodeJson(response)['token'] as String;
  }

  Future<String> getAuthToken() => getAuthTokenFor(testUser);

  Map<String, String> authHeaders({
    bool withContentType = false,
    String? token,
  }) => {
    if (withContentType) 'Content-Type': 'application/json',
    if ((token ?? authToken) != null)
      'Authorization': 'Bearer ${token ?? authToken}',
  };

  Future<Map<String, dynamic>> findCardByName(String name) async {
    final uri = Uri.parse(
      '$baseUrl/cards?name=${Uri.encodeQueryComponent(name)}&limit=25&page=1',
    );
    final response = await http.get(uri, headers: authHeaders());
    expect(response.statusCode, equals(200), reason: response.body);

    final body = decodeJson(response);
    final data =
        (body['data'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        [];
    expect(
      data,
      isNotEmpty,
      reason: 'Carta "$name" nao encontrada para teste de integracao.',
    );

    final exact = data.where(
      (card) =>
          (card['name']?.toString().toLowerCase() ?? '') == name.toLowerCase(),
    );
    return exact.isNotEmpty ? exact.first : data.first;
  }

  Future<String> createDeck({
    required String format,
    List<Map<String, dynamic>> cards = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: authHeaders(withContentType: true),
      body: jsonEncode({
        'name': 'Archetypes Flow ${DateTime.now().millisecondsSinceEpoch}',
        'format': format,
        'description': 'ai archetypes flow test',
        'cards': cards,
      }),
    );

    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    return decodeJson(response)['id'] as String;
  }

  Future<void> deleteDeck(String deckId) async {
    await http.delete(
      Uri.parse('$baseUrl/decks/$deckId'),
      headers: authHeaders(),
    );
  }

  Future<http.Response> postJson(String path, Map<String, dynamic> payload) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: authHeaders(withContentType: true),
      body: jsonEncode(payload),
    );
  }

  setUpAll(() async {
    authToken = await getAuthToken();
  });

  tearDownAll(() async {
    for (final deckId in createdDeckIds.reversed) {
      try {
        await deleteDeck(deckId);
      } catch (_) {}
    }
  });

  test(
    '/ai/archetypes caches repeated deck analysis responses',
    () async {
      final talrand = await findCardByName('Talrand, Sky Summoner');
      final deckId = await createDeck(
        format: 'commander',
        cards: [
          {'card_id': talrand['id'], 'quantity': 1, 'is_commander': true},
        ],
      );
      createdDeckIds.add(deckId);

      final firstResponse = await postJson('/ai/archetypes', {
        'deck_id': deckId,
      });
      expect(firstResponse.statusCode, equals(200), reason: firstResponse.body);
      final firstBody = decodeJson(firstResponse);
      final firstOptions =
          (firstBody['options'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
      expect(firstOptions, isNotEmpty);
      expect(firstBody['cache'], isA<Map>());
      expect(
        (firstBody['cache'] as Map)['hit'],
        isFalse,
        reason: firstResponse.body,
      );
      expect(
        ((firstBody['cache'] as Map)['key']?.toString() ?? '').isNotEmpty,
        isTrue,
      );
      expect(firstBody['timings'], isA<Map>());
      expect(
        (((firstBody['timings'] as Map)['stages_ms'] as Map)['deck_lookup']
                as num?)
            ?.toInt(),
        isNonNegative,
      );
      expect(
        (((firstBody['timings'] as Map)['stages_ms'] as Map)['cards_lookup']
                as num?)
            ?.toInt(),
        isNonNegative,
      );

      final secondResponse = await postJson('/ai/archetypes', {
        'deck_id': deckId,
      });
      expect(
        secondResponse.statusCode,
        equals(200),
        reason: secondResponse.body,
      );
      final secondBody = decodeJson(secondResponse);
      final secondOptions =
          (secondBody['options'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
      expect(secondOptions.length, equals(firstOptions.length));
      expect(secondBody['cache'], isA<Map>());
      expect(
        (secondBody['cache'] as Map)['hit'],
        isTrue,
        reason: secondResponse.body,
      );
      expect(
        (secondBody['cache'] as Map)['key'],
        equals((firstBody['cache'] as Map)['key']),
      );
      expect(
        (((secondBody['timings'] as Map)['stages_ms'] as Map)['openai_call']
                as num?)
            ?.toInt(),
        equals(0),
      );
    },
    skip: skipIntegration,
  );

  test(
    '/ai/archetypes uses commander reference options for Lorehold',
    () async {
      final lorehold = await findCardByName('Lorehold, the Historian');
      final deckId = await createDeck(
        format: 'commander',
        cards: [
          {'card_id': lorehold['id'], 'quantity': 1, 'is_commander': true},
        ],
      );
      createdDeckIds.add(deckId);

      final response = await postJson('/ai/archetypes', {'deck_id': deckId});
      expect(response.statusCode, equals(200), reason: response.body);

      final body = decodeJson(response);
      expect(body['source'], equals('commander_reference_profile'));
      expect(body['commander_reference'], isA<Map>());
      expect(
        ((body['commander_reference'] as Map)['commander'] as String)
            .toLowerCase(),
        equals('lorehold, the historian'),
      );

      final options =
          (body['options'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      expect(options, hasLength(greaterThanOrEqualTo(3)));

      final titles =
          options
              .map((option) => option['title']?.toString().toLowerCase() ?? '')
              .toList();
      expect(titles, contains('miracle big spells'));
      expect(titles, contains('topdeck / discard value'));
      expect(titles, contains('spellslinger burn finishers'));
      expect(
        titles.any((title) => title.contains('artifact') || title == 'aggro'),
        isFalse,
        reason: response.body,
      );
    },
    skip: skipIntegration,
  );

  test(
    '/ai/archetypes does not expose decks owned by another user',
    () async {
      final talrand = await findCardByName('Talrand, Sky Summoner');
      final deckId = await createDeck(
        format: 'commander',
        cards: [
          {'card_id': talrand['id'], 'quantity': 1, 'is_commander': true},
        ],
      );
      createdDeckIds.add(deckId);

      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final otherToken = await getAuthTokenFor({
        'email': 'test_archetypes_other_$timestamp@example.com',
        'password': testUserPassword,
        'username': 'test_archetypes_other_$timestamp',
      });

      final response = await http.post(
        Uri.parse('$baseUrl/ai/archetypes'),
        headers: authHeaders(withContentType: true, token: otherToken),
        body: jsonEncode({'deck_id': deckId}),
      );

      expect(response.statusCode, equals(404), reason: response.body);
      expect(decodeJson(response)['error'], isNotNull);
    },
    skip: skipIntegration,
  );
}
