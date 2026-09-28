@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/release_capability_policy.dart';
import '../lib/retention/post_game_note_service.dart';
import '../routes/decks/[id]/index.dart' as deck_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// LC-P0-05 (achado 3 dos fluxos) em PostgreSQL descartável: o
/// `deck_version_at` do `GET /decks/:id` é o instante da revisão do deck, não
/// o da requisição. Ler de novo devolve o mesmo instante (o seletor de cartas
/// do pós-jogo compara com `isAtSameMomentAs`, e o cache de 5 min do app
/// expira durante qualquer partida); mudar o deck muda a revisão e o
/// instante; a nota do pós-jogo grava o mesmo instante.
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
  late String islandId;

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
        'username': 'lc05_owner_$suffix',
        'email': 'lc05_owner_$suffix@example.invalid',
      },
    );
    owner = user.single.single! as String;
    final card = await pool.execute(
      Sql.named('''
        INSERT INTO cards (scryfall_id, name, type_line, color_identity)
        VALUES (gen_random_uuid(), @name, 'Basic Land — Island', '{}')
        RETURNING id::text
      '''),
      parameters: {'name': 'Island $suffix'},
    );
    islandId = card.single.single! as String;
    await pool.execute(
      Sql.named('''
        INSERT INTO card_legalities (card_id, format, status)
        VALUES (CAST(@id AS uuid), 'modern', 'legal')
      '''),
      parameters: {'id': islandId},
    );
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username = @username'),
      parameters: {'username': 'lc05_owner_$suffix'},
    );
    await pool.execute(
      Sql.named('DELETE FROM cards WHERE name = @name'),
      parameters: {'name': 'Island $suffix'},
    );
    await pool.close();
  });

  RequestContext context(String method, String path, Object? body) =>
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
          ReleaseCapabilityPolicy: releaseCapabilityPolicyWith(
            betaCoreCapabilities,
          ),
        },
      );

  Future<Map<String, dynamic>> readDeck(String deckId) async {
    final response = await deck_route.onRequest(
      context('GET', '/decks/$deckId', null),
      deckId,
    );
    expect(response.statusCode, HttpStatus.ok);
    return jsonDecode(await response.body()) as Map<String, dynamic>;
  }

  Future<String> seedDeck() async {
    final deck = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format)
        VALUES (CAST(@userId AS uuid), @name, 'modern')
        RETURNING id::text
      '''),
      parameters: {'userId': owner, 'name': 'Versão $suffix'},
    );
    final deckId = deck.single.single! as String;
    await pool.execute(
      Sql.named('''
        INSERT INTO deck_cards (deck_id, card_id, quantity)
        VALUES (CAST(@deckId AS uuid), CAST(@cardId AS uuid), 20)
      '''),
      parameters: {'deckId': deckId, 'cardId': islandId},
    );
    return deckId;
  }

  test('a mesma revisão devolve o mesmo deck_version_at, que é o instante '
      'dela', () async {
    final deckId = await seedDeck();
    final created = await pool.execute(
      Sql.named(
        'SELECT created_at FROM decks WHERE id = CAST(@deckId AS uuid)',
      ),
      parameters: {'deckId': deckId},
    );

    final first = await readDeck(deckId);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = await readDeck(deckId);

    expect(first['revision'], 1);
    expect(second['deck_version_at'], first['deck_version_at']);
    expect(second['deck_snapshot_hash'], first['deck_snapshot_hash']);
    expect(
      DateTime.parse(first['deck_version_at'] as String),
      (created.single.single! as DateTime).toUtc(),
    );
  }, skip: skipReason);

  test('mudar o deck muda a revisão e o instante, que fica estável na '
      'revisão nova', () async {
    final deckId = await seedDeck();
    final before = await readDeck(deckId);

    final patch = await deck_route.onRequest(
      context('PATCH', '/decks/$deckId', {'name': 'Versão nova $suffix'}),
      deckId,
    );
    expect(patch.statusCode, HttpStatus.ok);
    final event = await pool.execute(
      Sql.named('''
        SELECT created_at FROM deck_change_events
        WHERE deck_id = CAST(@deckId AS uuid) AND revision_after = 2
      '''),
      parameters: {'deckId': deckId},
    );

    final after = await readDeck(deckId);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final again = await readDeck(deckId);

    expect(after['revision'], 2);
    expect(after['deck_version_at'], isNot(before['deck_version_at']));
    expect(
      DateTime.parse(after['deck_version_at'] as String),
      (event.single.single! as DateTime).toUtc(),
    );
    expect(again['deck_version_at'], after['deck_version_at']);
  }, skip: skipReason);

  test('a nota do pós-jogo sem versão do app grava o instante da revisão '
      'lida pelo seletor', () async {
    final deckId = await seedDeck();
    final deck = await readDeck(deckId);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await PostGameNoteService(pool).upsertNote(
      userId: owner,
      deckId: deckId,
      note: {
        'id': 'lc05-$suffix',
        'result': 'vitória',
        'table_level': 'casual',
        'notes': 'partida longa',
        'performed_well': const [],
        'underperformed': const [],
        'issues': const [],
      },
    );
    final stored = await pool.execute(
      Sql.named('''
        SELECT deck_snapshot_hash, deck_version_at
        FROM post_game_notes WHERE id = @id
      '''),
      parameters: {'id': 'lc05-$suffix'},
    );

    expect(stored.single[0], deck['deck_snapshot_hash']);
    expect(
      (stored.single[1]! as DateTime).toUtc(),
      DateTime.parse(deck['deck_version_at'] as String),
    );
  }, skip: skipReason);
}
