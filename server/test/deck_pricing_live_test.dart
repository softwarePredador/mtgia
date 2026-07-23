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
  final skipIntegration =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !liveMutationApproved
          ? 'Teste mutante requer aprovacao explicita.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  String? token;
  String? deckId;
  late Pool pool;

  Map<String, dynamic> decode(http.Response response) =>
      (jsonDecode(response.body) as Map).cast<String, dynamic>();

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

  Future<http.Response> get(String path) =>
      http.get(Uri.parse('$baseUrl$path'), headers: headers());

  setUpAll(() async {
    if (skipIntegration != null) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));

    final registration = await post('/auth/register', {
      'email': 's4_08_pricing_$suffix@example.com',
      'password': 'BetaQa!2026-Deck',
      'username': 's4_08_pricing_$suffix',
    });
    expect(registration.statusCode, anyOf(200, 201), reason: registration.body);
    token = decode(registration)['token'] as String;

    final created = await post('/decks', {
      'name': 'S4-08 Pricing $suffix',
      'format': 'commander',
    });
    expect(created.statusCode, anyOf(200, 201), reason: created.body);
    deckId = decode(created)['id'] as String;

    await pool.execute('''
        UPDATE cards
        SET price_usd = CASE WHEN name = 'Sol Ring' THEN 1.50 ELSE NULL END,
            price = CASE WHEN name = 'Sol Ring' THEN 1.50 ELSE NULL END,
            price_source = CASE WHEN name = 'Sol Ring' THEN 'mtgjson' ELSE NULL END,
            price_updated_at = CASE
              WHEN name = 'Sol Ring' THEN CURRENT_TIMESTAMP
              ELSE NULL
            END
        WHERE (name = 'Sol Ring' AND set_code = 'TST')
           OR (name = 'Island' AND set_code = 'TST');
      ''');
    await pool.execute(
      Sql.named('''
        INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
        SELECT @deckId::uuid, id,
               CASE WHEN name = 'Island' THEN 2 ELSE 1 END,
               FALSE
        FROM cards
        WHERE (name = 'Sol Ring' AND set_code = 'TST')
           OR (name = 'Island' AND set_code = 'TST')
        ON CONFLICT (deck_id, card_id) DO UPDATE
        SET quantity = EXCLUDED.quantity;
      '''),
      parameters: {'deckId': deckId},
    );
  });

  tearDownAll(() async {
    if (skipIntegration == null) await pool.close();
  });

  test(
    'PostgreSQL and API preserve partial and unavailable pricing states',
    () async {
      final partialResponse = await post('/decks/$deckId/pricing', {
        'refresh_missing': false,
      });
      expect(partialResponse.statusCode, 200, reason: partialResponse.body);
      final partial = decode(partialResponse);
      expect(partial['currency'], 'USD');
      expect(partial['estimated_total_usd'], 1.5);
      expect(partial['known_price_cards'], 1);
      expect(partial['missing_price_cards'], 2);
      expect(partial['total_cards'], 3);
      expect(partial['pricing_status'], 'partial');
      expect(partial['price_source'], 'mtgjson');
      expect(partial['cache_status'], 'cached');
      expect(partial['pricing_updated_at'], isA<String>());

      final partialItems = (partial['items'] as List).cast<Map>();
      final island = partialItems.singleWhere(
        (item) => item['name'] == 'Island',
      );
      expect(island['unit_price_usd'], isNull);
      expect(island['line_total_usd'], isNull);

      await pool.execute(
        Sql.named('''
          UPDATE cards
          SET price_usd = NULL,
              price = NULL,
              price_source = NULL,
              price_updated_at = NULL
          WHERE name = 'Sol Ring' AND set_code = 'TST'
        '''),
      );

      final unavailableResponse = await post('/decks/$deckId/pricing', {
        'refresh_missing': false,
      });
      expect(
        unavailableResponse.statusCode,
        200,
        reason: unavailableResponse.body,
      );
      final unavailable = decode(unavailableResponse);
      expect(unavailable['estimated_total_usd'], isNull);
      expect(unavailable['known_price_cards'], 0);
      expect(unavailable['missing_price_cards'], 3);
      expect(unavailable['pricing_status'], 'unavailable');
      expect(unavailable['price_source'], 'unknown');

      final snapshot = await pool.execute(
        Sql.named('''
          SELECT pricing_total, pricing_currency, pricing_missing_cards,
                 pricing_source, pricing_updated_at
          FROM decks
          WHERE id = @deckId::uuid
        '''),
        parameters: {'deckId': deckId},
      );
      expect(snapshot, hasLength(1));
      expect(snapshot.first[0], isNull);
      expect(snapshot.first[1], 'USD');
      expect(snapshot.first[2], 3);
      expect(snapshot.first[3], 'unknown');
      expect(snapshot.first[4], isA<DateTime>());

      await pool.execute(
        Sql.named('''
          INSERT INTO user_binder_items (
            user_id, card_id, quantity, condition, is_foil,
            price, currency, language, list_type
          )
          SELECT users.id, cards.id,
                 CASE
                   WHEN cards.set_code = 'TST' AND cards.name = 'Island' THEN 3
                   WHEN cards.set_code = 'TST' THEN 2
                   ELSE 1
                 END,
                 'NM', FALSE,
                 CASE
                   WHEN cards.set_code = 'TST' AND cards.name = 'Sol Ring'
                     THEN 10.00
                   ELSE NULL
                 END,
                 CASE
                   WHEN cards.set_code = 'TST' AND cards.name = 'Sol Ring'
                     THEN 'BRL'
                   ELSE 'USD'
                 END,
                 'en', 'have'
          FROM users
          CROSS JOIN cards
          WHERE users.email = @email
            AND (
              (cards.name = 'Sol Ring' AND cards.set_code IN ('TST', 'T2S'))
              OR (cards.name = 'Island' AND cards.set_code = 'TST')
            )
          ON CONFLICT (
            user_id, card_id, condition, is_foil, language, list_type
          ) DO UPDATE
          SET quantity = EXCLUDED.quantity,
              price = EXCLUDED.price,
              currency = EXCLUDED.currency;
        '''),
        parameters: {'email': 's4_08_pricing_$suffix@example.com'},
      );

      final statsResponse = await get('/binder/stats');
      expect(statsResponse.statusCode, 200, reason: statsResponse.body);
      final stats = decode(statsResponse);
      expect(stats['estimated_value'], isNull);
      expect(stats['estimated_value_currency'], isNull);
      expect(stats['estimated_value_brl'], 20.0);
      expect(stats['estimated_value_usd'], 2.5);
      expect(stats['estimated_value_mixed_currency'], isTrue);
      expect(stats['priced_copies_count'], 3);
      expect(stats['price_missing_count'], 3);

      final pricedItemsResponse = await get(
        '/binder?list_type=have&min_price=0&limit=20',
      );
      expect(
        pricedItemsResponse.statusCode,
        200,
        reason: pricedItemsResponse.body,
      );
      final pricedItems = decode(pricedItemsResponse);
      expect(pricedItems['total'], 2);
      final rows = (pricedItems['data'] as List).cast<Map>();
      expect(rows.any((row) => row['card']?['name'] == 'Island'), isFalse);
    },
    skip: skipIntegration,
  );
}
