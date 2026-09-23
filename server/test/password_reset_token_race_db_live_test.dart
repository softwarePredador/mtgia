@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';

/// BT-AUTH-003: a recuperação roda depois da resposta, então pedidos seguidos
/// da mesma conta criam tokens em transações que se sobrepõem. Cada pedido
/// novo continua invalidando o anterior: sobra um token vivo por conta.
///
/// Requer `RUN_PASSWORD_RESET_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = Platform.environment['RUN_PASSWORD_RESET_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  late Pool pool;

  setUpAll(() {
    if (!enabled) return;
    AuthService.resetForTesting();
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
      // Várias conexões, como o pool da API: o padrão do pacote é uma só, e
      // com uma conexão as transações nunca se sobrepõem.
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 10,
      ),
    );
    Database.useConnectionForTesting(pool);
  });

  tearDownAll(() async {
    if (!enabled) return;
    Database.resetForTesting();
    await pool.close();
  });

  test('pedidos simultâneos deixam um único token vivo', () async {
    final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final email = 'corrida_$suffix@example.invalid';
    await pool.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash)
        VALUES (@username, @email, 'x')
      '''),
      parameters: {'username': 'corrida_$suffix', 'email': email},
    );

    final requests = await Future.wait([
      for (var i = 0; i < 20; i++)
        AuthService().createPasswordResetRequest(email: email),
    ]);
    expect(requests.whereType<PasswordResetRequest>(), hasLength(20));

    final counts = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int,
               COUNT(*) FILTER (WHERE t.consumed_at IS NULL)::int
        FROM password_reset_tokens t
        JOIN users u ON u.id = t.user_id
        WHERE u.email = @email
      '''),
      parameters: {'email': email},
    );
    expect(counts.single[0], 20);
    expect(counts.single[1], 1, reason: 'tokens vivos para a mesma conta');
  }, skip: skipReason);
}
