@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../routes/community/marketplace/index.dart' as marketplace_route;
import 'support/scripted_pool.dart';

/// D-38 (SCOPE-P0-TRD-00), em PostgreSQL descartável: a busca global do
/// marketplace respeita `trade_visibility` como `/community/trade-matches`.
/// "Só seguidores" aparece só para quem segue; "ninguém" só para o dono; o
/// anônimo vê só quem abre as trocas para todos. A rota roda de verdade.
///
/// Requer `RUN_DECK_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// já migrado.
void main() {
  final enabled = Platform.environment['RUN_DECK_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final cardName = 'Marketplace Visibility $suffix';
  late Pool pool;
  final ids = <String, String>{};

  setUpAll(() async {
    if (!enabled) return;
    AuthService.resetForTesting();
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    Database.useConnectionForTesting(pool);

    Future<String> user(String key, String tradeVisibility) async {
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash, trade_visibility)
          VALUES (@username, @email, 'x', @visibility)
          RETURNING id::text
        '''),
        parameters: {
          'username': 'mkt_${key}_$suffix',
          'email': 'mkt_${key}_$suffix@example.invalid',
          'visibility': tradeVisibility,
        },
      );
      return ids[key] = result.single.single! as String;
    }

    await user('viewer', 'everyone');
    await user('followers_followed', 'followers');
    await user('followers_stranger', 'followers');
    await user('everyone', 'everyone');
    await user('nobody', 'none');

    final card = await pool.execute(
      Sql.named('''
        INSERT INTO cards (scryfall_id, name)
        VALUES (gen_random_uuid(), @name)
        RETURNING id::text
      '''),
      parameters: {'name': cardName},
    );
    final cardId = card.single.single! as String;

    for (final owner in const [
      'followers_followed',
      'followers_stranger',
      'everyone',
      'nobody',
    ]) {
      await pool.execute(
        Sql.named('''
          INSERT INTO user_binder_items (user_id, card_id, quantity, for_trade)
          VALUES (CAST(@userId AS uuid), CAST(@cardId AS uuid), 1, TRUE)
        '''),
        parameters: {'userId': ids[owner], 'cardId': cardId},
      );
    }
    await pool.execute(
      Sql.named('''
        INSERT INTO user_follows (follower_id, following_id)
        VALUES (CAST(@viewer AS uuid), CAST(@owner AS uuid))
      '''),
      parameters: {'viewer': ids['viewer'], 'owner': ids['followers_followed']},
    );
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'mkt\\_%\\_$suffix'},
    );
    await pool.execute(
      Sql.named('DELETE FROM cards WHERE name = @name'),
      parameters: {'name': cardName},
    );
    Database.resetForTesting();
    await pool.close();
  });

  Future<({Set<String> owners, int total})> search({String? as}) async {
    final token =
        as == null
            ? null
            : AuthService().generateToken(ids[as]!, 'mkt_${as}_$suffix');
    final response = await marketplace_route.onRequest(
      ScriptedRequestContext(
        Request.get(
          Uri.parse(
            'http://localhost/community/marketplace'
            '?search=${Uri.encodeQueryComponent(cardName)}&limit=50',
          ),
          headers: {
            if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
        providers: {Pool: pool},
      ),
    );
    expect(response.statusCode, HttpStatus.ok, reason: await response.body());
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    final owners = <String>{
      for (final item in (body['data'] as List).cast<Map<String, dynamic>>())
        ((item['owner'] as Map<String, dynamic>)['id'] ?? '').toString(),
    };
    return (owners: owners, total: (body['total'] as num).toInt());
  }

  test(
    'quem segue vê "só seguidores"; ninguém mais vê além do previsto',
    () async {
      final viewer = await search(as: 'viewer');
      expect(viewer.owners, {ids['everyone'], ids['followers_followed']});
      expect(viewer.total, 2, reason: 'a contagem usa as mesmas cláusulas');
    },
    skip: skipReason,
  );

  test('o anônimo vê só quem abre as trocas para todos', () async {
    final anonymous = await search();
    expect(anonymous.owners, {ids['everyone']});
    expect(anonymous.total, 1);
  }, skip: skipReason);

  test('"ninguém" continua visível para o próprio dono', () async {
    final owner = await search(as: 'nobody');
    expect(owner.owners, contains(ids['nobody']));
    expect(owner.owners, isNot(contains(ids['followers_followed'])));
    expect(owner.owners, isNot(contains(ids['followers_stranger'])));
  }, skip: skipReason);
}
