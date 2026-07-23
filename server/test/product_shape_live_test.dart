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
    'X-Request-Id': 'product-shape-${DateTime.now().microsecondsSinceEpoch}',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> objectBody(http.Response response) {
    final decoded = jsonDecode(response.body);
    expect(decoded, isA<Map<String, dynamic>>(), reason: response.body);
    return decoded as Map<String, dynamic>;
  }

  List<dynamic> listBody(http.Response response) {
    final decoded = jsonDecode(response.body);
    expect(decoded, isA<List<dynamic>>(), reason: response.body);
    return decoded as List<dynamic>;
  }

  Future<Map<String, dynamic>> register(String suffix) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers(),
      body: jsonEncode({
        'username': 'product_shape_$suffix',
        'email': 'product_shape_$suffix@example.invalid',
        'password': 'BetaQa!2026-Deck',
      }),
    );
    expect(response.statusCode, 201, reason: response.body);
    return objectBody(response);
  }

  test(
    'core product shapes cover success empty missing and forbidden states',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final owner = await register('${suffix}_owner');
      final viewer = await register('${suffix}_viewer');
      final ownerToken = owner['token'] as String;
      final viewerToken = viewer['token'] as String;

      final emptyDecks = await http.get(
        Uri.parse('$baseUrl/decks'),
        headers: headers(ownerToken),
      );
      expect(emptyDecks.statusCode, 200, reason: emptyDecks.body);
      expect(listBody(emptyDecks), isEmpty);

      final missingCards = await http.get(
        Uri.parse('$baseUrl/cards?name=DefinitelyMissingCard&limit=5'),
        headers: headers(ownerToken),
      );
      expect(missingCards.statusCode, 200, reason: missingCards.body);
      final missingCardsBody = objectBody(missingCards);
      expect(missingCardsBody['data'], isEmpty);
      expect(missingCardsBody['total_returned'], 0);

      final cards = await http.get(
        Uri.parse('$baseUrl/cards?name=Sol%20Ring&limit=1'),
        headers: headers(ownerToken),
      );
      expect(cards.statusCode, 200, reason: cards.body);
      final cardRows = objectBody(cards)['data'] as List<dynamic>;
      expect(cardRows, isNotEmpty);
      final cardId = (cardRows.first as Map<String, dynamic>)['id'] as String;

      final createDeck = await http.post(
        Uri.parse('$baseUrl/decks'),
        headers: headers(ownerToken),
        body: jsonEncode({
          'name': 'Product Shape Deck $suffix',
          'format': 'commander',
          'description': 'Disposable S1 shape fixture',
          'is_public': true,
          'cards': [
            {'card_id': cardId, 'quantity': 1, 'is_commander': false},
          ],
        }),
      );
      expect(createDeck.statusCode, anyOf(200, 201), reason: createDeck.body);
      final deckId = objectBody(createDeck)['id'] as String;

      final ownerDecks = await http.get(
        Uri.parse('$baseUrl/decks'),
        headers: headers(ownerToken),
      );
      expect(ownerDecks.statusCode, 200, reason: ownerDecks.body);
      expect(
        listBody(ownerDecks).cast<Map<String, dynamic>>().single['id'],
        deckId,
      );

      final forbiddenDeck = await http.get(
        Uri.parse('$baseUrl/decks/$deckId'),
        headers: headers(viewerToken),
      );
      expect(forbiddenDeck.statusCode, 404, reason: forbiddenDeck.body);
      expect(objectBody(forbiddenDeck)['error'], isA<String>());

      final missingDeck = await http.get(
        Uri.parse('$baseUrl/decks/00000000-0000-0000-0000-000000000000'),
        headers: headers(ownerToken),
      );
      expect(missingDeck.statusCode, 404, reason: missingDeck.body);

      final emptyReplays = await http.get(
        Uri.parse('$baseUrl/decks/$deckId/battle-replays'),
        headers: headers(ownerToken),
      );
      expect(emptyReplays.statusCode, 200, reason: emptyReplays.body);
      final replayBody = objectBody(emptyReplays);
      expect(replayBody['data'], isEmpty);
      expect(replayBody['source'], 'battle_simulations');

      final forbiddenReplays = await http.get(
        Uri.parse('$baseUrl/decks/$deckId/battle-replays'),
        headers: headers(viewerToken),
      );
      expect(forbiddenReplays.statusCode, 404, reason: forbiddenReplays.body);

      final tradeMatches = await http.get(
        Uri.parse('$baseUrl/community/trade-matches?deck_id=$deckId'),
        headers: headers(ownerToken),
      );
      expect(tradeMatches.statusCode, 200, reason: tradeMatches.body);
      final tradeMatchBody = objectBody(tradeMatches);
      expect(tradeMatchBody['deck_id'], deckId);
      expect(tradeMatchBody['match_count'], 0);
      expect(tradeMatchBody['matches'], isEmpty);

      final forbiddenTradeMatches = await http.get(
        Uri.parse('$baseUrl/community/trade-matches?deck_id=$deckId'),
        headers: headers(viewerToken),
      );
      expect(
        forbiddenTradeMatches.statusCode,
        200,
        reason: forbiddenTradeMatches.body,
      );
      final forbiddenTradeMatchBody = objectBody(forbiddenTradeMatches);
      expect(forbiddenTradeMatchBody['source'], 'deck_missing_and_wishlist');
      expect(forbiddenTradeMatchBody['matches'], isEmpty);
      expect(forbiddenTradeMatchBody['message'], isA<String>());

      final emptyComments = await http.get(
        Uri.parse('$baseUrl/community/decks/$deckId/comments'),
        headers: headers(viewerToken),
      );
      expect(emptyComments.statusCode, 200, reason: emptyComments.body);
      expect(objectBody(emptyComments)['data'], isEmpty);

      final createComment = await http.post(
        Uri.parse('$baseUrl/community/decks/$deckId/comments'),
        headers: headers(viewerToken),
        body: jsonEncode({'body': 'Comentário de contrato S1.'}),
      );
      expect(createComment.statusCode, 201, reason: createComment.body);
      final comment = objectBody(createComment)['comment'] as Map;
      expect(comment['deck_id'], deckId);
      expect(comment['body'], 'Comentário de contrato S1.');

      final shortComment = await http.post(
        Uri.parse('$baseUrl/community/decks/$deckId/comments'),
        headers: headers(viewerToken),
        body: jsonEncode({'body': 'x'}),
      );
      expect(shortComment.statusCode, 400, reason: shortComment.body);

      final missingComments = await http.get(
        Uri.parse(
          '$baseUrl/community/decks/'
          '00000000-0000-0000-0000-000000000000/comments',
        ),
        headers: headers(viewerToken),
      );
      expect(missingComments.statusCode, 404, reason: missingComments.body);

      final contentReport = await http.post(
        Uri.parse('$baseUrl/community/decks/$deckId/reports'),
        headers: headers(viewerToken),
        body: jsonEncode({
          'reason': 'other',
          'details': 'Contrato S1 sem conteúdo sensível.',
        }),
      );
      expect(contentReport.statusCode, 201, reason: contentReport.body);
      expect((objectBody(contentReport)['report'] as Map)['status'], 'open');

      final invalidReport = await http.post(
        Uri.parse('$baseUrl/community/decks/$deckId/reports'),
        headers: headers(viewerToken),
        body: jsonEncode({'reason': 'not-a-reason'}),
      );
      expect(invalidReport.statusCode, 400, reason: invalidReport.body);

      final shareReport = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/reports'),
        headers: headers(ownerToken),
        body: jsonEncode({'title': 'Relatório de contrato S1'}),
      );
      expect(shareReport.statusCode, 201, reason: shareReport.body);
      final shareReportBody = objectBody(shareReport);
      final report = shareReportBody['report'] as Map<String, dynamic>;
      final reportId = report['id'] as String;
      expect(report['deck_id'], deckId);
      expect(shareReportBody['public_url'], contains(reportId));

      final publicReport = await http.get(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: headers(),
      );
      expect(publicReport.statusCode, 200, reason: publicReport.body);
      expect(objectBody(publicReport)['id'], reportId);

      final forbiddenShare = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/reports'),
        headers: headers(viewerToken),
        body: jsonEncode({}),
      );
      expect(forbiddenShare.statusCode, 404, reason: forbiddenShare.body);

      final missingPublicReport = await http.get(
        Uri.parse('$baseUrl/reports/rpt_missing'),
        headers: headers(),
      );
      expect(
        missingPublicReport.statusCode,
        404,
        reason: missingPublicReport.body,
      );
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
