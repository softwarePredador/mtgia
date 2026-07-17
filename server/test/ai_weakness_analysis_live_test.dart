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
  final runId = DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> decodeJson(http.Response response) {
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'value': decoded};
  }

  Map<String, String> headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<String> registerUser() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': 'weakness_live_$runId',
        'email': 'weakness_live_$runId@example.com',
        'password': 'BetaQa!2026-Deck',
      }),
    );

    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    final token = decodeJson(response)['token'] as String?;
    expect(token, isNotNull, reason: response.body);
    return token!;
  }

  Future<String> createEmptyDeck(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: headers(token),
      body: jsonEncode({
        'name': 'Weakness Live $runId',
        'format': 'commander',
        'description': 'Weakness-analysis live SQL coverage',
        'is_public': false,
        'cards': [],
      }),
    );

    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    final deckId = decodeJson(response)['id']?.toString();
    expect(deckId, isNotNull, reason: response.body);
    return deckId!;
  }

  Future<void> deleteDeck(String token, String deckId) async {
    await http.delete(
      Uri.parse('$baseUrl/decks/$deckId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  test(
    'POST /ai/weakness-analysis returns advisory weaknesses using DB-backed lookup',
    () async {
      final token = await registerUser();
      final deckId = await createEmptyDeck(token);

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/ai/weakness-analysis'),
          headers: headers(token),
          body: jsonEncode({'deck_id': deckId}),
        );

        expect(response.statusCode, 200, reason: response.body);
        final body = decodeJson(response);
        expect(body['deck_id'], deckId);
        expect(body['statistics'], isA<Map<String, dynamic>>());
        expect(body['weaknesses'], isA<List>());

        final weaknesses = (body['weaknesses'] as List).whereType<Map>();
        final ramp = weaknesses.firstWhere(
          (weakness) => weakness['type'] == 'insufficient_ramp',
          orElse: () => <String, dynamic>{},
        );
        expect(ramp, isNotEmpty, reason: response.body);
        expect(ramp['recommendations'], isA<List>());
        expect((ramp['recommendations'] as List), isNotEmpty);
      } finally {
        await deleteDeck(token, deckId);
      }
    },
    skip: skipIntegration,
  );
}
