import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/cards/printings/index.dart' as printings_route;
import 'support/scripted_pool.dart';

/// BT-CAT-04 (decisão D-35 do dono): `GET /cards/printings` só lê.
///
/// Antes, `sync=true` com 0 ou 1 edição local chamava a Scryfall duas vezes e
/// gravava em `cards` e `sets`, por chamador anônimo (achado 9 dos fluxos).
/// Estes testes sobem o handler de verdade, com um pool que registra cada
/// consulta e um cliente HTTP que conta toda chamada de saída.
void main() {
  const printingColumns = [
    'id',
    'scryfall_id',
    'oracle_id',
    'layout',
    'card_faces_json',
    'name',
    'mana_cost',
    'type_line',
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

  const solRingOracleId = '6ad8011d-3471-4369-9d68-b264cc027487';
  final aliasRow = <Object?>[
    '11111111-1111-4111-8111-111111111111',
    solRingOracleId,
    solRingOracleId,
    'normal',
    null,
    'Sol Ring',
    '{1}',
    'Artifact',
    '{T}: Add {C}{C}.',
    null,
    null,
    <String>[],
    <String>[],
    'https://api.scryfall.com/cards/named?exact=Sol+Ring&format=image',
    'lea',
    'Limited Edition Alpha',
    DateTime.utc(1993, 8, 5),
    'uncommon',
    false,
    null,
    null,
    null,
    '270',
    false,
  ];

  // Resposta que a versão antiga usava para importar: a carta e a lista de
  // impressões. Se a rota voltar a chamar a Scryfall, ela recebe isto.
  final scryfallNamed = {
    'object': 'card',
    'id': '22222222-2222-4222-8222-222222222222',
    'oracle_id': solRingOracleId,
    'name': 'Sol Ring',
    'prints_search_uri':
        'https://api.scryfall.com/cards/search?q=oracleid%3A$solRingOracleId&unique=prints',
  };
  final scryfallPrints = {
    'object': 'list',
    'data': [
      {
        'id': '22222222-2222-4222-8222-222222222222',
        'oracle_id': solRingOracleId,
        'name': 'Sol Ring',
        'set': 'cmm',
        'set_name': 'Commander Masters',
        'released_at': '2023-08-04',
        'collector_number': '410',
        'games': ['paper'],
        'layout': 'normal',
        'rarity': 'uncommon',
        'reserved': false,
        'foil': true,
      },
    ],
  };

  ScriptedPool poolReturning(List<List<Object?>> rows) => ScriptedPool([
    scriptedResult(
      columns: const ['to_regclass'],
      rows: const [
        ['public.sets'],
      ],
    ),
    scriptedResult(
      columns: const ['matched_columns'],
      rows: const [
        [3],
      ],
    ),
    scriptedResult(columns: printingColumns, rows: rows),
  ]);

  final dml = RegExp(
    r'\b(INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|TRUNCATE|ON\s+CONFLICT|MERGE\s+INTO)\b',
    caseSensitive: false,
  );

  Future<({Response response, List<Uri> upstream})> getPrintings(
    ScriptedPool pool,
    String query,
  ) async {
    final upstream = <Uri>[];
    final response = await http.runWithClient(
      () => printings_route.onRequest(
        ScriptedRequestContext(
          Request.get(Uri.parse('http://localhost/cards/printings?$query')),
          providers: {Pool: pool},
        ),
      ),
      () => MockClient((request) async {
        upstream.add(request.url);
        final body =
            request.url.path.endsWith('/cards/named')
                ? scryfallNamed
                : scryfallPrints;
        return http.Response(jsonEncode(body), 200);
      }),
    );
    return (response: response, upstream: upstream);
  }

  void expectOnlyTheThreeReads(ScriptedPool pool) {
    expect(pool.executedCount, 3, reason: pool.queries.join('\n---\n'));
    expect(pool.exhausted, isTrue);
    for (final sql in pool.queries) {
      expect(sql, isNot(matches(dml)), reason: sql);
    }
  }

  group('GET /cards/printings é somente leitura', () {
    test(
      'sync=true com uma edição local não chama a Scryfall nem escreve',
      () async {
        final pool = poolReturning([aliasRow]);

        final result = await getPrintings(
          pool,
          'name=Sol+Ring&limit=50&dedupe=false&sync=true',
        );

        expect(result.response.statusCode, HttpStatus.ok);
        expect(result.upstream, isEmpty);
        expectOnlyTheThreeReads(pool);
        final body = await result.response.json() as Map<String, dynamic>;
        expect(body['total_returned'], 1);
        expect((body['data'] as List).single['id'], aliasRow.first);
      },
    );

    test(
      'sem edição local responde 404 card_not_in_catalog e não importa nada',
      () async {
        final pool = poolReturning(const []);

        final result = await getPrintings(
          pool,
          'name=Sol+Ring&limit=50&dedupe=false&sync=true',
        );

        // BT-CAT-02 (D-35): carta ausente é 404 com código estável.
        expect(result.response.statusCode, HttpStatus.notFound);
        expect(result.upstream, isEmpty);
        expectOnlyTheThreeReads(pool);
        final body = await result.response.json() as Map<String, dynamic>;
        expect(body['error'], 'card_not_in_catalog');
        expect(body['name'], 'Sol Ring');
        expect(body['message'], contains('não está no catálogo do BrewTact'));
      },
    );

    test(
      'repetir a chamada de carta de impressão única não amplifica nada',
      () async {
        final upstream = <Uri>[];
        for (var attempt = 0; attempt < 5; attempt++) {
          final pool = poolReturning([aliasRow]);
          final result = await getPrintings(
            pool,
            'name=Sol+Ring&dedupe=false&sync=true',
          );
          expect(result.response.statusCode, HttpStatus.ok);
          upstream.addAll(result.upstream);
          expectOnlyTheThreeReads(pool);
        }
        expect(upstream, isEmpty);
      },
    );
  });
}
