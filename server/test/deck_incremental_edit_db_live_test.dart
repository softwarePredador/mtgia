@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/release_capability_policy.dart';
import '../routes/decks/[id]/cards/remove/index.dart' as remove_route;
import '../routes/decks/[id]/index.dart' as deck_route;
import '../routes/decks/index.dart' as decks_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// DCK-P0-00 em PostgreSQL descartável: edição incremental sob
/// `decks_private` (D-27) e deck vazio nunca público. As rotas rodam de
/// verdade, chamadas direto (o portão de capability tem teste próprio).
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
          'username': 'dck00_${key}_$suffix',
          'email': 'dck00_${key}_$suffix@example.invalid',
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
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'dck00\\_%\\_$suffix'},
    );
    await pool.execute(
      Sql.named('DELETE FROM cards WHERE name LIKE @pattern'),
      parameters: {'pattern': '% $suffix'},
    );
    await pool.close();
  });

  ReleaseCapabilityPolicy policy({bool gallery = false}) =>
      releaseCapabilityPolicyWith({
        ...betaCoreCapabilities,
        if (gallery) 'gallery_public',
      });

  RequestContext context(
    String method,
    String path,
    Object? body, {
    required String asUser,
    required ReleaseCapabilityPolicy capabilities,
  }) => ScriptedRequestContext(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    ),
    providers: {
      Pool: pool,
      String: asUser,
      ReleaseCapabilityPolicy: capabilities,
    },
  );

  Future<Map<String, dynamic>> json(Response response) async =>
      jsonDecode(await response.body()) as Map<String, dynamic>;

  Future<String> seedDeck({
    required String userId,
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
        'userId': userId,
        'name': 'Deck $suffix',
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

  Future<Map<String, dynamic>> readDeck(String deckId) async {
    final deck = await pool.execute(
      Sql.named('''
        SELECT name, description, archetype, bracket, is_public
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
    return {
      ...deck.single.toColumnMap(),
      'cards': {for (final row in cards) row[0]! as String: row[1]! as int},
    };
  }

  test('deck criado sem is_public nasce privado', () async {
    final response = await decks_route.onRequest(
      context(
        'POST',
        '/decks',
        {'name': 'Novo $suffix', 'format': 'modern', 'cards': const []},
        asUser: owner,
        capabilities: policy(gallery: true),
      ),
    );
    final body = await json(response);

    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    expect(body['is_public'], isFalse);
    expect((await readDeck(body['id'].toString()))['is_public'], isFalse);
  }, skip: skipReason);

  test('deck vazio público é recusado e nada é gravado', () async {
    final before = await pool.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM decks WHERE user_id = CAST(@userId AS uuid)',
      ),
      parameters: {'userId': owner},
    );

    final response = await decks_route.onRequest(
      context(
        'POST',
        '/decks',
        {
          'name': 'Vazio $suffix',
          'format': 'modern',
          'is_public': true,
          'cards': const [],
        },
        asUser: owner,
        capabilities: policy(gallery: true),
      ),
    );

    expect(response.statusCode, HttpStatus.unprocessableEntity);
    expect((await json(response))['error_code'], 'deck_public_requires_cards');
    final after = await pool.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM decks WHERE user_id = CAST(@userId AS uuid)',
      ),
      parameters: {'userId': owner},
    );
    expect(after.single.single, before.single.single);
  }, skip: skipReason);

  test('PATCH muda só os metadados pedidos e não toca nas cartas', () async {
    final deckId = await seedDeck(userId: owner, cards: {islandId: 20});

    final response = await deck_route.onRequest(
      context(
        'PATCH',
        '/decks/$deckId',
        {
          'name': 'Renomeado $suffix',
          'description': 'depois',
          'archetype': 'control',
          'bracket': 3,
        },
        asUser: owner,
        capabilities: policy(),
      ),
      deckId,
    );
    final body = await json(response);

    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    final deck = await readDeck(deckId);
    expect(deck['name'], 'Renomeado $suffix');
    expect(deck['description'], 'depois');
    expect(deck['archetype'], 'control');
    expect(deck['bracket'], 3);
    expect(deck['is_public'], isFalse);
    expect(deck['cards'], {islandId: 20});
  }, skip: skipReason);

  test('PATCH publica com galeria e cartas; recusa deck vazio', () async {
    final withCards = await seedDeck(userId: owner, cards: {islandId: 20});
    final empty = await seedDeck(userId: owner);

    final published = await deck_route.onRequest(
      context(
        'PATCH',
        '/decks/$withCards',
        {'is_public': true},
        asUser: owner,
        capabilities: policy(gallery: true),
      ),
      withCards,
    );
    expect(published.statusCode, HttpStatus.ok);
    expect((await readDeck(withCards))['is_public'], isTrue);

    final refused = await deck_route.onRequest(
      context(
        'PATCH',
        '/decks/$empty',
        {'is_public': true, 'description': 'não pode'},
        asUser: owner,
        capabilities: policy(gallery: true),
      ),
      empty,
    );
    expect(refused.statusCode, HttpStatus.unprocessableEntity);
    expect((await json(refused))['error_code'], 'deck_public_requires_cards');
    final deck = await readDeck(empty);
    expect(deck['is_public'], isFalse);
    expect(deck['description'], 'antes', reason: 'a transação desfaz tudo');
  }, skip: skipReason);

  test('PATCH no deck de outra pessoa dá 404 sem mudar nada', () async {
    final deckId = await seedDeck(userId: owner, cards: {islandId: 20});

    final response = await deck_route.onRequest(
      context(
        'PATCH',
        '/decks/$deckId',
        {'description': 'invasão'},
        asUser: stranger,
        capabilities: policy(),
      ),
      deckId,
    );

    expect(response.statusCode, HttpStatus.notFound);
    expect((await readDeck(deckId))['description'], 'antes');
  }, skip: skipReason);

  test('remover carta tira só aquela linha', () async {
    final deckId = await seedDeck(
      userId: owner,
      cards: {islandId: 20, bearId: 4},
    );

    final response = await remove_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/cards/remove',
        {'card_id': bearId},
        asUser: owner,
        capabilities: policy(),
      ),
      deckId,
    );
    final body = await json(response);

    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    expect(body['removed_quantity'], 4);
    expect(body['total_cards'], 20);
    expect((await readDeck(deckId))['cards'], {islandId: 20});
  }, skip: skipReason);

  test('remover a última carta de um deck público o torna privado', () async {
    final deckId = await seedDeck(
      userId: owner,
      isPublic: true,
      cards: {bearId: 1},
    );

    final response = await remove_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/cards/remove',
        {'card_id': bearId},
        asUser: owner,
        capabilities: policy(gallery: true),
      ),
      deckId,
    );
    final body = await json(response);

    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    expect(body['total_cards'], 0);
    expect(body['is_public'], isFalse);
    expect(body['unpublished_because_empty'], isTrue);
    final deck = await readDeck(deckId);
    expect(deck['is_public'], isFalse);
    expect(deck['cards'], isEmpty);
  }, skip: skipReason);

  test('carta fora do deck e deck alheio dão 404 sem mudar nada', () async {
    final deckId = await seedDeck(userId: owner, cards: {islandId: 20});

    final missing = await remove_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/cards/remove',
        {'card_id': bearId},
        asUser: owner,
        capabilities: policy(),
      ),
      deckId,
    );
    expect(missing.statusCode, HttpStatus.notFound);
    expect((await json(missing))['error_code'], 'card_not_in_deck');

    final foreign = await remove_route.onRequest(
      context(
        'POST',
        '/decks/$deckId/cards/remove',
        {'card_id': islandId},
        asUser: stranger,
        capabilities: policy(),
      ),
      deckId,
    );
    expect(foreign.statusCode, HttpStatus.notFound);
    expect((await json(foreign))['error_code'], 'deck_not_found');
    expect((await readDeck(deckId))['cards'], {islandId: 20});
  }, skip: skipReason);

  test('PUT com lista vazia num deck público o torna privado', () async {
    final deckId = await seedDeck(
      userId: owner,
      isPublic: true,
      cards: {islandId: 20},
    );

    final response = await deck_route.onRequest(
      context(
        'PUT',
        '/decks/$deckId',
        {'cards': const []},
        asUser: owner,
        capabilities: policy(gallery: true),
      ),
      deckId,
    );

    expect(response.statusCode, HttpStatus.ok, reason: await response.body());
    final deck = await readDeck(deckId);
    expect(deck['cards'], isEmpty);
    expect(deck['is_public'], isFalse);
  }, skip: skipReason);
}
