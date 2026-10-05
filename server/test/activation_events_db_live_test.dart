@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/users/me/activation-events/index.dart' as route;
import 'support/scripted_pool.dart';

/// BT-KPI-001 em PostgreSQL descartável: `POST /users/me/activation-events`
/// grava só o que o catálogo `activation_events_v1` aceita. Decklist, nome de
/// deck, texto livre e evento aposentado caem com 400 e nenhuma linha; o deck
/// de outra pessoa (ou na lixeira) cai com 404; os IDs internos que o app
/// atual ainda manda não chegam ao banco; a mesma chave de idempotência grava
/// uma vez só, guardada como hash (migration 073).
///
/// Requer `RUN_KPI_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// já migrado.
void main() {
  final enabled = Platform.environment['RUN_KPI_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  late Pool pool;
  var userCount = 0;

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
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'kpi_events_${suffix}_%'},
    );
    await pool.close();
  });

  Future<String> newUser() async {
    final name = 'kpi_events_${suffix}_${userCount++}';
    final user = await pool.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash)
        VALUES (@name, @email, 'x')
        RETURNING id::text
      '''),
      parameters: {'name': name, 'email': '$name@example.invalid'},
    );
    return user.single.single! as String;
  }

  Future<String> newDeck(String userId, {bool trashed = false}) async {
    final deck = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format, deleted_at)
        VALUES (
          CAST(@userId AS uuid), 'Deck secreto $suffix', 'commander',
          CASE WHEN @trashed THEN NOW() ELSE NULL END
        )
        RETURNING id::text
      '''),
      parameters: {'userId': userId, 'trashed': trashed},
    );
    return deck.single.single! as String;
  }

  Future<(int, Map<String, dynamic>)> post(String userId, Object? body) async {
    final response = await route.onRequest(
      ScriptedRequestContext(
        Request(
          'POST',
          Uri.parse('http://localhost/users/me/activation-events'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(body),
        ),
        providers: {Pool: pool, String: userId},
      ),
    );
    return (
      response.statusCode,
      jsonDecode(await response.body()) as Map<String, dynamic>,
    );
  }

  Future<List<Map<String, dynamic>>> rows(String userId) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT event_name, source, format, deck_id::text AS deck_id,
               metadata, dedupe_key
        FROM activation_funnel_events
        WHERE user_id = CAST(@userId AS uuid)
        ORDER BY created_at, id
      '''),
      parameters: {'userId': userId},
    );
    return [for (final row in result) row.toColumnMap()];
  }

  test('evento do onboarding grava só enumerados e o hash da chave, uma vez '
      'por chave', () async {
    final userId = await newUser();
    final key = 'onboarding:v1:$userId:started';
    final body = {
      'event_name': 'core_flow_started',
      'format': 'commander',
      'source': 'onboarding',
      'metadata': {
        'goal': 'buildDeck',
        'experience': 'firstSteps',
        'idempotency_key': key,
      },
    };

    final (status, first) = await post(userId, body);
    expect(status, HttpStatus.created);
    expect(first, {'ok': true, 'catalog_version': 'activation_events_v1'});

    final (repeatedStatus, repeated) = await post(userId, body);
    expect(repeatedStatus, HttpStatus.ok);
    expect(repeated['duplicate'], isTrue);

    final stored = await rows(userId);
    expect(stored, hasLength(1));
    expect(stored.single['event_name'], 'core_flow_started');
    expect(stored.single['source'], 'onboarding');
    expect(stored.single['format'], 'commander');
    expect(stored.single['metadata'], {
      'experience': 'firstSteps',
      'goal': 'buildDeck',
    });
    expect(
      stored.single['dedupe_key'],
      sha256.convert(utf8.encode(key)).toString(),
    );
    expect(jsonEncode(stored), isNot(contains(key)));

    // Outra pessoa com a mesma chave grava a própria linha.
    final other = await newUser();
    final (otherStatus, _) = await post(other, body);
    expect(otherStatus, HttpStatus.created);
    expect(await rows(other), hasLength(1));
  }, skip: skipReason);

  test('prévia do Optimize e rebuild: deck do dono, sem arquétipo livre nem '
      'IDs internos no banco', () async {
    final userId = await newUser();
    final deckId = await newDeck(userId);
    final (status, body) = await post(userId, {
      'event_name': 'optimize_preview_received',
      'deck_id': deckId,
      'source': 'deck_provider.optimizeDeck',
      'metadata': {
        'archetype': 'Plano secreto $suffix',
        'bracket': 3,
        'keep_theme': true,
        'intensity': 'aggressive',
        'recommendation_context': {
          'prefer_collection': false,
          'rebuild_intent': 'optimized',
          'post_game_note_id': 'nota-$suffix',
        },
      },
    });
    expect(status, HttpStatus.created);
    expect(body['dropped_fields'], [
      'metadata.archetype',
      'metadata.recommendation_context.post_game_note_id',
    ]);

    final (rebuildStatus, rebuild) = await post(userId, {
      'event_name': 'deck_rebuild_created',
      'deck_id': deckId,
      'source': 'deck_provider.rebuildDeck',
      'metadata': {
        'source_deck_id': deckId,
        'rebuild_scope_selected': 'full_non_commander_rebuild',
        'save_mode': 'draft_clone',
      },
    });
    expect(rebuildStatus, HttpStatus.created);
    expect(rebuild['dropped_fields'], ['metadata.source_deck_id']);

    final stored = await rows(userId);
    expect(stored.map((row) => row['deck_id']), [deckId, deckId]);
    expect(stored.first['metadata'], {
      'bracket': 3,
      'intensity': 'aggressive',
      'keep_theme': true,
      'recommendation_context': {
        'prefer_collection': false,
        'rebuild_intent': 'optimized',
      },
    });
    expect(stored.last['metadata'], {
      'rebuild_scope_selected': 'full_non_commander_rebuild',
      'save_mode': 'draft_clone',
    });
    final metadataText = jsonEncode([
      for (final row in stored) row['metadata'],
    ]);
    expect(metadataText, isNot(contains('Plano secreto')));
    expect(metadataText, isNot(contains('nota-$suffix')));
    expect(metadataText, isNot(contains(deckId)));
    expect(stored.every((row) => row['dedupe_key'] == null), isTrue);
  }, skip: skipReason);

  test('deck de outra pessoa ou na lixeira: 404 e nenhuma linha', () async {
    final owner = await newUser();
    final stranger = await newUser();
    final ownersDeck = await newDeck(owner);
    final trashedDeck = await newDeck(stranger, trashed: true);

    for (final deckId in [ownersDeck, trashedDeck]) {
      final (status, body) = await post(stranger, {
        'event_name': 'optimize_preview_received',
        'deck_id': deckId,
        'source': 'deck_provider.optimizeDeck',
        'metadata': {'bracket': 2},
      });
      expect(status, HttpStatus.notFound, reason: deckId);
      expect(body['error_code'], 'deck_not_found');
    }
    expect(await rows(stranger), isEmpty);
  }, skip: skipReason);

  test('decklist, nome de deck, texto livre e evento aposentado: 400 e '
      'nenhuma linha', () async {
    final userId = await newUser();
    final cases = <(Object?, String, String?)>[
      (
        {
          'event_name': 'deck_created',
          'source': 'deck_provider.createDeck',
          'metadata': {
            'cards': ['1 Sol Ring', '1 Talrand, Sky Summoner'],
          },
        },
        'activation_event_field_not_allowed',
        'metadata.cards',
      ),
      (
        {
          'event_name': 'deck_created',
          'source': 'deck_provider.createDeck',
          'deck_name': 'Talrand do João',
        },
        'activation_event_field_not_allowed',
        'deck_name',
      ),
      (
        {
          'event_name': 'onboarding_goal_selected',
          'source': 'onboarding',
          'metadata': {'goal': 'meu objetivo em texto livre'},
        },
        'activation_event_value_invalid',
        'metadata.goal',
      ),
      (
        {
          'event_name': 'deck_optimized',
          'source': 'deck_provider.optimizeDeck',
        },
        'activation_event_unknown',
        'event_name',
      ),
      (
        {
          'event_name': 'optimize_preview_received',
          'source': 'deck_provider.optimizeDeck',
          'deck_id': 'nao-e-uuid',
        },
        'activation_event_value_invalid',
        'deck_id',
      ),
      (['deck_created'], 'activation_event_body_invalid', null),
    ];
    for (final (body, code, field) in cases) {
      final (status, response) = await post(userId, body);
      expect(status, HttpStatus.badRequest, reason: '$body');
      expect(response['error_code'], code, reason: '$body');
      expect(response['field'], field, reason: '$body');
    }
    expect(await rows(userId), isEmpty);
  }, skip: skipReason);

  test('a 073 recusa chave que não é hash e repetição fora da rota', () async {
    final userId = await newUser();
    Future<void> insert(String dedupeKey) => pool.execute(
      Sql.named('''
        INSERT INTO activation_funnel_events (
          user_id, event_name, source, dedupe_key
        ) VALUES (
          CAST(@userId AS uuid), 'deck_created', 'deck_provider.createDeck',
          @dedupeKey
        )
      '''),
      parameters: {'userId': userId, 'dedupeKey': dedupeKey},
    );

    await expectLater(
      insert('onboarding:v1:$userId:started'),
      throwsA(
        isA<ServerException>().having((error) => error.code, 'code', '23514'),
      ),
    );
    final hash = 'a' * 64;
    await insert(hash);
    await expectLater(
      insert(hash),
      throwsA(
        isA<ServerException>().having((error) => error.code, 'code', '23505'),
      ),
    );
    expect(await rows(userId), hasLength(1));
  }, skip: skipReason);
}
