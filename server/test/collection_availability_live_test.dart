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
    'X-Request-Id': 'collection-live-${DateTime.now().microsecondsSinceEpoch}',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> objectBody(http.Response response) {
    final decoded = jsonDecode(response.body);
    expect(decoded, isA<Map<String, dynamic>>(), reason: response.body);
    return decoded as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String suffix) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers(),
      body: jsonEncode({
        'username': 'availability_$suffix',
        'email': 'availability_$suffix@example.invalid',
        'password': 'BetaQa!2026-Deck',
      }),
    );
    expect(response.statusCode, 201, reason: response.body);
    return objectBody(response);
  }

  Future<String> createDeck({
    required String token,
    required String suffix,
    required String cardId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: headers(token),
      body: jsonEncode({
        'name': 'Availability $suffix',
        'format': 'commander',
        'cards': [
          {'card_id': cardId, 'quantity': 1, 'is_commander': false},
        ],
      }),
    );
    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    return objectBody(response)['id'] as String;
  }

  Future<Map<String, dynamic>> addBinderItem({
    required String token,
    required String cardId,
    required int quantity,
    required String condition,
    required String language,
    bool isFoil = false,
    bool forTrade = false,
    bool forSale = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/binder'),
      headers: headers(token),
      body: jsonEncode({
        'card_id': cardId,
        'quantity': quantity,
        'condition': condition,
        'language': language,
        'is_foil': isFoil,
        'for_trade': forTrade,
        'for_sale': forSale,
        if (forSale) 'price': 9.99,
        'list_type': 'have',
      }),
    );
    expect(response.statusCode, 201, reason: response.body);
    return objectBody(response);
  }

  Future<http.Response> createSale({
    required String buyerToken,
    required String sellerId,
    required String binderItemId,
  }) {
    return http.post(
      Uri.parse('$baseUrl/trades'),
      headers: headers(buyerToken),
      body: jsonEncode({
        'receiver_id': sellerId,
        'type': 'sale',
        'payment_method': 'cash',
        'payment_amount': 19.98,
        'requested_items': [
          {'binder_item_id': binderItemId, 'quantity': 2, 'agreed_price': 9.99},
        ],
        'message': 'Concorrência de disponibilidade S1-07',
      }),
    );
  }

  test(
    'collection deck allocation and concurrent trades share one quantity contract',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final seller = await register('${suffix}_seller');
      final buyerA = await register('${suffix}_buyer_a');
      final buyerB = await register('${suffix}_buyer_b');
      final sellerToken = seller['token'] as String;
      final sellerId = (seller['user'] as Map<String, dynamic>)['id'] as String;
      final buyerAToken = buyerA['token'] as String;
      final buyerBToken = buyerB['token'] as String;

      final cards = await http.get(
        Uri.parse('$baseUrl/cards?name=Sol%20Ring&limit=10&dedupe=false'),
        headers: headers(sellerToken),
      );
      expect(cards.statusCode, 200, reason: cards.body);
      final cardRows = (objectBody(cards)['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((card) => card['name'] == 'Sol Ring')
          .toList(growable: false);
      expect(cardRows, hasLength(2));
      final firstPrinting = cardRows.singleWhere(
        (card) => card['set_code'].toString().toUpperCase() == 'TST',
      );
      final secondPrinting = cardRows.singleWhere(
        (card) => card['set_code'].toString().toUpperCase() == 'T2S',
      );
      final firstCardId = firstPrinting['id'] as String;
      final secondCardId = secondPrinting['id'] as String;

      final english = await addBinderItem(
        token: sellerToken,
        cardId: firstCardId,
        quantity: 1,
        condition: 'NM',
        language: 'en',
      );
      final portuguese = await addBinderItem(
        token: sellerToken,
        cardId: firstCardId,
        quantity: 1,
        condition: 'NM',
        language: 'PT_BR',
      );
      expect(portuguese['language'], 'pt-br');
      final advertisedBinder = await addBinderItem(
        token: sellerToken,
        cardId: secondCardId,
        quantity: 2,
        condition: 'LP',
        language: 'ja',
        isFoil: true,
        forTrade: true,
        forSale: true,
      );
      final englishItemId = english['id'] as String;
      final portugueseItemId = portuguese['id'] as String;
      final binderItemId = advertisedBinder['id'] as String;

      final duplicateLanguage = await http.post(
        Uri.parse('$baseUrl/binder'),
        headers: headers(sellerToken),
        body: jsonEncode({
          'card_id': firstCardId,
          'quantity': 1,
          'condition': 'NM',
          'language': 'pt-br',
          'list_type': 'have',
        }),
      );
      expect(duplicateLanguage.statusCode, 409, reason: duplicateLanguage.body);
      expect(
        objectBody(duplicateLanguage)['code'],
        'binder_item_identity_conflict',
      );

      await createDeck(
        token: sellerToken,
        suffix: '${suffix}_one',
        cardId: firstCardId,
      );
      await createDeck(
        token: sellerToken,
        suffix: '${suffix}_two',
        cardId: secondCardId,
      );

      final availabilityBefore = await http.get(
        Uri.parse(
          '$baseUrl/binder/availability',
        ).replace(queryParameters: {'card_ids': '$firstCardId,$secondCardId'}),
        headers: headers(sellerToken),
      );
      expect(
        availabilityBefore.statusCode,
        200,
        reason: availabilityBefore.body,
      );
      final availabilityRows =
          (objectBody(availabilityBefore)['data'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      expect(availabilityRows, hasLength(2));
      expect(
        availabilityRows.map((row) => row['playable_card_id']).toSet(),
        hasLength(1),
      );
      for (final row in availabilityRows) {
        expect(row['owned_quantity'], 4);
        expect(row['allocated_quantity'], 2);
        expect(row['committed_trade_quantity'], 0);
        expect(row['free_quantity'], 2);
        expect(row['missing_quantity'], 0);
      }

      final before = await http.get(
        Uri.parse('$baseUrl/binder?list_type=have&limit=10'),
        headers: headers(sellerToken),
      );
      expect(before.statusCode, 200, reason: before.body);
      final beforeItems =
          (objectBody(before)['data'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final physicalItems = beforeItems
          .where(
            (item) => {
              englishItemId,
              portugueseItemId,
              binderItemId,
            }.contains(item['id']),
          )
          .toList(growable: false);
      expect(physicalItems, hasLength(3));
      for (final item in physicalItems) {
        expect(item['owned_quantity'], 4);
        expect(item['allocated_quantity'], 2);
        expect(item['committed_trade_quantity'], 0);
        expect(item['free_quantity'], 2);
        expect(item['missing_quantity'], 0);
        expect(item['deck_count'], 2);
        expect(item['deck_quantity'], 2);
      }
      expect(
        physicalItems.fold<int>(
          0,
          (sum, item) => sum + (item['available_quantity'] as int),
        ),
        2,
      );
      final englishItem = physicalItems.singleWhere(
        (item) => item['id'] == englishItemId,
      );
      final portugueseItem = physicalItems.singleWhere(
        (item) => item['id'] == portugueseItemId,
      );
      final beforeItem = physicalItems.singleWhere(
        (item) => item['id'] == binderItemId,
      );
      expect(englishItem['language'], 'en');
      expect(portugueseItem['language'], 'pt-br');
      expect(beforeItem['language'], 'ja');
      expect(beforeItem['condition'], 'LP');
      expect(beforeItem['is_foil'], isTrue);
      expect(beforeItem['available_quantity'], 2);

      final nonOwnerUpdate = await http.put(
        Uri.parse('$baseUrl/binder/$binderItemId'),
        headers: headers(buyerAToken),
        body: jsonEncode({'language': 'de'}),
      );
      expect(nonOwnerUpdate.statusCode, 404, reason: nonOwnerUpdate.body);
      final nonOwnerDelete = await http.delete(
        Uri.parse('$baseUrl/binder/$binderItemId'),
        headers: headers(buyerAToken),
      );
      expect(nonOwnerDelete.statusCode, 404, reason: nonOwnerDelete.body);

      final marketplaceBefore = await http.get(
        Uri.parse('$baseUrl/community/marketplace?search=Sol%20Ring&limit=10'),
        headers: headers(buyerAToken),
      );
      expect(marketplaceBefore.statusCode, 200, reason: marketplaceBefore.body);
      final advertised = (objectBody(marketplaceBefore)['data']
              as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['id'] == binderItemId);
      expect(advertised['quantity'], 2);
      expect(advertised['available_quantity'], 2);

      final responses = await Future.wait([
        createSale(
          buyerToken: buyerAToken,
          sellerId: sellerId,
          binderItemId: binderItemId,
        ),
        createSale(
          buyerToken: buyerBToken,
          sellerId: sellerId,
          binderItemId: binderItemId,
        ),
      ]);
      expect(
        responses.map((response) => response.statusCode).toList()..sort(),
        [201, 409],
        reason: responses.map((response) => response.body).join('\n'),
      );
      final conflict = responses.singleWhere(
        (response) => response.statusCode == 409,
      );
      expect(objectBody(conflict)['code'], 'trade_quantity_unavailable');

      final committedIdentityUpdate = await http.put(
        Uri.parse('$baseUrl/binder/$binderItemId'),
        headers: headers(sellerToken),
        body: jsonEncode({'language': 'fr'}),
      );
      expect(
        committedIdentityUpdate.statusCode,
        409,
        reason: committedIdentityUpdate.body,
      );
      expect(
        objectBody(committedIdentityUpdate)['code'],
        'binder_item_committed',
      );
      final committedQuantityUpdate = await http.put(
        Uri.parse('$baseUrl/binder/$binderItemId'),
        headers: headers(sellerToken),
        body: jsonEncode({'quantity': 1}),
      );
      expect(
        committedQuantityUpdate.statusCode,
        409,
        reason: committedQuantityUpdate.body,
      );
      expect(
        objectBody(committedQuantityUpdate)['committed_trade_quantity'],
        2,
      );
      final committedDelete = await http.delete(
        Uri.parse('$baseUrl/binder/$binderItemId'),
        headers: headers(sellerToken),
      );
      expect(committedDelete.statusCode, 409, reason: committedDelete.body);
      expect(objectBody(committedDelete)['code'], 'binder_item_committed');

      final after = await http.get(
        Uri.parse('$baseUrl/binder?list_type=have&limit=10'),
        headers: headers(sellerToken),
      );
      expect(after.statusCode, 200, reason: after.body);
      final afterItem = (objectBody(after)['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['id'] == binderItemId);
      expect(afterItem['owned_quantity'], 4);
      expect(afterItem['allocated_quantity'], 2);
      expect(afterItem['committed_trade_quantity'], 2);
      expect(afterItem['free_quantity'], 0);
      expect(afterItem['available_quantity'], 0);

      final availabilityAfter = await http.get(
        Uri.parse(
          '$baseUrl/binder/availability',
        ).replace(queryParameters: {'card_ids': '$firstCardId,$secondCardId'}),
        headers: headers(sellerToken),
      );
      expect(availabilityAfter.statusCode, 200, reason: availabilityAfter.body);
      final availabilityAfterRows =
          (objectBody(availabilityAfter)['data'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      expect(availabilityAfterRows, hasLength(2));
      for (final row in availabilityAfterRows) {
        expect(row['owned_quantity'], 4);
        expect(row['allocated_quantity'], 2);
        expect(row['committed_trade_quantity'], 2);
        expect(row['free_quantity'], 0);
      }

      final marketplaceAfter = await http.get(
        Uri.parse('$baseUrl/community/marketplace?search=Sol%20Ring&limit=10'),
        headers: headers(buyerAToken),
      );
      expect(marketplaceAfter.statusCode, 200, reason: marketplaceAfter.body);
      final remaining = (objectBody(marketplaceAfter)['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((item) => item['id'] == binderItemId);
      expect(remaining, isEmpty);
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
