@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final liveMutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final skipIntegration =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !liveMutationApproved
          ? 'Teste mutante requer aprovação explícita.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final originalName = 'S4-01 Atomic Deck $suffix';
  String? token;

  Map<String, dynamic> decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    return (decoded as Map).cast<String, dynamic>();
  }

  Map<String, String> headers() => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<http.Response> post(String path, Map<String, dynamic> body) =>
      http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers(),
        body: jsonEncode(body),
      );

  Future<http.Response> put(String path, Map<String, dynamic> body) => http.put(
    Uri.parse('$baseUrl$path'),
    headers: headers(),
    body: jsonEncode(body),
  );

  Future<Map<String, dynamic>> getDeck(String deckId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/decks/$deckId'),
      headers: headers(),
    );
    expect(response.statusCode, 200, reason: response.body);
    return decode(response);
  }

  setUpAll(() async {
    if (skipIntegration != null) return;
    final response = await post('/auth/register', {
      'email': 's4_01_atomic_$suffix@example.com',
      'password': 'BetaQa!2026-Deck',
      'username': 's4_01_atomic_$suffix',
    });
    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    token = decode(response)['token'] as String;
  });

  test(
    'create, edit, import failure and delete preserve atomic deck invariants',
    () async {
      final invalidFormat = await post('/decks', {
        'name': 'Invalid Format $suffix',
        'format': 'invented',
        'cards': <Object>[],
      });
      expect(invalidFormat.statusCode, 400, reason: invalidFormat.body);

      final malformedCards = await post('/decks', {
        'name': 'Malformed Cards $suffix',
        'format': 'standard',
        'cards': [null],
      });
      expect(malformedCards.statusCode, 400, reason: malformedCards.body);

      final emptyCommander = await post('/decks', {
        'name': 'Empty Commander $suffix',
        'format': 'commander',
        'cards': <Object>[],
      });
      expect(emptyCommander.statusCode, anyOf(200, 201));
      final emptyCommanderBody = decode(emptyCommander);
      expect(emptyCommanderBody['deck_state'], 'draft');
      expect(emptyCommanderBody['requires_review'], isTrue);
      expect(emptyCommanderBody['review_reasons'], [
        'missing_commander',
        'incomplete_deck_size',
      ]);
      final emptyDeckId = emptyCommanderBody['id'] as String;
      final emptyDeleted = await http.delete(
        Uri.parse('$baseUrl/decks/$emptyDeckId'),
        headers: headers(),
      );
      expect(emptyDeleted.statusCode, 204, reason: emptyDeleted.body);

      final cardSearch = await http.get(
        Uri.parse('$baseUrl/cards?name=Sol%20Ring&limit=10'),
        headers: headers(),
      );
      expect(cardSearch.statusCode, 200, reason: cardSearch.body);
      final searchBody = decode(cardSearch);
      final cardRows = (searchBody['data'] as List).cast<Map>();
      final solRingId = cardRows.first['id'] as String;

      final rejectedCreateName = 'Rejected Create $suffix';
      final rejectedCreate = await post('/decks', {
        'name': rejectedCreateName,
        'format': 'standard',
        'cards': [
          {'card_id': solRingId, 'quantity': 3, 'is_commander': false},
          {'card_id': solRingId, 'quantity': 2, 'is_commander': false},
        ],
      });
      expect(rejectedCreate.statusCode, 400, reason: rejectedCreate.body);

      final created = await post('/decks', {
        'name': originalName,
        'format': 'standard',
        'cards': [
          {'card_id': solRingId, 'quantity': 2, 'is_commander': false},
          {'card_id': solRingId, 'quantity': 2, 'is_commander': false},
        ],
      });
      expect(created.statusCode, anyOf(200, 201), reason: created.body);
      final createdBody = decode(created);
      final deckId = createdBody['id'] as String;
      expect(createdBody['deck_state'], 'draft');
      expect(createdBody['requires_review'], isTrue);
      expect(createdBody['review_reasons'], contains('incomplete_deck_size'));

      final listResponse = await http.get(
        Uri.parse('$baseUrl/decks'),
        headers: headers(),
      );
      expect(listResponse.statusCode, 200, reason: listResponse.body);
      final listedDecks = (jsonDecode(listResponse.body) as List).cast<Map>();
      expect(
        listedDecks.where((deck) => deck['name'] == rejectedCreateName),
        isEmpty,
        reason: 'failed create must roll back the deck row',
      );

      final failedReplacement = await put('/decks/$deckId', {
        'name': 'Must Roll Back $suffix',
        'cards': [
          {
            'card_id': '00000000-0000-4000-8000-000000000099',
            'quantity': 1,
            'is_commander': false,
          },
        ],
      });
      expect(failedReplacement.statusCode, 400, reason: failedReplacement.body);
      var persisted = await getDeck(deckId);
      expect(persisted['name'], originalName);
      expect((persisted['stats'] as Map)['total_cards'], 4);

      final failedFormat = await put('/decks/$deckId', {'format': 'commander'});
      expect(failedFormat.statusCode, 400, reason: failedFormat.body);
      persisted = await getDeck(deckId);
      expect(persisted['format'], 'standard');
      expect((persisted['stats'] as Map)['total_cards'], 4);

      final invalidImport = await post('/import', {
        'name': 'Invalid Import $suffix',
        'format': 'invented',
        'list': '1 Sol Ring',
      });
      expect(invalidImport.statusCode, 400, reason: invalidImport.body);

      final invalidMerge = await post('/import/to-deck', {
        'deck_id': deckId,
        'list': 123,
        'replace_all': true,
      });
      expect(invalidMerge.statusCode, 400, reason: invalidMerge.body);
      persisted = await getDeck(deckId);
      expect((persisted['stats'] as Map)['total_cards'], 4);

      final deleted = await http.delete(
        Uri.parse('$baseUrl/decks/$deckId'),
        headers: headers(),
      );
      expect(deleted.statusCode, 204, reason: deleted.body);
      final afterDelete = await http.get(
        Uri.parse('$baseUrl/decks/$deckId'),
        headers: headers(),
      );
      expect(afterDelete.statusCode, 404, reason: afterDelete.body);
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
