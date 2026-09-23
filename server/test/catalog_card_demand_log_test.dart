import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/catalog_read_contract.dart';
import '../routes/cards/printings/index.dart' as printings_route;
import '../routes/cards/resolve/index.dart' as resolve_route;
import 'support/scripted_pool.dart';

/// D-63 (decisão do dono): cada 404 `card_not_in_catalog` deixa uma linha de
/// log estruturada com o nome normalizado, sem dado do usuário, e a contagem
/// de demanda sai do log. Sem tabela e sem escrita no banco.
///
/// Os handlers rodam de verdade, com pool roteirizado; o `print` da zona do
/// teste guarda cada linha que a rota escreve.
void main() {
  // Cabeçalhos com dado do usuário que nunca podem ir para a linha.
  const userHeaders = {
    'authorization': 'Bearer token-do-usuario-123',
    'cookie': 'sessao=cookie-do-usuario',
    'user-agent': 'AppDoUsuario/9.9',
    'x-forwarded-for': '203.0.113.77',
    'content-type': 'application/json',
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

  Future<({Response response, List<String> lines})> capture(
    Future<Response> Function() call,
  ) async {
    final lines = <String>[];
    final response = await runZoned(
      call,
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );
    return (response: response, lines: lines);
  }

  List<Map<String, dynamic>> demandLines(List<String> lines) => [
    for (final line in lines)
      if (line.startsWith('$catalogCardDemandLogMarker '))
        jsonDecode(line.substring(catalogCardDemandLogMarker.length + 1))
            as Map<String, dynamic>,
  ];

  void expectNoUserData(List<String> lines) {
    final text = lines.join('\n');
    for (final value in userHeaders.values) {
      if (value == 'application/json') continue;
      expect(text, isNot(contains(value)));
    }
    expect(text, isNot(contains('user_id')));
  }

  Future<({Response response, List<String> lines})> getPrintings(
    ScriptedPool pool,
    String query,
  ) => capture(
    () => printings_route.onRequest(
      ScriptedRequestContext(
        Request.get(
          Uri.parse('http://localhost/cards/printings?$query'),
          headers: userHeaders,
        ),
        providers: {Pool: pool},
      ),
    ),
  );

  Future<({Response response, List<String> lines})> postResolve(
    ScriptedPool pool,
    Map<String, Object?> body,
  ) => capture(
    () => resolve_route.onRequest(
      ScriptedRequestContext(
        Request.post(
          Uri.parse('http://localhost/cards/resolve'),
          headers: userHeaders,
          body: jsonEncode(body),
        ),
        providers: {Pool: pool},
      ),
    ),
  );

  group('linha de demanda de carta ausente', () {
    test('GET /cards/printings sem edição escreve uma linha, só com o nome '
        'normalizado', () async {
      final pool = ScriptedPool([
        setsTable(),
        identityColumns(),
        scriptedResult(columns: const ['id']),
      ]);

      final result = await getPrintings(
        pool,
        'name=%20%20Carta%20%20QUE%0ANao%09Existe%20&dedupe=false',
      );

      expect(result.response.statusCode, HttpStatus.notFound);
      expect(demandLines(result.lines), [
        {
          'event': 'card_not_in_catalog',
          'route': 'GET /cards/printings',
          'include_tokens': false,
          'name': 'carta que nao existe',
        },
      ]);
      expectNoUserData(result.lines);
      // A resposta continua a mesma: o nome como veio, sem normalizar.
      final body = await result.response.json() as Map<String, dynamic>;
      expect(body['error'], 'card_not_in_catalog');
      expect(body['name'], 'Carta  QUE\nNao\tExiste');
    });

    test('POST /cards/resolve ausente escreve uma linha', () async {
      final pool = ScriptedPool([
        identityColumns(),
        setsTable(),
        scriptedResult(columns: const ['id']),
        scriptedResult(columns: const ['candidate_name']),
      ]);

      final result = await postResolve(pool, {'name': 'Carta Que Nao Existe'});

      expect(result.response.statusCode, HttpStatus.notFound);
      expect(demandLines(result.lines), [
        {
          'event': 'card_not_in_catalog',
          'route': 'POST /cards/resolve',
          'include_tokens': false,
          'name': 'carta que nao existe',
        },
      ]);
      expectNoUserData(result.lines);
    });

    test('POST /cards/resolve com tokens marca include_tokens', () async {
      final pool = ScriptedPool([
        identityColumns(),
        setsTable(),
        scriptedResult(columns: const ['id']),
      ]);

      final result = await postResolve(pool, {
        'name': 'Soldier',
        'include_tokens': true,
      });

      expect(result.response.statusCode, HttpStatus.notFound);
      expect(demandLines(result.lines), [
        {
          'event': 'card_not_in_catalog',
          'route': 'POST /cards/resolve',
          'include_tokens': true,
          'name': 'soldier',
        },
      ]);
    });

    test('carta encontrada e nome ambíguo não escrevem linha', () async {
      const solRingOracleId = '6ad8011d-3471-4369-9d68-b264cc027487';
      final found = await getPrintings(
        ScriptedPool([
          setsTable(),
          identityColumns(),
          scriptedResult(
            columns: const [
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
            ],
            rows: [
              [
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
                null,
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
              ],
            ],
          ),
        ]),
        'name=Sol+Ring&dedupe=false',
      );
      expect(found.response.statusCode, HttpStatus.ok);
      expect(demandLines(found.lines), isEmpty);

      final ambiguous = await postResolve(
        ScriptedPool([
          identityColumns(),
          setsTable(),
          scriptedResult(columns: const ['id']),
          scriptedResult(
            columns: const ['candidate_name'],
            rows: const [
              ['Lightning Bolt'],
              ['Lightning Helix'],
            ],
          ),
        ]),
        {'name': 'lightning'},
      );
      expect(ambiguous.response.statusCode, HttpStatus.conflict);
      expect(demandLines(ambiguous.lines), isEmpty);
    });
  });

  group('normalização do nome', () {
    test('e-mail e segredo no nome não vão para o log', () {
      expect(
        normalizeCatalogDemandName('Fulano@Exemplo.com'),
        '[REDACTED_EMAIL]',
      );
      expect(
        normalizeCatalogDemandName('password: hunter2'),
        'password: [REDACTED]',
      );
    });

    test('a linha é sempre um JSON de uma linha, mesmo com nome hostil', () {
      for (final name in [
        'password: hunter2',
        'Circle of Protection: Red',
        'Borrowing 100,000 Arrows',
        'a"b\\c',
        'linha\nquebrada\r\ne\u0000controle',
        '${'x' * 500}🙂',
      ]) {
        final line = catalogCardDemandLogLine(
          name,
          route: 'GET /cards/printings',
        );
        expect(line, isNot(contains('\n')), reason: name);
        expect(line, startsWith('$catalogCardDemandLogMarker {'), reason: name);
        final fields =
            jsonDecode(line.substring(catalogCardDemandLogMarker.length + 1))
                as Map<String, dynamic>;
        expect(fields.keys, ['event', 'route', 'include_tokens', 'name']);
        final normalized = fields['name'] as String;
        expect(normalized.runes.length, lessThanOrEqualTo(200), reason: name);
        expect(normalized, isNot(contains(RegExp(r'[\u0000-\u001f]'))));
      }
      expect(
        normalizeCatalogDemandName('Circle of Protection: Red'),
        'circle of protection: red',
      );
    });
  });
}
