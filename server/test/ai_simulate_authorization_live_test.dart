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

  Future<String> registerUser(String suffix) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': 'ai_sim_${suffix}_$runId',
        'email': 'ai_sim_${suffix}_$runId@example.com',
        'password': 'TestPassword123!',
      }),
    );

    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    final data = decodeJson(response);
    final token = data['token'] as String?;
    expect(token, isNotNull, reason: response.body);
    return token!;
  }

  Future<String> fetchAnyUsableCommanderCardId() async {
    const preferredNames = [
      'Sol Ring',
      'Arcane Signet',
      'Command Tower',
      'Plains',
      'Island',
      'Mountain',
    ];

    for (final name in preferredNames) {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/cards?name=${Uri.encodeQueryComponent(name)}&limit=10'),
        headers: {'Content-Type': 'application/json'},
      );
      expect(response.statusCode, 200, reason: response.body);
      final data = decodeJson(response);
      final rawCards = data['data'] ?? data['cards'];
      if (rawCards is! List || rawCards.isEmpty) continue;

      final card = rawCards.whereType<Map>().firstWhere(
            (candidate) => candidate['id']?.toString().isNotEmpty == true,
            orElse: () => <String, dynamic>{},
          );
      final cardId = card['id']?.toString();
      if (cardId != null && cardId.isNotEmpty) return cardId;
    }

    markTestSkipped(
        'Nenhuma carta preferencial encontrada no backend testado.');
    return '';
  }

  Future<String> createDeck({
    required String token,
    required String cardId,
    required String name,
    required bool isPublic,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: headers(token),
      body: jsonEncode({
        'name': name,
        'format': 'commander',
        'description': 'AI simulate authorization live test',
        'is_public': isPublic,
        'cards': [
          {
            'card_id': cardId,
            'quantity': 1,
            'is_commander': false,
          }
        ],
      }),
    );

    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    final data = decodeJson(response);
    final deckId = data['id']?.toString();
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
    'POST /ai/simulate scopes primary decks to owner and opponent to owner/public',
    () async {
      final userAToken = await registerUser('owner_a');
      final userBToken = await registerUser('owner_b');
      final cardId = await fetchAnyUsableCommanderCardId();
      if (cardId.isEmpty) return;

      final createdDecks = <({String token, String id})>[];

      try {
        final userADeck = await createDeck(
          token: userAToken,
          cardId: cardId,
          name: 'AI Sim A $runId',
          isPublic: false,
        );
        createdDecks.add((token: userAToken, id: userADeck));

        final userBPrivateDeck = await createDeck(
          token: userBToken,
          cardId: cardId,
          name: 'AI Sim B Private $runId',
          isPublic: false,
        );
        createdDecks.add((token: userBToken, id: userBPrivateDeck));

        final userBPublicDeck = await createDeck(
          token: userBToken,
          cardId: cardId,
          name: 'AI Sim B Public $runId',
          isPublic: true,
        );
        createdDecks.add((token: userBToken, id: userBPublicDeck));

        final privatePrimary = await http.post(
          Uri.parse('$baseUrl/ai/simulate'),
          headers: headers(userAToken),
          body: jsonEncode({
            'deck_id': userBPrivateDeck,
            'type': 'goldfish',
            'simulations': 10,
          }),
        );
        expect(privatePrimary.statusCode, 404, reason: privatePrimary.body);

        final privateOpponent = await http.post(
          Uri.parse('$baseUrl/ai/simulate'),
          headers: headers(userAToken),
          body: jsonEncode({
            'deck_id': userADeck,
            'opponent_deck_id': userBPrivateDeck,
            'type': 'matchup',
          }),
        );
        expect(privateOpponent.statusCode, 404, reason: privateOpponent.body);

        final publicOpponent = await http.post(
          Uri.parse('$baseUrl/ai/simulate'),
          headers: headers(userAToken),
          body: jsonEncode({
            'deck_id': userADeck,
            'opponent_deck_id': userBPublicDeck,
            'type': 'matchup',
          }),
        );
        expect(publicOpponent.statusCode, 200, reason: publicOpponent.body);
        expect(decodeJson(publicOpponent)['type'], 'matchup');
      } finally {
        for (final deck in createdDecks.reversed) {
          await deleteDeck(deck.token, deck.id);
        }
      }
    },
    skip: skipIntegration,
  );
}
