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
          ? 'Teste mutante requer MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL.'
          : null;

  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  final runSuffix = DateTime.now().millisecondsSinceEpoch;
  late final Map<String, String> testUser = {
    'email': 'test_import_to_deck_$runSuffix@example.com',
    'password': 'BetaQa!2026-Deck',
    'username': 'test_import_to_deck_$runSuffix',
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

  Future<String> getAuthToken() async {
    var response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(testUser),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testUser['email'],
          'password': testUser['password'],
        }),
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to authenticate test user: ${response.body}');
    }

    return decodeJson(response)['token'] as String;
  }

  Map<String, String> authHeaders({bool withContentType = false}) => {
    if (withContentType) 'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  Future<String> createDeck({
    String format = 'standard',
    List<Map<String, dynamic>> cards = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: authHeaders(withContentType: true),
      body: jsonEncode({
        'name': 'ImportToDeck ${DateTime.now().millisecondsSinceEpoch}',
        'format': format,
        'description': 'test import to deck',
        'cards': cards,
      }),
    );

    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    return decodeJson(response)['id'] as String;
  }

  Future<Map<String, dynamic>?> findCardByNames(List<String> names) async {
    for (final name in names) {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/cards?name=${Uri.encodeQueryComponent(name)}&limit=10',
        ),
        headers: authHeaders(),
      );
      if (response.statusCode != 200) continue;
      final data = decodeJson(response);
      final cards = (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (cards.isNotEmpty) return cards.first;
    }
    return null;
  }

  bool isCommanderEligible(Map<String, dynamic> card) {
    final typeLine = (card['type_line'] as String? ?? '').toLowerCase();
    final oracle = (card['oracle_text'] as String? ?? '').toLowerCase();
    final hasPowerToughnessBox =
        (card['power']?.toString().trim().isNotEmpty ?? false) &&
        (card['toughness']?.toString().trim().isNotEmpty ?? false);
    return (typeLine.contains('legendary') && typeLine.contains('creature')) ||
        (typeLine.contains('legendary') &&
            (typeLine.contains('vehicle') || typeLine.contains('spacecraft')) &&
            hasPowerToughnessBox) ||
        oracle.contains('can be your commander');
  }

  Future<void> deleteDeck(String deckId) async {
    await http.delete(
      Uri.parse('$baseUrl/decks/$deckId'),
      headers: authHeaders(),
    );
  }

  setUpAll(() async {
    if (skipIntegration != null) return;
    authToken = await getAuthToken();
  });

  tearDownAll(() async {
    if (skipIntegration != null) return;
    for (final deckId in createdDeckIds) {
      await deleteDeck(deckId);
    }
  });

  group('Import to existing deck | /import/to-deck', () {
    test(
      'creates complete Commander draft and resolves commander field separately',
      () async {
        final response = await http.post(
          Uri.parse('$baseUrl/import'),
          headers: authHeaders(withContentType: true),
          body: jsonEncode({
            'name':
                'Import Commander Draft ${DateTime.now().millisecondsSinceEpoch}',
            'format': 'commander',
            'commander': 'Kaalia da Vastidão',
            'list': '''
1 Sol Ring
33 Planície
33 Pântano
32 Montanha
''',
          }),
        );

        expect(response.statusCode, equals(200), reason: response.body);
        final body = decodeJson(response);
        final deck = body['deck'] as Map<String, dynamic>?;
        expect(deck?['id'], isA<String>(), reason: response.body);
        createdDeckIds.add(deck!['id'] as String);
        expect(body['commander_detected'], isTrue, reason: response.body);
        expect(body['missing_commander'], isFalse, reason: response.body);
        expect(body['cards_imported'], greaterThanOrEqualTo(100));
        expect(body['not_found_lines'], isEmpty, reason: response.body);
        expect(body['deck_state'], 'validated', reason: response.body);
        expect(body['requires_review'], isFalse, reason: response.body);
        final validation = body['validation'] as Map<String, dynamic>;
        expect(validation['strict_validation_passed'], isTrue);
        expect(validation['import_complete'], isTrue);
      },
      skip: skipIntegration,
    );

    test(
      'saves an incomplete but legal Commander import as a reviewable draft',
      () async {
        final response = await http.post(
          Uri.parse('$baseUrl/import'),
          headers: authHeaders(withContentType: true),
          body: jsonEncode({
            'name':
                'Import Commander Partial ${DateTime.now().millisecondsSinceEpoch}',
            'format': 'commander',
            'commander': 'Kaalia da Vastidão',
            'list': '1 Sol Ring',
          }),
        );

        expect(response.statusCode, equals(200), reason: response.body);
        final body = decodeJson(response);
        final deck = body['deck'] as Map<String, dynamic>?;
        expect(deck?['id'], isA<String>(), reason: response.body);
        createdDeckIds.add(deck!['id'] as String);
        expect(body['deck_state'], 'draft', reason: response.body);
        expect(body['requires_review'], isTrue, reason: response.body);
        expect(body['is_partial'], isTrue, reason: response.body);
        final validation = body['validation'] as Map<String, dynamic>;
        expect(validation['strict_validation_passed'], isFalse);
        expect(validation['review_reasons'], contains('incomplete_deck_size'));
      },
      skip: skipIntegration,
    );

    test('imports list into existing deck successfully', () async {
      final deckId = await createDeck();
      createdDeckIds.add(deckId);

      final response = await http.post(
        Uri.parse('$baseUrl/import/to-deck'),
        headers: authHeaders(withContentType: true),
        body: jsonEncode({
          'deck_id': deckId,
          'list': '10 Forest',
          'replace_all': false,
        }),
      );

      expect(response.statusCode, equals(200), reason: response.body);
      final body = decodeJson(response);
      expect(body['success'], isTrue, reason: response.body);
      expect(body['cards_imported'], equals(10), reason: response.body);
    }, skip: skipIntegration);

    test('returns 400 when list type is invalid', () async {
      final deckId = await createDeck();
      createdDeckIds.add(deckId);

      final response = await http.post(
        Uri.parse('$baseUrl/import/to-deck'),
        headers: authHeaders(withContentType: true),
        body: jsonEncode({'deck_id': deckId, 'list': 123}),
      );

      expect(response.statusCode, equals(400), reason: response.body);
      expect(decodeJson(response)['error'], isA<String>());
    }, skip: skipIntegration);

    test('returns 404 for missing deck', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/import/to-deck'),
        headers: authHeaders(withContentType: true),
        body: jsonEncode({
          'deck_id': '00000000-0000-0000-0000-000000000099',
          'list': '10 Forest',
        }),
      );

      expect(response.statusCode, equals(404), reason: response.body);
      expect(decodeJson(response)['error'], isA<String>());
    }, skip: skipIntegration);

    test(
      'rejects import that would exceed Commander deck size',
      () async {
        final commander = await findCardByNames([
          'Talrand, Sky Summoner',
          'Krenko, Mob Boss',
          'Lathril, Blade of the Elves',
          'Niv-Mizzet, Parun',
        ]);
        final wastes = await findCardByNames(['Wastes']);

        if (commander == null ||
            !isCommanderEligible(commander) ||
            wastes == null) {
          return;
        }

        final deckId = await createDeck(
          format: 'commander',
          cards: [
            {'card_id': commander['id'], 'quantity': 1, 'is_commander': true},
            {'card_id': wastes['id'], 'quantity': 99, 'is_commander': false},
          ],
        );
        createdDeckIds.add(deckId);

        final response = await http.post(
          Uri.parse('$baseUrl/import/to-deck'),
          headers: authHeaders(withContentType: true),
          body: jsonEncode({
            'deck_id': deckId,
            'list': '1 Wastes',
            'replace_all': false,
          }),
        );

        expect(response.statusCode, equals(400), reason: response.body);
      },
      skip: skipIntegration,
    );

    test(
      'replace_all preserves existing Commander when imported list has no commander',
      () async {
        final commander = await findCardByNames([
          'Talrand, Sky Summoner',
          'Krenko, Mob Boss',
          'Lathril, Blade of the Elves',
          'Niv-Mizzet, Parun',
        ]);
        if (commander == null || !isCommanderEligible(commander)) {
          return;
        }

        final deckId = await createDeck(
          format: 'commander',
          cards: [
            {'card_id': commander['id'], 'quantity': 1, 'is_commander': true},
          ],
        );
        createdDeckIds.add(deckId);

        final response = await http.post(
          Uri.parse('$baseUrl/import/to-deck'),
          headers: authHeaders(withContentType: true),
          body: jsonEncode({
            'deck_id': deckId,
            'list': '1 Sol Ring',
            'replace_all': true,
          }),
        );

        expect(response.statusCode, equals(200), reason: response.body);
        final body = decodeJson(response);
        expect(body['commander_detected'], isTrue, reason: response.body);
        expect(body['missing_commander'], isFalse, reason: response.body);
        expect(body['commander_preserved'], isTrue, reason: response.body);
        expect(body['cards_imported'], equals(1), reason: response.body);
        expect(body['total_cards'], equals(2), reason: response.body);
      },
      skip: skipIntegration,
    );
  });
}
