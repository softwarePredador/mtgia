@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_swap_integrity.dart';
import '../lib/decks/deck_optimization_history_service.dart';
import '../lib/release_capability_policy.dart';
import '../routes/decks/[id]/cards/bulk/index.dart' as bulk_route;
import '../routes/decks/[id]/index.dart' as deck_route;
import '../routes/decks/[id]/optimizations/[eventId]/rollback/index.dart'
    as rollback_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// DCK-P0-02 em PostgreSQL descartável: o commit do Optimize pelo
/// `POST /decks/:id/cards/bulk` recusa, sem nenhuma escrita, o
/// `DeckReviewArtifact v1` adulterado, expirado, de outro usuário, de outro
/// deck ou de um estado velho do deck. Depois de cada recusa o teste relê as
/// cartas, a revisão, o estado de validação e o histórico de otimizações.
/// Com o DCK-P0-01 o artefato liga também a revisão do deck, e aplicar e
/// desfazer pelo Optimize entram no ledger de mudanças.
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
  late String deckId;
  late String otherDeckId;
  late String completeDeckId;
  late String islandId;
  late String bearId;
  late String elfId;

  String secret() =>
      resolveOptimizeApplySigningSecret(environment: Platform.environment);

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
          'username': 'dck02_${key}_$suffix',
          'email': 'dck02_${key}_$suffix@example.invalid',
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
      return result.single.single! as String;
    }

    Future<String> deck(String userId, {int islands = 20}) async {
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO decks (user_id, name, format)
          VALUES (CAST(@userId AS uuid), @name, 'modern')
          RETURNING id::text
        '''),
        parameters: {'userId': userId, 'name': 'Artifact $suffix'},
      );
      final id = result.single.single! as String;
      await pool.execute(
        Sql.named('''
          INSERT INTO deck_cards (deck_id, card_id, quantity)
          VALUES (CAST(@deckId AS uuid), CAST(@islandId AS uuid), @islands),
                 (CAST(@deckId AS uuid), CAST(@bearId AS uuid), 4)
        '''),
        parameters: {
          'deckId': id,
          'islandId': islandId,
          'bearId': bearId,
          'islands': islands,
        },
      );
      return id;
    }

    owner = await user('owner');
    stranger = await user('stranger');
    islandId = await card('Island', 'Basic Land — Island');
    bearId = await card('Grizzly Bears', 'Creature — Bear');
    elfId = await card('Llanowar Elves', 'Creature — Elf Druid');
    deckId = await deck(owner);
    otherDeckId = await deck(owner);
    // 60 cartas: passa na validação estrita do apply (controle positivo).
    completeDeckId = await deck(owner, islands: 56);
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'dck02\\_%\\_$suffix'},
    );
    await pool.execute(
      Sql.named('DELETE FROM cards WHERE name LIKE @pattern'),
      parameters: {'pattern': '% $suffix'},
    );
    await pool.close();
  });

  Future<String> currentSignature(String id) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT card_id::text, quantity::int, is_commander, condition
        FROM deck_cards WHERE deck_id = CAST(@id AS uuid)
      '''),
      parameters: {'id': id},
    );
    return DeckOptimizationHistoryService.buildDeckSignature([
      for (final row in rows)
        {
          'card_id': row[0],
          'quantity': row[1],
          'is_commander': row[2],
          'condition': row[3],
        },
    ]);
  }

  Future<int> revisionOf(String id) async {
    final rows = await pool.execute(
      Sql.named('SELECT revision FROM decks WHERE id = CAST(@id AS uuid)'),
      parameters: {'id': id},
    );
    return (rows.single.single! as num).toInt();
  }

  Future<List<String>> ledgerOf(String id) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT operation FROM deck_change_events
        WHERE deck_id = CAST(@id AS uuid) ORDER BY revision_after
      '''),
      parameters: {'id': id},
    );
    return [for (final row in rows) row[0]! as String];
  }

  Future<Map<String, Object?>> snapshot(String id) async {
    final cards = await pool.execute(
      Sql.named('''
        SELECT card_id::text, quantity::int FROM deck_cards
        WHERE deck_id = CAST(@id AS uuid) ORDER BY card_id
      '''),
      parameters: {'id': id},
    );
    final deck = await pool.execute(
      Sql.named('''
        SELECT validation_state, validation_updated_at, revision
        FROM decks WHERE id = CAST(@id AS uuid)
      '''),
      parameters: {'id': id},
    );
    final events = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int FROM deck_optimization_events
        WHERE deck_id = CAST(@id AS uuid)
      '''),
      parameters: {'id': id},
    );
    return {
      'cards': [for (final row in cards) '${row[0]}:${row[1]}'],
      'validation': deck.single.toColumnMap().toString(),
      'events': events.single.single,
    };
  }

  Future<Map<String, dynamic>> authorization({
    required String ownerId,
    required String forDeck,
    required String signature,
    int? revision,
    DateTime? issuedAt,
  }) async =>
      buildOptimizeApplyAuthorizationForResponse(
        signingSecret: secret(),
        ownerId: ownerId,
        deckId: forDeck,
        deckSignature: signature,
        deckRevision: revision ?? await revisionOf(forDeck),
        responseBody: {
          'mode': 'complete',
          'can_apply': true,
          'learning_eligible': true,
          'removals_detailed': const <Map<String, dynamic>>[],
          'additions_detailed': [
            {'card_id': elfId, 'quantity': 1},
          ],
        },
        issuedAt: issuedAt,
      )!;

  Future<Response> apply({
    required String asUser,
    required Map<String, dynamic> applyAuthorization,
    required String expectedSignature,
    String? toDeck,
  }) => bulk_route.onRequest(
    ScriptedRequestContext(
      Request.post(
        Uri.parse('http://localhost/decks/${toDeck ?? deckId}/cards/bulk'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'cards': [
            {'card_id': elfId, 'quantity': 1},
          ],
          'mutation_context': {
            'type': 'optimization_apply',
            'source': 'optimize_preview',
            'mode': 'complete',
            'expected_deck_signature': expectedSignature,
            'apply_authorization': applyAuthorization,
          },
        }),
      ),
      providers: {
        Pool: pool,
        String: asUser,
        ReleaseCapabilityPolicy: releaseCapabilityPolicyWith(
          betaCoreCapabilities,
        ),
      },
    ),
    toDeck ?? deckId,
  );

  Future<void> expectRefusedWithoutWrites(
    Response response,
    Map<String, Object?> before, {
    required String code,
    int status = HttpStatus.conflict,
  }) async {
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(response.statusCode, status, reason: '$body');
    if (status == HttpStatus.conflict) {
      expect(body['error_code'], 'optimization_apply_not_authorized');
      expect(body['authorization_error'], code);
    }
    expect(await snapshot(deckId), before, reason: 'nenhuma escrita');
  }

  test('controle positivo: o artefato válido do dono aplica', () async {
    final signature = await currentSignature(completeDeckId);
    final before = await snapshot(completeDeckId);

    final response = await apply(
      asUser: owner,
      applyAuthorization: await authorization(
        ownerId: owner,
        forDeck: completeDeckId,
        signature: signature,
      ),
      expectedSignature: signature,
      toDeck: completeDeckId,
    );
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    final after = await snapshot(completeDeckId);
    expect(after['cards'], contains('$elfId:1'));
    expect(after['events'], (before['events']! as int) + 1);
    expect(body['change_operation'], 'optimization_apply');
    expect(await ledgerOf(completeDeckId), ['optimization_apply']);

    // Desfazer pelo rollback do Optimize também é mudança do ledger.
    final eventId = (body['optimization_event'] as Map)['id'] as String;
    final rollback = await rollback_route.onRequest(
      ScriptedRequestContext(
        Request.post(
          Uri.parse(
            'http://localhost/decks/$completeDeckId/optimizations/$eventId/rollback',
          ),
        ),
        providers: {Pool: pool, String: owner},
      ),
      completeDeckId,
      eventId,
    );
    final rollbackBody =
        jsonDecode(await rollback.body()) as Map<String, dynamic>;
    expect(rollback.statusCode, HttpStatus.ok, reason: '$rollbackBody');
    expect(rollbackBody['change_operation'], 'optimization_rollback');
    expect(await ledgerOf(completeDeckId), [
      'optimization_apply',
      'optimization_rollback',
    ]);
    expect((await snapshot(completeDeckId))['cards'], before['cards']);
  }, skip: skipReason);

  test(
    'PUT com prévia velha do Optimize é conflito (409), sem escrita',
    () async {
      final before = await snapshot(deckId);
      final response = await deck_route.onRequest(
        ScriptedRequestContext(
          Request.put(
            Uri.parse('http://localhost/decks/$deckId'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'cards': [
                {'card_id': islandId, 'quantity': 20},
                {'card_id': elfId, 'quantity': 4},
              ],
              'mutation_context': {
                'type': 'optimization_apply',
                'source': 'optimize_preview',
                'mode': 'complete',
                'expected_deck_signature': 'assinatura-velha',
              },
            }),
          ),
          providers: {
            Pool: pool,
            String: owner,
            ReleaseCapabilityPolicy: releaseCapabilityPolicyWith(
              betaCoreCapabilities,
            ),
          },
        ),
        deckId,
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.conflict, reason: '$body');
      expect(body['error_code'], 'optimization_preview_stale');
      expect(await snapshot(deckId), before);
    },
    skip: skipReason,
  );

  test('artefato de outra revisão do deck falha sem escrita', () async {
    final signature = await currentSignature(deckId);
    final issuedFor = await revisionOf(deckId);
    // Mudança só de metadados: a assinatura das cartas é a mesma.
    await pool.execute(
      Sql.named('''
        UPDATE decks SET name = name || ' renomeado', revision = revision + 1
        WHERE id = CAST(@id AS uuid)
      '''),
      parameters: {'id': deckId},
    );
    final before = await snapshot(deckId);

    await expectRefusedWithoutWrites(
      await apply(
        asUser: owner,
        applyAuthorization: await authorization(
          ownerId: owner,
          forDeck: deckId,
          signature: signature,
          revision: issuedFor,
        ),
        expectedSignature: signature,
      ),
      before,
      code: 'stale_deck_revision',
    );
  }, skip: skipReason);

  test('artefato adulterado falha sem escrita', () async {
    final signature = await currentSignature(deckId);
    final before = await snapshot(deckId);
    final valid = await authorization(
      ownerId: owner,
      forDeck: deckId,
      signature: signature,
    );
    final token = valid['token'] as String;
    final tampered = {
      ...valid,
      'token': '${token.substring(0, token.length - 4)}AAAA',
    };

    await expectRefusedWithoutWrites(
      await apply(
        asUser: owner,
        applyAuthorization: tampered,
        expectedSignature: signature,
      ),
      before,
      code: 'invalid_signature',
    );
  }, skip: skipReason);

  test('artefato expirado falha sem escrita', () async {
    final signature = await currentSignature(deckId);
    final before = await snapshot(deckId);

    await expectRefusedWithoutWrites(
      await apply(
        asUser: owner,
        applyAuthorization: await authorization(
          ownerId: owner,
          forDeck: deckId,
          signature: signature,
          issuedAt: DateTime.now().toUtc().subtract(const Duration(hours: 25)),
        ),
        expectedSignature: signature,
      ),
      before,
      code: 'expired_token',
    );
  }, skip: skipReason);

  test('artefato emitido para outro usuário falha sem escrita', () async {
    final signature = await currentSignature(deckId);
    final before = await snapshot(deckId);

    await expectRefusedWithoutWrites(
      await apply(
        asUser: owner,
        applyAuthorization: await authorization(
          ownerId: stranger,
          forDeck: deckId,
          signature: signature,
        ),
        expectedSignature: signature,
      ),
      before,
      code: 'owner_binding_mismatch',
    );
  }, skip: skipReason);

  test('outro usuário não alcança o deck com o artefato do dono', () async {
    final signature = await currentSignature(deckId);
    final before = await snapshot(deckId);

    final response = await apply(
      asUser: stranger,
      applyAuthorization: await authorization(
        ownerId: owner,
        forDeck: deckId,
        signature: signature,
      ),
      expectedSignature: signature,
    );

    expect(response.statusCode, isNot(HttpStatus.ok));
    expect(await snapshot(deckId), before);
  }, skip: skipReason);

  test('artefato de outro deck falha sem escrita', () async {
    final signature = await currentSignature(deckId);
    final before = await snapshot(deckId);

    await expectRefusedWithoutWrites(
      await apply(
        asUser: owner,
        applyAuthorization: await authorization(
          ownerId: owner,
          forDeck: otherDeckId,
          signature: signature,
        ),
        expectedSignature: signature,
      ),
      before,
      code: 'deck_binding_mismatch',
    );
  }, skip: skipReason);

  test('artefato de um estado velho do deck falha sem escrita', () async {
    final signature = await currentSignature(deckId);
    final before = await snapshot(deckId);

    await expectRefusedWithoutWrites(
      await apply(
        asUser: owner,
        applyAuthorization: await authorization(
          ownerId: owner,
          forDeck: deckId,
          signature: '$signature|estado-antigo',
        ),
        expectedSignature: signature,
      ),
      before,
      code: 'stale_deck_signature',
    );
  }, skip: skipReason);
}
