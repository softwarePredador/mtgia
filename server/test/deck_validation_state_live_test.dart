@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final liveMutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final skipIntegration = !liveRequested
      ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
      : !liveMutationApproved
      ? 'Teste mutante requer aprovação explícita.'
      : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final email = 's4_02_validation_$suffix@example.com';
  String? token;

  Map<String, dynamic> decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    return (decoded as Map).cast<String, dynamic>();
  }

  Map<String, String> headers() => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<http.Response> post(String path, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers(),
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> getDeck(String deckId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/decks/$deckId'),
      headers: headers(),
    );
    expect(response.statusCode, 200, reason: response.body);
    return decode(response);
  }

  DateTime requireTimestamp(Map<String, dynamic> body) {
    final raw = body['validation_updated_at'];
    expect(raw, isA<String>());
    final parsed = DateTime.tryParse(raw as String);
    expect(parsed, isNotNull, reason: 'invalid validation timestamp: $raw');
    return parsed!;
  }

  Pool openPool() {
    return Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
  }

  Future<String> insertUnknownDeck() async {
    final pool = openPool();
    try {
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO decks (user_id, name, format)
          SELECT id, @name, 'standard'
          FROM users
          WHERE email = @email
          RETURNING id::text
        '''),
        parameters: {'name': 'Unknown State $suffix', 'email': email},
      );
      expect(result, hasLength(1));
      return result.first[0] as String;
    } finally {
      await pool.close();
    }
  }

  setUpAll(() async {
    if (skipIntegration != null) return;
    final response = await post('/auth/register', {
      'email': email,
      'password': 'BetaQa!2026-Deck',
      'username': 's4_02_validation_$suffix',
    });
    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    token = decode(response)['token'] as String;
  });

  test(
    'unknown, draft, validated and invalidated states stay coherent end to end',
    () async {
      final unknownDeckId = await insertUnknownDeck();
      final unknown = await getDeck(unknownDeckId);
      expect(unknown['deck_state'], 'unknown');
      expect(unknown['requires_review'], isTrue);
      expect(unknown['review_reasons'], ['validation_not_recorded']);
      expect(unknown['validation_updated_at'], isNull);

      final unknownDeleted = await http.delete(
        Uri.parse('$baseUrl/decks/$unknownDeckId'),
        headers: headers(),
      );
      expect(unknownDeleted.statusCode, 204, reason: unknownDeleted.body);

      final cardSearch = await http.get(
        Uri.parse('$baseUrl/cards?name=Plains&limit=1'),
        headers: headers(),
      );
      expect(cardSearch.statusCode, 200, reason: cardSearch.body);
      final cardRows = (decode(cardSearch)['data'] as List).cast<Map>();
      expect(cardRows, isNotEmpty);
      final plainsId = cardRows.first['id'] as String;

      final created = await post('/decks', {
        'name': 'S4-02 State Matrix $suffix',
        'format': 'standard',
        'cards': <Object>[],
      });
      expect(created.statusCode, anyOf(200, 201), reason: created.body);
      final createdBody = decode(created);
      final deckId = createdBody['id'] as String;
      expect(createdBody['deck_state'], 'draft');
      expect(createdBody['review_reasons'], ['incomplete_deck_size']);
      requireTimestamp(createdBody);

      final completed = await post('/decks/$deckId/cards/set', {
        'card_id': plainsId,
        'quantity': 60,
        'is_commander': false,
      });
      expect(completed.statusCode, 200, reason: completed.body);

      var persisted = await getDeck(deckId);
      expect(persisted['deck_state'], 'draft');
      expect(persisted['review_reasons'], [
        'deck_cards_changed_since_validation',
      ]);
      final draftTimestamp = requireTimestamp(persisted);

      final validated = await post('/decks/$deckId/validate', const {});
      expect(validated.statusCode, 200, reason: validated.body);
      final validatedBody = decode(validated);
      expect(validatedBody['deck_state'], 'validated');
      expect(validatedBody['requires_review'], isFalse);
      expect(validatedBody['review_reasons'], isEmpty);
      final validatedTimestamp = requireTimestamp(validatedBody);
      expect(validatedTimestamp.isBefore(draftTimestamp), isFalse);

      persisted = await getDeck(deckId);
      expect(persisted['deck_state'], 'validated');
      expect(persisted['review_reasons'], isEmpty);
      expect(
        requireTimestamp(persisted).toUtc(),
        validatedTimestamp.toUtc(),
      );

      final renamed = await put('/decks/$deckId', {
        'name': 'S4-02 Metadata Only $suffix',
      });
      expect(renamed.statusCode, 200, reason: renamed.body);
      persisted = await getDeck(deckId);
      expect(persisted['deck_state'], 'validated');
      expect(requireTimestamp(persisted).toUtc(), validatedTimestamp.toUtc());

      final invalidated = await post('/decks/$deckId/cards/set', {
        'card_id': plainsId,
        'quantity': 59,
        'is_commander': false,
      });
      expect(invalidated.statusCode, 200, reason: invalidated.body);
      persisted = await getDeck(deckId);
      expect(persisted['deck_state'], 'draft');
      expect(persisted['review_reasons'], [
        'deck_cards_changed_since_validation',
      ]);
      final changedTimestamp = requireTimestamp(persisted);
      expect(changedTimestamp.isBefore(validatedTimestamp), isFalse);

      final failedValidation = await post(
        '/decks/$deckId/validate',
        const {},
      );
      expect(failedValidation.statusCode, 400, reason: failedValidation.body);
      final failureBody = decode(failedValidation);
      expect(failureBody['deck_state'], 'draft');
      expect(failureBody['requires_review'], isTrue);
      expect(failureBody['review_reasons'], [
        'deck_cards_changed_since_validation',
        'strict_validation_failed',
      ]);
      final failureTimestamp = requireTimestamp(failureBody);

      persisted = await getDeck(deckId);
      expect(persisted['review_reasons'], failureBody['review_reasons']);
      expect(requireTimestamp(persisted).toUtc(), failureTimestamp.toUtc());

      final formatChanged = await put('/decks/$deckId', {'format': 'modern'});
      expect(formatChanged.statusCode, 200, reason: formatChanged.body);
      persisted = await getDeck(deckId);
      expect(persisted['format'], 'modern');
      expect(persisted['deck_state'], 'draft');
      expect(persisted['review_reasons'], [
        'deck_format_changed_since_validation',
      ]);
      requireTimestamp(persisted);

      final deleted = await http.delete(
        Uri.parse('$baseUrl/decks/$deckId'),
        headers: headers(),
      );
      expect(deleted.statusCode, 204, reason: deleted.body);
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
