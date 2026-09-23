import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/catalog_read_contract.dart';
import '../routes/cards/resolve/index.dart' as resolve_route;
import 'support/scripted_pool.dart';

/// BT-CAT-02 (decisão D-35 do dono): `POST /cards/resolve` só lê.
///
/// Antes, um nome ausente do catálogo levava a rota à Scryfall (busca fuzzy,
/// busca textual e todas as impressões) e a INSERT em `cards`, `sets` e
/// `card_legalities`, por chamador anônimo. Agora carta ausente é 404
/// `card_not_in_catalog` com frase em português, sem chamada externa e sem
/// escrita. O handler roda de verdade, com pool roteirizado e um cliente HTTP
/// que conta toda chamada de saída.
void main() {
  const resolveColumns = [
    'id',
    'scryfall_id',
    'name',
    'mana_cost',
    'type_line',
    'oracle_id',
    'layout',
    'card_faces_json',
    'oracle_text',
    'power',
    'toughness',
    'colors',
    'color_identity',
    'image_url',
    'set_code',
    'set_name',
    'set_release_date',
    'rarity',
    'is_reserved',
    'price',
    'price_source',
    'price_updated_at',
    'collector_number',
    'foil',
  ];

  const boltOracleId = '4457ed35-7c10-48c8-9776-456485fdf070';
  final boltRow = <Object?>[
    '33333333-3333-4333-8333-333333333333',
    '44444444-4444-4444-8444-444444444444',
    'Lightning Bolt',
    '{R}',
    'Instant',
    boltOracleId,
    'normal',
    null,
    'Lightning Bolt deals 3 damage to any target.',
    null,
    null,
    <String>['R'],
    <String>['R'],
    null,
    '2XM',
    'Double Masters',
    DateTime.utc(2020, 8, 7),
    'uncommon',
    false,
    null,
    null,
    null,
    '117',
    true,
  ];

  // O que a versão antiga importaria se voltasse a chamar a Scryfall.
  final scryfallCard = {
    'object': 'card',
    'id': '55555555-5555-4555-8555-555555555555',
    'oracle_id': '66666666-6666-4666-8666-666666666666',
    'name': 'Carta Que Nao Existe',
    'set': 'brt',
    'games': ['paper'],
    'layout': 'normal',
    'legalities': {'commander': 'legal'},
  };

  Result identityColumns() => scriptedResult(
    columns: const ['matched_columns'],
    rows: const [
      [3],
    ],
  );
  Result setsTable() => scriptedResult(
    columns: const ['to_regclass'],
    rows: const [
      ['public.sets'],
    ],
  );
  Result noRows(List<String> columns) => scriptedResult(columns: columns);

  final dml = RegExp(
    r'\b(INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|TRUNCATE|ON\s+CONFLICT|MERGE\s+INTO)\b',
    caseSensitive: false,
  );

  Future<({Response response, List<Uri> upstream})> resolve(
    ScriptedPool pool,
    Map<String, Object?> body,
  ) async {
    final upstream = <Uri>[];
    final response = await http.runWithClient(
      () => resolve_route.onRequest(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost/cards/resolve'),
            body: jsonEncode(body),
          ),
          providers: {Pool: pool},
        ),
      ),
      () => MockClient((request) async {
        upstream.add(request.url);
        return http.Response(jsonEncode(scryfallCard), 200);
      }),
    );
    return (response: response, upstream: upstream);
  }

  void expectOnlyReads(ScriptedPool pool, int expectedQueries) {
    expect(
      pool.executedCount,
      expectedQueries,
      reason: pool.queries.join('\n---\n'),
    );
    expect(pool.exhausted, isTrue);
    for (final sql in pool.queries) {
      expect(sql, isNot(matches(dml)), reason: sql);
    }
  }

  group('POST /cards/resolve é somente leitura', () {
    test(
      'carta ausente responde 404 card_not_in_catalog sem Scryfall nem escrita',
      () async {
        final pool = ScriptedPool([
          identityColumns(),
          setsTable(),
          noRows(resolveColumns),
          noRows(const ['candidate_name']),
        ]);

        final result = await resolve(pool, {'name': 'Carta Que Nao Existe'});

        expect(result.response.statusCode, HttpStatus.notFound);
        expect(result.upstream, isEmpty);
        expectOnlyReads(pool, 4);
        final body = await result.response.json() as Map<String, dynamic>;
        expect(body['error'], 'card_not_in_catalog');
        expect(body['name'], 'Carta Que Nao Existe');
        expect(
          body['message'],
          'A carta "Carta Que Nao Existe" não está no catálogo do BrewTact. '
          'Confira o nome; carta nova entra na próxima atualização do catálogo.',
        );
      },
    );

    test(
      'token ausente também é 404, sem busca de token na Scryfall',
      () async {
        final pool = ScriptedPool([
          identityColumns(),
          setsTable(),
          noRows(resolveColumns),
        ]);

        final result = await resolve(pool, {
          'name': 'Carta Que Nao Existe',
          'include_tokens': true,
        });

        expect(result.response.statusCode, HttpStatus.notFound);
        expect(result.upstream, isEmpty);
        expectOnlyReads(pool, 3);
        final body = await result.response.json() as Map<String, dynamic>;
        expect(body['error'], 'card_not_in_catalog');
      },
    );

    test('carta do catálogo continua resolvendo pelo banco local', () async {
      final pool = ScriptedPool([
        identityColumns(),
        setsTable(),
        scriptedResult(columns: resolveColumns, rows: [boltRow]),
      ]);

      final result = await resolve(pool, {'name': 'lightning bolt'});

      expect(result.response.statusCode, HttpStatus.ok);
      expect(result.upstream, isEmpty);
      expectOnlyReads(pool, 3);
      final body = await result.response.json() as Map<String, dynamic>;
      expect(body['source'], 'local');
      expect((body['data'] as List).single['oracle_id'], boltOracleId);
    });

    test('nome ambíguo continua 409 com candidatos, sem Scryfall', () async {
      final pool = ScriptedPool([
        identityColumns(),
        setsTable(),
        noRows(resolveColumns),
        scriptedResult(
          columns: const ['candidate_name'],
          rows: const [
            ['Lightning Bolt'],
            ['Lightning Helix'],
          ],
        ),
      ]);

      final result = await resolve(pool, {'name': 'lightning'});

      expect(result.response.statusCode, HttpStatus.conflict);
      expect(result.upstream, isEmpty);
      expectOnlyReads(pool, 4);
    });
  });

  test('a frase de carta ausente limita o nome devolvido', () {
    final longName = 'x' * 500;
    final message = cardNotInCatalogMessage(longName);
    expect(message.length, lessThan(400));
    expect(message, contains('não está no catálogo do BrewTact'));
  });
}
