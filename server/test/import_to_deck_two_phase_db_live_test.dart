@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/decks/deck_review_artifact.dart';
import '../lib/import_to_deck_merge_support.dart';
import '../lib/release_capability_policy.dart';
import '../routes/decks/[id]/cards/index.dart' as add_route;
import '../routes/decks/[id]/changes/[eventId]/undo/index.dart' as undo_route;
import '../routes/import/to-deck/index.dart' as commit_route;
import '../routes/import/to-deck/preview/index.dart' as preview_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// DCK-P0-03 em PostgreSQL descartável: import em deck existente em duas
/// fases. A prévia calcula a diferença completa e emite o artefato sem
/// escrever; o commit exige o artefato, aplica exatamente a lista da prévia,
/// recusa deck mudado (409) e regra que passou a falhar (400) sem escrever, e
/// o desfazer universal volta o deck de antes. As rotas rodam de verdade.
///
/// Requer `RUN_DECK_DB_TESTS=1`, `JWT_SECRET` (o segredo do artefato cai nele)
/// e as variáveis `DB_*` de um banco descartável já migrado.
void main() {
  final enabled = Platform.environment['RUN_DECK_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  late Pool pool;
  late String owner;
  late String stranger;
  late String islandId;
  late String bearId;
  late String elfId;
  late String goblinId;
  late String commanderId;

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

    Future<String> user(String key) async {
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash)
          VALUES (@username, @email, 'x')
          RETURNING id::text
        '''),
        parameters: {
          'username': 'dck03_${key}_$suffix',
          'email': 'dck03_${key}_$suffix@example.invalid',
        },
      );
      return result.single.single! as String;
    }

    Future<String> card(String name, String typeLine) async {
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO cards (scryfall_id, name, type_line, color_identity)
          VALUES (gen_random_uuid(), @name, @typeLine, '{}')
          RETURNING id::text
        '''),
        parameters: {'name': '$name $suffix', 'typeLine': typeLine},
      );
      final id = result.single.single! as String;
      for (final format in const ['modern', 'commander']) {
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

    owner = await user('owner');
    stranger = await user('stranger');
    islandId = await card('Island', 'Basic Land — Island');
    bearId = await card('Grizzly Bears', 'Creature — Bear');
    elfId = await card('Llanowar Elves', 'Creature — Elf Druid');
    goblinId = await card('Goblin Guide', 'Creature — Goblin Scout');
    commanderId = await card('Ezuri', 'Legendary Creature — Elf Warrior');
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'dck03\\_%\\_$suffix'},
    );
    await pool.execute(
      Sql.named('DELETE FROM cards WHERE name LIKE @pattern'),
      parameters: {'pattern': '% $suffix'},
    );
    await pool.close();
  });

  RequestContext context(
    String method,
    String path,
    Object? body, {
    String? asUser,
  }) => ScriptedRequestContext(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: const {'content-type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    ),
    providers: {
      Pool: pool,
      String: asUser ?? owner,
      ReleaseCapabilityPolicy: releaseCapabilityPolicyWith(
        betaCoreCapabilities,
      ),
    },
  );

  Future<Map<String, dynamic>> json(Response response) async =>
      jsonDecode(await response.body()) as Map<String, dynamic>;

  Future<String> seedDeck({
    String userId = '',
    String format = 'modern',
    Map<String, int> cards = const {},
    String? commander,
  }) async {
    final deck = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format)
        VALUES (CAST(@userId AS uuid), @name, @format)
        RETURNING id::text
      '''),
      parameters: {
        'userId': userId.isEmpty ? owner : userId,
        'name': 'Import $suffix',
        'format': format,
      },
    );
    final deckId = deck.single.single! as String;
    Future<void> insert(String cardId, int quantity, bool isCommander) =>
        pool.execute(
          Sql.named('''
            INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
            VALUES (CAST(@deckId AS uuid), CAST(@cardId AS uuid), @quantity,
                    @isCommander)
          '''),
          parameters: {
            'deckId': deckId,
            'cardId': cardId,
            'quantity': quantity,
            'isCommander': isCommander,
          },
        );
    if (commander != null) await insert(commander, 1, true);
    for (final entry in cards.entries) {
      await insert(entry.key, entry.value, false);
    }
    return deckId;
  }

  Future<Map<String, Object?>> state(String deckId) async {
    final deck = await pool.execute(
      Sql.named('''
        SELECT revision, validation_state, validation_reasons::text
        FROM decks WHERE id = CAST(@deckId AS uuid)
      '''),
      parameters: {'deckId': deckId},
    );
    final cards = await pool.execute(
      Sql.named('''
        SELECT card_id::text, quantity::int, is_commander
        FROM deck_cards WHERE deck_id = CAST(@deckId AS uuid)
        ORDER BY card_id
      '''),
      parameters: {'deckId': deckId},
    );
    final events = await pool.execute(
      Sql.named('''
        SELECT operation FROM deck_change_events
        WHERE deck_id = CAST(@deckId AS uuid) ORDER BY revision_after
      '''),
      parameters: {'deckId': deckId},
    );
    return {
      ...deck.single.toColumnMap(),
      'cards': {
        for (final row in cards)
          row[0]! as String: row[2] == true ? 'cmd:${row[1]}' : '${row[1]}',
      },
      'events': [for (final row in events) row[0]],
    };
  }

  Future<Map<String, dynamic>> preview(
    String deckId,
    String list, {
    bool replaceAll = false,
    String? asUser,
  }) async {
    final response = await preview_route.onRequest(
      context('POST', '/import/to-deck/preview', {
        'deck_id': deckId,
        'list': list,
        'replace_all': replaceAll,
      }, asUser: asUser),
    );
    final body = await json(response);
    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    return body;
  }

  Future<Response> commit(String deckId, Object? artifact, {String? asUser}) =>
      commit_route.onRequest(
        context('POST', '/import/to-deck', {
          'deck_id': deckId,
          if (artifact != null) 'review_artifact': artifact,
        }, asUser: asUser),
      );

  test(
    'a prévia devolve a diferença completa e o artefato, sem escrever',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20, bearId: 2});
      final before = await state(deckId);

      final body = await preview(
        deckId,
        '2 Llanowar Elves $suffix\n1 Grizzly Bears $suffix',
      );

      expect(await state(deckId), before, reason: 'a prévia não escreve');
      expect(body['can_commit'], isTrue);
      expect(body['revision'], 1);
      final diff = body['diff'] as Map<String, dynamic>;
      expect(diff['added'], [
        {
          'card_id': elfId,
          'name': 'Llanowar Elves $suffix',
          'quantity': 2,
          'is_commander': false,
          'condition': 'NM',
        },
      ]);
      expect(diff['changed'], [
        {
          'card_id': bearId,
          'name': 'Grizzly Bears $suffix',
          'quantity_before': 2,
          'quantity_after': 3,
          'is_commander_before': false,
          'is_commander_after': false,
          'condition_before': 'NM',
          'condition_after': 'NM',
        },
      ]);
      expect(diff['removed'], isEmpty);
      expect(diff['unchanged_count'], 1);
      expect(diff['total_before'], 22);
      expect(diff['total_after'], 25);
      final artifact = body['review_artifact'] as Map<String, dynamic>;
      expect(artifact['kind'], importToDeckReviewArtifactKind);
      expect(artifact['token'], startsWith('drv1.'));
    },
    skip: skipReason,
  );

  test(
    'confirmar aplica exatamente a lista da prévia e grava o evento',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20, bearId: 2});
      final body = await preview(deckId, '2 Llanowar Elves $suffix');

      final response = await commit(deckId, body['review_artifact']);
      final committed = await json(response);

      expect(response.statusCode, HttpStatus.ok, reason: '$committed');
      expect(committed['change_operation'], 'import_to_deck');
      expect(committed['revision'], 2);
      expect(committed['cards_added'], 1);
      expect(committed['total_cards'], 24);
      final after = await state(deckId);
      expect(after['cards'], {islandId: '20', bearId: '2', elfId: '2'});
      expect(after['events'], ['import_to_deck']);
    },
    skip: skipReason,
  );

  test(
    'replace_all troca a lista e mantém o comandante que a lista não traz',
    () async {
      final deckId = await seedDeck(
        format: 'commander',
        commander: commanderId,
        cards: {islandId: 30, bearId: 1},
      );

      final body = await preview(
        deckId,
        '40 Island $suffix\n1 Llanowar Elves $suffix',
        replaceAll: true,
      );

      expect(body['commander_preserved'], isTrue);
      final diff = body['diff'] as Map<String, dynamic>;
      expect(
        (diff['removed'] as List).map((card) => (card as Map)['card_id']),
        [bearId],
      );
      expect(diff['commanders_after'], ['Ezuri $suffix']);

      final response = await commit(deckId, body['review_artifact']);
      expect(
        response.statusCode,
        HttpStatus.ok,
        reason: '${await json(response)}',
      );
      expect((await state(deckId))['cards'], {
        islandId: '40',
        elfId: '1',
        commanderId: 'cmd:1',
      });
    },
    skip: skipReason,
  );

  test(
    'deck mudado depois da prévia: 409 import_preview_stale, sem escrever',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20});
      final body = await preview(deckId, '2 Llanowar Elves $suffix');
      final added = await add_route.onRequest(
        context('POST', '/decks/$deckId/cards', {
          'card_id': goblinId,
          'quantity': 1,
        }),
        deckId,
      );
      expect(added.statusCode, HttpStatus.ok);
      final before = await state(deckId);

      final response = await commit(deckId, body['review_artifact']);
      final rejected = await json(response);

      expect(response.statusCode, HttpStatus.conflict, reason: '$rejected');
      expect(rejected['error_code'], 'import_preview_stale');
      expect(rejected['review_error'], 'stale_deck_revision');
      expect(await state(deckId), before);
    },
    skip: skipReason,
  );

  test(
    'artefato adulterado, expirado ou de outro deck: 409, sem escrever',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20});
      final otherDeckId = await seedDeck(cards: {islandId: 20});
      final body = await preview(deckId, '2 Llanowar Elves $suffix');
      final otherBody = await preview(otherDeckId, '2 Llanowar Elves $suffix');
      final token =
          (body['review_artifact'] as Map<String, dynamic>)['token'] as String;
      final parts = token.split('.');
      final payload =
          jsonDecode(
                utf8.decode(
                  base64Url.decode(
                    '${parts[1]}${'=' * ((4 - parts[1].length % 4) % 4)}',
                  ),
                ),
              )
              as Map<String, dynamic>;
      final expired = issueDeckReviewArtifact(
        signingSecret: resolveDeckReviewSigningSecret(
          environment: Platform.environment,
        ),
        kind: importToDeckReviewArtifactKind,
        ownerId: owner,
        deckId: deckId,
        deckRevision: payload['deck_revision'] as int,
        deckSignature: payload['deck_signature'] as String,
        inputHash: payload['input_hash'] as String,
        constraintsHash: payload['constraints_hash'] as String,
        body: {
          'format': payload['format'],
          'replace_all': payload['replace_all'],
          'cards': payload['cards'],
        },
        issuedAt: DateTime.now().toUtc().subtract(const Duration(hours: 25)),
      );
      final before = await state(deckId);

      final cases = <String, Object>{
        'invalid_signature': '${parts[0]}.${parts[1]}.AAAA',
        'expired_token': expired,
        'deck_binding_mismatch': otherBody['review_artifact'] as Object,
      };
      for (final MapEntry(key: code, value: artifact) in cases.entries) {
        final response = await commit(deckId, artifact);
        final rejected = await json(response);
        expect(response.statusCode, HttpStatus.conflict, reason: code);
        expect(rejected['error_code'], 'import_review_invalid', reason: code);
        expect(rejected['review_error'], code, reason: code);
      }
      expect(await state(deckId), before);

      final foreign = await commit(deckId, token, asUser: stranger);
      expect(foreign.statusCode, HttpStatus.notFound);
      expect(await state(deckId), before);
    },
    skip: skipReason,
  );

  test('sem artefato: 428 import_review_required, sem escrever', () async {
    final deckId = await seedDeck(cards: {islandId: 20});
    final before = await state(deckId);

    final response = await commit_route.onRequest(
      context('POST', '/import/to-deck', {
        'deck_id': deckId,
        'list': '2 Llanowar Elves $suffix',
        'replace_all': true,
      }),
    );

    expect(response.statusCode, 428);
    expect((await json(response))['error_code'], 'import_review_required');
    expect(await state(deckId), before);
  }, skip: skipReason);

  test(
    'regra que passou a falhar depois da prévia: 400 e o deck fica igual',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20});
      final body = await preview(deckId, '1 Goblin Guide $suffix');
      await pool.execute(
        Sql.named('''
        UPDATE card_legalities SET status = 'banned'
        WHERE card_id = CAST(@id AS uuid) AND format = 'modern'
      '''),
        parameters: {'id': goblinId},
      );
      addTearDown(
        () => pool.execute(
          Sql.named('''
          UPDATE card_legalities SET status = 'legal'
          WHERE card_id = CAST(@id AS uuid) AND format = 'modern'
        '''),
          parameters: {'id': goblinId},
        ),
      );
      final before = await state(deckId);

      final response = await commit(deckId, body['review_artifact']);

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await state(deckId), before, reason: 'a falha preserva o deck');
    },
    skip: skipReason,
  );

  test('desfazer o import volta exatamente o deck de antes', () async {
    final deckId = await seedDeck(cards: {islandId: 20, bearId: 2});
    final original = await state(deckId);
    final body = await preview(
      deckId,
      '24 Island $suffix\n4 Goblin Guide $suffix',
      replaceAll: true,
    );
    final committed = await json(await commit(deckId, body['review_artifact']));
    expect((await state(deckId))['cards'], {islandId: '24', goblinId: '4'});

    final undo = await undo_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/changes/${committed['change_event_id']}/undo',
        null,
      ),
      deckId,
      committed['change_event_id'] as String,
    );

    expect(undo.statusCode, HttpStatus.ok, reason: '${await json(undo)}');
    final after = await state(deckId);
    expect(after['cards'], original['cards']);
    expect(after['events'], ['import_to_deck', 'undo']);
  }, skip: skipReason);

  test(
    'prévia de deck de outra pessoa: 404, e lista sem mudança não assina',
    () async {
      final strangersDeck = await seedDeck(
        userId: stranger,
        cards: {islandId: 20},
      );
      final foreign = await preview_route.onRequest(
        context('POST', '/import/to-deck/preview', {
          'deck_id': strangersDeck,
          'list': '1 Island $suffix',
        }),
      );
      expect(foreign.statusCode, HttpStatus.notFound);

      final deckId = await seedDeck(cards: {islandId: 20});
      final body = await preview(deckId, '20 Island $suffix', replaceAll: true);
      expect(body['can_commit'], isFalse);
      expect(body['review_unavailable_reason'], 'no_changes');
      expect(body.containsKey('review_artifact'), isFalse);
    },
    skip: skipReason,
  );
}
