@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/decks/deck_revision_support.dart';
import '../lib/release_capability_policy.dart';
import '../routes/decks/[id]/cards/bulk/index.dart' as bulk_route;
import '../routes/decks/[id]/cards/index.dart' as add_route;
import '../routes/decks/[id]/cards/remove/index.dart' as remove_route;
import '../routes/decks/[id]/cards/replace/index.dart' as replace_route;
import '../routes/decks/[id]/cards/set/index.dart' as set_route;
import '../routes/decks/[id]/changes/[eventId]/undo/index.dart' as undo_route;
import '../routes/decks/[id]/changes/index.dart' as changes_route;
import '../routes/decks/[id]/index.dart' as deck_route;
import '../routes/import/to-deck/index.dart' as import_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// DCK-P0-01 em PostgreSQL descartável: revisão otimista, ledger imutável de
/// mudanças e desfazer universal (decisão D-29 do dono). As rotas rodam de
/// verdade, chamadas direto (o portão de capability tem teste próprio).
///
/// Requer `RUN_DECK_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// já migrado (migration 067).
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
  late String bearReprintId;
  late String elfId;
  late String goblinId;

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints(
      [
        Endpoint(
          host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
          port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
          database: Platform.environment['DB_NAME']!,
          username: Platform.environment['DB_USER']!,
          password: Platform.environment['DB_PASS'] ?? '',
        ),
      ],
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 6,
      ),
    );

    Future<String> user(String key) async {
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash)
          VALUES (@username, @email, 'x')
          RETURNING id::text
        '''),
        parameters: {
          'username': 'dck01_${key}_$suffix',
          'email': 'dck01_${key}_$suffix@example.invalid',
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
      await pool.execute(
        Sql.named('''
          INSERT INTO card_legalities (card_id, format, status)
          VALUES (CAST(@id AS uuid), 'modern', 'legal')
        '''),
        parameters: {'id': id},
      );
      return id;
    }

    owner = await user('owner');
    stranger = await user('stranger');
    islandId = await card('Island', 'Basic Land — Island');
    bearId = await card('Grizzly Bears', 'Creature — Bear');
    bearReprintId = await card('Grizzly Bears', 'Creature — Bear');
    elfId = await card('Llanowar Elves', 'Creature — Elf Druid');
    goblinId = await card('Goblin Guide', 'Creature — Goblin Scout');
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'dck01\\_%\\_$suffix'},
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
    Map<String, String> headers = const {},
    bool requireIfMatch = false,
  }) => ScriptedRequestContext(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {'content-type': 'application/json', ...headers},
      body: body == null ? null : jsonEncode(body),
    ),
    providers: {
      Pool: pool,
      String: asUser ?? owner,
      ReleaseCapabilityPolicy: releaseCapabilityPolicyWith(
        betaCoreCapabilities,
      ),
      DeckRevisionPolicy: DeckRevisionPolicy(requireIfMatch: requireIfMatch),
    },
  );

  Future<Map<String, dynamic>> json(Response response) async {
    final text = await response.body();
    return text.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(text) as Map<String, dynamic>;
  }

  Map<String, String> ifMatch(Object revision) => {'If-Match': '"$revision"'};

  Future<String> seedDeck({
    bool isPublic = false,
    Map<String, int> cards = const {},
  }) async {
    final deck = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format, is_public, description)
        VALUES (CAST(@userId AS uuid), @name, 'modern', @isPublic, 'antes')
        RETURNING id::text
      '''),
      parameters: {
        'userId': owner,
        'name': 'Ledger $suffix',
        'isPublic': isPublic,
      },
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

  Future<Map<String, Object?>> state(String deckId) async {
    final deck = await pool.execute(
      Sql.named('''
        SELECT revision, name, description, is_public
        FROM decks WHERE id = CAST(@deckId AS uuid)
      '''),
      parameters: {'deckId': deckId},
    );
    final cards = await pool.execute(
      Sql.named('''
        SELECT card_id::text, quantity::int
        FROM deck_cards WHERE deck_id = CAST(@deckId AS uuid)
        ORDER BY card_id
      '''),
      parameters: {'deckId': deckId},
    );
    final events = await pool.execute(
      Sql.named('''
        SELECT operation, revision_before, revision_after
        FROM deck_change_events WHERE deck_id = CAST(@deckId AS uuid)
        ORDER BY revision_after
      '''),
      parameters: {'deckId': deckId},
    );
    return {
      ...deck.single.toColumnMap(),
      'cards': {for (final row in cards) row[0]! as String: row[1]! as int},
      'events': [for (final row in events) '${row[0]}:${row[1]}->${row[2]}'],
    };
  }

  Future<Response> add(
    String deckId,
    String cardId, {
    int quantity = 1,
    Map<String, String> headers = const {},
    bool requireIfMatch = false,
    String? asUser,
  }) => add_route.onRequest(
    context(
      'POST',
      '/decks/$deckId/cards',
      {'card_id': cardId, 'quantity': quantity},
      headers: headers,
      requireIfMatch: requireIfMatch,
      asUser: asUser,
    ),
    deckId,
  );

  test('GET devolve a revisão no corpo e no ETag', () async {
    final deckId = await seedDeck(cards: {islandId: 20});

    final response = await deck_route.onRequest(
      context('GET', '/decks/$deckId', null),
      deckId,
    );
    final body = await json(response);

    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    expect(body['revision'], 1);
    expect(response.headers['etag'] ?? response.headers['ETag'], '"1"');
  }, skip: skipReason);

  test(
    'todo mutator sobe a revisão em 1 e grava um evento com a operação',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20, bearId: 2});
      var revision = 1;

      Future<void> expectStep(Response response, String operation) async {
        final body = await json(response);
        expect(response.statusCode, HttpStatus.ok, reason: '$operation: $body');
        revision++;
        expect(body['revision'], revision, reason: operation);
        expect(body['revision_before'], revision - 1, reason: operation);
        expect(body['change_operation'], operation, reason: operation);
        expect(body['change_event_id'], isA<String>(), reason: operation);
        expect(
          body.containsKey('revision_warning'),
          isFalse,
          reason: operation,
        );
        expect(
          response.headers['etag'] ?? response.headers['ETag'],
          '"$revision"',
          reason: operation,
        );
      }

      await expectStep(
        await add(deckId, elfId, headers: ifMatch(revision)),
        'card_add',
      );
      await expectStep(
        await set_route.onRequest(
          context('POST', '/decks/$deckId/cards/set', {
            'card_id': elfId,
            'quantity': 3,
          }, headers: ifMatch(revision)),
          deckId,
        ),
        'card_set',
      );
      await expectStep(
        await replace_route.onRequest(
          context('POST', '/decks/$deckId/cards/replace', {
            'old_card_id': bearId,
            'new_card_id': bearReprintId,
          }, headers: ifMatch(revision)),
          deckId,
        ),
        'card_replace',
      );
      await expectStep(
        await remove_route.onRequest(
          context('POST', '/decks/$deckId/cards/remove', {
            'card_id': bearReprintId,
          }, headers: ifMatch(revision)),
          deckId,
        ),
        'card_remove',
      );
      await expectStep(
        await deck_route.onRequest(
          context('PATCH', '/decks/$deckId', {
            'name': 'Renomeado $suffix',
          }, headers: ifMatch(revision)),
          deckId,
        ),
        'deck_patch',
      );
      await expectStep(
        await bulk_route.onRequest(
          context('POST', '/decks/$deckId/cards/bulk', {
            'cards': [
              {'card_id': goblinId, 'quantity': 2},
            ],
          }, headers: ifMatch(revision)),
          deckId,
        ),
        'card_bulk',
      );
      await expectStep(
        await deck_route.onRequest(
          context('PUT', '/decks/$deckId', {
            'cards': [
              {'card_id': islandId, 'quantity': 22},
              {'card_id': goblinId, 'quantity': 4},
            ],
          }, headers: ifMatch(revision)),
          deckId,
        ),
        'deck_replace',
      );
      await expectStep(
        await import_route.onRequest(
          context('POST', '/import/to-deck', {
            'deck_id': deckId,
            'list': '2 Llanowar Elves $suffix',
          }, headers: ifMatch(revision)),
        ),
        'import_to_deck',
      );

      final after = await state(deckId);
      expect(after['revision'], revision);
      expect(after['events'], [
        'card_add:1->2',
        'card_set:2->3',
        'card_replace:3->4',
        'card_remove:4->5',
        'deck_patch:5->6',
        'card_bulk:6->7',
        'deck_replace:7->8',
        'import_to_deck:8->9',
      ]);
    },
    skip: skipReason,
  );

  test('If-Match velho dá 409 com a revisão atual e não escreve', () async {
    final deckId = await seedDeck(cards: {islandId: 20});
    expect((await add(deckId, elfId)).statusCode, HttpStatus.ok);
    final before = await state(deckId);

    final response = await add(deckId, goblinId, headers: ifMatch(1));
    final body = await json(response);

    expect(response.statusCode, HttpStatus.conflict, reason: '$body');
    expect(body['error_code'], deckRevisionConflictCode);
    expect(body['current_revision'], 2);
    expect(response.headers['etag'] ?? response.headers['ETag'], '"2"');
    expect(await state(deckId), before);
  }, skip: skipReason);

  test('If-Match aceita W/ e *, e recusa o que não é revisão', () async {
    final deckId = await seedDeck(cards: {islandId: 20});

    expect(
      (await add(deckId, elfId, headers: {'If-Match': 'W/"1"'})).statusCode,
      HttpStatus.ok,
    );
    expect(
      (await add(deckId, elfId, headers: {'If-Match': '*'})).statusCode,
      HttpStatus.ok,
    );
    final before = await state(deckId);
    final malformed = await add(deckId, elfId, headers: {'If-Match': 'abc'});

    expect(malformed.statusCode, HttpStatus.badRequest);
    expect((await json(malformed))['error_code'], deckIfMatchInvalidCode);
    expect(await state(deckId), before);
  }, skip: skipReason);

  test(
    'duas mudanças concorrentes com a mesma revisão: uma vence, a outra 409',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20});

      final responses = await Future.wait([
        add(deckId, elfId, headers: ifMatch(1)),
        add(deckId, goblinId, headers: ifMatch(1)),
      ]);
      final statuses =
          responses.map((response) => response.statusCode).toList()..sort();

      expect(statuses, [HttpStatus.ok, HttpStatus.conflict]);
      final after = await state(deckId);
      expect(after['revision'], 2);
      expect(after['events'], ['card_add:1->2']);
      expect((after['cards']! as Map).length, 2);
    },
    skip: skipReason,
  );

  test(
    'repetir o pedido com a mesma Idempotency-Key devolve o mesmo recibo',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20});
      final key = {'Idempotency-Key': 'add-elf-$suffix'};

      final first = await add(deckId, elfId, headers: key);
      final firstBody = await json(first);
      final retry = await add(deckId, elfId, headers: {...key, ...ifMatch(1)});
      final retryBody = await json(retry);

      expect(first.statusCode, HttpStatus.ok, reason: '$firstBody');
      expect(retry.statusCode, HttpStatus.ok, reason: '$retryBody');
      expect(retryBody['replayed'], isTrue);
      expect(retryBody['change_event_id'], firstBody['change_event_id']);
      expect(retryBody['revision'], 2);
      final after = await state(deckId);
      expect((after['cards']! as Map)[elfId], 1, reason: 'não somou de novo');
      expect(after['events'], ['card_add:1->2']);

      final reused = await add(deckId, elfId, quantity: 2, headers: key);
      expect(reused.statusCode, HttpStatus.unprocessableEntity);
      expect((await json(reused))['error_code'], deckIdempotencyKeyReusedCode);
      expect(await state(deckId), after);
    },
    skip: skipReason,
  );

  test(
    'sem If-Match a mudança segue e avisa; com a política exigindo, 428',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20});

      final lenient = await add(deckId, elfId);
      expect(
        (await json(lenient))['revision_warning'],
        deckIfMatchMissingWarning,
      );
      final before = await state(deckId);

      final strict = await add(deckId, goblinId, requireIfMatch: true);
      final body = await json(strict);
      expect(
        strict.statusCode,
        HttpStatus.preconditionRequired,
        reason: '$body',
      );
      expect(body['error_code'], deckRevisionRequiredCode);
      expect(body['current_revision'], 2);
      expect(await state(deckId), before);

      final withHeader = await add(
        deckId,
        goblinId,
        requireIfMatch: true,
        headers: ifMatch(2),
      );
      expect(withHeader.statusCode, HttpStatus.ok);
    },
    skip: skipReason,
  );

  test(
    'pedido que não muda nada e pedido recusado não gastam revisão',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20, elfId: 2});

      final same = await set_route.onRequest(
        context('POST', '/decks/$deckId/cards/set', {
          'card_id': elfId,
          'quantity': 2,
        }),
        deckId,
      );
      final sameBody = await json(same);
      expect(same.statusCode, HttpStatus.ok, reason: '$sameBody');
      expect(sameBody['revision'], 1);
      expect(sameBody['change_event_id'], isNull);

      final refused = await add(deckId, elfId, quantity: 5);
      expect(refused.statusCode, HttpStatus.badRequest);
      final after = await state(deckId);
      expect(after['revision'], 1);
      expect(after['events'], isEmpty);
    },
    skip: skipReason,
  );

  test(
    'desfazer devolve cartas e metadados de antes como mudança nova',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20, elfId: 2});
      final original = await state(deckId);

      final removed = await json(
        await remove_route.onRequest(
          context('POST', '/decks/$deckId/cards/remove', {'card_id': elfId}),
          deckId,
        ),
      );
      final renamed = await json(
        await deck_route.onRequest(
          context('PATCH', '/decks/$deckId', {
            'name': 'Outro $suffix',
            'description': 'depois',
          }),
          deckId,
        ),
      );

      final undoRename = await undo_route.onRequest(
        context(
          'POST',
          '/decks/$deckId/changes/${renamed['change_event_id']}/undo',
          null,
          headers: ifMatch(3),
        ),
        deckId,
        renamed['change_event_id'] as String,
      );
      final undoRenameBody = await json(undoRename);
      expect(undoRename.statusCode, HttpStatus.ok, reason: '$undoRenameBody');
      expect(undoRenameBody['revision'], 4);
      expect(undoRenameBody['change_operation'], 'undo');

      final undoRemove = await undo_route.onRequest(
        context(
          'POST',
          '/decks/$deckId/changes/${removed['change_event_id']}/undo',
          null,
        ),
        deckId,
        removed['change_event_id'] as String,
      );
      expect(
        undoRemove.statusCode,
        HttpStatus.conflict,
        reason: 'o HEAD é o desfazer do nome, não a remoção',
      );
      expect((await json(undoRemove))['error_code'], 'deck_undo_conflict');

      final state4 = await state(deckId);
      expect(state4['name'], original['name']);
      expect(state4['description'], original['description']);
      expect(state4['cards'], {islandId: 20});

      final undoEvent = await pool.execute(
        Sql.named('''
        SELECT undo_of_event_id::text FROM deck_change_events
        WHERE deck_id = CAST(@deckId AS uuid) AND revision_after = 4
      '''),
        parameters: {'deckId': deckId},
      );
      expect(undoEvent.single.single, renamed['change_event_id']);
    },
    skip: skipReason,
  );

  test(
    'desfazer a última mudança de cartas devolve a mesma quantidade',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20, elfId: 3});

      final removed = await json(
        await remove_route.onRequest(
          context('POST', '/decks/$deckId/cards/remove', {'card_id': elfId}),
          deckId,
        ),
      );
      final undo = await undo_route.onRequest(
        context(
          'POST',
          '/decks/$deckId/changes/${removed['change_event_id']}/undo',
          null,
        ),
        deckId,
        removed['change_event_id'] as String,
      );

      expect(undo.statusCode, HttpStatus.ok, reason: '${await json(undo)}');
      final after = await state(deckId);
      expect(after['cards'], {islandId: 20, elfId: 3});
      expect(after['events'], ['card_remove:1->2', 'undo:2->3']);
    },
    skip: skipReason,
  );

  test('desfazer não publica: o deck volta privado', () async {
    final deckId = await seedDeck(isPublic: true, cards: {elfId: 4});

    final removed = await json(
      await remove_route.onRequest(
        context('POST', '/decks/$deckId/cards/remove', {'card_id': elfId}),
        deckId,
      ),
    );
    expect(removed['unpublished_because_empty'], isTrue);

    final undo = await undo_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/changes/${removed['change_event_id']}/undo',
        null,
      ),
      deckId,
      removed['change_event_id'] as String,
    );
    final body = await json(undo);

    expect(undo.statusCode, HttpStatus.ok, reason: '$body');
    expect(body['visibility_kept_private'], isTrue);
    final after = await state(deckId);
    expect(after['cards'], {elfId: 4});
    expect(after['is_public'], isFalse);
  }, skip: skipReason);

  test('desfazer recusa um estado que as regras de hoje barram', () async {
    final deckId = await seedDeck(cards: {islandId: 20, goblinId: 1});
    final removed = await json(
      await remove_route.onRequest(
        context('POST', '/decks/$deckId/cards/remove', {'card_id': goblinId}),
        deckId,
      ),
    );
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

    final undo = await undo_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/changes/${removed['change_event_id']}/undo',
        null,
      ),
      deckId,
      removed['change_event_id'] as String,
    );

    expect(undo.statusCode, HttpStatus.conflict);
    expect((await json(undo))['error_code'], 'deck_undo_invalid');
    expect(await state(deckId), before);
  }, skip: skipReason);

  test(
    'o histórico lista do mais novo ao mais velho, com o nome das cartas',
    () async {
      final deckId = await seedDeck(cards: {islandId: 20});
      await add(deckId, elfId);
      await deck_route.onRequest(
        context('PATCH', '/decks/$deckId', {'archetype': 'aggro'}),
        deckId,
      );

      final response = await changes_route.onRequest(
        context('GET', '/decks/$deckId/changes', null),
        deckId,
      );
      final body = await json(response);

      expect(response.statusCode, HttpStatus.ok, reason: '$body');
      expect(body['revision'], 3);
      final events = (body['events'] as List).cast<Map<String, dynamic>>();
      expect(events.map((event) => event['operation']), [
        'deck_patch',
        'card_add',
      ]);
      expect(events.map((event) => event['can_undo']), [true, false]);
      expect(events.first['metadata_after'], {'archetype': 'aggro'});
      expect(events.last['cards_before'], isEmpty);
      expect(events.last['cards_after'], [
        {
          'card_id': elfId,
          'quantity': 1,
          'is_commander': false,
          'condition': 'NM',
          'name': 'Llanowar Elves $suffix',
        },
      ]);
    },
    skip: skipReason,
  );

  test('outra pessoa não lê o histórico nem muda o deck', () async {
    final deckId = await seedDeck(cards: {islandId: 20});
    final change = await json(await add(deckId, elfId));
    final before = await state(deckId);

    final history = await changes_route.onRequest(
      context('GET', '/decks/$deckId/changes', null, asUser: stranger),
      deckId,
    );
    final undo = await undo_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/changes/${change['change_event_id']}/undo',
        null,
        asUser: stranger,
      ),
      deckId,
      change['change_event_id'] as String,
    );
    final added = await add(deckId, goblinId, asUser: stranger);

    expect(history.statusCode, HttpStatus.notFound);
    expect(undo.statusCode, HttpStatus.notFound);
    expect(added.statusCode, HttpStatus.notFound);
    expect((await json(added))['error_code'], 'deck_not_found');
    expect(await state(deckId), before);
  }, skip: skipReason);

  test('DELETE com If-Match velho é 409 e não apaga', () async {
    final deckId = await seedDeck(cards: {islandId: 20});
    await add(deckId, elfId);

    final stale = await deck_route.onRequest(
      context('DELETE', '/decks/$deckId', null, headers: ifMatch(1)),
      deckId,
    );
    expect(stale.statusCode, HttpStatus.conflict);
    expect((await json(stale))['error_code'], deckRevisionConflictCode);
    expect((await state(deckId))['revision'], 2);

    final current = await deck_route.onRequest(
      context('DELETE', '/decks/$deckId', null, headers: ifMatch(2)),
      deckId,
    );
    expect(current.statusCode, HttpStatus.noContent);
  }, skip: skipReason);

  test('o ledger só recebe INSERT; a cascata do deck apaga', () async {
    final deckId = await seedDeck(cards: {islandId: 20});
    await add(deckId, elfId);

    await expectLater(
      pool.execute(
        Sql.named('''
          UPDATE deck_change_events SET operation = 'undo'
          WHERE deck_id = CAST(@deckId AS uuid)
        '''),
        parameters: {'deckId': deckId},
      ),
      throwsA(isA<ServerException>()),
    );
    await expectLater(
      pool.execute(
        Sql.named('''
          DELETE FROM deck_change_events
          WHERE deck_id = CAST(@deckId AS uuid)
        '''),
        parameters: {'deckId': deckId},
      ),
      throwsA(isA<ServerException>()),
    );
    expect((await state(deckId))['events'], ['card_add:1->2']);

    await pool.execute(
      Sql.named('DELETE FROM decks WHERE id = CAST(@deckId AS uuid)'),
      parameters: {'deckId': deckId},
    );
    final left = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int FROM deck_change_events
        WHERE deck_id = CAST(@deckId AS uuid)
      '''),
      parameters: {'deckId': deckId},
    );
    expect(left.single.single, 0);
  }, skip: skipReason);
}
