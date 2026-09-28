@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_format_legality_support.dart';
import '../lib/release_capability_policy.dart';
import '../routes/decks/[id]/analysis/index.dart' as analysis_route;
import '../routes/decks/[id]/cards/index.dart' as add_route;
import '../routes/decks/[id]/cards/replace/index.dart' as replace_route;
import '../routes/decks/[id]/cards/set/index.dart' as set_route;
import '../routes/decks/[id]/index.dart' as deck_route;
import '../routes/decks/[id]/validate/index.dart' as validate_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// DCK-P1-04 em PostgreSQL descartável: uma única verdade de validação
/// estrita por revisão. Legalidade ausente não vira legal na validação
/// estrita (D-28); legalidade que muda rebaixa o deck validado (migration
/// 068); toda mudança devolve a prontidão do deck na mesma resposta; a
/// análise nunca diz "válido" sem a validação estrita; e os seletores de
/// candidatos do Optimize deixam de admitir carta sem legalidade.
///
/// Requer `RUN_DECK_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// já migrado (migration 068).
void main() {
  final enabled = Platform.environment['RUN_DECK_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  late Pool pool;
  late String owner;
  late String islandId;
  late String bearId;
  late String bearReprintId;
  late String elfId;
  late String unknownId;

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));

    final user = await pool.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash)
        VALUES (@username, @email, 'x')
        RETURNING id::text
      '''),
      parameters: {
        'username': 'p104_owner_$suffix',
        'email': 'p104_owner_$suffix@example.invalid',
      },
    );
    owner = user.single.single! as String;

    Future<String> card(
      String name,
      String typeLine, {
      List<String> legalIn = const ['modern', 'commander'],
    }) async {
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO cards (scryfall_id, name, type_line, color_identity)
          VALUES (gen_random_uuid(), @name, @typeLine, '{}')
          RETURNING id::text
        '''),
        parameters: {'name': '$name $suffix', 'typeLine': typeLine},
      );
      final id = result.single.single! as String;
      for (final format in legalIn) {
        await pool.execute(
          Sql.named('''
            INSERT INTO card_legalities (card_id, format, status)
            VALUES (CAST(@id AS uuid), @format, 'legal')
          '''),
          parameters: {'id': id, 'format': format},
        );
      }
      return id;
    }

    islandId = await card('Island', 'Basic Land — Island');
    bearId = await card('Grizzly Bears', 'Creature — Bear');
    bearReprintId = await card('Grizzly Bears', 'Creature — Bear');
    elfId = await card('Llanowar Elves', 'Creature — Elf Druid');
    unknownId = await card(
      'Mystery Card',
      'Creature — Horror',
      legalIn: const [],
    );
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'p104\\_%\\_$suffix'},
    );
    await pool.execute(
      Sql.named('DELETE FROM cards WHERE name LIKE @pattern'),
      parameters: {'pattern': '% $suffix'},
    );
    await pool.close();
  });

  RequestContext context(String method, String path, [Object? body]) =>
      ScriptedRequestContext(
        Request(
          method,
          Uri.parse('http://localhost$path'),
          headers: const {'content-type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        ),
        providers: {
          Pool: pool,
          String: owner,
          ReleaseCapabilityPolicy: releaseCapabilityPolicyWith({
            ...betaCoreCapabilities,
            'ai_analyze_optimize_advisory',
          }),
        },
      );

  Future<Map<String, dynamic>> json(Response response) async =>
      jsonDecode(await response.body()) as Map<String, dynamic>;

  Future<String> seedDeck(
    Map<String, int> cards, {
    String format = 'modern',
  }) async {
    final deck = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format)
        VALUES (CAST(@userId AS uuid), @name, @format)
        RETURNING id::text
      '''),
      parameters: {'userId': owner, 'name': 'Strict $suffix', 'format': format},
    );
    final deckId = deck.single.single! as String;
    for (final entry in cards.entries) {
      await pool.execute(
        Sql.named('''
          INSERT INTO deck_cards (deck_id, card_id, quantity)
          VALUES (CAST(@deckId AS uuid), CAST(@cardId AS uuid), @quantity)
        '''),
        parameters: {
          'deckId': deckId,
          'cardId': entry.key,
          'quantity': entry.value,
        },
      );
    }
    return deckId;
  }

  Future<Response> validate(String deckId) => validate_route.onRequest(
    context('POST', '/decks/$deckId/validate', const {}),
    deckId,
  );

  Future<Map<String, Object?>> validation(String deckId) async {
    final row = await pool.execute(
      Sql.named('''
        SELECT validation_state, validation_reasons::text
        FROM decks WHERE id = CAST(@deckId AS uuid)
      '''),
      parameters: {'deckId': deckId},
    );
    final map = row.single.toColumnMap();
    return {
      'state': map['validation_state'],
      'reasons': jsonDecode(map['validation_reasons'] as String),
    };
  }

  Future<void> setLegality(String cardId, String format, String status) =>
      pool.execute(
        Sql.named('''
          UPDATE card_legalities SET status = @status
          WHERE card_id = CAST(@id AS uuid) AND format = @format
        '''),
        parameters: {'id': cardId, 'format': format, 'status': status},
      );

  test(
    'estrito recusa carta sem legalidade conhecida; montar segue aceitando',
    () async {
      final deckId = await seedDeck({islandId: 56, bearId: 4});
      final added = await add_route.onRequest(
        context('POST', '/decks/$deckId/cards', {
          'card_id': unknownId,
          'quantity': 1,
        }),
        deckId,
      );
      expect(added.statusCode, HttpStatus.ok, reason: 'montar não é estrito');

      final response = await validate(deckId);
      final body = await json(response);

      expect(response.statusCode, HttpStatus.badRequest, reason: '$body');
      expect(body['error'], contains('legalidade conhecida'));
      expect(
        body['review_reasons'],
        containsAll(['strict_validation_failed', 'legality_unknown']),
      );
      final persisted = await validation(deckId);
      expect(persisted['state'], 'draft');
      expect(persisted['reasons'], contains('legality_unknown'));
    },
    skip: skipReason,
  );

  test(
    'legalidade que muda rebaixa só o deck validado do formato com a carta',
    () async {
      final affected = await seedDeck({islandId: 56, bearId: 4});
      final untouched = await seedDeck({islandId: 56, elfId: 4});
      final otherFormat = await seedDeck({
        islandId: 99,
        bearId: 1,
      }, format: 'commander');
      for (final deckId in [affected, untouched]) {
        expect((await validate(deckId)).statusCode, HttpStatus.ok);
      }
      await pool.execute(
        Sql.named('''
        UPDATE decks SET validation_state = 'validated',
               validation_reasons = '[]'::jsonb
        WHERE id = CAST(@deckId AS uuid)
      '''),
        parameters: {'deckId': otherFormat},
      );
      addTearDown(() => setLegality(bearId, 'modern', 'legal'));

      // Regravar o mesmo status não rebaixa nada.
      await setLegality(bearId, 'modern', 'legal');
      expect((await validation(affected))['state'], 'validated');

      await setLegality(bearId, 'modern', 'banned');

      final demoted = await validation(affected);
      expect(demoted['state'], 'draft');
      expect(demoted['reasons'], contains('card_legality_changed'));
      expect((await validation(untouched))['state'], 'validated');
      expect((await validation(otherFormat))['state'], 'validated');
    },
    skip: skipReason,
  );

  test('linha de legalidade apagada ou criada também rebaixa', () async {
    final deleted = await seedDeck({islandId: 56, elfId: 4});
    expect((await validate(deleted)).statusCode, HttpStatus.ok);
    await pool.execute(
      Sql.named('''
        DELETE FROM card_legalities
        WHERE card_id = CAST(@id AS uuid) AND format = 'modern'
      '''),
      parameters: {'id': elfId},
    );
    addTearDown(
      () => pool.execute(
        Sql.named('''
          INSERT INTO card_legalities (card_id, format, status)
          VALUES (CAST(@id AS uuid), 'modern', 'legal')
          ON CONFLICT (card_id, format) DO NOTHING
        '''),
        parameters: {'id': elfId},
      ),
    );
    expect((await validation(deleted))['state'], 'draft');

    // Deck validado antes da D-28 com uma carta sem linha: a linha nova
    // também rebaixa.
    final legacy = await seedDeck({islandId: 56, unknownId: 4});
    await pool.execute(
      Sql.named('''
        UPDATE decks SET validation_state = 'validated',
               validation_reasons = '[]'::jsonb
        WHERE id = CAST(@deckId AS uuid)
      '''),
      parameters: {'deckId': legacy},
    );
    await pool.execute(
      Sql.named('''
        INSERT INTO card_legalities (card_id, format, status)
        VALUES (CAST(@id AS uuid), 'modern', 'not_legal')
      '''),
      parameters: {'id': unknownId},
    );
    addTearDown(
      () => pool.execute(
        Sql.named('''
          DELETE FROM card_legalities WHERE card_id = CAST(@id AS uuid)
        '''),
        parameters: {'id': unknownId},
      ),
    );
    final legacyState = await validation(legacy);
    expect(legacyState['state'], 'draft');
    expect(legacyState['reasons'], contains('card_legality_changed'));
  }, skip: skipReason);

  test(
    'toda mudança devolve a prontidão; só nome mantém o validado',
    () async {
      final deckId = await seedDeck({islandId: 56, bearId: 4});
      expect((await validate(deckId)).statusCode, HttpStatus.ok);

      final renamed = await json(
        await deck_route.onRequest(
          context('PATCH', '/decks/$deckId', {'name': 'Outro nome $suffix'}),
          deckId,
        ),
      );
      expect(renamed['readiness'], containsPair('deck_state', 'validated'));
      expect(renamed['readiness'], containsPair('requires_review', false));

      final changed = await json(
        await set_route.onRequest(
          context('POST', '/decks/$deckId/cards/set', {
            'card_id': bearId,
            'quantity': 3,
          }),
          deckId,
        ),
      );
      final readiness = changed['readiness'] as Map<String, dynamic>;
      expect(readiness['deck_state'], 'draft');
      expect(readiness['review_reasons'], [
        'deck_cards_changed_since_validation',
      ]);
      expect((await validation(deckId))['state'], 'draft');
    },
    skip: skipReason,
  );

  test('troca 1 por 1 da edição tira o validado', () async {
    final deckId = await seedDeck({islandId: 56, bearId: 4});
    expect((await validate(deckId)).statusCode, HttpStatus.ok);

    final swapped = await json(
      await replace_route.onRequest(
        context('POST', '/decks/$deckId/cards/replace', {
          'old_card_id': bearId,
          'new_card_id': bearReprintId,
        }),
        deckId,
      ),
    );

    expect(swapped['readiness'], containsPair('deck_state', 'draft'));
    expect((await validation(deckId))['state'], 'draft');
  }, skip: skipReason);

  test('a análise só diz válido com a validação estrita do deck', () async {
    final deckId = await seedDeck({islandId: 56, bearId: 4});
    Future<Map<String, dynamic>> readiness() async {
      final response = await analysis_route.onRequest(
        context('GET', '/decks/$deckId/analysis'),
        deckId,
      );
      final body = await json(response);
      expect(response.statusCode, HttpStatus.ok, reason: '$body');
      return body['readiness'] as Map<String, dynamic>;
    }

    final before = await readiness();
    expect(before['status'], 'awaiting_strict_validation');
    expect(before['strict_validated'], isFalse);

    expect((await validate(deckId)).statusCode, HttpStatus.ok);
    final after = await readiness();
    expect(after['status'], anyOf('valid_deck', 'ready_with_warnings'));
    expect(after['strict_validated'], isTrue);

    final withUnknown = await seedDeck({islandId: 56, unknownId: 4});
    final unknownResponse = await analysis_route.onRequest(
      context('GET', '/decks/$withUnknown/analysis'),
      withUnknown,
    );
    final unknownBody = await json(unknownResponse);
    final issues =
        (unknownBody['legality'] as Map?)?['issues'] ?? unknownBody['issues'];
    expect(
      jsonEncode(unknownBody),
      contains('legality_unknown'),
      reason: 'a carta sem legalidade aparece como erro: $issues',
    );
    expect(
      (unknownBody['readiness'] as Map)['blockers'],
      contains('legality_or_structure_errors'),
    );
  }, skip: skipReason);

  test(
    'seletor de candidatos do Optimize não admite carta sem legalidade',
    () async {
      final result = await filterOptimizeCardNamesByKnownFormatLegality(
        pool: pool,
        names: ['Llanowar Elves $suffix', 'Mystery Card $suffix'],
        deckFormat: 'modern',
      );

      expect(result.allowed, ['Llanowar Elves $suffix']);
      expect(result.blocked, ['Mystery Card $suffix']);
    },
    skip: skipReason,
  );
}
