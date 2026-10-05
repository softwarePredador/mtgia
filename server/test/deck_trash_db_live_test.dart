@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../bin/ml_extract_features.dart' as ml;
import '../lib/ai/ai_generate_materialize_support.dart';
import '../lib/ai/optimize_request_support.dart';
import '../lib/ai/optimize_stage_telemetry.dart';
import '../lib/decks/deck_revision_support.dart';
import '../lib/decks/deck_trash_support.dart';
import '../lib/privacy/retention_cleanup.dart';
import '../lib/release_capability_policy.dart';
import '../lib/reports/shareable_report_service.dart';
import '../lib/user_data_privacy_service.dart';
import '../routes/ai/archetypes/index.dart' as archetypes_route;
import '../routes/ai/rebuild/index.dart' as rebuild_route;
import '../routes/decks/[id]/_middleware.dart' as deck_id_middleware;
import '../routes/decks/[id]/changes/[eventId]/undo/index.dart' as undo_route;
import '../routes/decks/[id]/changes/index.dart' as changes_route;
import '../routes/decks/[id]/index.dart' as deck_route;
import '../routes/decks/[id]/restore/index.dart' as restore_route;
import '../routes/decks/index.dart' as decks_route;
import '../routes/decks/trash/index.dart' as trash_route;
import '../routes/import/to-deck/preview/index.dart' as import_preview_route;
import '../routes/reports/[id].dart' as report_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// DCK-P0-06 (decisões D-30 e D-19 do dono) em PostgreSQL descartável:
/// apagar manda o deck para a lixeira sem apagar nada; o deck na lixeira some
/// de todas as superfícies (as rotas de `/decks/:id` pelo guarda, as de fora
/// pelo filtro), não conta em aprendizado e entra na exportação; restaurar o
/// devolve íntegro e privado, sem republicar relatório; a limpeza por prazo o
/// apaga de vez em 30 dias, com relatórios e eventos de aprendizado.
///
/// Requer `RUN_DECK_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// já migrado.
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
          'username': 'dck06_${key}_$suffix',
          'email': 'dck06_${key}_$suffix@example.invalid',
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
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM sync_state WHERE key = @key'),
      parameters: {'key': retentionCleanupStateKey},
    );
    await pool.execute(
      Sql.named('''
        DELETE FROM deck_learning_events
        WHERE commander_name LIKE @pattern
      '''),
      parameters: {'pattern': '% $suffix'},
    );
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'dck06\\_%\\_$suffix'},
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
    required String asUser,
    Map<String, String> headers = const {},
  }) => ScriptedRequestContext(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {'content-type': 'application/json', ...headers},
      body: body == null ? null : jsonEncode(body),
    ),
    providers: {
      Pool: pool,
      String: asUser,
      ReleaseCapabilityPolicy: releaseCapabilityPolicyWith({
        ...betaCoreCapabilities,
        'gallery_public',
      }),
    },
  );

  Future<Object?> json(Response response) async =>
      jsonDecode(await response.body());

  Future<String> seedDeck({
    required String userId,
    bool isPublic = false,
    String name = 'Deck',
  }) async {
    final deck = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format, is_public, description)
        VALUES (CAST(@userId AS uuid), @name, 'modern', @isPublic, 'lista')
        RETURNING id::text
      '''),
      parameters: {
        'userId': userId,
        'name': '$name $suffix',
        'isPublic': isPublic,
      },
    );
    final deckId = deck.single.single! as String;
    for (final entry in {islandId: 20, bearId: 4}.entries) {
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

  Future<Map<String, dynamic>> row(String deckId) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT is_public, revision, deleted_at
        FROM decks WHERE id = CAST(@deckId AS uuid)
      '''),
      parameters: {'deckId': deckId},
    );
    return result.isEmpty ? const {} : result.single.toColumnMap();
  }

  Future<List<String>> cardRows(String deckId) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT card_id::text || ':' || quantity || ':' || is_commander
        FROM deck_cards WHERE deck_id = CAST(@deckId AS uuid)
        ORDER BY card_id
      '''),
      parameters: {'deckId': deckId},
    );
    return [for (final line in result) line.single! as String];
  }

  Future<List<Map<String, dynamic>>> ledger(String deckId) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT id::text, operation, revision_before, revision_after,
               metadata_before, metadata_after
        FROM deck_change_events
        WHERE deck_id = CAST(@deckId AS uuid)
        ORDER BY revision_after
      '''),
      parameters: {'deckId': deckId},
    );
    return [for (final line in result) line.toColumnMap()];
  }

  Future<Response> delete(String deckId, {String? ifMatch}) =>
      deck_route.onRequest(
        context(
          'DELETE',
          '/decks/$deckId',
          null,
          asUser: owner,
          headers: {if (ifMatch != null) 'If-Match': ifMatch},
        ),
        deckId,
      );

  Future<Response> restore(String deckId, {String? asUser, String? ifMatch}) =>
      restore_route.onRequest(
        context(
          'POST',
          '/decks/$deckId/restore',
          null,
          asUser: asUser ?? owner,
          headers: {if (ifMatch != null) 'If-Match': ifMatch},
        ),
        deckId,
      );

  Future<String> share(String deckId) async {
    final report = await ShareableReportService(
      pool,
    ).createForDeck(userId: owner, deckId: deckId, body: const {});
    return report!['id'] as String;
  }

  Future<Response> publicReport(String reportId) => report_route.onRequest(
    ScriptedRequestContext(
      Request.get(Uri.parse('http://localhost/reports/$reportId')),
      providers: {Pool: pool},
    ),
    reportId,
  );

  test('apagar manda para a lixeira: nada sai do banco, o deck deixa a '
      'galeria e o relatório morre', () async {
    final deckId = await seedDeck(userId: owner, isPublic: true);
    final reportId = await share(deckId);
    expect((await publicReport(reportId)).statusCode, HttpStatus.ok);
    final cardsBefore = await cardRows(deckId);
    final revisionBefore = (await row(deckId))['revision'] as int;

    final response = await delete(deckId, ifMatch: '"$revisionBefore"');

    expect(response.statusCode, HttpStatus.noContent);
    final after = await row(deckId);
    expect(after['deleted_at'], isNotNull);
    expect(after['is_public'], isFalse);
    expect(after['revision'], revisionBefore + 1);
    expect(await cardRows(deckId), cardsBefore);
    final events = await ledger(deckId);
    expect(events.last['operation'], 'deck_delete');
    expect(events.last['revision_before'], revisionBefore);
    expect(events.last['metadata_before'], {'is_public': true});
    expect(events.last['metadata_after'], {'is_public': false});
    final report = await pool.execute(
      Sql.named(
        'SELECT deck_id::text, is_public FROM shared_deck_reports '
        'WHERE id = @id',
      ),
      parameters: {'id': reportId},
    );
    expect(report.single[0], deckId);
    expect(report.single[1], isFalse);
    expect((await publicReport(reportId)).statusCode, HttpStatus.notFound);

    // De novo: o deck já está na lixeira, então é como se não existisse.
    expect((await delete(deckId)).statusCode, HttpStatus.notFound);
  }, skip: skipReason);

  test('deck na lixeira some das rotas de /decks/:id; só o restaurar '
      'passa', () async {
    final trashed = await seedDeck(userId: owner);
    final alive = await seedDeck(userId: owner);
    expect((await delete(trashed)).statusCode, HttpStatus.noContent);

    final guarded = deck_id_middleware.middleware((context) async {
      final segments = context.request.uri.pathSegments;
      return deck_route.onRequest(context, segments[1]);
    });
    for (final (asUser, deckId, status) in [
      (owner, trashed, HttpStatus.notFound),
      (stranger, trashed, HttpStatus.notFound),
      (owner, alive, HttpStatus.ok),
    ]) {
      final response = await guarded(
        context('GET', '/decks/$deckId', null, asUser: asUser),
      );
      expect(response.statusCode, status, reason: '$asUser $deckId');
    }
    final refused = await guarded(
      context('GET', '/decks/$trashed/export', null, asUser: owner),
    );
    expect(refused.statusCode, HttpStatus.notFound);
    expect(
      (await json(refused))! as Map,
      containsPair('error_code', 'deck_not_found'),
    );

    var reached = 0;
    final probe = deckTrashGuard()((context) {
      reached += 1;
      return Response(statusCode: HttpStatus.accepted);
    });
    for (final (method, path, passes) in [
      ('POST', '/decks/$trashed/restore', true),
      ('POST', '/decks/$trashed/cards', false),
      ('PATCH', '/decks/$trashed', false),
      ('GET', '/decks/$trashed/changes', false),
      ('GET', '/decks/$alive/changes', true),
      ('GET', '/decks/trash', true),
    ]) {
      final before = reached;
      final response = await probe(context(method, path, null, asUser: owner));
      expect(
        response.statusCode,
        passes ? HttpStatus.accepted : HttpStatus.notFound,
        reason: '$method $path',
      );
      expect(reached, before + (passes ? 1 : 0), reason: '$method $path');
    }
  }, skip: skipReason);

  test('a mudança de conteúdo recusa deck na lixeira mesmo sem o guarda '
      '(a trava da linha fecha a corrida com o DELETE)', () async {
    final deckId = await seedDeck(userId: owner);
    expect((await delete(deckId)).statusCode, HttpStatus.noContent);
    final revision = (await row(deckId))['revision'] as int;

    final locked = await pool.runTx(
      (session) => lockDeckForMutation(
        session,
        deckId: deckId,
        userId: owner,
        request: DeckMutationRequest.fromHeaders(
          const {},
          operation: 'deck_patch',
          deckId: deckId,
          requireIfMatch: false,
        ),
      ),
    );
    expect(locked, isNull);

    final patch = await deck_route.onRequest(
      context('PATCH', '/decks/$deckId', {
        'name': 'Mexido $suffix',
      }, asUser: owner),
      deckId,
    );
    expect(patch.statusCode, HttpStatus.notFound);
    expect((await row(deckId))['revision'], revision);
  }, skip: skipReason);

  test('deck na lixeira some das superfícies fora de /decks/:id', () async {
    final trashed = await seedDeck(userId: owner, name: 'Lixeira');
    final alive = await seedDeck(userId: owner, name: 'Vivo');
    expect((await delete(trashed)).statusCode, HttpStatus.noContent);

    final list = await decks_route.onRequest(
      context('GET', '/decks', null, asUser: owner),
    );
    expect(list.statusCode, HttpStatus.ok);
    final ids = {for (final deck in (await json(list))! as List) deck['id']};
    expect(ids, contains(alive));
    expect(ids, isNot(contains(trashed)));

    final preview = await import_preview_route.onRequest(
      context('POST', '/import/to-deck/preview', {
        'deck_id': trashed,
        'list': '4 Grizzly Bears $suffix',
      }, asUser: owner),
    );
    expect(preview.statusCode, HttpStatus.notFound);

    expect(
      await loadOptimizeStoredDeckSettings(
        pool: pool,
        deckId: trashed,
        userId: owner,
      ),
      isNull,
    );
    expect(
      await loadOptimizeStoredDeckSettings(
        pool: pool,
        deckId: alive,
        userId: owner,
      ),
      isNotNull,
    );
    await expectLater(
      verifyOptimizeDeckAccess(pool: pool, deckId: trashed, userId: owner),
      throwsA(isA<OptimizeDeckContextException>()),
    );
    await verifyOptimizeDeckAccess(pool: pool, deckId: alive, userId: owner);
    // Com e sem a telemetria de estágio (as duas leituras do contexto).
    for (final telemetry in [
      null,
      OptimizeStageTelemetry(deckId: trashed, requestMode: 'optimize'),
    ]) {
      await expectLater(
        loadOptimizeDeckContext(
          pool: pool,
          deckId: trashed,
          userId: owner,
          targetArchetype: 'midrange',
          requestMode: 'optimize',
          intensity: 'balanced',
          bracket: null,
          keepTheme: true,
          telemetry: telemetry,
        ),
        throwsA(
          isA<OptimizeDeckContextException>().having(
            (error) => error.code,
            'code',
            'DECK_NOT_FOUND',
          ),
        ),
        reason: 'telemetria: ${telemetry != null}',
      );
    }

    for (final (name, call) in [
      (
        'archetypes',
        () => archetypes_route.onRequest(
          context('POST', '/ai/archetypes', {
            'deck_id': trashed,
          }, asUser: owner),
        ),
      ),
      (
        'rebuild',
        () => rebuild_route.onRequest(
          context('POST', '/ai/rebuild', {
            'deck_id': trashed,
            'save_mode': 'preview_only',
          }, asUser: owner),
        ),
      ),
    ]) {
      expect((await call()).statusCode, HttpStatus.notFound, reason: name);
    }

    expect(
      await ShareableReportService(
        pool,
      ).createForDeck(userId: owner, deckId: trashed, body: const {}),
      isNull,
    );
  }, skip: skipReason);

  test('repetir a materialização do Generate não devolve deck da lixeira '
      'como vivo', () async {
    final deckId = await seedDeck(userId: owner);
    final request = await pool.execute(
      Sql.named('''
        INSERT INTO ai_generate_requests (
          user_id, request_key, format, status, materialized_deck_id,
          materialized_at
        ) VALUES (
          CAST(@userId AS uuid), @key, 'modern', 'completed',
          CAST(@deckId AS uuid), CURRENT_TIMESTAMP
        ) RETURNING id::text
      '''),
      parameters: {'userId': owner, 'key': 'dck06-$suffix', 'deckId': deckId},
    );
    final requestId = request.single.single! as String;
    Future<Map<String, Object?>> materialize() => pool.runTx(
      (session) => materializeAiGenerateRequest(
        session,
        userId: owner,
        requestId: requestId,
        token: null,
        name: null,
        signingSecret: 'segredo-de-teste-dck06',
      ),
    );

    final replay = await materialize();
    expect(replay['replayed'], isTrue);
    expect((replay['deck']! as Map)['id'], deckId);

    expect((await delete(deckId)).statusCode, HttpStatus.noContent);
    await expectLater(
      materialize(),
      throwsA(
        isA<AiGenerateMaterializeRefusal>().having(
          (refusal) => refusal.responseBody['error_code'],
          'error_code',
          'generate_deck_in_trash',
        ),
      ),
    );
  }, skip: skipReason);

  test('a lixeira lista só os decks apagados do dono, com a data da '
      'purga', () async {
    final first = await seedDeck(userId: owner, name: 'Primeiro');
    final second = await seedDeck(userId: owner, name: 'Segundo');
    final alive = await seedDeck(userId: owner, name: 'Vivo');
    final foreign = await seedDeck(userId: stranger, name: 'Alheio');
    expect((await delete(first)).statusCode, HttpStatus.noContent);
    expect((await delete(second)).statusCode, HttpStatus.noContent);
    final strangerDelete = await deck_route.onRequest(
      context('DELETE', '/decks/$foreign', null, asUser: stranger),
      foreign,
    );
    expect(strangerDelete.statusCode, HttpStatus.noContent);

    final response = await trash_route.onRequest(
      context('GET', '/decks/trash', null, asUser: owner),
    );
    expect(response.statusCode, HttpStatus.ok);
    final body = (await json(response))! as Map<String, dynamic>;
    expect(body['retention_days'], 30);
    final decks = (body['decks'] as List).cast<Map<String, dynamic>>();
    final ids = [for (final deck in decks) deck['id']];
    expect(ids, containsAllInOrder([second, first]));
    expect(ids, isNot(contains(alive)));
    expect(ids, isNot(contains(foreign)));
    final entry = decks.firstWhere((deck) => deck['id'] == first);
    expect(entry['card_count'], 24);
    final deletedAt = DateTime.parse(entry['deleted_at'] as String);
    expect(
      DateTime.parse(entry['purge_after'] as String).difference(deletedAt),
      const Duration(days: 30),
    );
  }, skip: skipReason);

  test('restaurar devolve o deck íntegro e privado, sem republicar o '
      'relatório', () async {
    final deckId = await seedDeck(userId: owner, isPublic: true);
    final reportId = await share(deckId);
    final cardsBefore = await cardRows(deckId);
    expect((await delete(deckId)).statusCode, HttpStatus.noContent);
    final trashedRevision = (await row(deckId))['revision'] as int;

    final foreign = await restore(deckId, asUser: stranger);
    expect(foreign.statusCode, HttpStatus.notFound);
    expect(
      (await json(foreign))! as Map,
      containsPair('error_code', deckNotInTrashCode),
    );
    final stale = await restore(deckId, ifMatch: '"${trashedRevision - 1}"');
    expect(stale.statusCode, HttpStatus.conflict);
    expect((await row(deckId))['deleted_at'], isNotNull);

    final response = await restore(deckId, ifMatch: '"$trashedRevision"');
    expect(response.statusCode, HttpStatus.ok);
    final body = (await json(response))! as Map<String, dynamic>;
    expect(body['change_operation'], 'deck_restore');
    expect(body['revision'], trashedRevision + 1);
    expect(body['is_public'], isFalse);
    expect(
      response.headers['etag'] ?? response.headers['ETag'],
      '"${trashedRevision + 1}"',
    );

    final after = await row(deckId);
    expect(after['deleted_at'], isNull);
    expect(after['is_public'], isFalse);
    expect(after['revision'], trashedRevision + 1);
    expect(await cardRows(deckId), cardsBefore);
    expect((await ledger(deckId)).last['operation'], 'deck_restore');
    expect((await publicReport(reportId)).statusCode, HttpStatus.notFound);

    final list = await decks_route.onRequest(
      context('GET', '/decks', null, asUser: owner),
    );
    expect({
      for (final deck in (await json(list))! as List) deck['id'],
    }, contains(deckId));
    // Um deck vivo não está na lixeira.
    expect((await restore(deckId)).statusCode, HttpStatus.notFound);
  }, skip: skipReason);

  test('lixeira e restaurar ficam no histórico, sem desfazer', () async {
    final deckId = await seedDeck(userId: owner);
    expect((await delete(deckId)).statusCode, HttpStatus.noContent);
    expect((await restore(deckId)).statusCode, HttpStatus.ok);

    final history = await changes_route.onRequest(
      context('GET', '/decks/$deckId/changes', null, asUser: owner),
      deckId,
    );
    final events = ((await json(history))! as Map)['events'] as List<dynamic>;
    expect(
      [for (final event in events) event['operation']],
      ['deck_restore', 'deck_delete'],
    );
    expect([for (final event in events) event['can_undo']], [false, false]);

    final restoreEvent = (await ledger(deckId)).last;
    final revision = (await row(deckId))['revision'] as int;
    final undo = await undo_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/changes/${restoreEvent['id']}/undo',
        null,
        asUser: owner,
      ),
      deckId,
      restoreEvent['id'] as String,
    );
    expect(undo.statusCode, HttpStatus.conflict);
    expect(
      (await json(undo))! as Map,
      containsPair('error_code', 'deck_undo_unsupported'),
    );
    expect((await row(deckId))['revision'], revision);
    expect((await row(deckId))['deleted_at'], isNull);
  }, skip: skipReason);

  test(
    'deck na lixeira entra na exportação e fica fora do aprendizado',
    () async {
      final trashed = await seedDeck(userId: owner, name: 'Exportado');
      final alive = await seedDeck(userId: owner, name: 'Aprendido');
      expect((await delete(trashed)).statusCode, HttpStatus.noContent);

      final export = await UserDataPrivacyService(pool).exportUserData(owner);
      final decks = ((export['data'] as Map)['decks'] as List).cast<Map>();
      final exported = decks.singleWhere((deck) => deck['id'] == trashed);
      expect(exported['deleted_at'], isNotNull);
      final cards = ((export['data'] as Map)['deck_cards'] as List).cast<Map>();
      expect(cards.where((card) => card['deck_id'] == trashed), hasLength(2));

      final features = await pool.execute(ml.mlFeatureDeckSourceSql);
      final featureIds = {for (final line in features) '${line[0]}'};
      expect(featureIds, contains(alive));
      expect(featureIds, isNot(contains(trashed)));

      // O pull do Hermes (bin/pull_learning_events.py) só leva evento de deck
      // vivo: o de deck na lixeira espera e o de deck que não existe não sai.
      final missing =
          '00000000-0000-4000-8000-${'$suffix'.padLeft(12, '0').substring(0, 12)}';
      for (final deckId in [alive, trashed, missing]) {
        await pool.execute(
          Sql.named('''
          INSERT INTO deck_learning_events (
            deck_id, commander_name, format, card_count, created_at
          ) VALUES (
            CAST(@deckId AS uuid), @name, 'modern', 24,
            TIMESTAMPTZ '2001-01-01 00:00:00+00'
          )
        '''),
          parameters: {'deckId': deckId, 'name': 'Evento $suffix'},
        );
      }
      final pull = File('bin/pull_learning_events.py').readAsStringSync();
      final sql =
          RegExp(
            r'PENDING_EVENTS_SQL = """(.*?)"""',
            dotAll: true,
          ).firstMatch(pull)!.group(1)!;
      final pending = await pool.execute(sql);
      final pendingDecks = {for (final line in pending) '${line[1]}'};
      expect(pendingDecks, contains(alive));
      expect(pendingDecks, isNot(contains(trashed)));
      expect(pendingDecks, isNot(contains(missing)));
    },
    skip: skipReason,
  );

  test('a limpeza por prazo apaga de vez o deck com mais de 30 dias na '
      'lixeira, com relatórios e eventos de aprendizado', () async {
    const approval = {
      retentionCleanupWriteApprovalEnvironment:
          retentionCleanupWriteApprovalValue,
    };
    final reportOf = <String, String>{};
    Future<String> trashedFor(Duration age, String name) async {
      final deckId = await seedDeck(userId: owner, name: name);
      await deck_route.onRequest(
        context('PATCH', '/decks/$deckId', {
          'description': 'nova $name',
        }, asUser: owner),
        deckId,
      );
      reportOf[deckId] = await share(deckId);
      await pool.execute(
        Sql.named('''
          INSERT INTO deck_learning_events (deck_id, commander_name, format)
          VALUES (CAST(@deckId AS uuid), @name, 'modern')
        '''),
        parameters: {'deckId': deckId, 'name': '$name $suffix'},
      );
      expect((await delete(deckId)).statusCode, HttpStatus.noContent);
      // O tempo passa: o deck foi apagado há [age], e o relatório e o evento
      // nasceram antes disso (depois da lixeira não nasce cópia nenhuma).
      await pool.execute(
        Sql.named('''
          UPDATE decks SET deleted_at = CURRENT_TIMESTAMP - @age::interval
          WHERE id = CAST(@deckId AS uuid)
        '''),
        parameters: {'deckId': deckId, 'age': '${age.inMinutes} minutes'},
      );
      for (final table in const [
        'shared_deck_reports',
        'deck_learning_events',
      ]) {
        await pool.execute(
          Sql.named('''
            UPDATE $table
            SET created_at = CURRENT_TIMESTAMP - @age::interval - INTERVAL '1 day'
            WHERE deck_id = CAST(@deckId AS uuid)
          '''),
          parameters: {'deckId': deckId, 'age': '${age.inMinutes} minutes'},
        );
      }
      return deckId;
    }

    // O relatório conta pelo id: sem a regra dele, a cascata só zeraria o
    // deck_id (SET NULL) e a cópia ficaria.
    Future<Map<String, int>> footprint(String deckId) async {
      final result = await pool.execute(
        Sql.named('''
          SELECT
            (SELECT COUNT(*)::int FROM decks WHERE id = CAST(@d AS uuid)),
            (SELECT COUNT(*)::int FROM deck_cards
              WHERE deck_id = CAST(@d AS uuid)),
            (SELECT COUNT(*)::int FROM deck_change_events
              WHERE deck_id = CAST(@d AS uuid)),
            (SELECT COUNT(*)::int FROM shared_deck_reports WHERE id = @r),
            (SELECT COUNT(*)::int FROM deck_learning_events
              WHERE deck_id = CAST(@d AS uuid))
        '''),
        parameters: {'d': deckId, 'r': reportOf[deckId]},
      );
      final values = result.single;
      return {
        'decks': values[0]! as int,
        'deck_cards': values[1]! as int,
        'deck_change_events': values[2]! as int,
        'shared_deck_reports': values[3]! as int,
        'deck_learning_events': values[4]! as int,
      };
    }

    final expired = await trashedFor(
      deckTrashRetention + const Duration(minutes: 5),
      'Vencido',
    );
    final recent = await trashedFor(
      deckTrashRetention - const Duration(minutes: 5),
      'Recente',
    );
    final alive = await seedDeck(userId: owner, name: 'Antigo vivo');
    await pool.execute(
      Sql.named('''
        UPDATE decks SET created_at = CURRENT_TIMESTAMP - INTERVAL '400 days'
        WHERE id = CAST(@deckId AS uuid)
      '''),
      parameters: {'deckId': alive},
    );
    final aliveReport = await share(alive);
    expect((await footprint(expired))['deck_change_events'], 2);
    final recentBefore = await footprint(recent);

    final dryRun = await RetentionCleanupRunner(pool).run(
      mode: RetentionCleanupMode.dryRun,
      runId: 'dck06-dry-$suffix',
      environment: const {},
    );
    final eligible = {
      for (final rule in (dryRun['rules'] as List).cast<Map>())
        rule['id']: rule['eligible'],
    };
    for (final id in const [
      'shared_deck_reports_trashed_deck_30d',
      'deck_learning_events_trashed_deck_30d',
      'decks_trash_30d',
    ]) {
      expect(eligible[id], greaterThanOrEqualTo(1), reason: id);
    }
    expect((await footprint(expired))['decks'], 1);

    final receipt = await RetentionCleanupRunner(pool).run(
      mode: RetentionCleanupMode.activate,
      runId: 'dck06-$suffix',
      environment: approval,
    );
    expect(receipt['applied'], isTrue);
    expect(await footprint(expired), {
      'decks': 0,
      'deck_cards': 0,
      'deck_change_events': 0,
      'shared_deck_reports': 0,
      'deck_learning_events': 0,
    });
    expect(await footprint(recent), recentBefore);
    expect((await row(alive))['deleted_at'], isNull);
    expect((await publicReport(aliveReport)).statusCode, HttpStatus.ok);
  }, skip: skipReason);
}
