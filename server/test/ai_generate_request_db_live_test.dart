@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/ai_generate_request_store.dart';
import '../lib/privacy/retention_cleanup.dart';
import '../lib/release_capability_policy.dart';
import '../lib/verified_email_middleware.dart';
import '../routes/ai/generate/requests/[id]/index.dart' as request_route;
import '../routes/ai/generate/requests/[id]/materialize.dart'
    as materialize_route;
import '../routes/decks/[id]/changes/[eventId]/undo/index.dart' as undo_route;
import '../routes/decks/[id]/changes/index.dart' as changes_route;
import '../routes/decks/index.dart' as decks_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// DCK-P0-04 em PostgreSQL descartável: o pedido do Generate fica durável
/// (entrada original, impressão e resultado), outro aparelho o reidrata, e o
/// deck nasce no servidor a partir do resultado e dos controles gravados,
/// com o `DeckReviewArtifact v1` do tipo `generate_materialize`. A limpeza
/// por prazo (D-29) apaga o prompt em 30 dias e o texto de descrição do
/// ledger, que o desfazer não inventa depois.
///
/// Requer `RUN_DECK_DB_TESTS=1`, `JWT_SECRET` e as variáveis `DB_*` de um
/// banco descartável já migrado (migration 069).
void main() {
  final enabled = Platform.environment['RUN_DECK_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  late Pool pool;
  late String owner;
  late String stranger;
  late String commanderName;
  late String elfName;
  late String forestName;

  setUpAll(() async {
    if (!enabled) return;
    overrideVerifiedEmailRequirementForTesting(false);
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
          'username': 'p004_${key}_$suffix',
          'email': 'p004_${key}_$suffix@example.invalid',
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
        parameters: {'name': name, 'typeLine': typeLine},
      );
      final id = result.single.single! as String;
      await pool.execute(
        Sql.named('''
          INSERT INTO card_legalities (card_id, format, status)
          VALUES (CAST(@id AS uuid), 'commander', 'legal')
        '''),
        parameters: {'id': id},
      );
      return name;
    }

    owner = await user('owner');
    stranger = await user('stranger');
    commanderName = await card(
      'Ezuri $suffix',
      'Legendary Creature — Elf Warrior',
    );
    elfName = await card('Llanowar Elves $suffix', 'Creature — Elf Druid');
    forestName = await card('Forest $suffix', 'Basic Land — Forest');
  });

  tearDownAll(() async {
    if (!enabled) return;
    overrideVerifiedEmailRequirementForTesting(null);
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'p004\\_%\\_$suffix'},
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
      ReleaseCapabilityPolicy: releaseCapabilityPolicyWith({
        ...betaCoreCapabilities,
        'ai_generate_rebuild',
      }),
    },
  );

  Future<Map<String, dynamic>> json(Response response) async =>
      jsonDecode(await response.body()) as Map<String, dynamic>;

  /// Um pedido gravado como o POST /ai/generate assíncrono grava, e o
  /// resultado como o job grava ao terminar.
  Future<String> generated({
    String? prompt,
    int? bracket = 2,
    bool canMaterialize = true,
    String? extraCard,
  }) async {
    final jobId = 'job-${DateTime.now().microsecondsSinceEpoch}';
    final requestId = await AiGenerateRequestStore.record(
      pool,
      userId: owner,
      requestKey: 'key-$jobId',
      requestFingerprint: 'fingerprint-$jobId',
      jobId: jobId,
      format: 'Commander',
      controls: {'bracket': bracket, 'commander_name': commanderName},
      prompt: prompt ?? 'um deck de elfos para jogar com meu irmão',
    );
    await AiGenerateRequestStore.recordResult(
      pool,
      jobId: jobId,
      canMaterialize: canMaterialize,
      result: {
        'prompt': prompt,
        'generated_deck': {
          'commander': {'name': commanderName},
          'cards': [
            {'name': elfName, 'quantity': 1},
            {'name': forestName, 'quantity': 30},
            if (extraCard != null) {'name': extraCard, 'quantity': 1},
          ],
        },
      },
    );
    return requestId;
  }

  Future<Map<String, dynamic>> read(String id, {String? asUser}) async {
    final response = await request_route.onRequest(
      context('GET', '/ai/generate/requests/$id', null, asUser: asUser),
      id,
    );
    final body = await json(response);
    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    return body;
  }

  Future<Response> materialize(String id, Object? artifact, {String? name}) =>
      materialize_route.onRequest(
        context('POST', '/ai/generate/requests/$id/materialize', {
          if (artifact != null) 'review_artifact': artifact,
          if (name != null) 'name': name,
        }),
        id,
      );

  Future<int> deckCount() async {
    final result = await pool.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM decks WHERE user_id = CAST(@owner AS uuid)',
      ),
      parameters: {'owner': owner},
    );
    return result.single.single! as int;
  }

  test(
    'o pedido guarda a entrada original e é idempotente pela chave',
    () async {
      final first = await AiGenerateRequestStore.record(
        pool,
        userId: owner,
        requestKey: 'idem-$suffix',
        requestFingerprint: 'f1',
        jobId: 'job-idem-$suffix',
        format: 'Commander',
        controls: const {'bracket': 3},
        prompt: 'prompt original',
      );
      final again = await AiGenerateRequestStore.record(
        pool,
        userId: owner,
        requestKey: 'idem-$suffix',
        requestFingerprint: 'f1',
        jobId: 'job-idem-2-$suffix',
        format: 'Commander',
        controls: const {'bracket': 3},
        prompt: 'prompt original',
      );
      expect(again, first);
      await expectLater(
        AiGenerateRequestStore.record(
          pool,
          userId: owner,
          requestKey: 'idem-$suffix',
          requestFingerprint: 'f2',
          jobId: 'job-idem-3-$suffix',
          format: 'Commander',
          controls: const {'bracket': 4},
          prompt: 'outro prompt',
        ),
        throwsA(isA<AiGenerateRequestConflict>()),
      );

      final body = await read(first);
      expect(body['prompt'], 'prompt original');
      expect(body['controls'], {'bracket': 3});
      expect(body['status'], 'expired', reason: 'o job de teste não existe');
    },
    skip: skipReason,
  );

  test(
    'outro aparelho reidrata o último pedido; outra pessoa não o vê',
    () async {
      final id = await generated(prompt: 'deck de elfos rápido');

      final latest = await read('latest');
      expect(latest['id'], id);
      expect(latest['prompt'], 'deck de elfos rápido');
      expect(latest['status'], 'completed');
      expect(latest['result'], containsPair('total_cards', 32));
      final artifact = latest['review_artifact'] as Map<String, dynamic>;
      expect(artifact['kind'], aiGenerateMaterializeArtifactKind);

      final foreign = await request_route.onRequest(
        context('GET', '/ai/generate/requests/$id', null, asUser: stranger),
        id,
      );
      expect(foreign.statusCode, HttpStatus.notFound);
    },
    skip: skipReason,
  );

  test(
    'materializar cria o deck do resultado, privado e sem o prompt, uma vez',
    () async {
      final id = await generated();
      final artifact = (await read(id))['review_artifact'];
      final before = await deckCount();

      final response = await materialize(id, artifact, name: 'Elfos $suffix');
      final body = await json(response);

      expect(response.statusCode, HttpStatus.created, reason: '$body');
      expect(body['replayed'], isFalse);
      final deck = body['deck'] as Map<String, dynamic>;
      expect(deck['name'], 'Elfos $suffix');
      expect(deck['format'], 'commander');
      expect(deck['is_public'], isFalse);
      expect(deck['description'], isNull, reason: 'D-29: sem o prompt');
      expect(deck['bracket'], 2);
      final cards = await pool.execute(
        Sql.named('''
        SELECT c.name, dc.quantity, dc.is_commander
        FROM deck_cards dc JOIN cards c ON c.id = dc.card_id
        WHERE dc.deck_id = CAST(@deckId AS uuid) ORDER BY c.name
      '''),
        parameters: {'deckId': deck['id']},
      );
      expect(
        [for (final row in cards) '${row[0]}:${row[1]}:${row[2]}'],
        ['$commanderName:1:true', '$forestName:30:false', '$elfName:1:false'],
      );
      expect(await deckCount(), before + 1);

      final retry = await materialize(id, artifact);
      final retryBody = await json(retry);
      expect(retry.statusCode, HttpStatus.ok);
      expect(retryBody['replayed'], isTrue);
      expect((retryBody['deck'] as Map)['id'], deck['id']);
      expect(await deckCount(), before + 1, reason: 'retry não duplica');
      expect((await read(id))['can_materialize'], isFalse);
    },
    skip: skipReason,
  );

  test(
    'sem revisão, revisão adulterada ou de outro pedido: nada é criado',
    () async {
      final id = await generated();
      final otherId = await generated();
      final artifact = (await read(id))['review_artifact'] as Map;
      final otherArtifact = (await read(otherId))['review_artifact'];
      final token = artifact['token'] as String;
      final before = await deckCount();

      final missing = await materialize(id, null);
      expect(missing.statusCode, 428);
      expect((await json(missing))['error_code'], 'generate_review_required');

      for (final (candidate, reason) in [
        ('${token.substring(0, token.length - 4)}AAAA', 'invalid_signature'),
        (otherArtifact, 'input_mismatch'),
      ]) {
        final response = await materialize(id, candidate);
        final body = await json(response);
        expect(response.statusCode, HttpStatus.conflict, reason: reason);
        expect(body['error_code'], 'generate_review_invalid', reason: reason);
      }
      expect(await deckCount(), before);
    },
    skip: skipReason,
  );

  test('resultado A nunca salva como controles B', () async {
    final id = await generated(bracket: 2);
    final artifact = (await read(id))['review_artifact'];
    await pool.execute(
      Sql.named('''
        UPDATE ai_generate_requests
        SET controls = jsonb_set(controls, '{bracket}', '4'::jsonb)
        WHERE id = CAST(@id AS uuid)
      '''),
      parameters: {'id': id},
    );
    final before = await deckCount();

    final response = await materialize(id, artifact);
    final body = await json(response);

    expect(response.statusCode, HttpStatus.conflict, reason: '$body');
    expect(body['review_error'], 'constraints_mismatch');
    expect(await deckCount(), before);
  }, skip: skipReason);

  test(
    'resultado sem condição de virar deck ou com carta fora do catálogo',
    () async {
      final blocked = await generated(canMaterialize: false);
      final blockedBody = await read(blocked);
      expect(blockedBody.containsKey('review_artifact'), isFalse);
      final unavailable = await materialize(blocked, 'drv1.x.y');
      expect(unavailable.statusCode, HttpStatus.conflict);
      expect(
        (await json(unavailable))['error_code'],
        'generate_result_unavailable',
      );

      final missing = await generated(extraCard: 'Carta Inexistente $suffix');
      final artifact = (await read(missing))['review_artifact'];
      final response = await materialize(missing, artifact);
      final body = await json(response);
      expect(response.statusCode, HttpStatus.conflict, reason: '$body');
      expect(body['error_code'], 'generate_result_unresolvable');
      expect(body['unresolved_cards'], ['Carta Inexistente $suffix']);
    },
    skip: skipReason,
  );

  test('POST /decks não aceita lista de um pedido do Generate', () async {
    final response = await decks_route.onRequest(
      context('POST', '/decks', {
        'name': 'Injetado $suffix',
        'format': 'commander',
        'generate_request_id': await generated(),
        'cards': [
          {'name': elfName, 'quantity': 1},
        ],
      }),
    );

    expect(response.statusCode, HttpStatus.badRequest);
    expect(
      (await json(response))['error_code'],
      'generate_materialize_required',
    );
  }, skip: skipReason);

  test('D-29: a limpeza apaga o prompt e o texto de descrição do ledger; o '
      'desfazer não inventa a descrição', () async {
    final oldRequest = await generated(prompt: 'prompt antigo e pessoal');
    final freshRequest = await generated(prompt: 'prompt recente');
    await pool.execute(
      Sql.named('''
        UPDATE ai_generate_requests
        SET created_at = CURRENT_TIMESTAMP - INTERVAL '31 days'
        WHERE id = CAST(@id AS uuid)
      '''),
      parameters: {'id': oldRequest},
    );
    final deck = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format, description, revision)
        VALUES (CAST(@owner AS uuid), @name, 'commander', 'depois', 2)
        RETURNING id::text
      '''),
      parameters: {'owner': owner, 'name': 'Ledger $suffix'},
    );
    final deckId = deck.single.single! as String;
    final event = await pool.execute(
      Sql.named('''
        INSERT INTO deck_change_events (
          deck_id, user_id, revision_before, revision_after, operation,
          metadata_before, metadata_after, created_at
        ) VALUES (
          CAST(@deckId AS uuid), CAST(@owner AS uuid), 1, 2, 'deck_patch',
          '{"description": "prompt antigo na descrição"}'::jsonb,
          '{"description": "depois"}'::jsonb,
          CURRENT_TIMESTAMP - INTERVAL '31 days'
        ) RETURNING id::text
      '''),
      parameters: {'deckId': deckId, 'owner': owner},
    );
    final eventId = event.single.single! as String;

    // O ledger só aceita a redação completa, na transação marcada pela
    // limpeza: cada tentativa abaixo erra num único ponto.
    Future<void> expectRefused(String setClause, {required bool marked}) =>
        expectLater(
          pool.runTx((tx) async {
            if (marked) {
              await tx.execute(
                "SELECT set_config('manaloom.deck_ledger_redaction', "
                "'d29_prompt_retention', true)",
              );
            }
            await tx.execute(
              Sql.named(
                'UPDATE deck_change_events SET $setClause '
                'WHERE id = CAST(@id AS uuid)',
              ),
              parameters: {'id': eventId},
            );
          }),
          throwsA(isA<ServerException>()),
        );
    const nullBefore = """metadata_before = '{"description": null}'::jsonb""";
    const nullAfter = """metadata_after = '{"description": null}'::jsonb""";
    const stamp = 'description_redacted_at = CURRENT_TIMESTAMP';

    // Sem a marca da limpeza, nem a redação completa passa.
    await expectRefused('$nullBefore, $nullAfter, $stamp', marked: false);
    // Com a marca, mudar outra coluna junto segue recusado.
    await expectRefused(
      "operation = 'undo', $nullBefore, $nullAfter, $stamp",
      marked: true,
    );
    // Com a marca, trocar o texto por outro (em vez de apagar) é recusado.
    await expectRefused(
      """metadata_before = '{"description": "outro texto"}'::jsonb, """
      '$nullAfter, $stamp',
      marked: true,
    );
    // Com a marca, apagar o texto sem registrar a redação é recusado.
    await expectRefused('$nullBefore, $nullAfter', marked: true);
    // Com a marca, mexer em outra chave dos metadados é recusado.
    await expectRefused(
      """metadata_before = '{"description": null, "name": "x"}'::jsonb, """
      '$nullAfter, $stamp',
      marked: true,
    );

    final receipt = await RetentionCleanupRunner(pool).run(
      mode: RetentionCleanupMode.activate,
      runId: 'p004-$suffix',
      environment: const {
        retentionCleanupWriteApprovalEnvironment:
            retentionCleanupWriteApprovalValue,
      },
    );
    await pool.execute(
      Sql.named('DELETE FROM sync_state WHERE key = @key'),
      parameters: {'key': retentionCleanupStateKey},
    );
    expect(receipt['applied'], isTrue);

    final oldBody = await read(oldRequest);
    expect(oldBody['prompt'], isNull);
    expect(oldBody['prompt_available'], isFalse);
    expect(oldBody['prompt_purged_at'], isNotNull);
    expect(oldBody['controls'], isNotEmpty, reason: 'o pedido fica');
    expect((await read(freshRequest))['prompt'], 'prompt recente');

    final redacted = await pool.execute(
      Sql.named('''
        SELECT metadata_before->>'description', metadata_after->>'description',
               description_redacted_at IS NOT NULL, operation
        FROM deck_change_events WHERE id = CAST(@id AS uuid)
      '''),
      parameters: {'id': eventId},
    );
    expect(redacted.single, [null, null, true, 'deck_patch']);

    final history = await json(
      await changes_route.onRequest(
        context('GET', '/decks/$deckId/changes', null),
        deckId,
      ),
    );
    final listed = (history['events'] as List).single as Map;
    expect(listed['description_redacted'], isTrue);
    expect(listed['can_undo'], isFalse);

    final undo = await undo_route.onRequest(
      context('POST', '/decks/$deckId/changes/$eventId/undo', null),
      deckId,
      eventId,
    );
    expect(undo.statusCode, HttpStatus.conflict);
    expect((await json(undo))['error_code'], 'deck_undo_redacted');
  }, skip: skipReason);
}
