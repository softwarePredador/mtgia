import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/decks/[id]/pricing/index.dart' as pricing_route;
import 'support/scripted_pool.dart';

/// Decisões D-35 e D-62 do dono: `POST /decks/:id/pricing` lê o preço do
/// banco, que o job diário do catálogo (`BT-CAT-01`) mantém.
///
/// Antes, a rota buscava na Scryfall, a pedido do usuário, o preço de até 10
/// cartas sem preço (todas, com `force`) e gravava o resultado em `cards`.
/// Estes testes sobem o handler de verdade, com um pool que registra cada
/// consulta e um cliente HTTP que conta toda chamada de saída.
void main() {
  const userId = '0f0f0f0f-0000-4000-8000-000000000001';
  const deckId = '0d0d0d0d-0000-4000-8000-000000000002';
  const solRingOracleId = '6ad8011d-3471-4369-9d68-b264cc027487';
  const islandOracleId = 'b2c6aa39-2d2a-459c-a555-fb48ba993373';
  final priceDate = DateTime.utc(2026, 9, 22, 9);
  final snapshotAt = DateTime.utc(2026, 9, 23, 17);

  const deckCardColumns = [
    'card_id',
    'quantity',
    'is_commander',
    'name',
    'scryfall_id',
    'set_code',
    'price_usd',
    'price',
    'price_source',
    'price_updated_at',
  ];

  // Linhas-alias Oracle (scryfall_id = oracle_id), para onde os decks apontam.
  // O Sol Ring tem o preço da D-62 em `price_usd` e o espelho legado antigo em
  // `price`; a Ilha sem preço era o gatilho da busca na Scryfall.
  final solRing = <Object?>[
    '11111111-1111-4111-8111-111111111111',
    1,
    false,
    'Sol Ring',
    solRingOracleId,
    'cmm',
    '1.99',
    '1.50',
    'scryfall',
    priceDate,
  ];
  final islandWithoutPrice = <Object?>[
    '22222222-2222-4222-8222-222222222222',
    2,
    false,
    'Island',
    islandOracleId,
    'tst',
    null,
    null,
    null,
    null,
  ];
  final islandWithPrice = <Object?>[
    '22222222-2222-4222-8222-222222222222',
    2,
    false,
    'Island',
    islandOracleId,
    'tst',
    '0.25',
    '0.25',
    'mtgjson',
    priceDate,
  ];

  // Se a rota voltar a buscar preço, recebe este, bem diferente do banco.
  final scryfallCard = {
    'object': 'card',
    'id': '33333333-3333-4333-8333-333333333333',
    'oracle_id': solRingOracleId,
    'name': 'Sol Ring',
    'prices': {'usd': '9.99', 'usd_foil': '19.99'},
  };

  ScriptedPool poolFor(List<List<Object?>> deckCards) => ScriptedPool([
    scriptedResult(
      columns: const ['id'],
      rows: const [
        [deckId],
      ],
    ),
    scriptedResult(columns: deckCardColumns, rows: deckCards),
    scriptedResult(
      columns: const ['pricing_updated_at'],
      rows: [
        [snapshotAt],
      ],
    ),
  ]);

  final dml = RegExp(
    r'\b(INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|TRUNCATE|ON\s+CONFLICT|MERGE\s+INTO)\b',
    caseSensitive: false,
  );
  final cardsWrite = RegExp(
    r'\b(UPDATE\s+cards|INSERT\s+INTO\s+cards|DELETE\s+FROM\s+cards)\b',
    caseSensitive: false,
  );

  Future<({Response response, List<Uri> upstream})> postPricing(
    ScriptedPool pool,
    Object? body,
  ) async {
    final upstream = <Uri>[];
    final response = await http.runWithClient(
      () => pricing_route.onRequest(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost/decks/$deckId/pricing'),
            headers: const {'content-type': 'application/json'},
            body: body,
          ),
          providers: {Pool: pool, String: userId},
        ),
        deckId,
      ),
      () => MockClient((request) async {
        upstream.add(request.url);
        return http.Response(jsonEncode(scryfallCard), 200);
      }),
    );
    return (response: response, upstream: upstream);
  }

  // Duas leituras e o snapshot do próprio deck; nada em `cards`.
  void expectReadsAndOnlyTheDeckSnapshot(ScriptedPool pool) {
    final trail = pool.queries.join('\n---\n');
    expect(pool.executedCount, 3, reason: trail);
    expect(pool.exhausted, isTrue, reason: trail);
    expect(pool.queries[0], isNot(matches(dml)), reason: trail);
    expect(pool.queries[1], isNot(matches(dml)), reason: trail);
    expect(pool.queries[2], contains('UPDATE decks'), reason: trail);
    expect(
      pool.queries[2],
      contains('WHERE id = @deckId AND user_id = @userId'),
      reason: trail,
    );
    for (final sql in pool.queries) {
      expect(sql, isNot(matches(cardsWrite)), reason: sql);
    }
  }

  group('POST /decks/:id/pricing lê o preço do banco', () {
    test('carta sem preço não dispara a Scryfall nem escrita em cards, '
        'com qualquer corpo', () async {
      final bodies = <String, Object?>{
        // O que o app envia (deck_provider_support_mutation.dart).
        'force false': jsonEncode({'force': false}),
        'force e refresh_missing': jsonEncode({
          'force': true,
          'refresh_missing': true,
        }),
        'sem corpo': null,
        'corpo inválido': 'isto não é JSON',
      };

      for (final entry in bodies.entries) {
        final pool = poolFor([solRing, islandWithoutPrice]);

        final result = await postPricing(pool, entry.value);

        expect(result.upstream, isEmpty, reason: entry.key);
        expectReadsAndOnlyTheDeckSnapshot(pool);
        expect(result.response.statusCode, HttpStatus.ok, reason: entry.key);

        final body = await result.response.json() as Map<String, dynamic>;
        expect(body['deck_id'], deckId, reason: entry.key);
        expect(body['currency'], 'USD', reason: entry.key);
        expect(body['estimated_total_usd'], 1.99, reason: entry.key);
        expect(body['known_price_cards'], 1, reason: entry.key);
        expect(body['missing_price_cards'], 2, reason: entry.key);
        expect(body['total_cards'], 3, reason: entry.key);
        expect(body['pricing_status'], 'partial', reason: entry.key);
        expect(body['price_source'], 'scryfall', reason: entry.key);
        expect(
          body['pricing_updated_at'],
          snapshotAt.toIso8601String(),
          reason: entry.key,
        );
        expect(body['cache_status'], 'cached', reason: entry.key);
        expect(body['refreshed_price_cards'], 0, reason: entry.key);
        expect(body['failed_refresh_rows'], 0, reason: entry.key);
        expect(body['deferred_refresh_rows'], 0, reason: entry.key);

        final items = (body['items'] as List).cast<Map<String, dynamic>>();
        final sol = items.singleWhere((item) => item['name'] == 'Sol Ring');
        expect(sol['unit_price_usd'], 1.99, reason: entry.key);
        expect(sol['price_source'], 'scryfall', reason: entry.key);
        expect(
          sol['price_updated_at'],
          priceDate.toIso8601String(),
          reason: entry.key,
        );
        final island = items.singleWhere((item) => item['name'] == 'Island');
        expect(island['unit_price_usd'], isNull, reason: entry.key);
        expect(island['line_total_usd'], isNull, reason: entry.key);
        expect(island['price_source'], 'unknown', reason: entry.key);

        // O snapshot do deck guarda o mesmo total, só para o dono.
        final snapshot = pool.parameters[2]! as Map<String, dynamic>;
        expect(snapshot['total'], 1.99, reason: entry.key);
        expect(snapshot['missing'], 2, reason: entry.key);
        expect(snapshot['source'], 'scryfall', reason: entry.key);
        expect(snapshot['currency'], 'USD', reason: entry.key);
        expect(snapshot['deckId'], deckId, reason: entry.key);
        expect(snapshot['userId'], userId, reason: entry.key);
      }
    });

    test('force repetido não amplifica nada e o total sai do banco', () async {
      final upstream = <Uri>[];
      for (var attempt = 0; attempt < 5; attempt++) {
        final pool = poolFor([solRing, islandWithPrice]);

        final result = await postPricing(
          pool,
          jsonEncode({'force': true, 'refresh_missing': true}),
        );

        upstream.addAll(result.upstream);
        expect(upstream, isEmpty, reason: 'tentativa ${attempt + 1}');
        expectReadsAndOnlyTheDeckSnapshot(pool);
        expect(result.response.statusCode, HttpStatus.ok);
        final body = await result.response.json() as Map<String, dynamic>;
        expect(body['estimated_total_usd'], 2.49);
        expect(body['known_price_cards'], 3);
        expect(body['missing_price_cards'], 0);
        expect(body['pricing_status'], 'complete');
        expect(body['price_source'], 'mixed');
        expect(body['cache_status'], 'cached');
        expect(body['refreshed_price_cards'], 0);
      }
    });

    test('deck de outro usuário responde 404 depois de uma leitura', () async {
      final pool = ScriptedPool([
        scriptedResult(columns: const ['id']),
      ]);

      final result = await postPricing(pool, jsonEncode({'force': true}));

      expect(result.response.statusCode, HttpStatus.notFound);
      expect(result.upstream, isEmpty);
      expect(pool.executedCount, 1);
      expect(pool.queries.single, isNot(matches(dml)));
      expect(pool.parameters.single, {'deckId': deckId, 'userId': userId});
    });

    test('a rota e as bibliotecas que ela importa não abrem cliente HTTP nem '
        'gravam em cards', () {
      const route = 'routes/decks/[id]/pricing/index.dart';
      final libImport = RegExp(
        r"^import '((?:\.\./)+lib/[^']+\.dart)';",
        multiLine: true,
      );
      final httpClient = RegExp(
        r'package:http/|HttpClient\(|api\.scryfall\.com',
      );
      final source = File(route).readAsStringSync();
      final checked = <String>{route};
      for (final match in libImport.allMatches(source)) {
        checked.add(p.normalize(p.join(p.dirname(route), match.group(1)!)));
      }

      expect(checked, contains('lib/pricing_contract.dart'));
      for (final path in checked) {
        final text = File(path).readAsStringSync();
        expect(text, isNot(matches(httpClient)), reason: path);
        expect(text, isNot(matches(cardsWrite)), reason: path);
      }
      // A única escrita da rota é o snapshot do próprio deck.
      expect(dml.allMatches(source), hasLength(1));
      expect(source, contains('UPDATE decks'));
      expect(source, contains('WHERE id = @deckId AND user_id = @userId'));
    });
  });
}
